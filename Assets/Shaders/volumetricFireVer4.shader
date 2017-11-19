Shader "Unlit/volumetricFireVer4"
{
	Properties
	{
		_Freq("Frequency", Float) = 1
		_Speed("Speed", Float) = 1
		_Strength("Strength", Range(0, 1.0)) = 0.5
		_DarkColor("Dark Color", Color) = (0, 0, 0, 1)
		_LightColor("Light Color", Color) = (0.7, 0.5, 0, 1)
		_ThirdColor("Third Color", Color) = (0.5, 0.5, 0, 1)
		
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" }
		LOD 100

		Blend SrcAlpha One

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
			};

			uniform float
				_Freq,
				_Speed,
				_Strength
			;

			uniform fixed4
				_DarkColor,
				_LightColor,
				_ThirdColor
			;

			#define STEPS 128
			#define STEP_SIZE 1.0 / STEPS
			
			v2f vert (appdata v)
			{
				v2f o;

				o.localPos = v.vertex.xyz;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				//o.srcPos = mul(unity_ObjectToWorld, v.vertex);
				//o.srcPos *= _Freq;
				//o.srcPos.y += _Time.y * _Speed;
				//o.srcPos.w = _Time.y * _Speed / 4.0;

				return o;
			}

			// Remaps value from one range to other range, e.g. 0.2 from range (0.0, 0.4) to range (0.0, 1.0) becomes 0.5 
			float remap(float value, float original_min, float original_max, float new_min, float new_max)
			{
				return new_min + (((value - original_min) / (original_max - original_min)) * (new_max - new_min));
			}

			fixed4 raymarch(float3 start, float3 direction, float4 srcPos)
			{
				fixed4 c = fixed4(_DarkColor.rgb, 0);
				float3 p = start;
				float4 np = srcPos;
				float3 direcionStep = direction * STEP_SIZE;
				
				float3 shapeOffset = float3(cos(_Time.y * _Speed * 0.1), _Time.y * _Speed * 0.5, cos(_Time.y * _Speed * 0.083 + 1) + 2);

				for (int i = 0; i < STEPS * 1.44; i++)
				{
					float detailSample = 1 - abs(snoise(np * _Freq) + snoise(np * _Freq * 2)) * 0.5;
					float shapeSample = snoise((p + shapeOffset) * _Freq * 0.7) + snoise(p + shapeOffset * _Freq * 0.14 + float3(detailSample, detailSample, -detailSample));

					shapeSample = remap(shapeSample, -2, 2, -0.5, 0.5);
					float height = max(p.y * 2 + 1, 0.0) * 0.143;

					float fireSample = (max(0.00, shapeSample - height + pow(1 - height * 7, 5) + min(detailSample, 0.0) * 2) - (max(detailSample - 0.8, 0.0) * 1.4));

					fireSample = max(0.0, fireSample) * pow(_Strength, 2);

					c.a += fireSample * 0.5;
					c.rgb += (_LightColor + _ThirdColor) * fireSample * c.a ;
					//c.a += max(0.0, shapeSample - 0.5 - test / 7 + min(detailSample, 0.0) * 2);
					//c.a += max(ns + min(shapeSample, 0.0) - test, 0.0); //max(ns, 0.0);//max(nsLow, 0.0);//
					if (c.a >= 1.0 || abs(p.x) > 0.5027 || abs(p.y) > 0.5027 || abs(p.z) > 0.5027) {
						break;
					}
					p += direcionStep;
					np += float4(direcionStep, 0.0);
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
				float4 srcPos = float4(i.localPos.x + cos(_Time.y * _Speed) * 0.1,
									   i.localPos.y + (_Time.y * _Speed * 2.5) / _Freq,
									   i.localPos.z + cos(_Time.y * _Speed / 1.1 + 1) * 0.1 + 2,
									   _Time.y * _Speed * 0.15);
				return raymarch(i.localPos, normalize(i.wPos - _WorldSpaceCameraPos), srcPos);
			}
			ENDCG
		}
	}
}
