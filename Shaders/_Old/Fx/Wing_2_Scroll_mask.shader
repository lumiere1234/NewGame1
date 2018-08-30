// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Unlit alpha-cutout shader.
// - no lighting
// - no lightmap support
// - no per-material color

Shader "Custom/Wing_2Scroll_mask" {
Properties {
	_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
	_Color01("Main_Texture_Color", Color) = (1,1,1,1)
	_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
	_ScrollMaskTex("Scroll Mask", 2D) = "white" {}
	_Blend_Texture("Blend_Texture", 2D) = "black" {}
	_Color02("Blend_Texture_Color", Color) = (1,1,1,1)
	_Blend_Texture01("Blend_Texture01", 2D) = "black" {}
	_Color03("Blend_Texture_Color", Color) = (1,1,1,1)
	_Speeds("TextureSpeeds", Vector) = (1,1,-1,1)
}
SubShader {
	Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
	Cull off

	Fog { Mode Off }
	LOD 100

	Lighting Off

	Pass {  
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv_MainTex : TEXCOORD0;
				half2 uv_MaskTex : TEXCOORD1;
				float2 uv_Blend_Tex : TEXCOORD2;
				float2 uv_Blend_Tex01 : TEXCOORD3;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _Cutoff;

			sampler2D _ScrollMaskTex;
			float4 _ScrollMaskTex_ST;
			sampler2D _Blend_Texture;
			float4 _Blend_Texture_ST;
			sampler2D _Blend_Texture01;
			float4 _Blend_Texture01_ST;

			fixed3 _Color01;
			fixed3 _Color02;
			fixed3 _Color03;

			float4 _Speeds;

			v2f vert (appdata_t v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				float4 speeds = _Speeds * _Time.x;
				o.uv_MainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv_MaskTex = TRANSFORM_TEX(v.texcoord, _ScrollMaskTex);
				o.uv_Blend_Tex = TRANSFORM_TEX(v.texcoord.xy,_Blend_Texture) + frac(float2(speeds.x, speeds.y) );
				o.uv_Blend_Tex01 = TRANSFORM_TEX(v.texcoord.xy,_Blend_Texture01) + frac(float2(speeds.z, speeds.w) );
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv_MainTex);

				clip(col.a - _Cutoff);
				fixed mask = tex2D(_ScrollMaskTex, i.uv_MaskTex);

				fixed3 blendTex = tex2D(_Blend_Texture,i.uv_Blend_Tex) * _Color02;
				fixed3 blendTex1 = tex2D(_Blend_Texture01,i.uv_Blend_Tex01)* _Color03;

				col = fixed4( col.rgb * _Color01 + (1-mask) * (blendTex + blendTex1), col.a );
				return col;
			}
		ENDCG
	}
}

}