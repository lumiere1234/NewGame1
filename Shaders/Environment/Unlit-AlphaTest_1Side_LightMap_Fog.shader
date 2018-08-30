// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'



// Unlit alpha-cutout shader.
// - no lighting
// - lightmap support
// - no per-material color

Shader "* Unlit/Transparent Cutout 1 Side (Support lightmap, Fog)" {
Properties {
	[ShowWhenHasKeyword(VERTEX_COLOR_ON)] _VertexColorAmount( "Vertex Color Amount", Range(0,1)) = 1
	_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
	_Cutoff ("Alpha cutoff", Range(0,1)) = 0.50
}
SubShader {
	

	Cull back Lighting Off ZWrite On 

	CGINCLUDE
		#include "../CGIncludes/WokInclude.cginc"
		#include "../CGIncludes/ZL_CGInclude.cginc"

		struct appdata_t {
			float4 vertex : POSITION;
			float2 texcoord : TEXCOORD0;
			float2 texcoord1 : TEXCOORD1;

			#ifdef VERTEX_COLOR_ON
				float4 color : COLOR;
			#endif
		};

		struct v2f {
			float4 vertex : SV_POSITION;
			half2 texcoord : TEXCOORD0;
			#ifdef VERTEX_COLOR_ON
				float4 color : COLOR;
			#endif
			float2 lmap : TEXCOORD1;
			UNITY_FOG_COORDS(2)
		};

		sampler2D _MainTex;
		float4 _MainTex_ST;
		fixed _Cutoff;
		#ifdef VERTEX_COLOR_ON
			float _VertexColorAmount;
		#endif

		v2f vert (appdata_t v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
			#ifdef VERTEX_COLOR_ON
				o.color = v.color;
				o.color.rgb = lerp(fixed3(1,1,1), o.color,  _VertexColorAmount );
			#endif
			
			o.lmap = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
			UNITY_TRANSFER_FOG(o,o.vertex);
			return o;
		}
		
		fixed4 frag (v2f i) : SV_Target
		{
			fixed4 col = tex2D(_MainTex, i.texcoord);
			
			clip(col.a - _Cutoff);

			#ifdef VERTEX_COLOR_ON
				col.rgb *= i.color.rgb;
			#endif

			#if ZL_LIGHTMAP_ON
			col.rgb *= WokLightmap( i.lmap);
			#endif

			UNITY_APPLY_FOG(i.fogCoord, col);
			return col;
		}

	ENDCG




	Pass {  
		Tags { "Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#pragma multi_compile  ZL_LIGHTMAP_OFF ZL_LIGHTMAP_ON
			#pragma multi_compile  VERTEX_COLOR_OFF VERTEX_COLOR_ON
		ENDCG
	}
}
CustomEditor "UnlitTransparentCutoutInspector"

}
     