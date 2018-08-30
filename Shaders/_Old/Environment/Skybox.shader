// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/SkyBox/Skybox" {
Properties {
	_MainTex ("Base layer (RGB)", 2D) = "white" {}
	_AMultiplier ("Layer Multiplier", Float) = 1
	_Color2 ("multi color", Color) = (1,1,1,1)
}

SubShader {
	Tags { "Queue"="Geometry+10" "RenderType"="Opaque" }
	
	Lighting Off Fog { Mode Off }
	ZWrite Off
	
	LOD 100
	
		
	CGINCLUDE
	#include "UnityCG.cginc"
	sampler2D _MainTex;
	float4 _MainTex_ST;

	float4 _Color2;
	float _AMultiplier;
	
	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		fixed4 color : TEXCOORD3;		
	};

	
	v2f vert (appdata_full v)
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = TRANSFORM_TEX(v.texcoord.xy,_MainTex);
		o.color =   fixed4(_AMultiplier, _AMultiplier, _AMultiplier, _AMultiplier);

		return o;
	}
	ENDCG


	Pass {
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma fragmentoption ARB_precision_hint_fastest		
		fixed4 frag (v2f i) : COLOR
		{
			fixed4 o;
			fixed3 tex = tex2D (_MainTex, i.uv);
			o = fixed4(tex.rgb * i.color.rgb * _Color2.rgb, 1);
			return o;
		}
		ENDCG 
	}	
}
}
