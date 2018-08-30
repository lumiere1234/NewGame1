// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "* FX/Additive_RedControlUV"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex ("Particle Texture", 2D) = "white" {}
//		_MainTexRepeatIntervalX("Repeat Interval X", Float) = 1.0
//		_MainTexRepeatIntervalY("Repeat Interval Y", Float) = 1.0
		_LightFactor("Light factor", Float) = 1.0
		_X_RepeatNumber("_X_RepeatNumber", Float) = 1
	}
	
	SubShader
	{
		LOD 100

		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
		}
		
		Blend SrcAlpha One
	  Cull Off 
	  Lighting Off 
	  ZWrite Off 
	  Fog { Color (0,0,0,0) }

		Pass
		{
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				
				#include "UnityCG.cginc"
	
				struct appdata_t
				{
					float4 vertex : POSITION;
					float2 texcoord : TEXCOORD0;
					fixed4 color : COLOR;
				};
	
				struct v2f
				{
					float4 vertex : SV_POSITION;
					half2 texcoord : TEXCOORD0;
					fixed4 color : COLOR;
				};
	
				sampler2D _MainTex;
				float4 _MainTex_ST;
				float4 _Color;
				half _MainTexRepeatIntervalX;
				half _MainTexRepeatIntervalY;
				half _LightFactor;
				half _X_RepeatNumber;
				
				v2f vert (appdata_t v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex) + half2(v.color.r*(1+_X_RepeatNumber)-1, 0.0);//frac(half2(_ScrollX, _ScrollY) * v.color.a);
					o.color = v.color;
					return o;
				}
				
				fixed4 frag (v2f i) : COLOR
				{
//					half tempx = 0.0;
//					if ((i.texcoord.x- _MainTex_ST.z) < _MainTexRepeatIntervalX)
//						tempx = i.texcoord.x - _MainTex_ST.z;
//					i.texcoord.x = _MainTex_ST.z + tempx;
//				    i.texcoord.y = _MainTex_ST.w + fmod(i.texcoord.y, _MainTexRepeatIntervalY);
					fixed4 col = tex2D(_MainTex, i.texcoord)*_Color*_LightFactor;
					col.a = col.a *i.color.a;
					return col;
				}
			ENDCG
		}
	}
}
