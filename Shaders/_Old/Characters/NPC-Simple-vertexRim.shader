// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/NPC/NPC-Simple-VertexRim" {
	Properties {
        _MainTex ("Base (RGB)", 2D) = "white" {}
		_colDiffuse ("Diffuse Color", Color) = (1,1,1,1)
		_RimColor("Rim Light外部颜色", Color) = (0,0,0,0)
		_RimDiffuse("Rim Light漫反射倍增", float ) = 1.5
		_SelfIlluminateColor("自发光颜色", Color) = (0,0,0,0)
		_SelfIlluminated("自发光倍增", float ) = 1.0
		_colDiffuseFactor("diffuse系数", Color) = (1,1,1,1)
   }

	CGINCLUDE
	#include "UnityCG.cginc"
	#include "Lighting.cginc"

	sampler2D	_MainTex;
	float4 _colDiffuse;
	float4 _RimColor;
	float  _RimDiffuse;
	fixed4 _SelfIlluminateColor;
	half  _SelfIlluminated;
	float4 _colDiffuseFactor;



    struct appdata {
        float4 vertex	: POSITION;
        float3 normal	: NORMAL;
		float2 uv		: TEXCOORD0;
    };

    struct v2f {
        float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		half nDotV : TEXCOORD1;

    };
        
    v2f vert (appdata v) {
        v2f o;
        o.pos = UnityObjectToClipPos( v.vertex );
        fixed3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
		o.uv = v.uv;

		// 0.3 is similar with common texture resamp
		o.nDotV = pow (saturate( dot(v.normal, viewDir)), 0.3);

        return o;
    }
        
    fixed4 frag (v2f Input) : COLOR0 
	{ 
		
		fixed4 colBaseTex = tex2D (_MainTex, Input.uv);

		fixed4 rimLight = fixed4( (1- Input.nDotV) * _RimColor.rgb,1);
		

		fixed4 col = (colBaseTex*_colDiffuse + rimLight*_RimDiffuse + _SelfIlluminateColor * _SelfIlluminated  ) *  _colDiffuseFactor;
		return col;
	}

	ENDCG

SubShader {
	Tags { "Queue"="Geometry+1" "LightMode"="ForwardBase"  "IgnoreProjector"="True" "RenderType"="Opaque" }	

    Pass {
		Cull Back
		Lighting Off
		Fog { Mode Off }
		
        CGPROGRAM

		#pragma exclude_renderers d3d11 xbox360
        #pragma vertex vert
        #pragma fragment frag
		#pragma fragmentoption ARB_precision_hint_fastest 


        ENDCG
    }
}
}

