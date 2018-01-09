// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/volumetricFireVer5"
{
	Properties
	{
		[Header(Fire Modeling)] [PowerSlider(3.0)] _ThickFireHeight("Thick Fire Height", Range(0.0, 300.0)) = 200.0
		_FireHeight("Fire Height", Range(0.0, 1.0)) = 0.143
		_FireFadeOutTreshold("Fire Fadeout Treshold", Range(0.0, 3.0)) = 0.75
		_FireShapeMultiplier("Fire Shape Multiplier", Range(0.0, 1.0)) = 0.25
		_Freq("Frequency", Range(0.0, 50.0)) = 4.4
		[Toggle] _DistortWithDetailNoise("Distort with detail noise", Range(0.0, 1.0)) = 1.0


		[Header(Fire Coloring)] _Strength("Strength", Range(0, 1.0)) = 0.345
		_StrengthMultiplier("Strength Multiplier", Range(1.0, 30.0)) = 15.0
		_ParticleAlpha("Per Particle Alpha", Range(0, 128.0)) = 64.0
		_DarkColor("Dark Color", Color) = (1, 0, 0, 1)
		_LightColor("Light Color", Color) = (0, 1, 1, 1)
		_ThirdColor("Third Color", Color) = (0.066, 0.5647, 0, 1)
		_Contrast("Contrast", Range(0.0, 2.0)) = 1.0
		_Brightness("Brightness", Range(-1.0, 1.0)) = 0.0

		
		[Header(Smoke)] _SmokeColor("Smoke Color", Color) = (0.5,0.5,0.5,1)
		_SmokeHeight("Smoke Starting Height", Range(0,0.5)) = 0.05
		_SmokeStrength("Smoke Strength", Range(0.0, 400.0)) = 200.0
		

		[Header(Animation)] _Speed("Overall Speed", Range(0.0, 3.0)) = 1.96
		_UpwardsSpeed("Upwards Speed", Range(0.0, 2.0)) = 0.5
		_WobbleSpeed("Sideways Wobble Speed", Range(0.0, 12.0)) = 1.0
		_DistortionSpeed("Distortion Speed", Range(0.0, 4.0)) = 2.0


		[Header(Rendering)] [IntRange] _Steps("Steps", Range(2, 256)) = 128
		[Toggle] _RandomOffset("Random Offset Toggle", Range(0.0, 1.0)) = 1.0
		[KeywordEnum(Off, Front, Back)] _Cull("Cull", Float) = 1.0
		[Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc("Blend source mode", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _BlendDst("Blend destination mode", Float) = 1
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" }
		LOD 100
        
		Cull [_Cull] // Cull Back also provides some interesting results, but is more cartoonish (originally Cull Off)
		Blend [_BlendSrc] [_BlendDst]
		ZTest Always
		ZWrite Off
		

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			// https://github.com/ashima/webgl-noise
			#include "noiseSimplex.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				//float4 srcPos : TEXCOORD0;
				float3 wPos : TEXCOORD1;
				float3 localPos : TEXCOORD2;
				float2 uv : TEXCOORD3;
			};

			uniform float
				_Freq,
				_Speed,
				_Strength,
				_ParticleAlpha,
				_SmokeHeight,
				_RandomOffset,
				_FireHeight,
				_FireShapeMultiplier,
				_FireFadeOutTreshold,
				_ThickFireHeight,
				_UpwardsSpeed,
				_DistortionSpeed,
				_DistortWithDetailNoise,
				_WobbleSpeed,
				_SmokeStrength,
				_StrengthMultiplier,
				_Brightness,
				_Contrast
			;

			uniform fixed4
				_DarkColor,
				_LightColor,
				_ThirdColor,
				_SmokeColor
			;

			uniform int _Steps;

			#define STEP_SIZE 1.73205 / _Steps
			
			v2f vert (appdata v)
			{
				v2f o;

				o.localPos = v.vertex.xyz;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				o.uv = ComputeScreenPos(o.pos);

				return o;
			}

			float rand(float2 co)
			{
				float a = 12.9898;
				float b = 78.233;
				float c = 43758.5453;
				float dt = dot(co.xy, float2(a, b));
				float sn = fmod(dt, 3.14);

				return 2.0 * frac(sin(sn) * c) - 1.0;
			}

			float getRandomOffsetAmount(float2 uv) {
				return abs(rand(_Time.zw + uv)) * _RandomOffset;
			}

			// Remaps value from one range to other range, e.g. 0.2 from range (0.0, 0.4) to range (0.0, 1.0) becomes 0.5 
			float remap(float value, float original_min, float original_max, float new_min, float new_max)
			{
				return new_min + (((value - original_min) / (original_max - original_min)) * (new_max - new_min));
			}

			float sampleFire(float4 pos, float height)
			{
				float detailSample = abs(snoise(pos * _Freq) * 2.0 + snoise(pos * _Freq * 2.0)) / 3.0;

				float shapeSample = snoise(pos.xyz * _Freq * 0.7) + snoise(pos.xyz * _Freq * 0.3 + float3(detailSample, detailSample, detailSample) * _DistortWithDetailNoise);
				shapeSample *= _FireShapeMultiplier;

				//float fireSample = max(0.00, shapeSample) - max(detailSample - 0.8, 0.0);
				float fireSample = remap(shapeSample, detailSample, 1.0, 0.0, 1.0);

				float heightFadeOut = height * _FireFadeOutTreshold;
				float heightFadeIn =  pow(1.0 - height, _ThickFireHeight);

				fireSample -= heightFadeOut;
				fireSample += heightFadeIn;

				fireSample = max(0.0, fireSample) * pow(_Strength, 2);

				return fireSample;
			}

			// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
			float sdBox(float3 p, float3 b)
			{
				float3 d = abs(p) - b;
				return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
			}

			fixed4 raymarch(float4 start, float4 direction, float randomOffsetAmount)
			{
				float stepSize = STEP_SIZE;
				fixed4 c = fixed4(_DarkColor.rgb, 0);
				float4 p = start;
				float4 direcionStep = direction * stepSize;

				float4 randomOffset = direcionStep * randomOffsetAmount;
				p +=  randomOffset;
				
				float4 timeOffset = float4(cos(_Time.x * -_Speed * _WobbleSpeed), _Time.w * -_Speed * _UpwardsSpeed / _Freq, cos(_Time.x * -_Speed  * _WobbleSpeed * 0.9 + 1.0) + 2.0,  _Time.x * -_Speed * _DistortionSpeed);

				float smokeLerpConstant = _SmokeHeight * stepSize * _SmokeStrength * saturate((1.0 - dot(direction.xyz, float3(0.0, 1.0, 0.0)))); // the dot product makes it so when looking from bottom or top, it looks correct.

				for (int i = 0; i < _Steps; i++)
				{
					float height = max(p.y * 2 + 1, 0.0) * _FireHeight;
					float fireSample = sampleFire(p + timeOffset, height);

					float4 particle = float4((_LightColor + _ThirdColor).rgb, fireSample);

					particle.rgb *= particle.a;

					c = (1.0 - c.a) * particle * min(1.0, stepSize * _StrengthMultiplier) + c;
					c.rgb = lerp(c.rgb, _SmokeColor, saturate(height *smokeLerpConstant)); // change color based on height, maybe even could try multi colored gradients

					// Old color way
					//c.a += fireSample * _ParticleAlpha * stepSize;
					//  //c.rgb += (_LightColor + _ThirdColor) * fireSample * stepSize; // this doesn't even seem to do anything

					// c.rgb = lerp(c.rgb, _SmokeColor, saturate(height * _SmokeHeight * stepSize * _SmokeStrength)); // change color based on height, maybe even could try multi colored gradients


				//	c.rgb += mad(_Time, 2.0, -0,5) / 255;
#if 1 // 1 kasutab esimest if statementi, 0 kasutab teist. Enda testimisega jõudlus mõlemaga sama, ei suutnud märgatavat erinevust leida.
					if (c.a >= 0.99 || abs(p.x) > 0.5027 || abs(p.y) > 0.5027 || abs(p.z) > 0.5027) {
						break;
					}
#else
					if (c.a >= 0.99 || sdBox(p.xyz, float3(0.5, 0.5, 0.5)) > 0.0) {
						break;
					}
#endif

					p += direcionStep;
				}
				// c = saturate(c);
				return c;
			}
			
			fixed4 frag(v2f i) : SV_Target
			{
				//float ns = snoise(i.srcPos) / 2 + 0.5f;
				//return float4(ns, ns, ns, ns);
				//float ns = pow(1 - max(i.localPos.y * 2 + 1, 0.0), 5);
				//return float4(ns, ns, ns, 1.0);
				//_Time.y = 0;
				float randomOffsetAmount = getRandomOffsetAmount(i.uv);
				
				float4 color = raymarch(float4(i.localPos, 0.0), float4(normalize(i.wPos - _WorldSpaceCameraPos), 0.0), randomOffsetAmount);

				// https://stackoverflow.com/questions/944713/help-with-pixel-shader-effect-for-brightness-and-contrast
				//color.rgb /= color.a;
				// Apply contrast.
				color.rgb = ((color.rgb - 0.5f) * max(_Contrast, 0)) + 0.5f;

				// Apply brightness.
				color.rgb += _Brightness;

				// Return final pixel color.
				//color.rgb *= color.a;

				return saturate(color);
			}
			ENDCG

		}

	}
}
