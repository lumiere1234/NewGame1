// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Chp/Particles/Additive Tint TwoSide Brighter fragment" {
Properties {
	_TintColor("Color", Color) = (0.5,0.5,0.5,0.5)
	_MainTex ("Base layer (RGB)", 2D) = "white" {}
}

SubShader {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	
	Blend SrcAlpha One
	

	Cull Off Lighting Off ZWrite Off Fog { Mode Off }
	
		
	CGINCLUDE
	#include "UnityCG.cginc"
	sampler2D _MainTex;
	float4 _MainTex_ST;
	
	float4 _TintColor;
	
	
	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;

	};

	
	v2f vert (appdata_base v)
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = TRANSFORM_TEX(v.texcoord.xy,_MainTex);
		return o;
	}
	ENDCG


	Pass {
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma fragmentoption ARB_precision_hint_fastest		
		fixed4 frag (v2f i) : COLOR
		{
			fixed4 o;
			o = tex2D (_MainTex, i.uv) * _TintColor *2;
			return o;
		}
		ENDCG 
	}	
}
}
