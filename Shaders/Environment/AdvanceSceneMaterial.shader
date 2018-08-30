// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "* Environment/Advance Scene Material"
{
	Properties
	{
		[NoScaleOffset]_MainTex ("BaseMap", 2D) = "white" {}
		[NoScaleOffset]_Normal ("NormalMap(B通道控制高光)", 2D) = "bump" {}
		_SpecAmount ("高光强度", Float) = 0.5
		_Power ("高光范围", Float) = 30

		[NoScaleOffset]_CustomCubeMap ("自定义Cubemap", CUBE) = "" {}
		[NoScaleOffset]_Mask ("Mask(R:反射强度 G:未使用 B:未使用)", 2D) = "white" {}
		_ReflectionAmont("反射强度",Range(0,1)) = 0
		_ColorBleedInRender("色溢强度(烘焙时有效)",Range(0,1)) = 0

	} 

	CGINCLUDE
	#include "../CGIncludes/ZL_CGInclude.cginc"
	#include "Lighting.cginc"
	#include "AutoLight.cginc"


	ENDCG


	SubShader //最高配置：高光、法线、阴影、雾
	{

		//用于烘焙色溢的MetaPass，用UsePass会导致客户端变紫，原因不明
		Pass 
		{
			Name "Meta"
			Tags { "LightMode" = "Meta" }

			CGPROGRAM
				#include "UnityStandardMeta.cginc"
				#pragma vertex vert_meta
				#pragma fragment frag_meta2
				float _ColorBleedInRender = 0;//需要外接Properties变量，否则不生效
				float4 frag_meta2 (v2f_meta i): SV_Target
				{
					FragmentCommonData data = UNITY_SETUP_BRDF_INPUT (i.uv);
					UnityMetaInput o;
					UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);
					fixed4 c = tex2D (_MainTex, i.uv);
					o.Albedo = c.rgb * _ColorBleedInRender;
					o.Emission = Emission(i.uv.xy) * _ColorBleedInRender;
					return UnityMetaFragment(o);
				}
			ENDCG
		}



		Tags { "Queue"="Geometry" "LightMode"="ForwardBase"  "IgnoreProjector"="False" "RenderType"="Opaque" }

		Pass
		{
        	Tags {"LightMode"="ForwardBase"}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
			#pragma multi_compile ZL_NORMALMAP_OFF ZL_NORMALMAP_ON
			#pragma multi_compile ZL_SPECULAR_OFF ZL_SPECULAR_ON
			#pragma multi_compile ZL_LIGHTMAP_OFF ZL_LIGHTMAP_ON
			#pragma multi_compile ZL_REFLECTION_OFF ZL_REFLECTION_CUBE ZL_REFLECTION_PROBE
			#pragma multi_compile ZL_DEBUG_MODE_OFF ZL_DEBUG_MODE_ON
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			sampler2D	_MainTex;
			float4 _MainTex_ST;
			sampler2D _Mask;

			sampler2D _Normal;
			float4 _Normal_ST;

			float _SpecAmount;
			float _Power;

			samplerCUBE _CustomCubeMap;
			float _ReflectionAmont;

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 uv: TEXCOORD0;
				WORLD_MATRIX(1,2,3)
				float3 worldSpaceLightDir : TEXCOORD4;
				float3 worldSpaceViewDir : TEXCOORD5;
				SHADOW_COORDS(6)
				UNITY_FOG_COORDS(7)
			};

			
			v2f vert (appdata_full v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.uv.xy = v.texcoord.xy;
				o.uv.zw = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;

				CALCULATE_WORLD_MATRIX
				o.worldSpaceLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				o.worldSpaceViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

				TRANSFER_SHADOW(o);
				UNITY_TRANSFER_FOG(o,o.pos);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//Unpack Vector
				float3 worldVertexNormal = float3(i.worldMatrixRow0.z,i.worldMatrixRow1.z,i.worldMatrixRow2.z);

				//Base color
				fixed3 col = tex2D (_MainTex, i.uv.xy).rgb;
				fixed3 maskColor = tex2D (_Mask, i.uv.xy).rgb;

				float3 finalNormal = worldVertexNormal;
				float spcularControlMap = Luminance(col.rgb);
				#if ZL_NORMALMAP_ON
					fixed4 normalMapColor = tex2D(_Normal, i.uv.xy);
					//float3 normal = UnpackNormal(tex2D(_Normal, i.uv.xy));
					finalNormal = UnpackNormalMap(normalMapColor);//强制使用自定义的方式解压法线，法线不能以NormalMap方式导入，这样才能让B通道能够被使用，否则在编辑器里，DXT5nm压缩方式会把B通道像素丢弃，无法正确控制高光
				
					CalculateNormalmap(i.worldMatrixRow0, i.worldMatrixRow1, i.worldMatrixRow2, normalMapColor, finalNormal);
					spcularControlMap = normalMapColor.b;
				#endif

				#if ZL_REFLECTION_PROBE || ZL_REFLECTION_CUBE

					Unity_GlossyEnvironmentData data;
					data.roughness = 0;
					float3 reflectDir = reflect(-i.worldSpaceViewDir, finalNormal);
					data.reflUVW = reflectDir;

					#if ZL_REFLECTION_PROBE
						half3 glossRefelct = Unity_GlossyEnvironment(unity_SpecCube0, unity_SpecCube0_HDR, data);
					#else
						half3 glossRefelct = texCUBE(_CustomCubeMap, reflectDir).rgb;
					#endif

					float fesnel = saturate(dot(i.worldSpaceViewDir.xyz, finalNormal));

					float3 refelctColor = glossRefelct * (1 - fesnel) + col * fesnel;
					col = lerp(col, refelctColor, _ReflectionAmont * maskColor.r);
				#endif
				
				#if ZL_DEBUG_MODE_ON
					col = SceneLighting(finalNormal,worldVertexNormal,worldVertexNormal,i.uv.zw,i.worldSpaceLightDir,i.worldSpaceViewDir,float3(_Power, _SpecAmount,spcularControlMap),SHADOW_ATTENUATION(i));
				#else
					col *= SceneLighting(finalNormal,worldVertexNormal,worldVertexNormal,i.uv.zw,i.worldSpaceLightDir,i.worldSpaceViewDir,float3(_Power, _SpecAmount,spcularControlMap),SHADOW_ATTENUATION(i));
				#endif

				UNITY_APPLY_FOG(i.fogCoord, col);
				return fixed4(col,1);
			}
			ENDCG
		}

		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
		//UsePass "Hidden/MetaPass/META"
	}


	//FallBack "Diffuse"

}
     