// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// brighter than moblie particle, same looking as particle/additive
Shader "Chp/Particles/Additive Tint TwoSide Brighter Clip" {
Properties {
	_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
	_MainTex ("Particle Texture", 2D) = "white" {}
	_ClipRange("Clip Range", Vector) = (0.0,1.0,0.0,1.0)
}

Category {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	Blend SrcAlpha One

	Cull Off Lighting Off ZWrite Off Fog { Mode Off }
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
			float2 texcoord : TEXCOORD1;
			float4 scrPos:TEXCOORD2;
		};

		fixed4 _TintColor;
		sampler2D _MainTex;
		float4 _ClipRange;

		v2f vert (appdata_t v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.color = v.color;
			o.texcoord = v.texcoord;
			o.scrPos = ComputeScreenPos(o.vertex);
			o.scrPos.xy = o.scrPos.xy/o.scrPos.w;
			return o;
		}

		fixed4 frag( v2f i ) : COLOR
		{
			// if ((i.scrPos.x > _ClipRange[1]) ||
			// 	(i.scrPos.x < _ClipRange[0]) ||
			// 	(i.scrPos.y > _ClipRange[3]) ||
			// 	(i.scrPos.y < _ClipRange[2]))
			// 	discard;
		
			half4 t4 =_ClipRange - i.scrPos.xxyy;
			fixed2 mt = saturate( fixed2(1,1) - ceil(fixed2(t4.x * t4.y, t4.z *t4.w)));
			fixed mask = mt.x * mt.y;
			return 2.0f * mask * i.color * _TintColor * tex2D( _MainTex, i.texcoord);
		}
		ENDCG
			}
		}
	
	
}
}
