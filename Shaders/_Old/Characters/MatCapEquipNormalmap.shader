// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Matcap Equip NormalMap.." {
	Properties
	{
		_MainTex ("Base (RGB)", 2D) = "grey" {}
		_BumpMap ("Normal(RG) Mask (B) ", 2D) = "bump" {}
		_MaskMap("Mask (RGB)", 2D) = "white" {}
		[ShowWhenHasKeyword(TwoMask_On, MultiCap_On)] _MaskBMap ("MaskB (R:alpha G:upperRight B:tint)", 2D) = "black" {}
		[ShowWhenHasKeyword(transparentCullout_On)] _AlphaRef ("AlphaTest Ref", Range(0,1)) = 0.5
		[ShowWhenHasKeyword(transparentCullout_On, TwoMask_Off)] _AlphaTex("Alpha (A8)", 2D) = "white" {}
		[ShowWhenHasKeyword(TwoMask_On, MultiCap_On)] _Tint ("装备换色 ", Color) = (1,1,1,0.5)

		_EnvMap ("EnvCap (RGB)", 2D) = "white" {}
	}
	
	Subshader
	{
		Tags { "Queue"="Geometry+1" "LightMode"="ForwardBase"  "IgnoreProjector"="True" "RenderType"="Opaque"}

		Cull Back Lighting Off ZWrite On Fog { Mode Off }
		Pass
		{
		
			CGPROGRAM
	
				
				#pragma multi_compile MultiCap_Off MultiCap_On
				#pragma multi_compile transparentCullout_Off transparentCullout_On
				#pragma multi_compile TwoMask_Off TwoMask_On
				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest
				#include "UnityCG.cginc"


				sampler2D _MainTex;
				float4 _MainTex_ST;
				
				sampler2D _BumpMap;
				float4 _BumpMap_ST;

				sampler2D _MaskMap;
				sampler2D _EnvMap;

				#ifdef TwoMask_On
					#ifdef MultiCap_On
						sampler2D _MaskBMap;
						fixed4 _Tint;
					#endif
				#else
					#ifdef transparentCullout_On
						sampler2D _AlphaTex;
					#endif
				#endif

				#ifdef transparentCullout_On
					fixed _AlphaRef;
				#endif


				struct v2f
				{
					float4 pos	: SV_POSITION;
					float2 uv : TEXCOORD0;
					float3 c0  : TEXCOORD1;
					float3 c1  : TEXCOORD2;
					float2 uvBump : TEXCOORD3;
				};
				
				v2f vert (appdata_tan v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos (v.vertex);
					o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
					o.uvBump = TRANSFORM_TEX(v.texcoord,_BumpMap);
					
					half2 capUV;
					TANGENT_SPACE_ROTATION;
					o.c0 = mul(rotation, UNITY_MATRIX_IT_MV[0].xyz);
					o.c1 = mul(rotation, UNITY_MATRIX_IT_MV[1].xyz);
					return o;
				}

				float4 frag (v2f i) : COLOR
				{
					fixed alpha = 1;
					#ifdef transparentCullout_On 
						#ifdef TwoMask_Off
							alpha = tex2D(_AlphaTex, i.uv);
							clip( alpha - _AlphaRef);
						#endif
					#endif

					fixed3 col = tex2D(_MainTex, i.uv);
					fixed4 mask = tex2D(_MaskMap, i.uv);
					
					half2 capCoord;
					
					fixed3 normals = UnpackNormal( tex2D( _BumpMap, i.uvBump )) ;
					capCoord = half2(dot(i.c0, normals), dot(i.c1, normals));
					
					
					fixed3 matcap;
					
					#ifdef MultiCap_On
						capCoord = capCoord *0.25 + 0.25;
						half4 uv1 = capCoord.xyxy + half4(0,0,0.5,0);
						half4 uv2 = capCoord.xyxy + half4(0,0.5,0.5,0.5);
						fixed3 lowerLeftCol = tex2D(_EnvMap, uv1.xy) * mask.r;
						fixed3 lowerRightCol = tex2D(_EnvMap, uv1.zw) * mask.g;
						fixed3 upperLeftCol = tex2D(_EnvMap, uv2.xy) * mask.b;
						
						matcap = lowerLeftCol  + upperLeftCol + lowerRightCol ;

						#ifdef TwoMask_On
							fixed3 maskB = tex2D( _MaskBMap, i.uv);
							col = lerp( col, (_Tint.a * 2) * _Tint.rgb * col, maskB.b);
							matcap += tex2D(_EnvMap, uv2.zw) * maskB.g;	//upperRight
							alpha = maskB.r;
							#ifdef transparentCullout_On
								clip( alpha - _AlphaRef);
							#endif
						#else
							matcap += tex2D(_EnvMap, uv2.zw) * mask.a;
						#endif
					#else

						
						capCoord = capCoord *0.5 + 0.5;
						matcap = tex2D(_EnvMap, capCoord) * mask.r;
					#endif
					
					

					return fixed4(col + matcap,alpha);
				}
			ENDCG
		}

		UsePass "Mobile/VertexLit/SHADOWCASTER"
	}
	
	//Fallback "VertexLit"
	CustomEditor "MatcapEquipMaterialInspector"
}