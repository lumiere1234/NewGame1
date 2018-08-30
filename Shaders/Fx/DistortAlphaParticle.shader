// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "* FX/distort_alpha_particle" {
Properties {
	_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
	_MainTex ("Alpha (A)", 2D) = "white" {}
	_NoiseTex ("Distort Texture (RG)", 2D) = "white" {}
	_HeatTime  ("Heat Time", float ) = 0
	_ForceX  ("Strength X", float) = 0.1
	_ForceY  ("Strength Y", float) = 0.1
	_Light ("Light", Float) = 1.0
	_EdgePower("_EdgePower",Range(0,1))=0.5
	_Transparent("_Transparent",Range(-1,2))=0
}

Category {
	Tags { "Queue"="Transparent" "RenderType"="Transparent" }
	Blend SrcAlpha OneMinusSrcAlpha
	Cull Off Lighting Off ZWrite Off Fog { Color (1,1,1,0) }
	BindChannels {
		Bind "Color", color
		Bind "Vertex", vertex
		Bind "TexCoord", texcoord
	}

	SubShader {
		Pass {
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma fragmentoption ARB_precision_hint_fastest
#pragma multi_compile_particles
#include "UnityCG.cginc"

struct appdata_t {
	float4 vertex : POSITION;
	fixed4 color : COLOR;
	float2 texcoord: TEXCOORD0;
};

struct v2f {
	float4 vertex : POSITION;
	fixed4 color : COLOR;
	float2 uvmain : TEXCOORD1;
};

fixed4 _TintColor;
fixed _ForceX;
fixed _ForceY;
fixed _HeatTime;
float4 _MainTex_ST;
float4 _NoiseTex_ST;
sampler2D _NoiseTex;
sampler2D _MainTex;
float _Light;
float _Transparent;
float _EdgePower;

v2f vert (appdata_t v)
{
	v2f o;
	o.vertex = UnityObjectToClipPos(v.vertex);
	o.color = v.color*_Light;
	o.uvmain = TRANSFORM_TEX( v.texcoord, _MainTex );
	
	return o;
}

//float _BlackPointAlpha(float alpha,float level)
//{
//    float Diff = 1.0 - level;
//    return (alpha - level)/Diff;
//
//}
fixed4 frag( v2f i ) : COLOR
{
	//noise effect
	fixed4 o;
	fixed4 offsetColor1 = tex2D(_NoiseTex, i.uvmain + _Time.xz*_HeatTime);
    fixed4 offsetColor2 = tex2D(_NoiseTex, i.uvmain + _Time.yx*_HeatTime);
    fixed4 offsetColor3 = tex2D(_NoiseTex, i.uvmain + _Time.xyzw*_HeatTime/2);
    
	//i.uvmain.x += ((offsetColor1.r + offsetColor1.r) - 1) * _ForceX;
	i.uvmain.x += (offsetColor3.r)*(offsetColor1.r-0.5)* _ForceX;
	//i.uvmain.y += ((offsetColor2.r + offsetColor2.r) - 1) * _ForceY;
	i.uvmain.y += (offsetColor3.r)*(offsetColor2.r-0.5)* _ForceY;
	o= i.color * tex2D( _MainTex, i.uvmain);
	o.rgb=o.rgb*_Light*_TintColor;
//	o.rgb*=o*_TintColor*(1.5-_AlphaPower)*_Light;
	float delta= 1.0-(o.a*4-1.0 -offsetColor3.b); //_Transparent-offsetColor3.b;
	float temp=saturate(-delta/_EdgePower)*(offsetColor3.b+1)*_Light*o.a;
//	o.a*=(o.a-_Transparent);
	o.a=delta>0? (o.a=0):(o.a=temp);
	//o.a*=_BlackPointAlpha(dot(o.rgb,float3(0.3,0.59,0.11)),_AlphaPower)*(1-_AlphaPower);
	//o.a = 1.0f;
	return o;
}
ENDCG
		}
}
	// ------------------------------------------------------------------
	// Fallback for older cards and Unity non-Pro
	
//	SubShader {
//		Blend DstColor Zero
//		Pass {
//			Name "BASE"
//			SetTexture [_MainTex] {	combine texture }
//		}
//	}	
}
}
