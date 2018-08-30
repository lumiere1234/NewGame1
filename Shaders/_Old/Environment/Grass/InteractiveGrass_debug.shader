// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "CHP/Grass/InteractiveGrass Debug" {
	Properties {
        _MainTex ("Texture (RGB)", 2D) = "white" {}
        _Radius( "Radius", range(0.1, 5)) = 0.2
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		_RotSpeedMulti("Rot Speed Multi", Range(0.2,5)) = 1
		_TintColor ("Tint Color", Color) = (1,1,1,0.5)
		_LowerColor ("LowerColor", Color) = (0.5, 0.5, 0.7,1)
   }

	CGINCLUDE
	#include "UnityCG.cginc"

	sampler2D	_MainTex;
	float4 _MainTex_ST;
	float _Radius;
	fixed _Cutoff;
	float _RotSpeedMulti;
	float4 _TintColor;
	float4 _LowerColor;

    struct appdata {
        float4 vertex	: POSITION;
		float2 uv		: TEXCOORD0;
		float4 color : COLOR0;
		float3 normal : NORMAL;
		float4 tangent : TANGENT;
		float2 texcoord1 : TEXCOORD1;

    };

    struct v2f {
        float4 pos : SV_POSITION;
		float2 uvBase           : TEXCOORD0;
		float4 color : COLOR;		
    };
   #define TWO_PI	6.28318530718f   
    v2f vert (appdata v) {
        v2f o;
        
        float remainTime = v.texcoord1.x -_Time.y;
       	
       	fixed greateThanZero = saturate(sign(remainTime));
        float speed = greateThanZero *remainTime * 0.8 + 1;


        float phi = (v.tangent.w) * 2 + (v.vertex.x + v.vertex.z) *0.5;
        float waveMulti =  greateThanZero * remainTime * 0.25 + 1 ;
        float sinV;
        float cosV;
        float f = remainTime * speed * _RotSpeedMulti + phi;
        f = frac ( f / TWO_PI) *TWO_PI;

        sincos(f, sinV, cosV);

        float3 offset = float3( cosV,0, sinV) * waveMulti* _Radius ;
        offset *= v.color.a;
        v.vertex += float4(offset,0);
        o.pos = UnityObjectToClipPos( v.vertex );
		o.uvBase = TRANSFORM_TEX(v.uv, _MainTex);
		o.color = v.color;
		o.color = lerp (fixed4(1,1,1,1), fixed4(1,0,0,1), saturate( remainTime ));
		
        return o;
    }
        
    fixed4 frag (v2f i) : COLOR0 
	{ 
		fixed4 mastTex = tex2D(_MainTex, i.uvBase);
		
		clip(mastTex.a - _Cutoff);
		fixed3 colMulti = 2 * _TintColor.a * i.color * _TintColor.rgb * lerp(  _LowerColor, fixed3(1,1,1), i.color.a);

		fixed3 col = mastTex.rgb * colMulti;
		
		return fixed4( col, mastTex.a);
	}

	ENDCG

	SubShader {
		//Tags { "Queue"="AlphaTest" "LightMode"="ForwardBase"  "IgnoreProjector"="True" "RenderType"="Opaque" }
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
        Pass {
        	AlphaTest Greater [_Cutoff]
			Cull Off
			Lighting Off
			ZWrite On
			ZTest LEqual
			
			

	        CGPROGRAM

			#pragma exclude_renderers xbox360 flash
	        #pragma vertex vert
	        #pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest 
			
	        ENDCG
	    }
	}
}

