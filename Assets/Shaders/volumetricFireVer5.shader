Shader "Unlit/volumetricFireVer5"
{
	Properties
	{
		[Header(Fire Modeling)] [PowerSlider(3.0)] _ThickFireHeight("Thick Fire Height", Range(0.0, 300.0)) = 200.0
		_FireHeight("Fire Height", Range(0.0, 1.0)) = 0.143
		_FireFadeOutTreshold("Fire Fadeout Treshold", Range(0.0, 3.0)) = 0.75
		_FireShapeMultiplier("Fire Shape Multiplier", Range(0.0, 1.0)) = 0.25
		_Freq("Frequency", Float) = 4.4
		[Toggle] _DistortWithDetailNoise("Distort with detail noise", Range(0.0, 1.0)) = 1.0


		[Header(Fire Coloring)] _Strength("Strength", Range(0, 1.0)) = 0.345
		_ParticleAlpha("Per Particle Alpha", Range(0, 128.0)) = 64.0
		_DarkColor("Dark Color", Color) = (1, 0, 0, 1)
		_LightColor("Light Color", Color) = (0, 1, 1, 1)
		_ThirdColor("Third Color", Color) = (0.066, 0.5647, 0, 1)

		
		[Header(Smoke)] _SmokeColor("Smoke Color", Color) = (0.5,0.5,0.5,1)
		_SmokeHeight("Smoke Starting Height", Range(0,0.5)) = 0.05
		

		[Header(Animation)] _Speed("Overall Speed", Range(0.0, -3.0)) = -1.96
		_UpwardsSpeed("Upwards Speed", Range(0.0, 2.0)) = 0.5
		_WobbleSpeed("Sideways Wobble Speed", Range(0.0, 12.0)) = 1.0
		_DistortionSpeed("Distortion Speed", Range(0.0, 4.0)) = 2.0


		[Header(Rendering)] [IntRange] _Steps("Steps", Range(2, 256)) = 128
		[Toggle] _RandomOffset("Random Offset Toggle", float) = 1
		
		
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" }
		LOD 100
        
		Cull Back // Cull Back also provides some interesting results, but is more cartoonish (originally Cull Off)
		Blend SrcAlpha One
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
				_WobbleSpeed
			;

			uniform fixed4
				_DarkColor,
				_LightColor,
				_ThirdColor,
				_SmokeColor
			;

			uniform int _Steps;

			#define STEP_SIZE 1.0 / _Steps
			
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

			fixed4 raymarch(float4 start, float3 direction, float randomOffsetAmount)
			{
				fixed4 c = fixed4(_DarkColor.rgb, 0);
				float4 p = start;
				float3 direcionStep = direction * STEP_SIZE;

				float3 randomOffset = direcionStep * randomOffsetAmount;
				p +=  float4(randomOffset, 0.0);
				
				float4 timeOffset = float4(cos(_Time.x * _Speed * _WobbleSpeed), _Time.w * _Speed * _UpwardsSpeed / _Freq, cos(_Time.x * _Speed  * _WobbleSpeed * 0.9 + 1.0) + 2.0,  _Time.x * _Speed * _DistortionSpeed);

				for (int i = 0; i < _Steps * 1.73205; i++)
				{
					float height = max(p.y * 2 + 1, 0.0) * _FireHeight;
					float fireSample = sampleFire(p + timeOffset, height);

					c.a += fireSample * _ParticleAlpha * STEP_SIZE;
					c.rgb += (_LightColor + _ThirdColor) * fireSample * STEP_SIZE; // this doesn't even seem to do anything

                    c.rgb = lerp(c.rgb, _SmokeColor, height * _SmokeHeight); // change color based on height, maybe even could try multi colored gradients
					
				//	c.rgb += mad(_Time, 2.0, -0,5) / 255;
					
					if (c.a >= 1.0 || abs(p.x) > 0.5027 || abs(p.y) > 0.5027 || abs(p.z) > 0.5027) {
						break;
					}
					p += float4(direcionStep, 0.0);
				}
				c = clamp(c, 0.0, 1.0);
				return c;
			}
			
			fixed4 frag(v2f i) : SV_Target
			{
			
				//float ns = snoise(i.srcPos) / 2 + 0.5f;
				//return float4(ns, ns, ns, ns);
				//float ns = pow(1 - max(i.localPos.y * 2 + 1, 0.0), 5);
				//return float4(ns, ns, ns, 1.0);
				//_Time.y = 0;

				//float4 srcPos = float4(i.localPos.x + cos(_Time.x * _Speed),
				//					   i.localPos.y + (_Time.w * _Speed * _UpwardsSpeed) / _Freq,
				//					   i.localPos.z + cos(_Time.x * _Speed * 0.9 + 1.0)  + 2.0,
				//					   _Time.x * _Speed * _DistortionSpeed);

				float randomOffsetAmount = getRandomOffsetAmount(i.uv);

				return raymarch(float4(i.localPos, 0.0), normalize(i.wPos - _WorldSpaceCameraPos), randomOffsetAmount);
			}
			ENDCG

		}

	}
}
