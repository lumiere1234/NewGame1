// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/FxWall" {
Properties {
	_MainTex ("Base layer (RGB)", 2D) = "white" {}
	_DetailTex ("2nd layer (RGB)", 2D) = "white" {}
	_MaskTex( "mask (RGB)", 2D) = "white" {}
	_ScrollX ("Base layer Scroll speed X", Float) = 1.0
	_ScrollY ("Base layer Scroll speed Y", Float) = 0.0
	_Scroll2X ("2nd layer Scroll speed X", Float) = 1.0
	_Scroll2Y ("2nd layer Scroll speed Y", Float) = 0.0
	_Scroll3X ("3nd layer Scroll speed X", Float) = 1.0
	_Scroll3Y ("3nd layer Scroll speed Y", Float) = 0.0
	
	_AMultiplier ("Layer Multiplier", Float) = 0.5
	_Color("Color", Color) = (1,1,1,1)
	
}

SubShader {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	
	Blend One One
	
//	Blend One OneMinusSrcColor
	Cull Off Lighting Off ZWrite Off Fog { Mode Off }
	
	LOD 100
	
		
	CGINCLUDE
	#pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
	#include "UnityCG.cginc"
	sampler2D _MainTex;
	sampler2D _DetailTex;
	sampler2D _MaskTex;
	

	float4 _MainTex_ST;
	float4 _DetailTex_ST;
	float4 _MaskTex_ST;
	
	float _ScrollX;
	float _ScrollY;
	float _Scroll2X;
	float _Scroll2Y;
	float _Scroll3X;
	float _Scroll3Y;
	float _AMultiplier;
	float4 _Color;
	
	
	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float2 uv2 : TEXCOORD1;
		float2 uv3 : TEXCOORD2;
		fixed4 color : TEXCOORD3;		

	};

	
	v2f vert (appdata_full v)
	{
		v2f o;
//				float3	viewPos		= mul(UNITY_MATRIX_MV,v.vertex);
//		float		dist			= length(viewPos);
//		float		nfadeout	= saturate(dist / _FadeOutDistNear);
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = TRANSFORM_TEX(v.texcoord.xy,_MainTex) + frac(float2(_ScrollX, _ScrollY) * _Time);
		o.uv2 = TRANSFORM_TEX(v.texcoord.xy,_DetailTex) + frac(float2(_Scroll2X, _Scroll2Y) * _Time);
		o.uv3 = TRANSFORM_TEX(v.texcoord.xy,_MaskTex) + frac(float2(_Scroll3X, _Scroll3Y) * _Time);
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
			fixed4 tex2 = tex2D (_DetailTex, i.uv2);
			fixed4 tex3 = tex2D (_MaskTex, i.uv3);
			
			o = tex *tex2 * tex3 *i.color ;
			o = tex *tex3*tex2 *i.color;
			return o;
		}
		ENDCG 
	}	
}
}
