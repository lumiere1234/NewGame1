// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// - Unlit
// - Scroll 2 layers /w Multiplicative op

Shader "Custom/SkyBox/Skybox - Scroll 3 Layers ClampY" {
Properties {
	_MainTex ("Base layer (RGB)", 2D) = "white" {}
	_DetailTex ("Cloud layer (RGBA)", 2D) = "black" {}
	_DetailTex2 ("Cloud layer2 (RGBA)", 2D) = "black" {}
	_ScrollX ("Base layer Scroll speed", Float) = 0.1
	_Scroll2X ("Cloud layer speed", Float) = 0.5
	_Scroll3X ("Cloud layer2 speed", Float) = 1.0
	_AMultiplier ("Layer Multiplier", Float) = 1
	_Color2 ("multi color", Color) = (1,1,1,1)
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
	sampler2D _DetailTex2;

	float4 _MainTex_ST;
	float4 _DetailTex_ST;
	float4 _DetailTex2_ST;
	float4 _Color2;
	
	float _ScrollX;
	float _Scroll2X;
	float _Scroll3X;
	float _AMultiplier;
	
	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float2 uv2 : TEXCOORD1;
		float2 uv3 : TEXCOORD2;
		fixed4 color : TEXCOORD3;		
	};

	
	inline float2 Tranform_Tex_ClampY( float2 uv, float4 st, float offset){
		return float2(uv.x * st.x - st.z + offset, saturate(uv.y * st.y - st.w));
	}
	

	v2f vert (appdata_full v)
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		fixed3 offsetUV = frac( float3(_ScrollX, _Scroll2X, _Scroll3X) * _Time.xxx);
		o.uv = TRANSFORM_TEX(v.texcoord.xy,_MainTex) + float2(offsetUV.x, 0) ;

		o.uv2 = Tranform_Tex_ClampY(v.texcoord.xy, _DetailTex_ST, offsetUV.y);
		o.uv3 = Tranform_Tex_ClampY(v.texcoord.xy, _DetailTex2_ST, offsetUV.z);
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
			fixed4 tex3 = tex2D (_DetailTex2, i.uv3);
			
			o = lerp( lerp( tex, tex2, tex2.a), tex3,tex3.a )* i.color*_Color2;
			
			return o;
		}
		ENDCG 
	}	
}
}
