// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// ---------
// | B | A |
// ---------
// | R | G |
// ---------
Shader "Custom/Matcap Equip.." {
	Properties
	{
		//MatCapSimple MatCapMultiEnvOneMask MatCapMultiEnvTwoMask
		_MainTex ("Base (RGB)", 2D) = "grey" {}
		_MaskMap("Mask (RGB)", 2D) = "white" {}
		[ShowWhenHasAnyKeyword(MatCapMultiEnvTwoMask, MatCapMultiEnvTwoMaskTwoTint)] _MaskBMap ("MaskB (R:alpha G:upperRight B:tint)", 2D) = "white" {}
		[ShowWhenHasKeyword(transparentCullout_On)] _AlphaRef ("AlphaTest Ref", Range(0,1)) = 0.5
		[ShowWhenHasAnyKeyword(MatCapMultiEnvTwoMask, MatCapMultiEnvTwoMaskTwoTint)] _Tint ("装备换色 ", Color) = (1,1,1,0.5)
		[ShowWhenHasKeyword(MatCapMultiEnvTwoMaskTwoTint)] _Tint2 ("装备换色2 ", Color) = (1,1,1,0.5)
		[ShowWhenHasKeyword(MatCapMultiEnvTwoMaskTwoTint)] _Tint3 ("头发换色", Color) = (1,1,1,0.5)
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

		
		#if defined(MatCapMultiEnvTwoMask) || defined(MatCapMultiEnvTwoMaskTwoTint)
			sampler2D _MaskBMap;
			fixed4 _Tint;
		#endif		
		#ifdef MatCapMultiEnvTwoMaskTwoTint
			fixed4 _Tint2;
			fixed4 _Tint3;
		#endif
		

		#ifdef transparentCullout_On
			fixed _AlphaRef;
		#endif

		fixed4 _SelfIlluminateColor;
		fixed4 _colDiffuse;
		fixed4 _RimColor;

		struct appdata {
		    float4 vertex : POSITION;
		    fixed4 color : COLOR;
		    float3 normal : NORMAL;
		    float4 tangent : TANGENT;
		    float4 texcoord : TEXCOORD0;
		}
		;
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
			
			
			#if defined(MatCapMultiEnvTwoMaskTwoTint)
				fixed4 color : COLOR;
			#endif
			fixed4 colorAdd : COLOR1;
		};

		
		v2f vert (appdata v)
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
			#if defined(MatCapMultiEnvTwoMaskTwoTint)
				o.color = v.color;
			#endif
				
			return o;
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
		 		fixed2 t = saturate ( fixed2(2*maskB.b-1, -2*maskB.b +1 )) ;
		 		fixed base = saturate(1-t.x-t.y - i.color.r);
				
		 		col.rgb *= fixed3(base,base,base) + 2* ( saturate(1-i.color.r)*( t.x * _Tint.a * _Tint.rgb + t.y *_Tint2.a * _Tint2.rgb)  + i.color.r *_Tint3.a * _Tint3.rgb );
		 		
		 	#endif
		 	return fixed4(col+ i.colorAdd  + matcap , alpha);
		
		 }
	ENDCG


	Subshader
	{
		Tags { "Queue"="Geometry+1" "LightMode"="ForwardBase"  "IgnoreProjector"="True" "RenderType"="Opaque"}
		LOD 600
		Cull Back Lighting Off ZWrite On Fog { Mode Off }
		Pass
		{
			CGPROGRAM
				#pragma multi_compile MatCapSimple MatCapMultiEnvOneMask MatCapMultiEnvTwoMask MatCapMultiEnvTwoMaskTwoTint
				#pragma multi_compile transparentCullout_Off transparentCullout_On
				#pragma exclude_renderers flash
				
				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest
				
			ENDCG
		}
	}

	Fallback "VertexLit"
	CustomEditor "MatcapEquipMaterialInspector"
}