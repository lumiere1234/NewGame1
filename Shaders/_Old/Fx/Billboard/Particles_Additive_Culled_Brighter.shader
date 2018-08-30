// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// brighter than moblie particle, same looking as particle/additive
Shader "Billboard/Additive Tint TwoSide Brighter" {
	Properties {
		_TintColor("Color", Color) = (0.5,0.5,0.5,0.5)
		_MainTex ("Base layer (RGB)", 2D) = "white" {}
	}

	CGINCLUDE
	#include "UnityCG.cginc"
	sampler2D _MainTex;
	float4 _MainTex_ST;
	float4 _TintColor;
	
	struct appdata {
	    float4 vertex : POSITION;
	    float4 color : COLOR;
	    float4 texcoord : TEXCOORD0;
	};

	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float4 color : Color;
	};

	v2f vert (appdata v)
	{
		v2f o;
		float3 turnDir = _WorldSpaceCameraPos.xyz - mul( unity_ObjectToWorld, v.vertex );
		float3 y = float3(0, 1, 0);
		float3 x = normalize(cross(turnDir, y));
		float3 z = normalize(cross(y, x));
		float4x4 modelMatrix = float4x4
		(
			x.x, y.x, z.x, 0,
			x.y, y.y, z.y, 0,
			x.z, y.z, z.z, 0,
			0, 0, 0, 1
		);
		o.pos = UnityObjectToClipPos(mul(modelMatrix, v.vertex));
		o.uv = TRANSFORM_TEX(v.texcoord.xy,_MainTex);
		o.color = v.color;
		return o;
	}
	fixed4 frag (v2f i) : COLOR
	{
		fixed4 o;
		o = tex2D (_MainTex, i.uv) * _TintColor * 2 * i.color;
		return o;
	}
	ENDCG

	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		
		Cull Off Lighting Off ZWrite Off Fog { Mode Off }
		Blend SrcAlpha OneMinusSrcAlpha

		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest		

			ENDCG 
		}	
	}
	CustomEditor "CustomRendererQueueMaterialEditor"
}

