// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "* Environment/Cubemap_Reflection" {

Properties {
	_MainTex ("Base (RGB) Trans (A)", 2D) = "black" {}
	
	_Cube ("Cube Map", Cube) = "" {}
	
	
	_reflectionColor ("Reflection Color", Color) = (0.5, 0.5, 0.5, 1)
	_MaskTex ("Mask (RGB)", 2D) = "white" {}
	[ShowWhenHasKeyword(Frenel_On)] _frenel("Frenel: x: power y: offset", Vector) = (1,0.1,0,0)

	
	
	[ShowWhenHasKeyword(NormalMap_On)] _BumpMap ("Normalmap", 2D) = "bump" {}
	// [ShowWhenHasKeyword(NormalMap_On)] _bumpRepeat( "repeat", float ) = 20


}
SubShader {
	Cull back Lighting Off ZWrite On 

	CGINCLUDE
		#include "UnityCG.cginc"
		sampler2D _MainTex;
		float4 _MainTex_ST;
		sampler2D _MaskTex;

		samplerCUBE _Cube;

		#ifdef NormalMap_On
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
		#endif

		fixed4 _reflectionColor;
		

		#ifdef Frenel_On
			half4 _frenel;
		#endif
		

		#ifdef LightMap_On
			// float4 unity_LightmapST;
			// sampler2D unity_Lightmap;
		#endif

		struct vertexInput {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 tangent : TANGENT;
			float2 texcoord : TEXCOORD0;
			#ifdef LightMap_On					
				float2 texcoord1 : TEXCOORD1;
			#endif

			
		};

		struct vertOutput {
			float4 vertex : SV_POSITION;
			float2 uv : TEXCOORD0;
			float3 normalDir : TEXCOORD1;

			#ifdef NormalMap_On
				float3	TtoW0 	: TEXCOORD3;
				float3	TtoW1	: TEXCOORD4;
				float3	TtoW2	: TEXCOORD5;				
				//float2	uv1	: TEXCOORD6;
			#else 
			
			#endif 
			float3 viewDir : TEXCOORD2;

			// #ifdef Frenel_On
			// 	half frenel : TEXCOORD7;
			// #endif
			
			#ifdef LightMap_On
				float2 lmap : TEXCOORD7;
			#endif
			UNITY_FOG_COORDS(6)
			

		};

		vertOutput vert (vertexInput v)
		{
			vertOutput o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
			
			float3 normalDir = normalize( mul(float4(v.normal, 0.0), unity_WorldToObject).xyz );
			float3 viewDir =  normalize( float3(mul(unity_ObjectToWorld, v.vertex).xyz - _WorldSpaceCameraPos).xyz );

			o.viewDir = viewDir;

			#ifdef NormalMap_On
				//o.uv1 = TRANSFORM_TEX(v.texcoord, _BumpMap);
				TANGENT_SPACE_ROTATION;
				o.TtoW0 = mul(rotation, unity_ObjectToWorld[0].xyz);
				o.TtoW1 = mul(rotation, unity_ObjectToWorld[1].xyz);
				o.TtoW2 = mul(rotation, unity_ObjectToWorld[2].xyz);
				
			#else
			#endif

			o.normalDir = normalDir;

			#ifdef Frenel_On
			// o.frenel = saturate(  1 + dot( normalDir , viewDir)) ;
			#endif

			#ifdef LightMap_On
			o.lmap = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
			#endif

			UNITY_TRANSFER_FOG(o,o.vertex);
			return o;
		}
		
		fixed4 frag (vertOutput i) : SV_Target
		{
			float3 col = tex2D(_MainTex, i.uv);
			float3 mask = tex2D(_MaskTex, i.uv);
			
			#ifdef NormalMap_On
				half3 worldNormal;
				fixed3 normal = UnpackNormal(tex2D(_BumpMap, i.uv));
				worldNormal.x = dot(i.TtoW0, normal);
				worldNormal.y = dot(i.TtoW1, normal);
				worldNormal.z = dot(i.TtoW2, normal);

				half3 reflectDir = reflect(i.viewDir, worldNormal);
			#else
				float3 reflectDir = normalize( reflect(i.viewDir, i.normalDir));
			#endif



			#ifdef LightMap_On
				fixed3 lm = DecodeLightmap (UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lmap));
				col *= lm ;
			#endif

			fixed3 reflection = texCUBE(_Cube, reflectDir) * _reflectionColor*2*mask;

			#ifdef Frenel_On
				half frenel = 1-dot( i.viewDir, -i.normalDir);
				frenel = clamp((frenel + _frenel.y) * _frenel.x, 0 ,100);
				reflection *= frenel;
			#endif
			UNITY_APPLY_FOG(i.fogCoord, col);
			return fixed4( reflection + col,1);
		}

	ENDCG


	Pass {  
		Tags { "Queue"="Geometry" "LightMode"="ForwardBase"  "IgnoreProjector"="True" "RenderType"="Opaque" }
		CGPROGRAM

			#pragma multi_compile LightMap_Off LightMap_On
			#pragma multi_compile NormalMap_Off NormalMap_On
			#pragma multi_compile Mask_On Mask_Off
			#pragma multi_compile Frenel_Off Frenel_On 

			#pragma multi_compile_fog

			#pragma target 2.0
			#pragma vertex vert
			#pragma fragment frag

		ENDCG
	}


}
CustomEditor "CubemapRefectionMaterialInspector"
}