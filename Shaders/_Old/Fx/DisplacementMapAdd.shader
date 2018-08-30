// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "FX/Displacement Map Add" {
Properties {
	_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
	_NoiseTex ("Distort Texture (RG)", 2D) = "white" {}
	_MainTex ("MainTex", 2D) = "white" {}
	_HeatTime  ("Heat Time", range (-1,1)) = 0
	_ForceX  ("Strength X", range (0,1)) = 0.1
	_ForceY  ("Strength Y", range (0,1)) = 0.1
}

Category {
	Tags { "Queue"="Transparent" "RenderType"="Transparent" }
	Blend SrcAlpha One
	Cull Off Lighting Off ZWrite Off Fog { Color (0,0,0,0) }
	// BindChannels {
	// 	Bind "Color", color
	// 	Bind "Vertex", vertex
	// 	Bind "TexCoord", texcoord
	// }

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
			float2 uvmain : TEXCOORD0;
			float2 uvOffset1 : TEXCOORD1;
			float2 uvOffset2 : TEXCOORD2;
		};

		fixed4 _TintColor;
		fixed _ForceX;
		fixed _ForceY;
		fixed _HeatTime;
		float4 _MainTex_ST;
		float4 _NoiseTex_ST;
		sampler2D _NoiseTex;
		sampler2D _MainTex;

		v2f vert (appdata_t v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.color = v.color;
			o.uvmain = TRANSFORM_TEX( v.texcoord, _MainTex );
			o.uvOffset1 = o.uvmain + frac(_Time.xz*_HeatTime);
			o.uvOffset2 = o.uvmain + frac(_Time.yx*_HeatTime);
			return o;
		}

		fixed4 frag( v2f i ) : COLOR
		{
			
			fixed offset = 0;
			offset += tex2D(_NoiseTex, i.uvOffset1).r;
			offset += tex2D(_NoiseTex, i.uvOffset2).r-1;
			i.uvmain += float2(_ForceX, _ForceY) * offset;
			
			return 2.0f * i.color * _TintColor * tex2D( _MainTex, i.uvmain);
		}
		ENDCG
			}
		}
	}
}
