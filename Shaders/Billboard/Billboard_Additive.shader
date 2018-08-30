// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "* Billboard/Billboard_Additive" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,1.0)
		_VerticalBillboarding("垂直方向是否billboard", Range(0,1)) = 1
		_DistanceOffset("距原位置距离", Float) = 1.0
		_Scale("Scale", Float) = 1.0
	}
	
	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		Blend SrcAlpha One
		Cull Off Lighting Off ZWrite Off Fog { Mode Off }
	
		CGINCLUDE	
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			fixed4 _TintColor;
			fixed _VerticalBillboarding;
			fixed _DistanceOffset;
			float _Scale;

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			void CalcOrthonormalBasis(float3 dir,out float3 right,out float3 up)
			{
				up = abs(dir.y) > 0.999f ? float3(0,0,1) : float3(0,1,0);		
				right = normalize(cross(up,dir));		
				up = cross(dir,right);	
			}
	
			v2f vert (appdata_full v)
			{
				v2f o;
			
				float3 centerOffs  = float3(float(0.5).xx - v.color.rg,0) * v.texcoord1.xyy;
				float3 centerLocal = v.vertex.xyz + centerOffs.xyz;
				float3 viewerLocal = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));			
				float3 localDir = viewerLocal - centerLocal;
				
				localDir[1] = lerp(0,localDir[1],_VerticalBillboarding);
		
				float3 rightLocal;
				float3 upLocal;
				float3 localDirN = normalize(localDir);
				CalcOrthonormalBasis(localDirN ,rightLocal,upLocal);
		
				float3 BBLocalPos = centerLocal - (rightLocal * centerOffs.x + upLocal * centerOffs.y) *_Scale + localDirN * _DistanceOffset;
				o.uv = v.texcoord.xy;
				o.pos = UnityObjectToClipPos(float4(BBLocalPos,1));
						
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
					return tex2D (_MainTex, i.uv.xy) * _TintColor;
				}
			ENDCG 
		}	
	}
}
