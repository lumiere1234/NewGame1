// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "* Environment/Snow Building Texture (Support lightmap, Fog)" 
{
Properties {
	_MainTex ("Base (RGB)", 2D) = "white" {}
	[NoScaleOffset]_MainBumpMap("Base Normal Map",2D) = "bump" {}
	_SecondTex ("Add (RGB)", 2D) = "white" {}
	[NoScaleOffset]_AddBumpMap("Add Normal Map",2D) = "bump" {}
	
	_Power("Glossiness", Float) = 4
	_SpecAmount("Specular Level", Float) = 1

	_NormalVector ("Snow Direction", Vector) = (0,1,0.1,1)

	_NormalScale ("Direction Scale", Range (0.01, 10)) = 8
	_NormalOffset ("Side", Range (0.01, 1)) = .7

	_ColorMaskAmount ("Color Mask Amount", Vector) = (0.22, 0.707, 0.071, 0)
	

	_SnowThreshold ("Threshold", Range (0.01, 1)) = 0.1
	_SmoothEdge ("Smooth", Range (0.01, 1)) = 0.1

	_ColorBleedInRender("色溢强度(烘焙时有效)",Range(0,1)) = 0

}

SubShader {
	
		CGINCLUDE
			#include "../CGIncludes/ZL_CGInclude.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
		ENDCG


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
		Cull Back Lighting Off ZWrite On 
		LOD 100

	Pass {  
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile ZL_LIGHTMAP_OFF ZL_LIGHTMAP_ON
			#pragma multi_compile ZL_NORMALMAP_OFF ZL_NORMALMAP_ON
			#pragma multi_compile ZL_SPECULAR_OFF ZL_SPECULAR_ON
			#pragma multi_compile ZL_DEBUG_MODE_OFF ZL_DEBUG_MODE_ON
			#pragma multi_compile_fog		



			struct v2f {
				float4 pos : SV_POSITION;
				half4 texcoord : TEXCOORD0;
				half4 texcoord1 : TEXCOORD1;
				TANGENT_SPACE_VERCTORS(2,3,4)
				SHADOW_COORDS(6)
				UNITY_FOG_COORDS(7)
			};

			sampler2D _MainTex;
			sampler2D _MainBumpMap;
			sampler2D _SecondTex;
			sampler2D _AddBumpMap;

			float4 _MainTex_ST;
			float4 _SecondTex_ST;

			
			float4 _NormalVector;
			float4 _ColorMaskAmount;

			float _NormalScale;
			float _NormalOffset;
			float _SnowThreshold;
			float _SmoothEdge;
			float _Power;
			float _SpecAmount;
			
			v2f vert (appdata_tan_uv2 v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				o.pos = UnityObjectToClipPos(v.vertex);

				o.texcoord.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.texcoord1.xy = TRANSFORM_TEX(v.texcoord1, _SecondTex);
				#if ZL_LIGHTMAP_ON
					o.texcoord.zw = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				TANGENT_SPACE_CALCULATE

				half dotN = saturate( dot ( worldNormal, _NormalVector)) * _NormalScale + _NormalOffset;
				o.texcoord1.w = step( 1, dotN);//把原来的mask塞到texcoord1的W里，节约一个TEXCOORD

				TRANSFER_SHADOW(o);
				UNITY_TRANSFER_FOG(o,o.pos);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half3 col = tex2D(_MainTex, i.texcoord);
				half3 second = tex2D(_SecondTex, i.texcoord1);

				half normalAmount = i.texcoord1.w;//原来的mask塞到texcoord1的W里了
				half colorAmount = dot( _ColorMaskAmount.rgb, col) ;
				colorAmount = (colorAmount - _SnowThreshold) /(_SmoothEdge );
				float amount = saturate( normalAmount  * colorAmount );  
				col = lerp( col, second, amount);


				float3 finalNormal = i.tangentSpaceVertexNormal;
				float spcularControlMap = Luminance(col.rgb);
				#if ZL_NORMALMAP_ON
					fixed4 firstBump = tex2D(_MainBumpMap, i.texcoord);
					fixed4 secondBump = tex2D(_AddBumpMap, i.texcoord1);
					fixed4 finalBump = lerp( firstBump, secondBump, amount);

					finalNormal = UnpackNormalMap(finalBump);//强制使用自定义的方式解压法线，法线不能以NormalMap方式导入，这样才能让B通道能够被使用，否则在编辑器里，DXT5nm压缩方式会把B通道像素丢弃，无法正确控制高光
					spcularControlMap = finalBump.b;
				#endif

				float3 worldNormal = float3(i.tangentSpaceLightDir.w, i.tangentSpaceViewDir.w, i.tangentSpaceVertexNormal.w);
				#if ZL_DEBUG_MODE_ON
					col.rgb = SceneLighting(finalNormal,i.tangentSpaceVertexNormal,worldNormal,i.texcoord.zw,i.tangentSpaceLightDir,i.tangentSpaceViewDir,float3(_Power, _SpecAmount,spcularControlMap),SHADOW_ATTENUATION(i));
				#else
					col.rgb *= SceneLighting(finalNormal,i.tangentSpaceVertexNormal,worldNormal,i.texcoord.zw,i.tangentSpaceLightDir,i.tangentSpaceViewDir,float3(_Power, _SpecAmount,spcularControlMap),SHADOW_ATTENUATION(i));
				#endif

				UNITY_APPLY_FOG(i.fogCoord, col);
				return half4(col,1);
			}
		ENDCG
	}

	UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"





}

}

     