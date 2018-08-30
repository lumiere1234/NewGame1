// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/ModelOutline" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
   }

	CGINCLUDE
	#include "UnityCG.cginc"
	#include "Lighting.cginc"
	
	sampler2D	_MainTex;

    struct appdata {
        float4 vertex	: POSITION;
        float2 uv		: TEXCOORD0;
    };

    struct v2f {
        float4 pos : SV_POSITION;
        float2 uvBase           : TEXCOORD0;
    };
        
    v2f vert (appdata v) {
        v2f o;
        o.pos = UnityObjectToClipPos( v.vertex );
        o.uvBase = v.uv;
        return o;
    }
        
    fixed4 frag (v2f Input) : COLOR0 
	{
		float4 colBaseTex  = tex2D(_MainTex,Input.uvBase); 
		float4 OutputColor = float4(0.5, 0.5, 1.0, 0.6 * colBaseTex.a);
		return OutputColor;

	}

	ENDCG

SubShader {
	Tags { "LightMode"="ForwardBase"  "IgnoreProjector"="True" "RenderType"="Transparent" }	
	LOD  200

    Pass {
    AlphaTest Greater 0.1
		Cull Back
		Lighting Off
		Fog { Mode Off }
		ZTest Greater
		ZWrite Off
		Offset 0, -1200
		Blend SrcAlpha One

        CGPROGRAM

		#pragma exclude_renderers d3d11 xbox360
        #pragma vertex vert
        #pragma fragment frag
		#pragma fragmentoption ARB_precision_hint_fastest 


        ENDCG
    }
}
}

