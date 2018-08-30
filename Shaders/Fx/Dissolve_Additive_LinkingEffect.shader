// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "* FX/Dissolve/Dissolve Additive Linking Effect"
{
	Properties 
   	{
   	 	_TintColor ("Tint Color", Color) = (1,1,1,1)
		_MainTex ("Main Texture (RBG)", 2D) 		= "gray" {}
		_DissolveTex ("Dissolve Texture (RBG)", 2D) 		= "white" {}
		[ShowWhenHasAnyKeyword(ZL_FX_EDGE_MULTIPLY, ZL_FX_EDGE_COLOR, ZL_FX_EDGE_FADE)] _EdgeSize("Edge Size", Range ( 0.0001, 0.5 ) )	= 0.25
    	[ShowWhenHasKeyword(ZL_FX_EDGE_MULTIPLY)] _EdgeMulti("Edge multiply", float) = 2
    	[ShowWhenHasKeyword(ZL_FX_EDGE_COLOR)] _EdgeColor("Edge Color", Color) = ( 1,0,0,1 )
   	}
   
	//=========================================================================
	SubShader 
	{
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}

    	Pass 
		{    
      	 	Cull Off Lighting Off ZWrite Off
      	 	Blend SrcAlpha One
     		Fog { Mode Off }
			CGPROGRAM
			
 			#pragma vertex vert
			#pragma fragment frag
			#pragma exclude_renderers flash
			#pragma fragmentoption ARB_precision_hint_fastest

			#pragma multi_compile ZL_FX_EDGE_NONE ZL_FX_EDGE_MULTIPLY ZL_FX_EDGE_COLOR ZL_FX_EDGE_FADE
			#pragma multi_compile ZL_PREMULTIPLY_ALPHA_OFF ZL_PREMULTIPLY_ALPHA_ON

			#include "UnityCG.cginc"
	
			sampler2D	_MainTex;
			sampler2D   _DissolveTex;
			float4		_MainTex_ST;
			float4   	_DissolveTex_ST;
			fixed4		_TintColor;

			fixed       _EdgeSize;
			fixed4		_EdgeColor;
			half 		_EdgeMulti;
			
           	struct vertexInput
            {
                float4 vertex	: POSITION;
                float2 texcoord	: TEXCOORD0;
                float4 color : COLOR;
			};
           	struct vertexOutput
            {
                half4 pos		: SV_POSITION;
                half2 tex		: TEXCOORD0;
                half2 uv2		: TEXCOORD1;
                fixed4 color 	: COLOR;
            };

			vertexOutput vert ( vertexInput v )
			{
				vertexOutput o;
     			o.pos	= UnityObjectToClipPos ( v.vertex );
     			o.tex = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
     			o.uv2 = TRANSFORM_TEX(v.texcoord.xy, _DissolveTex);
     			o.color = v.color;
				return o;
			}
 	
			fixed4 frag ( vertexOutput i ):COLOR
			{
				fixed4 col 	= tex2D ( _MainTex, i.tex );

				half mix = 1- i.color.a;
				#if ZL_PREMULTIPLY_ALPHA_ON
					col.rgb *= col.a;
				#endif
					col.rgb *= 2 *_TintColor.rgb;
				fixed alpha = Luminance(  (tex2D ( _DissolveTex, i.uv2 )));

				#ifdef ZL_FX_EDGE_NONE
					alpha = step( mix - alpha, 0) ;

				#else
					alpha = (alpha - mix + _EdgeSize * (1 - mix)) *(1/_EdgeSize);
					
					#if defined(ZL_FX_EDGE_MULTIPLY) || defined(ZL_FX_EDGE_COLOR)
						fixed inner = step( 0.99, alpha);
						fixed outer = step( 0,alpha);
						fixed edge = outer - inner;

						#if defined(ZL_FX_EDGE_MULTIPLY)
							col *= (edge * _EdgeMulti +1);
						#endif

						#if defined(ZL_FX_EDGE_COLOR)
							fixed _a = step(0.01, dot(col.rgb * col.a,fixed3(1,1,1)));
							col = lerp(col, _EdgeColor *_a , edge);
						#endif

						alpha = outer ;
					#endif

					#if defined(ZL_FX_EDGE_FADE)

					#endif
					alpha = saturate(alpha);
				#endif

				return fixed4(col.rgb, alpha * col.a);
			}
			ENDCG
		}
 	}

 	CustomEditor "ParticleDissolveAdditiveSeperateAlphaEdgesInspector"
}
