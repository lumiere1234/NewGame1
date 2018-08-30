// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/Terrain/SevenTerrain_Base" {
	Properties {
		_MainTex ("Base (RGB) Smoothness (A)", 2D) = "white" {}
		_MetallicTex ("Metallic (R)", 2D) = "white" {}

		// used in fallback on old cards
		_Color ("Main Color", Color) = (1,1,1,1)
	}

CGINCLUDE
		#include "../../CGIncludes/SevenInclude.cginc"

		sampler2D	_MainTex;
		float4 _MainTex_ST;


	    struct appdata {
	        float4 vertex	: POSITION;
			float2 uv		: TEXCOORD0;
	    };

	    struct v2f {
	        float4 vertex : SV_POSITION;
			float2 uvBase           : TEXCOORD0;
			
	    };
	        
	    v2f vert (appdata v) {
	        v2f o;
	        o.vertex = UnityObjectToClipPos( v.vertex );
			o.uvBase = TRANSFORM_TEX(v.uv, _MainTex);
			
	        return o;
	    }
	        
	    fixed4 frag (v2f i) : COLOR0 
		{ 
			fixed3 col = tex2D(_MainTex, i.uvBase);
			
			#if LIGHTMAP_ON
				col *= SevenLightmap (i.uvBase);
			#endif
			
			return fixed4(col.rgb,1);
		}

		ENDCG

	SubShader {
		Tags {
			"RenderType" = "Opaque"
			"Queue" = "Geometry-100"
		}
		LOD 100

		Pass {
			Cull Back
			Lighting Off
			ZWrite On
			ZTest LEqual

	        CGPROGRAM

			#pragma exclude_renderers xbox360 flash
	        #pragma vertex vert
	        #pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest 
			#pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
	        ENDCG
	    }

	
	}


	FallBack "Diffuse"
}
