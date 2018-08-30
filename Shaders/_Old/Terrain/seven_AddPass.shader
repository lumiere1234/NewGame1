// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// this shader will not be used at runtime

Shader "Hidden/Terrain/SevenTerrain_Add" {
	Properties {
		// set by terrain engine
		[HideInInspector] _Control ("Control (RGBA)", 2D) = "red" {}
		[HideInInspector] _Splat3 ("Layer 3 (A)", 2D) = "white" {}
		[HideInInspector] _Splat2 ("Layer 2 (B)", 2D) = "white" {}
		[HideInInspector] _Splat1 ("Layer 1 (G)", 2D) = "white" {}
		[HideInInspector] _Splat0 ("Layer 0 (R)", 2D) = "white" {}
		

		// used in fallback on old cards & base map
		[HideInInspector] _MainTex ("BaseMap (RGB)", 2D) = "white" {}
		[HideInInspector] _Color ("Main Color", Color) = (1,1,1,1)
		_Power ("Glossiness  (0 ~ 150)", float ) = 30
		_specAmount ("Specular Level", float) = 2
		_Low ("Low Threshold (0 ~ 1)", float) = 0
		_Hi ("High Threshold (0 ~ 1)", float) = 1
		_TextureE_Size ("Texture 5 Size", float) = 8
	}


CGINCLUDE
	//#include "UnityCG.cginc"
	#include "../../CGIncludes/SevenInclude.cginc"

	sampler2D	_MainTex;
	float4 _MainTex_ST;

	sampler2D _Control;
	float4 _Control_ST;
	sampler2D _Splat0,_Splat1,_Splat2,_Splat3;
	sampler2D _Normal0;
	float4 _Splat0_ST, _Splat1_ST, _Splat2_ST, _Splat3_ST;
	float _Low;
	float _Hi;
	//float4 _SpecColor;

	float _specAmount;
	float _Power;
	float _TextureE_Size;

    struct appdata {
        float4 vertex	: POSITION;
        float3 normal : NORMAL;
		float2 uv		: TEXCOORD0;

		
    };

    struct v2f {
        float4 vertex : SV_POSITION;
        
		float2 uvBase    : TEXCOORD0;
		float2 uv_SplatA : TEXCOORD1;

		
    };
        
    v2f vert (appdata v) {
        v2f o;
        o.vertex = UnityObjectToClipPos( v.vertex );
		o.uvBase = TRANSFORM_TEX(v.uv, _Control);

		o.uv_SplatA =  TRANSFORM_TEX(v.uv.xy,_Splat0);
 		
        return o;
    }

        
    fixed4 frag (v2f i) : COLOR0 
	{ 
		// return black, because the fifth texture is be rendered at first pass
		return fixed4(0,0,0,0);
	}

	ENDCG

	SubShader {
		Tags {		"SplatCount" = "4"		"Queue" = "Geometry-99"		"RenderType" = "Opaque"}

        Pass {

			Cull Back
			Lighting Off
			ZWrite On
			Blend One One

	        CGPROGRAM

			#pragma exclude_renderers xbox360 flash
	        #pragma vertex vert
	        #pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest 
			
			#pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
			#pragma multi_compile SPECULAR_ADD SPECULAR_ONLY 

	        ENDCG
	    }
	}


Fallback off
}
