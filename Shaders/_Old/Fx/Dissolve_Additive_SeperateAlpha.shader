// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "Custom/Disslove/Disslove Additive SeperateAlpha"
{
	Properties 
   	{
   	 	_TintColor ("Tint Color", Color) = (1,1,1,1)
		_MainTex ("Main Texture (RBG)", 2D) 		= "gray" {}
		_DissloveTex ("Disslove Texture (RBG)", 2D) 		= "white" {}
		//_burnColor ( "BurnColor", Color ) = ( 0,0,0,0 )
    	//_burnSize("BurnSize", Range ( 0.0, 0.5 ) )	= 0.25
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


			#include "UnityCG.cginc"
	

			sampler2D	_MainTex;
			sampler2D   _DissloveTex;
			float4   _DissloveTex_ST;
			float4		_MainTex_ST;
			fixed4		 _TintColor;
			fixed       _mix;
			//fixed       _burnSize;
			//fixed4		_burnColor;
			
			
           	struct vertexInput
            {
                float4 vertex	: POSITION;
                float2 texcoord	: TEXCOORD0;
			};
           	struct vertexOutput
            {
                half4 pos		: SV_POSITION;
                half2 tex		: TEXCOORD0;
                half2 uv2		: TEXCOORD1;
            };

			vertexOutput vert ( vertexInput v )
			{
				vertexOutput o;
     			o.pos	= UnityObjectToClipPos ( v.vertex );
     			o.tex = TRANSFORM_TEX(v.texcoord.xy,_MainTex);
     			o.uv2 = TRANSFORM_TEX(v.texcoord.xy, _DissloveTex);
				return o;
			}
 	
			fixed4 frag ( vertexOutput i ):COLOR
			{
				fixed4 col 	= tex2D ( _MainTex, i.tex );
				
				fixed alpha = Luminance(  (tex2D ( _DissloveTex, i.uv2 )).rgb);

				// col.rgb	=  lerp (col.rgb * _TintColor*2, _burnColor, step ( alpha , _mix ) );
				col.a 	= step ( _mix , alpha ) * _TintColor.a;


				return col;
			}
			ENDCG
		}
 	}
}
