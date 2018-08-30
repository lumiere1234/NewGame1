// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'




Shader "Custom/Wing_Transparent_2Scroll_mask_2999" {
Properties {
	_MainTex ("Base layer (RGBA)", 2D) = "white" {}
	_Color01("Main_Texture_Color", Color) = (0.5,0.5,0.5,1)
	_Alpha ("Alpha", Range(0.0, 1)) = 1
	_FxAmount ("Fx", Range(0, 1)) = 1

	_Cutoff ("Base Alpha cutoff", Range (0.1 ,1)) = .9

	_ScrollMaskTex("Scroll Mask", 2D) = "white" {}
	_Blend_Texture("Blend_Texture", 2D) = "black" {}
	_Color02("Blend_Texture_Color", Color) = (0.5,0.5,0.5,1)
	_Blend_Texture01("Blend_Texture01", 2D) = "black" {}
	_Color03("Blend_Texture_Color", Color) = (0.5,0.5,0.5,1)
	_Speeds("TextureSpeeds", Vector) = (1,1,-1,1)
}

SubShader {
	Tags { "Queue"="Transparent-1"  "IgnoreProjector"="True" "RenderType"="Transparent" }
	
	LOD 100
	
		
	CGINCLUDE
	
	#include "UnityCG.cginc"
	sampler2D _MainTex;

	float4 _MainTex_ST;
	fixed _Cutoff;
	fixed _Alpha;
	fixed _FxAmount;

	sampler2D _ScrollMaskTex;
	float4 _ScrollMaskTex_ST;
	sampler2D _Blend_Texture;
	float4 _Blend_Texture_ST;
	sampler2D _Blend_Texture01;
	float4 _Blend_Texture01_ST;

	fixed3 _Color01;
	fixed3 _Color02;
	fixed3 _Color03;	

	float4 _Speeds;
	
	struct v2f {
				float4 pos : SV_POSITION;
				half2 uv_MainTex : TEXCOORD0;
				half2 uv_MaskTex : TEXCOORD1;
				float2 uv_Blend_Tex : TEXCOORD2;
				float2 uv_Blend_Tex01 : TEXCOORD3;
	};

	
	v2f vert (appdata_full v)
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		
		float4 speeds = _Speeds * _Time.x;
		o.uv_MainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
		o.uv_MaskTex = TRANSFORM_TEX(v.texcoord, _ScrollMaskTex);
		o.uv_Blend_Tex = TRANSFORM_TEX(v.texcoord.xy,_Blend_Texture) + frac(float2(speeds.x, speeds.y) );
		o.uv_Blend_Tex01 = TRANSFORM_TEX(v.texcoord.xy,_Blend_Texture01) + frac(float2(speeds.z, speeds.w) );
		return o;
	}

	fixed4 frag (v2f i) : COLOR
	{
		fixed4 col;
		col = tex2D(_MainTex, i.uv_MainTex);
		
		clip( col.a - _Cutoff);
		col = fixed4( col.rgb * _Color01 *2, col.a * _Alpha);
		return col;
	}

	fixed4 fragA(v2f i) : COLOR
	{
		fixed4 col;
		col = tex2D(_MainTex, i.uv_MainTex);
		col = fixed4( col.rgb * _Color01 *2, col.a * _Alpha);
		return col;
	}
	
	fixed4 fragFx(v2f i) : COLOR
	{
		fixed4 col;
		col = tex2D(_MainTex, i.uv_MainTex);
		fixed mask = tex2D(_ScrollMaskTex, i.uv_MaskTex);
		fixed3 blendTex = tex2D(_Blend_Texture,i.uv_Blend_Tex) * _Color02 *2;
		fixed3 blendTex1 = tex2D(_Blend_Texture01,i.uv_Blend_Tex01)* _Color03 *2;

		// fade out the model first, then fade the fx
		col = fixed4(  + ((1-mask *_Alpha)* _FxAmount) * (blendTex + blendTex1),  _FxAmount * saturate(  col.a * 5) );
		return col;
	}		
	ENDCG


	Pass {
		Cull Off
		ZWrite on
		ZTest Less
		AlphaTest Greater [_Cutoff]
		Blend SrcAlpha OneMinusSrcAlpha
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		ENDCG 
	}	
	pass{
		Cull Off
        ZWrite off
        ZTest Less
        AlphaTest LEqual [_Cutoff]
        Blend SrcAlpha OneMinusSrcAlpha
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment fragA
		ENDCG 

	}
	// scroll fx pass
	pass{
		Cull Off
        ZWrite off
        ZTest LEqual
        Blend SrcAlpha One
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment fragFx
		ENDCG 

	}
}
}
