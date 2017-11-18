Shader "Unlit/volumetricFire"
{
	Properties
	{
		_Freq("Frequency", Float) = 1
		_Speed("Speed", Float) = 1
		_DarkColor("Dark Color", Color) = (0, 0, 0, 1)
		_LightColor("Light Color", Color) = (0.7, 0.5, 0, 1)
		_ThirdColor("Third Color", Color) = (0.5, 0.5, 0, 1)

	}
		SubShader
	{
		Tags{ "Queue" = "Transparent" }
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
		//float4 srcPos : TEXCOORD0;
		float3 wPos : TEXCOORD1;
		float3 localPos : TEXCOORD2;
	};

	uniform float
		_Freq,
		_Speed
		;

	uniform fixed4
		_DarkColor,
		_LightColor,
		_ThirdColor
		;

#define STEPS 128
#define STEP_SIZE 1.0 / STEPS

	v2f vert(appdata v)
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
		fixed4 c = fixed4(1, 1, 1, 0);
		float3 p = start;
		float4 np = srcPos;
		float3 direcionStep = direction * STEP_SIZE;
		float ns = 0;

		float3 shapeOffset = float3(cos(_Time.y * _Speed / 10), _Time.y * _Speed / 4, cos(_Time.y * _Speed / 12 + 1) + 2);

		for (int i = 0; i < STEPS * 1.44; i++)
		{
			ns = snoise(np * _Freq);
			float shapeSample = snoise((p + shapeOffset) * 2) * 4 + snoise(p + shapeOffset) * 4;

			float test = max(p.y * 2, 0.0);

			c.a += max(ns + min(shapeSample, 0.0) - test, 0.0); //max(ns, 0.0);//max(nsLow, 0.0);//
			if (c.a >= 1.0 || abs(p.x) > 0.5027 || abs(p.y) > 0.5027 || abs(p.z) > 0.5027) {
				break;
			}
			p += direcionStep;
			np += float4(direcionStep, 0.0);
		}
		ns = pow(clamp(ns / 2 + 0.5f, 0.0, 1.0), 2);

		float w1 = pow(1 - ns, 2);
		float w2 = 2 * ns * (1 - ns);
		float w3 = pow(ns, 2);
		c.rgb = _DarkColor * w1 + _ThirdColor * w2 + _LightColor * w3;
		c.a = clamp(c.a, 0.0, 1.0);
		return c;
	}

	fixed4 frag(v2f i) : SV_Target
	{
		//float ns = snoise(i.srcPos) / 2 + 0.5f;
		//return float4(ns, ns, ns, ns);
		//float ns = ;
		//return float4(ns, ns, ns, 1.0);
		float4 srcPos = float4(i.localPos.x, i.localPos.y + (_Time.y * _Speed) / _Freq, i.localPos.z, (_Time.y * _Speed) / _Freq);
		return raymarch(i.localPos, normalize(i.wPos - _WorldSpaceCameraPos), srcPos);
	}
		ENDCG
	}
	}
}