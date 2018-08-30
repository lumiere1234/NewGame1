// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Unlit alpha-cutout shader.
// - no lighting
// - lightmap support
// - no per-material color

Shader "Unlit/Transparent Cutout 2 Side (Support lightmap, Fog)" {
Properties {
	_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
	_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
}
SubShader {
	

	Cull Off Lighting Off ZWrite On //Fog { Mode Off }

	CGINCLUDE
		#include "../../CGIncludes/SevenInclude.cginc"
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

//		float4 unity_LightmapST;
//		sampler2D unity_Lightmap;

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
			
			
			#if SEVEN_LIGHTMAP_ON
			col.rgb *= SevenLightmap( i.lmap);
			#endif

			
			return col;
		}
	ENDCG





		Pass {  
		Tags { "Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile  SEVEN_LIGHTMAP_OFF SEVEN_LIGHTMAP_ON
		ENDCG
	}
}

}