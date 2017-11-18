Shader "Unlit/volumetricFire"
{
	Properties
	{
		_Freq("Frequency", Float) = 1
		_Speed("Speed", Float) = 1
		
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" }
		LOD 100

		Blend SrcAlpha OneMinusSrcAlpha

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
				float3 srcPos : TEXCOORD0;
			};

			uniform float
				_Freq,
				_Speed
			;
			
			v2f vert (appdata v)
			{
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);

				o.srcPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.srcPos *= _Freq;
				o.srcPos.y += _Time.y * _Speed;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				float ns = snoise(i.srcPos) / 2 + 0.5f;
				return float4(ns, ns, ns, 1.0f);
			}
			ENDCG
		}
	}
}
