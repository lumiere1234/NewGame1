// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "Chp/Disslove/Disslove Advanced SeperateAlpha"
{
	Properties 
   	{
   	 	_TintColor ("Tint Color", Color) = (1,1,1,1)
		_MainTex ("Main Texture (RBG)", 2D) 		= "gray" {}
		_DissloveTex ("Disslove Texture (RBG)", 2D) 		= "white" {}
		_burnColor ( "BurnColor", Color ) = ( 0,0,0,0 )
		_outerColor ( "outerColor", Color ) = ( 0,0,0,0 )
		_StartAmount("StartAmount", float) = 0.5
    	_burnSize("BurnSize", Range ( 0.0, 0.5 ) )	= 0.1
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
      	 	Blend SrcAlpha OneMinusSrcAlpha
      		
     		
			CGPROGRAM
			
 			#pragma vertex vert
			#pragma fragment frag
			#pragma exclude_renderers flash
			#pragma fragmentoption ARB_precision_hint_fastest


			#include "UnityCG.cginc"
	

			sampler2D	_MainTex;
			sampler2D   _DissloveTex;
			float4		_MainTex_ST;
			fixed4		 _TintColor;
			fixed       _mix;
			fixed       _burnSize;
			fixed4		_burnColor;
			fixed4		_outerColor;
			half 		_StartAmount;
			

           	struct vertexInput
            {
                float4 vertex	: POSITION;
                float2 texcoord	: TEXCOORD0;
			};
           	struct vertexOutput
            {
                half4 pos		: SV_POSITION;
                half2 tex		: TEXCOORD0;
            };

			vertexOutput vert ( vertexInput v )
			{
				vertexOutput o;
     			o.pos	= UnityObjectToClipPos ( v.vertex );
     			o.tex = TRANSFORM_TEX(v.texcoord.xy,_MainTex);
				return o;
			}
 	
			fixed4 frag ( vertexOutput i ):COLOR
			{
				fixed4 col 	= tex2D ( _MainTex, i.tex );
				
				fixed alpha = Luminance(  (tex2D ( _DissloveTex, i.tex )).rgb);
				
				fixed notZero = step(0.0039, alpha) ;
				fixed t = (alpha -_mix+_burnSize) /_burnSize ;
				 t = saturate(t) - floor(saturate(t));

				fixed4 edgeColor = lerp(_outerColor, _burnColor + col * (t), t);
				
				col.rgb	=  lerp (col.rgb, edgeColor, step ( alpha , _mix ) )  * (1- _mix + _StartAmount);
				col.rgb *=  _TintColor*2;
				col.a 	= step ( _mix -_burnSize, alpha ) * notZero* _TintColor.a;

				return col;
			}
			ENDCG
		}
 	}
}
