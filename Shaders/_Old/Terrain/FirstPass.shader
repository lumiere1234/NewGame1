// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: commented out 'sampler2D unity_Lightmap', a built-in variable
// Upgrade NOTE: replaced tex2D unity_Lightmap with UNITY_SAMPLE_TEX2D

Shader "Nature/Terrain/Diffuse" {
	Properties 
   	{
    	[HideInInspector] _Control ("Control (RGBA)", 2D) = "red" {}
		[HideInInspector] _Splat3 ("Layer 3 (A)", 2D) = "white" {}
		[HideInInspector] _Splat2 ("Layer 2 (B)", 2D) = "white" {}
		[HideInInspector] _Splat1 ("Layer 1 (G)", 2D) = "white" {}
		[HideInInspector] _Splat0 ("Layer 0 (R)", 2D) = "white" {}
		// used in fallback on old cards & base map
		[HideInInspector] _MainTex ("BaseMap (RGB)", 2D) = "white" {}
		[HideInInspector] _Color ("Main Color", Color) = (1,1,1,1)
   	}
   

	//=========================================================================
	SubShader 
	{
		Tags {		"SplatCount" = "4"
		"Queue" = "Geometry-100"
		"RenderType" = "Opaque"}

    	Pass 
		{    
      	 	Cull Back Lighting Off ZWrite On
			CGPROGRAM
			
 			#pragma vertex vert
			#pragma fragment frag
			#pragma exclude_renderers flash
			#pragma fragmentoption ARB_precision_hint_fastest


			#include "UnityCG.cginc"
	
			sampler2D _Control;
			sampler2D	_MainTex;
			float4		_MainTex_ST;
			sampler2D	_Splat3;
			float4		_Splat3_ST;		
			sampler2D	_Splat2;
			float4		_Splat2_ST;		
			sampler2D	_Splat1;
			float4		_Splat1_ST;		
			sampler2D	_Splat0;
			float4		_Splat0_ST;		
			
			// sampler2D unity_Lightmap;
           	struct vertexInput
            {
                float4 vertex	: POSITION;
              
               	float2 uv_Control : TEXCOORD0;
				 // float2 uv_Splat0 : TEXCOORD1;
				 // float2 uv_Splat1 : TEXCOORD2;
				 // float2 uv_Splat2 : TEXCOORD3;
				 // float2 uv_Splat3 : TEXCOORD4;
			};
			
           	struct vertexOutput
            {
                half4 pos		: SV_POSITION;
                float2 tex		: TEXCOORD0;
                float2 uv_SplatA : TEXCOORD1;
				float2 uv_SplatB : TEXCOORD2;
				float2 uv_SplatC : TEXCOORD3;
				float2 uv_SplatD : TEXCOORD4;
				float2 uv_SplatE : TEXCOORD5;
            };

			vertexOutput vert ( vertexInput v )
			{
				vertexOutput o;
     			o.pos	= UnityObjectToClipPos ( v.vertex );
     			o.tex =  TRANSFORM_TEX(v.uv_Control.xy,_MainTex);
     			o.uv_SplatA =  TRANSFORM_TEX(v.uv_Control.xy,_Splat0);
     			o.uv_SplatB =  TRANSFORM_TEX(v.uv_Control.xy,_Splat1) ;
     			o.uv_SplatC =  TRANSFORM_TEX(v.uv_Control.xy,_Splat2) ;
     			//hack
     			o.uv_SplatD = float2(0,0) ;
     			o.uv_SplatE =  TRANSFORM_TEX(v.uv_Control.xy,_Splat3) ;

				return o;
			}
 	
			fixed4 frag ( vertexOutput i ):COLOR
			{
				fixed4 splat_control	= tex2D ( _Control, i.tex );
				fixed3 col;
				
				col  = splat_control.r * tex2D (_Splat0, i.uv_SplatA).rgb;
				col  += splat_control.g * tex2D (_Splat1, i.uv_SplatB).rgb;
				col  += splat_control.b * tex2D (_Splat2,  i.uv_SplatC).rgb;
				col  += splat_control.a * tex2D (_Splat3,  i.uv_SplatE).rgb;
				
				fixed3 lm = DecodeLightmap (UNITY_SAMPLE_TEX2D(unity_Lightmap, i.tex));
				col.rgb *= lm;
				return fixed4 ( col.rgb, 1);
			}
			ENDCG
		}
 	}
}

