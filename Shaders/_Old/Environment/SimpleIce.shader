// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "FX/SimpleIce" {

Properties {
	_MainTex ("Base (RGB) Trans (A)", 2D) = "black" {}
	_MainColor ("Main Color", Color) = (0.5,0.5,0.5,1)
	_Cube ("Cube Map", Cube) = "" {}

	_Reflection ("reflection", Color) = (0.5, 0.5, 0.5, 1)
	_Refraction ("refraction", Color) = (0.5, 0.5, 0.5, 1)
	
	_frenel("Frenel Mulit: x   offset: y   overall: z", Vector) = (2,1.5,0.2,0)

	
	
	_BumpMap ("Normalmap", 2D) = "bump" {}
	_BumpAmount ("BumpAmount", Range (0.01,2)) = 1

}
SubShader {
	Tags { "Queue"="Geometry" "LightMode"="ForwardBase"  "IgnoreProjector"="True" "RenderType"="Opaque" }

	CGINCLUDE
		#include "UnityCG.cginc"
		sampler2D _MainTex;
		float4 _MainTex_ST;
		float4 _MainColor;
		sampler2D _MaskTex;

		samplerCUBE _Cube;
		float4 _Reflection;
		float4 _Refraction;

		
		sampler2D _BumpMap;
		float4 _BumpMap_ST;

		half _BumpAmount;
		half4 _frenel;

		struct vertexInput {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 tangent : TANGENT;
			float2 texcoord : TEXCOORD0;
							
			
			
		};

		struct vertOutput {
			float4 vertex : SV_POSITION;
			float2 uv : TEXCOORD0;
			float2 uv1 : Texcoord1;
			float3 normalDir : TEXCOORD2;
			float3 viewDir : TEXCOORD3;
			
			half nDotV : TEXCOORD4;
		};

		vertOutput vert (vertexInput v)
		{
			vertOutput o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
			o.uv1 = TRANSFORM_TEX(v.texcoord, _BumpMap);

			float3 normalDir = normalize( mul(float4(v.normal, 0.0), unity_WorldToObject).xyz );
			float3 viewDir =  normalize( float3(mul(unity_ObjectToWorld, v.vertex).xyz - _WorldSpaceCameraPos).xyz );

			o.viewDir = viewDir;
			o.normalDir = normalDir;

			o.nDotV = dot( normalDir , viewDir) ;
			return o;
		}

		fixed4 frag (vertOutput i) : SV_Target
		{

			float3 col = tex2D(_MainTex, i.uv);
			fixed3 offset = tex2D( _BumpMap, i.uv1 ) - fixed3(0.5,0.5,1);
			fixed3 normalDir = i.normalDir + offset * _BumpAmount;
			fixed3 refractDir =  normalize( refract(i.viewDir, normalDir, 0.65));
			fixed3 refraction = texCUBE(_Cube, refractDir ) * _Refraction;
			
			fixed3 reflectDir = normalize( reflect(i.viewDir, normalDir));
			fixed3 reflection = texCUBE(_Cube, reflectDir) * 2 * _Reflection;
			
			
			fixed frenel = saturate( -i.nDotV );
			frenel  = frenel* _frenel.x + _frenel.y;
			
			col =  (col.rrr * frenel  + reflection * col ) * _frenel.z;
			return fixed4(col * _MainColor + refraction,1);
		}
		

	ENDCG



	Pass {  
		
		Cull back

		CGPROGRAM

			#pragma target 2.0
			#pragma vertex vert
			#pragma fragment frag

		ENDCG
	}

}

}