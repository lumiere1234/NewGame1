// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "* Billboard/VertexColor/Billboard_Color_Additive_Fog" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_TintColor ("Tint Color", Color) = (1,1,1,1)
		_VerticalBillboarding("垂直方向是否billboard", Range(0,1)) = 1
		_Scale("自身缩放", Float) = 1.0
		_DistanceOffset("距原位置距离", Float) = 0.0
	}
	
	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		Blend SrcAlpha One
		Cull Off Lighting Off ZWrite Off
		Fog {Range 0, 200}
	
		CGINCLUDE	
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _TintColor;
			fixed _VerticalBillboarding;
			half _DistanceOffset;
			float _Scale;
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				fixed4 color : COLOR;
			};
			struct appdata {
    			float4 vertex : POSITION;
    			float4 texcoord : TEXCOORD0;
			    float4 texcoord1 : TEXCOORD1;
    			fixed4 color : COLOR;
			};

			void CalcOrthonormalBasis(float3 dir,out float3 right,out float3 up)
			{
				up = abs(dir.y) > 0.999f ? float3(0,0,1) : float3(0,1,0);		
				right = normalize(cross(up,dir));		
				up = cross(dir,right);	
			}
	
			v2f vert (appdata v)
			{
				v2f o;
				float3 centerOffs = v.texcoord1.xyz;
				float3 centerLocal = v.vertex.xyz;
				
				float3 viewerLocal = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));			
				float3 localDir = viewerLocal - centerLocal;
				
				localDir.y = ( lerp(0,localDir.y,_VerticalBillboarding) );
				localDir = normalize(localDir);
		
				float3 rightLocal;
				float3 upLocal;
		
				CalcOrthonormalBasis(localDir ,rightLocal,upLocal);

				float3 BBLocalPos = centerLocal - (rightLocal * centerOffs.x + upLocal * centerOffs.y) *_Scale  + localDir * _DistanceOffset;	
				o.uv = TRANSFORM_TEX(v.texcoord.xy,_MainTex);
				o.pos = UnityObjectToClipPos(float4(BBLocalPos,1));
				o.color = v.color;	
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
					return tex2D (_MainTex, i.uv) * i.color*_TintColor;
				}
			ENDCG 
		}	
	}
}
