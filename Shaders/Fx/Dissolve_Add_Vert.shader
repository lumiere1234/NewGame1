// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "* FX/Dissolve_add_vert"
{
	Properties 
   	{
   	 	_TintColor ("Tint Color", Color) = (0.5, 0.5, 0.5, 1)
		_MainTex ("Main Texture (RBG)", 2D) 		= "gray" {}
		_DissloveTex ("Disslove Texture (RBG)", 2D) 		= "white" {}
		//_burnColor ( "BurnColor", Color ) = ( 0,0,0,0 )
    	[ShowWhenHasAnyKeyword(ZL_FX_EDGE_MULTIPLY, ZL_FX_EDGE_COLOR, ZL_FX_EDGE_FADE)] _burnSize("Edge Size", Range ( 0.0001, 0.5 ) )	= 0.25
    	[ShowWhenHasKeyword(ZL_FX_EDGE_MULTIPLY)] _EdgeMulti("Edge multiply", float) = 2
    	[ShowWhenHasKeyword(ZL_FX_EDGE_COLOR)] _EdgeColor("Edge Color", Color) = ( 1,0,0,1 )
    	_mix("Mix", Range ( 0,1.5 ) )			= 0.35
   	}
   
	//=========================================================================
	SubShader 
	{
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}

    	Pass 
		{    
      	 	Cull Off Lighting Off ZWrite Off
      	 	Fog { Mode Off }
      	 	Blend SrcAlpha One
     		
			CGPROGRAM
			
 			#pragma vertex vert
			#pragma fragment frag
			#pragma exclude_renderers flash
			#pragma fragmentoption ARB_precision_hint_fastest

			#pragma multi_compile ZL_FX_EDGE_NONE ZL_FX_EDGE_MULTIPLY ZL_FX_EDGE_COLOR ZL_FX_EDGE_FADE
			//#pragma multi_compile ZL_FX_COLOR_PREMULTIPLY_ALPHA_OFF ZL_FX_COLOR_PREMULTIPLY_ALPHA_ON

			#include "UnityCG.cginc"
	
			sampler2D	_MainTex;
			sampler2D   _DissloveTex;
			float4   _DissloveTex_ST;
			float4		_MainTex_ST;
			fixed4		 _TintColor;
			fixed       _mix;
			fixed       _burnSize;

			fixed4		_EdgeColor;
			half _EdgeMulti;


			
			
           	struct vertexInput
            {
                float4 vertex	: POSITION;
                float2 texcoord	: TEXCOORD0;
                float4 vertexColor: COLOR;
			};
           	struct vertexOutput
            {
                half4 pos		: SV_POSITION;
                half2 tex		: TEXCOORD0;
                half2 uv2		: TEXCOORD1;
                float4 vertexColor: TEXCOORD3;
            };

			vertexOutput vert ( vertexInput v )
			{
				vertexOutput o;
     			o.pos	= UnityObjectToClipPos ( v.vertex );
     			o.tex = TRANSFORM_TEX(v.texcoord.xy,_MainTex);
     			o.uv2 = TRANSFORM_TEX(v.texcoord.xy, _DissloveTex);
     			o.vertexColor = v.vertexColor;
				return o;
			}
 	
			fixed4 frag ( vertexOutput i ):COLOR
			{
				fixed4 col 	= tex2D ( _MainTex, i.tex );
				half mix = 0.8+i.vertexColor.a*-1.2;
				//#if ZL_FX_COLOR_PREMULTIPLY_ALPHA_ON
				//	col.rgb *= col.a;
				//#endif
					col.rgb *= 2 *_TintColor.rgb*i.vertexColor.rgb*_mix;
				fixed alpha = Luminance(  (tex2D ( _DissloveTex, i.uv2 ).rgb));

				#ifdef ZL_FX_EDGE_NONE
					alpha = step( mix - alpha, 0) ;

				#else
					alpha = (alpha - mix + _burnSize) *(1/_burnSize);
					
					#if defined(ZL_FX_EDGE_MULTIPLY) || defined(ZL_FX_EDGE_COLOR)
						fixed inner = step( 0.99, alpha);
						fixed outer = step( 0,alpha);
						fixed edge = outer - inner;

						#if defined(ZL_FX_EDGE_MULTIPLY)
							col *= (edge * _EdgeMulti +1);
						#endif

						#if defined(ZL_FX_EDGE_COLOR)
							fixed _a = step(0.01, dot(col.rgb * col.a,fixed3(1,1,1)));
							// col = lerp(col, _EdgeColor *_a , edge);
							col = col * (1-edge) + _EdgeColor *_a * edge;
						#endif

						alpha = outer ;
					#endif

					#if defined(ZL_FX_EDGE_FADE)

					#endif
					alpha = saturate(alpha);
				#endif

				return fixed4(col.rgb, alpha);
			}
			ENDCG
		}
 	}

	//CustomEditor "DissloveAdditiveSeperateAlphaEdgesInspector"
}
