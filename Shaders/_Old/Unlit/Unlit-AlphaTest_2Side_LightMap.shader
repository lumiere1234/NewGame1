// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: commented out 'float4 unity_LightmapST', a built-in variable
// Upgrade NOTE: commented out 'sampler2D unity_Lightmap', a built-in variable
// Upgrade NOTE: replaced tex2D unity_Lightmap with UNITY_SAMPLE_TEX2D

// Unlit alpha-cutout shader.
// - no lighting
// - lightmap support
// - no per-material color

Shader "Unlit/Transparent Cutout 2 Side (Support lightmap)" {
Properties {
	_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
	_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
}
SubShader {
	

	Cull Off Lighting Off ZWrite On

	CGINCLUDE
		#include "UnityCG.cginc"
		struct appdata_t {
			float4 vertex : POSITION;
			float2 texcoord : TEXCOORD0;
			float2 texcoord1 : TEXCOORD1;
		};

		struct v2f {
			float4 vertex : SV_POSITION;
			half2 texcoord : TEXCOORD0;
			float2 lmap : TEXCOORD1;
		};

		sampler2D _MainTex;
		float4 _MainTex_ST;
		fixed _Cutoff;

		// float4 unity_LightmapST;
		// sampler2D unity_Lightmap;

		v2f vert (appdata_t v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
			
			o.lmap = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
			return o;
		}
		
		fixed4 frag (v2f i) : SV_Target
		{
			fixed4 col = tex2D(_MainTex, i.texcoord);
			clip(col.a - _Cutoff);
			
			return col;
		}
		fixed4 fragLM (v2f i) : SV_Target
		{
			fixed4 col = tex2D(_MainTex, i.texcoord);
			clip(col.a - _Cutoff);
			
			fixed3 lm = DecodeLightmap (UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lmap));
			col.rgb *= lm;
			
			return col;
		}
	ENDCG




	Pass {  
		Tags { "LIGHTMODE"="Vertex" "Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
		ENDCG
	}

	Pass {  
		Tags { "LIGHTMODE"="VertexLM" "Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragLM
		ENDCG
	}
		Pass {  
		Tags { "LIGHTMODE"="VertexLMRGBM" "Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragLM

		ENDCG
	}
}

}