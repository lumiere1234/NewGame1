// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Chp/FX/Mask Additive Scroll" {
Properties {
	_MainTex ("Base layer (RGB)", 2D) = "white" {}
	_MaskTex( "mask (RGB)", 2D) = "white" {}
	_ScrollX ("Base layer Scroll speed X", Float) = 1.0
	_ScrollY ("Base layer Scroll speed Y", Float) = 0.0
	
	_AMultiplier ("Layer Multiplier", Float) = 2
	_Color("Color", Color) = (1,1,1,1)
	
}

SubShader {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	
	Blend One One
	
//	Blend One OneMinusSrcColor
	Cull Off Lighting Off ZWrite Off Fog { Mode Off }
	
	LOD 100
	
		
	CGINCLUDE
	#include "UnityCG.cginc"
	sampler2D _MainTex;
	sampler2D _DetailTex;
	sampler2D _MaskTex;
	

	float4 _MainTex_ST;
	float4 _MaskTex_ST;
	
	float _ScrollX;
	float _ScrollY;

	float _AMultiplier;
	float4 _Color;
	
	
	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float2 uv1 : TEXCOORD1;

		fixed4 color : TEXCOORD2;		
	};

	
	v2f vert (appdata_base v)
	{
		v2f o;

		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = TRANSFORM_TEX(v.texcoord.xy,_MaskTex) + frac(float2(_ScrollX, _ScrollY) * float2(_Time.y, _Time.y));
		o.uv1 = TRANSFORM_TEX(v.texcoord.xy,_MaskTex);
		
		o.color = fixed4(_AMultiplier, _AMultiplier, _AMultiplier, _AMultiplier)*_Color;
		
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
			fixed4 tex = tex2D (_MainTex, i.uv);
			
			fixed4 mask = tex2D (_MaskTex, i.uv1);
			
			o = tex *mask *i.color ;
			
			return o;
		}
		ENDCG 
	}	
}
}
