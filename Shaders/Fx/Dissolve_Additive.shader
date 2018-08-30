// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "* FX/Dissolve_add_distex"
{
	Properties 
   	{
   	 	_TintColor ("Tint Color", Color) = (1,1,1,1)
		_MainTex ("Main Texture (RBG)", 2D) 		= "gray" {}
		_DissolveTex ("Main Texture (RBG)", 2D) 		= "gray" {}

    	_mix("Mix", Range ( 0,1 ) )			= 0.35
   	}
   
	//=========================================================================
	SubShader 
	{
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}

    	Pass 
		{    
      	 	Cull Off Lighting Off ZWrite Off
      	 	Blend One One
     		Fog { Mode Off }
			CGPROGRAM
			
 			#pragma vertex vert
			#pragma fragment frag
			#pragma exclude_renderers flash
			#pragma fragmentoption ARB_precision_hint_fastest


			#include "UnityCG.cginc"
	

			sampler2D	_MainTex;
			float4		_MainTex_ST;
			sampler2D	_DissolveTex;
			float4		_DissolveTex_ST;
			fixed4		 _TintColor;
			fixed       _mix;
			
			
           	struct vertexInput
            {
                float4 vertex	: POSITION;
                float2 texcoord	: TEXCOORD0;
//                float2 texcoord : TEXCOORD1;
                float4 vertexColor: COLOR;
			};
           	struct vertexOutput
            {
                half4 pos		: SV_POSITION;
                half2 tex		: TEXCOORD0;
                half2 tex2		: TEXCOORD1;
                float4 vertexColor: TEXCOORD3;
            };

			vertexOutput vert ( vertexInput v )
			{
				vertexOutput o;
     			o.pos	= UnityObjectToClipPos ( v.vertex );
     			o.tex = TRANSFORM_TEX(v.texcoord.xy,_MainTex);
     			o.tex2=	TRANSFORM_TEX(v.texcoord.xy,_DissolveTex);
     			o.vertexColor = v.vertexColor;
				return o;
			}
 	
			fixed4 frag ( vertexOutput i ):COLOR
			{
				fixed4 col 	= tex2D ( _MainTex, i.tex );
				fixed4 dis =  tex2D (_DissolveTex,i.tex2);
				//fixed f = Luminance(col.rgb);

				col.rgb	= _TintColor*2 * col.rgb * (dis.rgb - _mix) /(1.001 - _mix)*i.vertexColor.a;
				//col.a=col.a*i.vertexColor.a;
				
				return fixed4 ( col.rgb, col.a);
			}
			ENDCG
		}
 	}
}
