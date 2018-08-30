Shader "* Environment/Sun And Moon(Billboard)"
{
	Properties
	{
		[NoScaleOffset]_MainTex ("太阳", 2D) = "white" {}
		[NoScaleOffset]_MoonTex ("月亮", 2D) = "white" {}
		_Scale ("大小", Float) = 1
		_Color ("染色(Alpha控制插值)", Color) = (1,1,1,0)
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" }

		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"


			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _MoonTex;
			float _Scale;
			float4 _Color;
			
			v2f vert (appdata_base v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_P,  mul(UNITY_MATRIX_MV, float4(0.0, 0.0, 0.0, 1.0)) + float4(v.vertex.x, v.vertex.y, 0.0, 0.0) * _Scale);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 sun = tex2D(_MainTex, i.uv);
				fixed4 moon = tex2D(_MoonTex,i.uv);
				fixed3 colorLerp = lerp(sun,moon,_Color.a) * _Color.rgb;
				float alpha = lerp(sun.a,moon.a,_Color.a);
				return fixed4(colorLerp,alpha);
			}
			ENDCG
		}
	}
}
