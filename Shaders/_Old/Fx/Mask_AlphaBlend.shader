// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Chp/FX/Mask AlphaBlend" {
Properties {
	_MainTex ("Base layer (RGB)", 2D) = "white" {}
	_MaskTex( "mask (RGB)", 2D) = "white" {}
	
	
}

SubShader {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	
	Blend SrcAlpha OneMinusSrcAlpha
	Cull Off Lighting Off ZWrite Off Fog { Mode Off }
	
	LOD 100
	
		
	CGINCLUDE
	#include "UnityCG.cginc"
	sampler2D _MainTex;
	sampler2D _MaskTex;
	

	float4 _MainTex_ST;
	float4 _MaskTex_ST;
	
	
	
	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;

	};

	
	v2f vert (appdata_base v)
	{
		v2f o;

		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = TRANSFORM_TEX(v.texcoord.xy,_MaskTex);
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
			fixed4 tex = tex2D (_MainTex, i.uv);
			fixed4 mask = tex2D (_MaskTex, i.uv);
			return fixed4(tex.rgb, mask.r);
		}
		ENDCG 
	}	
}
}
