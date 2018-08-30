// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'




Shader "Custom/Fabao_Transparent" {
Properties {
	_MainTex ("Base layer (RGBA)", 2D) = "white" {}
	
	_Alpha ("Alpha", Range(0.0, 1)) = 1
	
}

SubShader {
	Tags { "Queue"="Transparent-1"  "IgnoreProjector"="True" "RenderType"="Transparent" }
	
	LOD 100
	
		
	CGINCLUDE
	
	#include "UnityCG.cginc"
	sampler2D _MainTex;

	float4 _MainTex_ST;
	fixed _Alpha;
	
	struct v2f {
				float4 pos : SV_POSITION;
				half2 uv_MainTex : TEXCOORD0;
	};

	
	v2f vert (appdata_full v)
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv_MainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
		return o;
	}

	fixed4 frag (v2f i) : COLOR
	{
		fixed4 col;
		col = tex2D(_MainTex, i.uv_MainTex);
		col = fixed4( col.rgb, col.a * _Alpha);
		return col;
	}

	
	ENDCG


	Pass {
		Cull back
		ZWrite on
		ZTest Less
		
		Blend SrcAlpha OneMinusSrcAlpha
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		ENDCG 
	}	


}
}
