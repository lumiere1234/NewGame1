// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "* Terrain/Standard"
{
	Properties
	{
		[HideInInspector] _Control ("Control (RGBA)", 2D) = "red" {}
		[HideInInspector] _Splat3 ("Layer 3 (A)", 2D) = "white" {}
		[HideInInspector] _Splat2 ("Layer 2 (B)", 2D) = "white" {}
		[HideInInspector] _Splat1 ("Layer 1 (G)", 2D) = "white" {}
		[HideInInspector] _Splat0 ("Layer 0 (R)", 2D) = "white" {}
		[HideInInspector] _Normal3 ("Normal 3 (A)", 2D) = "bump" {}
		[HideInInspector] _Normal2 ("Normal 2 (B)", 2D) = "bump" {}
		[HideInInspector] _Normal1 ("Normal 1 (G)", 2D) = "bump" {}
		[HideInInspector] _Normal0 ("Normal 0 (R)", 2D) = "bump" {}
		[HideInInspector] _MainTex ("BaseMap (RGB)", 2D) = "white" {}

		

		_SpecAmount ("Specular Level", Range(0, 2)) = 0.5
		_Power ("Glossiness", Range(1,150)) = 30
		_Low ("Low Threshold", Range(0.01,1)) = 0
		_Hi ("High Threshold", Range(0.01,1)) = 1
		_SpecMulti("Spec Multi A B C D   (0~1)", Vector) = (1,1,1,1)

		_AddOnTex ("AddOn Map (RGB)", 2D) = "grey" {}

		[Toggle(ZL_DEBUG_MODE_ON)]_DebugMode("Debug Mode",Float) = 0
	} 

	CGINCLUDE
	#include "../CGIncludes/ZL_CGInclude.cginc"
	#include "UnityCG.cginc"
	#include "Lighting.cginc"
	#include "AutoLight.cginc"

	sampler2D	_MainTex;
	float4 _MainTex_ST;

	sampler2D _Control;
	float4 _Control_ST;

	sampler2D _Splat0,_Splat1,_Splat2,_Splat3;
	float4 _Splat0_ST, _Splat1_ST, _Splat2_ST, _Splat3_ST;

	sampler2D _Normal0,_Normal1,_Normal2,_Normal3;
	float _NormalDepth;

	float _SpecAmount;
	float _Power;
	float _Low;
	float _Hi;
	float4 _SpecMulti;

	#if ZL_LIGHTMAP_PAINT_ON
	sampler2D _AddOnTex;
	#endif



	ENDCG

	SubShader //最高配置：高光、法线、阴影、雾
	{
		Tags { "Queue"="Geometry-100" "LightMode"="ForwardBase"  "IgnoreProjector"="False" "RenderType"="Opaque" }

		Pass
		{
        	Tags {"LightMode"="ForwardBase"}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
			#pragma multi_compile ZL_NORMALMAP_OFF ZL_NORMALMAP_ON
			#pragma multi_compile ZL_SPECULAR_OFF ZL_SPECULAR_ON
			#pragma multi_compile ZL_LIGHTMAP_PAINT_OFF ZL_LIGHTMAP_PAINT_ON
			#pragma multi_compile ZL_LIGHTMAP_OFF ZL_LIGHTMAP_ON
			#pragma multi_compile ZL_DEBUG_MODE_OFF ZL_DEBUG_MODE_ON
			#pragma multi_compile_fog
			

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 uvBase : TEXCOORD0;	//Base and lightmapUV
				float4 uv_SplatA : TEXCOORD1; // A and B
				float4 uv_SplatB : TEXCOORD2; // C and D
				TANGENT_SPACE_VERCTORS(3,4,5)
				SHADOW_COORDS(6)
				UNITY_FOG_COORDS(7)
			};

			
			v2f vert (appdata_full v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				o.pos = UnityObjectToClipPos(v.vertex);

				o.uvBase.xy = TRANSFORM_TEX(v.texcoord, _Control);
				o.uvBase.zw = v.texcoord.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				o.uv_SplatA.xy =  TRANSFORM_TEX(v.texcoord.xy,_Splat0);
     			o.uv_SplatA.zw =  TRANSFORM_TEX(v.texcoord.xy,_Splat1);
     			o.uv_SplatB.xy =  TRANSFORM_TEX(v.texcoord.xy,_Splat2);
     			o.uv_SplatB.zw =  TRANSFORM_TEX(v.texcoord.xy,_Splat3);

				v.tangent.xyz = cross(v.normal, float3(0,0,1));
				v.tangent.w = -1;


				TANGENT_SPACE_CALCULATE
				TRANSFER_SHADOW(o);
				UNITY_TRANSFER_FOG(o,o.pos);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//Base color
				float4 splat_control = tex2D ( _Control, i.uvBase.xy );
				float weight = dot(splat_control.rgba, half4(1,1,1,1));
				fixed3 col = splat_control.r * tex2D (_Splat0, i.uv_SplatA.xy).rgb;
				col += splat_control.g * tex2D (_Splat1, i.uv_SplatA.zw).rgb;
				col += splat_control.b * tex2D (_Splat2,  i.uv_SplatB.xy).rgb;
				col += splat_control.a * tex2D (_Splat3,  i.uv_SplatB.zw).rgb;

				half3 finalLight = 1;

				//Additional lightmap paint mode
				#if ZL_LIGHTMAP_PAINT_ON
					//i.uvBase.z = clamp(i.uvBase.x,0.01,1);
					//i.uvBase.w = clamp(i.uvBase.y,0.01,1);
					finalLight *= 2 * tex2D(_AddOnTex, i.uvBase.zw).rgb ;
				#endif
		
				float3 finalNormal = i.tangentSpaceVertexNormal;
				float spcularControlMap = Luminance(col.rgb);
				#if ZL_NORMALMAP_ON
					half4 normalTex0 = tex2D(_Normal0, i.uv_SplatA.xy);
					half4 normalTex1 = tex2D(_Normal1, i.uv_SplatA.zw);
					half4 normalTex2 = tex2D(_Normal2, i.uv_SplatB.xy);
					half4 normalTex3 = tex2D(_Normal3, i.uv_SplatB.zw);
					half4 normalColor = splat_control.r * normalTex0;
					normalColor += splat_control.g * normalTex1;
					normalColor += splat_control.b * normalTex2;
					normalColor += splat_control.a * normalTex3;
				
					finalNormal = UnpackNormalMap(normalColor);
				#endif

				//Specular
				#if ZL_SPECULAR_ON
					#if ZL_NORMALMAP_ON
						spcularControlMap = splat_control.r * normalTex0.b + splat_control.g * normalTex1.b + splat_control.b * normalTex2.b + splat_control.a * normalTex3.b;
					#else
						half specMulit = dot (splat_control * _SpecMulti, fixed4(1,1,1,1)) ;
						float v = saturate(Luminance(col.rgb * specMulit) - _Low) / (1 - _Low - (1-_Hi));
						//half3 spec = specValue * max (0, v) * _LightColor0.xyz;
						spcularControlMap = max (0, v);
					#endif
				#endif		

				float3 worldNormal = float3(i.tangentSpaceLightDir.w, i.tangentSpaceViewDir.w, i.tangentSpaceVertexNormal.w);
				finalLight *= SceneLighting(finalNormal,i.tangentSpaceVertexNormal,worldNormal,i.uvBase.zw,i.tangentSpaceLightDir,i.tangentSpaceViewDir,float3(_Power, _SpecAmount,spcularControlMap),SHADOW_ATTENUATION(i));

				#if ZL_DEBUG_MODE_ON
					col = finalLight;
				#else
					col *= finalLight;
				#endif

				UNITY_APPLY_FOG(i.fogCoord, col);
				return fixed4(col,1);
			}
			ENDCG
		}

		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
		//UsePass "Hidden/MetaPass/META"

	}

	Dependency "AddPassShader" = "Hidden/Terrain/Standard_AddPass"
	Dependency "BaseMapShader" = "Hidden/Terrain/Standard_Base"
}
     