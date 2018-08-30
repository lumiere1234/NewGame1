// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/Terrain/SevenTerrainPainter" {
	Properties {
		// set by terrain engine
		[HideInInspector] _Control ("Control (RGBA)", 2D) = "red" {}
		[HideInInspector] _Splat3 ("Layer 3 (A)", 2D) = "white" {}
		[HideInInspector] _Splat2 ("Layer 2 (B)", 2D) = "white" {}
		[HideInInspector] _Splat1 ("Layer 1 (G)", 2D) = "white" {}
		[HideInInspector] _Splat0 ("Layer 0 (R)", 2D) = "white" {}
		[HideInInspector] _Normal0 ("Normal 0 (R)", 2D) = "bump" {}

		// used in fallback on old cards & base map
		[HideInInspector] _MainTex ("BaseMap (RGB)", 2D) = "white" {}
		[HideInInspector] _Color ("Main Color", Color) = (1,1,1,1)
		_AddOnTex ("AddOn Map (RGB)", 2D) = "grey" {}
		_Power ("Glossiness  (0 ~ 150)", float ) = 30
		_specAmount ("Specular Level", float) = 2
		_Low ("Low Threshold (0 ~ 1)", float) = 0
		_Hi ("High Threshold (0 ~ 1)", float) = 1
		_TextureE_Size ("Texture 5 Size", float) = 8
	}


CGINCLUDE
	//#include "UnityCG.cginc"
	#include "../CGIncludes/SevenInclude.cginc"

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

	sampler2D _AddOnTex;

    struct appdata {
        float4 vertex	: POSITION;
        float3 normal : NORMAL;
		float2 uv		: TEXCOORD0;

		
    };

    struct v2f {
        float4 vertex : SV_POSITION;
        
		float2 uvBase    : TEXCOORD0;
		float2 uv_SplatA : TEXCOORD1;
		float2 uv_SplatB : TEXCOORD2;
		float2 uv_SplatC : TEXCOORD3;
		float2 uv_SplatD : TEXCOORD4;
		float2 uv_SplatE : TEXCOORD5;
		//float2 uv_lightmap : TEXCOORD6;
		float2 specColor : TEXCOORD6;	// color will be clamp
		


    };
        
    v2f vert (appdata v) {
        v2f o;
        o.vertex = UnityObjectToClipPos( v.vertex );
		o.uvBase = TRANSFORM_TEX(v.uv, _Control);

		o.uv_SplatA =  TRANSFORM_TEX(v.uv.xy,_Splat0);
     	o.uv_SplatB =  TRANSFORM_TEX(v.uv.xy,_Splat1) ;
     	o.uv_SplatC =  TRANSFORM_TEX(v.uv.xy,_Splat2) ;
     	o.uv_SplatD =  TRANSFORM_TEX(v.uv.xy,_Splat3) ;

		o.uv_SplatE = v.uv.xy *(256 / _TextureE_Size);


     	half3 viewDir = normalize (WorldSpaceViewDir(v.vertex));
		half3 lightDir =  normalize(WorldSpaceLightDir(v.vertex));
		half3 h = normalize(lightDir + viewDir);
		float p = pow(saturate(dot ( h, v.normal) ) , _Power) * _specAmount;
		
		o.specColor = half2( p, 1);
		
        return o;
    }

        
    fixed4 frag (v2f i) : COLOR0 
	{ 
		fixed4 splat_control	= tex2D ( _Control, i.uvBase );

		fixed3 col;
		
		col = splat_control.r * tex2D (_Splat0, i.uv_SplatA).rgb;
		col += splat_control.g * tex2D (_Splat1, i.uv_SplatB).rgb;
		col += splat_control.b * tex2D (_Splat2,  i.uv_SplatC).rgb;
		col += splat_control.a * tex2D (_Splat3,  i.uv_SplatD).rgb;
		col += (1-splat_control.r - splat_control.g - splat_control.b- splat_control.a) * tex2D(_Normal0, i.uv_SplatE).rgb;



		col *=  tex2D ( _AddOnTex, i.uvBase).rgb *2;
		float f = (1-splat_control.r - splat_control.g - splat_control.b- splat_control.a);
		float v = saturate(saturate(Luminance(col.rgb) - _Low)/(1 - _Low - (1-_Hi)));
		
		

		//return fixed4(v,v,v,1);
		half3 spec = i.specColor.x * v ;
		#if SPECULAR_ONLY
			return fixed4(spec.rgb,1);
		#endif

		col += spec.x*(  col);

		#if LIGHTMAP_ON
		fixed3 lm = SevenLightmap (i.uvBase);
		col *= lm ;
		#endif
		
		
		return fixed4(col.rgb,1);
	}

	ENDCG

	SubShader {
		Tags {		"SplatCount" = "4"		"Queue" = "Geometry-100"		"RenderType" = "Opaque"}

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
			#pragma multi_compile SPECULAR_ADD SPECULAR_ONLY 

	        ENDCG
	    }
	}

	Dependency "AddPassShader" = "Hidden/Terrain/WokTerrain_Add"
	Dependency "BaseMapShader" = "Hidden/Terrain/WokTerrain_Base"

	//Fallback "Nature/Terrain/Diffuse"
	CustomEditor "TerrainMaterialInspector"
}
