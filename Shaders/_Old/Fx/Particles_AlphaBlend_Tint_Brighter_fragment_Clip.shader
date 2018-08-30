// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Chp/Particles/Additive Tint TwoSide Brighter fragment Clip" {
Properties {
	_TintColor("Color", Color) = (0.5,0.5,0.5,0.5)
	_MainTex ("Base layer (RGB)", 2D) = "white" {}
	_ClipRange("Clip Range", Vector) = (0.0,1.0,0.0,1.0)
}

SubShader {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	
	Blend SrcAlpha One
	

	Cull Off Lighting Off ZWrite Off Fog { Mode Off }
	
		
	CGINCLUDE
	#include "UnityCG.cginc"
	sampler2D _MainTex;
	float4 _MainTex_ST;
	
	float4 _TintColor;
	float4 _ClipRange;
	
	struct appdata_t {
		float4 vertex : POSITION;
		fixed4 color : COLOR;
		float2 texcoord: TEXCOORD0;
	};

	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		fixed4 color : COLOR;
		float4 scrPos:TEXCOORD1;
	};

	
	v2f vert (appdata_t v)
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = TRANSFORM_TEX(v.texcoord.xy,_MainTex);
		o.color = v.color;
		o.scrPos = ComputeScreenPos(o.pos);
		o.scrPos.xy = o.scrPos.xy/o.scrPos.w;
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
			// if and discard is expensive...
			// if ((i.scrPos.x > _ClipRange[1]) ||
			// 	(i.scrPos.x < _ClipRange[0]) ||
			// 	(i.scrPos.y > _ClipRange[3]) ||
			// 	(i.scrPos.y < _ClipRange[2]))
			// 	discard;
			// _ClipRange[1]

			fixed4 o;
			half4 t4 =_ClipRange - i.scrPos.xxyy;
			fixed2 mt = saturate( fixed2(1,1) - ceil(fixed2(t4.x * t4.y, t4.z *t4.w)));
			fixed mask = mt.x * mt.y;

			o = 2 *mask* i.color * tex2D (_MainTex, i.uv) * _TintColor;
			return o;
		}
		ENDCG 
	}	
}
}
