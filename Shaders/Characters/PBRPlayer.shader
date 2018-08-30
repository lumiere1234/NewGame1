﻿Shader "* Character/PBR Player" {
	Properties {
		[NoScaleOffset]_MainTex ("BaseColor", 2D) = "white" {}
		[NoScaleOffset]_MetallicGlossMap("MSS(R:Metallic G:Smoothness B:Unused)", 2D) = "white" {}
		[NoScaleOffset]_MaskMap("Mask(R:Alpha G:ClothTint B:Emission)", 2D) = "white" {}
		[NoScaleOffset]_BumpMap("Normal Map", 2D) = "bump" {}
		[Space]_CutOut("Alpha Cut off",Range(0,1)) = 0.5
		[Space]_ClothTint1("Cloth Tint 1", Color) = (1,1,1)
		[Space]_ClothTint2("Cloth Tint 2", Color) = (1,1,1)
		[Space]_SelfIlluminateColor("Emission Color", Color) = (0,0,0)
		[NoScaleOffset]_DetailFlowMask("DF(R:Detail G:Flow B:Unused)", 2D) = "black" {}
		_FlowTex("Flow Texture", 2D) = "black" {}
		_FlowColor("Flow Color", Color) = (1,1,1)
		_DetailNormalMap1("Detail 1 Normal Map", 2D) = "bump" {}
		_DetailNormalMap2("Detail 2 Normal Map", 2D) = "bump" {}

		[Space][Space][Space]_animParams("Animmation Params(xyz控制扰动，w控制强度)",Vector) = (1.975, 0.793, 0.375, 0.193)
		[Space][Space][Space]_Wind("Wind params(xyz控制位移距离，w控制强度)",Vector) = (0,0,0,1)
	}


	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM

		#pragma surface surf Standard vertex:vert exclude_path:prepass nolightmap noforwardadd
		#pragma skip_variants FOG_EXP FOG_EXP2 POINT SPOT POINT_COOKIE DIRECTIONAL_COOKIE DIRLIGHTMAP_COMBINED DIRLIGHTMAP_SEPARATE SHADOWS_SCREEN VERTEXLIGHT_ON
		//fullforwardshadows
		#pragma target 3.0

		#include "TerrainEngine.cginc"

		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _MaskMap;
		sampler2D _MetallicGlossMap;
		sampler2D _DetailFlowMask;
		sampler2D _FlowTex;
		sampler2D _DetailNormalMap1;
		sampler2D _DetailNormalMap2;
		float4 _animParams;
		float _CutOut;


		struct Input 
		{
			float2 uv_MainTex;
			float2 uv_DetailNormalMap1;
			float2 uv_DetailNormalMap2;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _SelfIlluminateColor;
		fixed4 _ClothTint1;
		fixed4 _ClothTint2;
		half _FlowSpeed;
		float4 _FlowTex_ST;
		fixed4 _FlowColor;


		void vert (inout appdata_full v, out Input o) 
		{
			UNITY_INITIALIZE_OUTPUT(Input,o);
			float4 newPos = AnimateVertex(v.vertex, v.normal, _animParams);
			v.vertex = lerp(v.vertex, newPos,1 - v.color.g);
		}

		void surf (Input IN, inout SurfaceOutputStandard o) 
		{
			fixed4 baseColor = tex2D(_MainTex, IN.uv_MainTex);
			fixed4 mss = tex2D(_MetallicGlossMap, IN.uv_MainTex);
			fixed4 normal = tex2D(_BumpMap, IN.uv_MainTex);
			fixed4 mask = tex2D(_MaskMap, IN.uv_MainTex);
			fixed4 detailFlowMask = tex2D(_DetailFlowMask, IN.uv_MainTex);

			//流光UV
			float2 flowUV = TRANSFORM_TEX(IN.uv_MainTex,_FlowTex);
			flowUV.x += _Time * _FlowTex_ST.z;
			flowUV.y += _Time * _FlowTex_ST.w;
			fixed4 flowTex = tex2D(_FlowTex, flowUV);

			fixed4 detailNormal1 = tex2D(_DetailNormalMap1, IN.uv_DetailNormalMap1);
			fixed4 detailNormal2 = tex2D(_DetailNormalMap2, IN.uv_DetailNormalMap2);
		
			//装备染色
			fixed2 clothTintMask = saturate(fixed2(mask.g - 0.5, -mask.g + 0.5 ) * 2) ;
			fixed clothTintArea = clothTintMask.x + clothTintMask.y;
			//fixed3 clothTintLuminance = Luminance(baseColor.rgb * clothTintArea);//美术说要自已变灰，所以不用进行Luminance计算
			fixed3 clothTintArea1Color = baseColor * _ClothTint1.a * _ClothTint1 * 2 * clothTintMask.x;
			fixed3 clothTintArea2Color = baseColor * _ClothTint2.a * _ClothTint2 * 2 * clothTintMask.y;

			//Detail
			fixed2 detailAmountMask = saturate(fixed2(detailFlowMask.r - 0.5, -detailFlowMask.r + 0.5 ) * 2) ;
			fixed detailArea = detailAmountMask.x + detailAmountMask.y;
			fixed4 finalNormal = normal * (1 - detailArea) + (detailNormal1 * detailAmountMask.x + detailNormal2 * detailAmountMask.y);


			//Alpha
			clip(mask.r - _CutOut);

			o.Albedo = baseColor.rgb * (1 - clothTintArea) + clothTintArea1Color + clothTintArea2Color;
			o.Metallic = mss.r;
			o.Smoothness = mss.g;
			o.Emission = mask.b * _SelfIlluminateColor + detailFlowMask.g * flowTex * _FlowColor * _FlowColor.a;
			o.Normal = UnpackNormal(finalNormal);
		}
		ENDCG
	}
	FallBack "Diffuse"
}
