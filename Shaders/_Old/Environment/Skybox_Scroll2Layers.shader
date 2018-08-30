// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// - Unlit
// - Scroll 2 layers /w Multiplicative op

Shader "Custom/SkyBox/Skybox - Scroll 2 Layers" {
Properties {
	_MainTex ("Base layer (RGB)", 2D) = "white" {}
	_DetailTex ("Cloud layer (RGBA)", 2D) = "black" {}
	_ScrollX ("Base layer Scroll speed", Float) = 0.1
	_Scroll2X ("Cloud layer speed", Float) = 0.5
	_AMultiplier ("Layer Multiplier", Float) = 1
}

SubShader {
	Tags { "Queue"="Geometry+10" "RenderType"="Opaque" }
	
	Lighting Off Fog { Mode Off }
	ZWrite Off
	
	LOD 100
	
		
	CGINCLUDE
	#pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
	#include "UnityCG.cginc"
	sampler2D _MainTex;
	sampler2D _DetailTex;

	float4 _MainTex_ST;
	float4 _DetailTex_ST;
	
	float _ScrollX;
	float _Scroll2X;
	float _AMultiplier;
	
	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float2 uv2 : TEXCOORD1;
		fixed4 color : TEXCOORD3;		
	};

	
	v2f vert (appdata_full v)
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		fixed2 offsetUV = frac( float2(_ScrollX, _Scroll2X) * _Time.xx);
		o.uv = TRANSFORM_TEX(v.texcoord.xy,_MainTex) + float2(offsetUV.x, 0) ;
		o.uv2 = TRANSFORM_TEX(v.texcoord.xy,_DetailTex) + float2(offsetUV.y, 0) ;
		o.color =   fixed4(_AMultiplier, _AMultiplier, _AMultiplier, _AMultiplier);

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
			
			o = lerp( tex, tex2, tex2.a)* i.color;
			
			return o;
		}
		ENDCG 
	}	
}
}
