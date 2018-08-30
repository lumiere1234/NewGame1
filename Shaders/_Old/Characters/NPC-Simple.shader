// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/NPC/NPC-Simple" {
	Properties {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _RimLightTex ("RimLight外部贴图 (RGB)", 2D) = "white" {}
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
	sampler2D	_RimLightTex;

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
		float2 uv           : TEXCOORD0;
		float3 normal			: TEXCOORD1;
		fixed3 ViewDir          : TEXCOORD2;	//object space
		fixed3 LightDir         : TEXCOORD3;	//object space
    };
        
    v2f vert (appdata v) {
        v2f o;
        o.pos = UnityObjectToClipPos( v.vertex );

        fixed3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
		fixed3 vLightDir = normalize(ObjSpaceLightDir(v.vertex) + viewDir *1.2);
              
		o.ViewDir = viewDir;
		o.LightDir = vLightDir;
		o.normal = normalize(v.normal);
		o.uv = v.uv;

        return o;
    }
        
    fixed4 frag (v2f Input) : COLOR0 
	{ 
		fixed4 col;
		fixed4 colBaseTex = tex2D (_MainTex, Input.uv);
		float3 Normal = 0.0;
		fixed4 RimLight = 0.0;
		
		Normal = normalize(Input.normal);
		fixed3 ViewDir  = normalize(Input.ViewDir);
		float fNdotV = saturate(dot(Normal,ViewDir));
		RimLight.rgb = tex2D(_RimLightTex, float2(fNdotV, 0.0)).rgb * _RimColor.rgb;
		
		col = (colBaseTex*_colDiffuse + RimLight*_RimDiffuse+ _SelfIlluminateColor * _SelfIlluminated  ) *  _colDiffuseFactor;
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

