// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "Chp/Disslove/Disslove Edge"
{
	Properties 
   	{
   	 	_TintColor ("Tint Color", Color) = (1,1,1,1)
		_MainTex ("Main Texture (RBGA)", 2D) 		= "gray" {}
		_burnColor ( "BurnColor", Color ) = ( 0,0,0,0 )
    	_burnSize("BurnSize", Range ( 0.0, 0.5 ) )	= 0.25
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
			float4		_MainTex_ST;
			fixed4		 _TintColor;
			fixed       _mix;
			fixed       _burnSize;
			fixed4		_burnColor;
			
			
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
				fixed alpha = col.a;

				col.rgb	=  lerp (col.rgb * _TintColor*2, _burnColor, step ( alpha , _mix ) );
				col.a 	= step ( _mix -_burnSize, alpha ) * _TintColor.a;

				return col;
			}
			ENDCG
		}
 	}
}