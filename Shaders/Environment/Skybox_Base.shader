// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "Custom/wok Skybox Base" {
Properties {
	_MainTex ("Base layer (RGB)", 2D) = "white" {}
	_MainTex2 ("Base layer (RGB)", 2D) = "white" {}
	_AMultiplier ("Layer Multiplier", Float) = 1
	_Color ("multi color", Color) = (1,0.5,0,1)
	_SunSize ("Sun size", Range(0.0001, 2)) = 0.006
	_SunRangeSoftness("Sun Softness", Range(0.0001, 1)) = 1
	_SunMultipier ("Sun Intensity", Range(0, 10)) = 1.25
	_Blend ("Blend", Range(0,1)) = 0
	_FogAmount ("Fog Amount", Range(0,1)) = 1
}

SubShader {

	
	CGINCLUDE

	#include "../CGIncludes/WokInclude.cginc"

	sampler2D _MainTex;
	sampler2D _MainTex2;
	float _AMultiplier;

	float4 _MainTex_ST;

	float _SunSize;
	float _SunRangeSoftness;
	float4 _Color;
	fixed3 _LightColor0;
	float _SunMultipier;
	float _FogAmount;

	float _Blend;
	
	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		fixed3 lightDir : TEXCOORD1;
		fixed3 normal :  TEXCOORD2;
		WOK_FOG_COORDS(3)
		float4 worldPos : TEXCOORD4;
	};

	
	v2f vert (appdata_full v)
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex) ;
		o.lightDir =  normalize( UnityWorldSpaceLightDir(o.pos));

		o.normal = UnityObjectToWorldNormal(v.normal);
		o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
		o.fogCoord = WOK_TRANSFER_ALTITUDE_FOG(o.pos.z, o.worldPos, wokAltitudeFogParams);

		return o;
	}

	half4 frag (v2f i) : COLOR
	{
		half4 o;
		half4 col = lerp( tex2D (_MainTex, i.uv),  tex2D (_MainTex2, i.uv), _Blend);
		half nDotL =  clamp( dot( normalize ( -i.normal), i.lightDir), -1, 1);
		half lightRange = (nDotL - 1 + _SunSize) / ( _SunSize * _SunRangeSoftness );

		lightRange = max( 0, min ( lightRange, _SunMultipier)) ;
		
		col.rgb *= _AMultiplier;
		col.rgb += _SunMultipier * lightRange * _Color.rgb;

		col.rgb = lerp( col.rgb,  WOK_APPLY_FOG_COLOR( col.rgb,  i.worldPos, i.fogCoord, wokAltitudeFogParams), _FogAmount);

		return col;	
	}

	ENDCG
	
	Tags { "Queue"="Geometry+10" "LightMode"="ForwardBase" "RenderType"="Opaque" }
	
	Lighting Off Fog { Mode Off }
	ZWrite Off
	
	LOD 100

	Pass {
		CGPROGRAM
		#pragma multi_compile WOK_ALTITUDE_FOG_OFF WOK_ALTITUDE_FOG_ON

		#pragma vertex vert
		#pragma fragment frag
		#pragma fragmentoption ARB_precision_hint_fastest		

		ENDCG 
	}	
}
}
