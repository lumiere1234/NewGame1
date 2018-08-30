// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// ---------
// | B | A |
// ---------
// | R | G |
// ---------
Shader "Custom/Matcap Equip Transparent.. " {
	Properties
	{
		_MainTex ("Base (RGB)", 2D) = "grey" {}
		_MaskMap("Mask (RGB)", 2D) = "white" {}
		[ShowWhenHasAnyKeyword(MatCapMultiEnvTwoMask, MatCapMultiEnvTwoMaskTwoTint)] _MaskBMap ("MaskB (R:alpha G:upperRight B:tint)", 2D) = "white" {}
		_AlphaMulti ("Transparent", Range(0,1)) = 1
		_AlphaRef ("AlphaTest Ref", Range(0,1)) = 0.15
		[ShowWhenHasAnyKeyword(MatCapMultiEnvTwoMask, MatCapMultiEnvTwoMaskTwoTint)] _Tint ("装备换色 ", Color) = (1,1,1,0.5)
		[ShowWhenHasKeyword(MatCapMultiEnvTwoMaskTwoTint)] _Tint2 ("装备换色2 ", Color) = (1,1,1,0.5)
		_EnvMap ("EnvCap (RGB)", 2D) = "white" {}
		//MatFs
		_colDiffuse("Col Diffuse", Color) = (1,1,1,1)
		_RimColor("Rim Color", Color) = (0,0,0,1)
		_SelfIlluminateColor("Self Illuminate", Color) = (0,0,0,1)
	}
	
	CGINCLUDE
		#include "UnityCG.cginc"

		sampler2D _MainTex;
		float4 _MainTex_ST;
		sampler2D _MaskMap;
		sampler2D _EnvMap;
		#define transparentCullout_On;
		
		#if defined(MatCapMultiEnvTwoMask) || defined(MatCapMultiEnvTwoMaskTwoTint)
			sampler2D _MaskBMap;
			fixed4 _Tint;
		#endif		
		#ifdef MatCapMultiEnvTwoMaskTwoTint
			fixed4 _Tint2;
		#endif
		

		#ifdef transparentCullout_On
			fixed _AlphaRef;
			fixed _AlphaMulti;
		#endif
		fixed4 _SelfIlluminateColor;
		fixed4 _colDiffuse;
		fixed4 _RimColor;


		struct v2f
		{
			float4 pos	: SV_POSITION;
			float2 uv : TEXCOORD0;
			half2 capCoord : TEXCOORD1;
			#if defined (MatCapMultiEnvOneMask) || defined (MatCapMultiEnvTwoMask) || defined(MatCapMultiEnvTwoMaskTwoTint)
				half2 capCoord_lowerRt : TEXCOORD2;
				half2 capCoord_upperLf : TEXCOORD3;
			#endif
			#if defined(  MatCapMultiEnvTwoMask ) || defined(MatCapMultiEnvTwoMaskTwoTint)
				half2 capCoord_upperRt : TEXCOORD4;
			#endif
			
			fixed4 colorAdd : COLOR;
		};


		v2f vert (appdata_tan v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos (v.vertex);
			o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
			
			
			TANGENT_SPACE_ROTATION;
			
			half2 capCoord = half2(mul(rotation, UNITY_MATRIX_IT_MV[0].xyz).z, mul(rotation, UNITY_MATRIX_IT_MV[1].xyz).z);
			float f = length(capCoord); 
			o.colorAdd = 2*f*f * _RimColor + _SelfIlluminateColor ;

			#ifdef MatCapSimple
				o.capCoord = capCoord * 0.5 + 0.5;
			#endif
			#if defined (MatCapMultiEnvOneMask) || defined (MatCapMultiEnvTwoMask) || defined(MatCapMultiEnvTwoMaskTwoTint)
				o.capCoord = capCoord * 0.25 + 0.25;		//R: lowerLf
				o.capCoord_lowerRt = o.capCoord + half2(0.5,0);	
				o.capCoord_upperLf = o.capCoord + half2(0,0.5);	
			#endif
			#if defined( MatCapMultiEnvTwoMask) || defined(MatCapMultiEnvTwoMaskTwoTint)
				o.capCoord_upperRt = o.capCoord + half2(0.5,0.5);
			#endif

			return o;
		}
		float4 fragBack(v2f i) : COLOR
		{
			fixed alpha = 1;
			fixed3 mask = tex2D(_MaskMap, i.uv);
			#if defined( MatCapMultiEnvTwoMask) || defined(MatCapMultiEnvTwoMaskTwoTint)
				fixed3 maskB;
				maskB = tex2D(_MaskBMap, i.uv);
			#endif

		 	#ifdef transparentCullout_On 
		 		#if defined (MatCapSimple) || defined (MatCapMultiEnvOneMask)
				 	alpha = mask.r;
				#endif
				
				#if defined (MatCapMultiEnvTwoMask) || defined(MatCapMultiEnvTwoMaskTwoTint)
				 	alpha = maskB.r;
				#endif
				
	 		 	clip( alpha - _AlphaRef);						
	 		 	alpha *= _AlphaMulti;
		 	 #endif

			fixed3 col = tex2D(_MainTex, i.uv) * _colDiffuse.rgb;
		 	#ifdef MatCapMultiEnvTwoMask
		 		col = lerp( col, (_Tint.a * 2) * _Tint.rgb * col, maskB.b );
		 	#endif
		 	#ifdef MatCapMultiEnvTwoMaskTwoTint 
		 		fixed2 t = saturate ( fixed2(maskB.b-0.5, -maskB.b +0.5 ) *2) ;
		 		fixed base = 1-t.x-t.y;
		 		col.rgb *= fixed3(base,base,base) + t.x * _Tint.a *2 * _Tint.rgb + t.y *_Tint2.a*2* _Tint2.rgb;
		 	#endif

		 	
		 	return fixed4(col+ i.colorAdd, alpha);
		}

		float4 frag (v2f i) : COLOR
		{
			fixed alpha = 1;
			fixed3 mask = tex2D(_MaskMap, i.uv);
			#if defined( MatCapMultiEnvTwoMask) || defined(MatCapMultiEnvTwoMaskTwoTint)
				fixed3 maskB;
				maskB = tex2D(_MaskBMap, i.uv);
			#endif

		 	#ifdef transparentCullout_On 
		 		#if defined (MatCapSimple) || defined (MatCapMultiEnvOneMask) 
				 	alpha = mask.r;
				#endif
				
				#if defined (MatCapMultiEnvTwoMask) || defined(MatCapMultiEnvTwoMaskTwoTint)
				 	alpha = maskB.r;
				#endif
	
	 		 	clip( alpha - _AlphaRef);						
	 		 	alpha *= _AlphaMulti;
		 	 #endif

		 	fixed3 col = tex2D(_MainTex, i.uv) * _colDiffuse.rgb;
		
		 	fixed3 matcap = fixed3(0,0,0);
			
			#ifdef MatCapSimple
				matcap += tex2D(_EnvMap,i.capCoord ) * mask.g;
			#endif

			#if MatCapMultiEnvOneMask
				#ifndef transparentCullout_On
					matcap += tex2D(_EnvMap,i.capCoord ) * mask.r;	
				#endif
				matcap += tex2D(_EnvMap,i.capCoord_lowerRt ) * mask.g;	
				matcap += tex2D(_EnvMap,i.capCoord_upperLf ) * mask.b;	
			#endif

		 	#if defined( MatCapMultiEnvTwoMask) || defined(MatCapMultiEnvTwoMaskTwoTint)
		 		matcap += tex2D(_EnvMap,i.capCoord ) * mask.r;	
				matcap += tex2D(_EnvMap,i.capCoord_lowerRt ) * mask.g;	
				matcap += tex2D(_EnvMap,i.capCoord_upperLf ) * mask.b;	
				matcap += tex2D(_EnvMap,i.capCoord_upperRt ) * maskB.g;	
		 	#endif
		 	
		 	#ifdef MatCapMultiEnvTwoMask
		 		col = lerp( col, (_Tint.a * 2) * _Tint.rgb * col, maskB.b );
		 	#endif
		 	#ifdef MatCapMultiEnvTwoMaskTwoTint 
		 		fixed2 t = saturate ( fixed2(maskB.b-0.5, -maskB.b +0.5 ) *2) ;
		 		fixed base = 1-t.x-t.y;
		 		col.rgb *= fixed3(base,base,base) + t.x * _Tint.a *2 * _Tint.rgb + t.y *_Tint2.a*2* _Tint2.rgb;
		 	#endif
				
		

		 	return fixed4(col + i.colorAdd  + matcap , alpha);
		
		 }
	ENDCG


	Subshader
	{
		Tags { "Queue"="Geometry+1" "LightMode"="ForwardBase"  "IgnoreProjector"="True" "RenderType"="Opaque"}
		LOD 600
		
		Pass
		{
			Cull Front Lighting Off ZWrite Off Fog { Mode Off }
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			
				#pragma multi_compile MatCapSimple MatCapMultiEnvOneMask MatCapMultiEnvTwoMask MatCapMultiEnvTwoMaskTwoTint
				#pragma exclude_renderers flash
				
				#pragma vertex vert
				#pragma fragment fragBack
				#pragma fragmentoption ARB_precision_hint_fastest
			ENDCG
		}

		Pass
		{
			Cull Back Lighting Off ZWrite On Fog { Mode Off }
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
				#pragma multi_compile MatCapSimple MatCapMultiEnvOneMask MatCapMultiEnvTwoMask MatCapMultiEnvTwoMaskTwoTint
				
				#pragma exclude_renderers flash
				
				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest
			ENDCG
		}
	}

	Fallback "VertexLit"
	CustomEditor "MatcapEquipTransparentMaterialInspector"
}