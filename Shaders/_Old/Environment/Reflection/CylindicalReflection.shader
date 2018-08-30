// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: commented out 'float4 unity_LightmapST', a built-in variable
// Upgrade NOTE: commented out 'sampler2D unity_Lightmap', a built-in variable
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced tex2D unity_Lightmap with UNITY_SAMPLE_TEX2D

Shader "Environment/Cylindical_Reflection" {

Properties {
	_MainTex ("Base (RGB) Trans (A)", 2D) = "black" {}

	_mathTex("math texture", 2D) = "black"{}
	_uvClampThreshold( "EdgeRemove", Range(0,0.1)) = 0.02
	
	_CylindicalTex ("cylinder reflection (RGB) ", 2D) = "black" {}
	
	
	_reflectionColor ("Reflection Color", Color) = (0.5, 0.5, 0.5, 1)
	_MaskTex ("Mask (RGB)", 2D) = "white" {}
	[ShowWhenHasKeyword(Frenel_On)] _frenel("Frenel: x: power y: offset", Vector) = (1,0.1,0,0)

	[ShowWhenHasKeyword(Scroll_On)] _speed("Speed vector (xy)", Vector) = (0,0.1,0,0)

	
	
	[ShowWhenHasKeyword(DetailMap_On)] _detailTex( "Detail (RGB)", 2D ) = "white" {}
	
	[ShowWhenHasKeyword(DetailMap_On)] _detailAmount( "Detail Amount", Range(0.005, 0.5) ) = 0.04


}
SubShader {
	Cull back Lighting Off ZWrite On 
	CGINCLUDE
		#include "UnityCG.cginc"
	

		sampler2D _MainTex;
		float4 _MainTex_ST;
		sampler2D _MaskTex;

		sampler2D _CylindicalTex;

		#ifdef DetailMap_On
			sampler2D _detailTex;
			float4 _detailTex_ST;
			// half _detailRepeat;
			half _detailAmount;
		#endif

		
		
		
		float _uvClampThreshold;
		fixed4 _reflectionColor;
		
		sampler2D _mathTex;
		#ifdef Frenel_On
			half4 _frenel;
		#endif
		
		#ifdef Scroll_On
			float4 _speed;
		#endif

		#ifdef LightMap_On
			// float4 unity_LightmapST;
			// sampler2D unity_Lightmap;
		#endif

		struct vertexInput {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float2 texcoord : TEXCOORD0;
			#ifdef LightMap_On
				float2 texcoord1 : TEXCOORD1;
			#endif
		};

		struct vertOutput {
			float4 vertex : SV_POSITION;
			float2 uv : TEXCOORD0;

			float3 normalDir : TEXCOORD1;
			float3 viewDir : TEXCOORD2;


			#ifdef Frenel_On
				half frenel : TEXCOORD3;
			#endif
			
			#ifdef LightMap_On
				float2 lmap : TEXCOORD4;
			#endif

			#ifdef DetailMap_On
				float2 uv1 : TEXCOORD5;
			#endif
		};

		vertOutput vert (vertexInput v)
		{
			vertOutput o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
			#ifdef DetailMap_On
				o.uv1 = TRANSFORM_TEX(v.texcoord, _detailTex);
			#endif
			float3 normalDir = normalize( mul(float4(v.normal, 0.0), unity_WorldToObject).xyz );
			float3 viewDir =  normalize( float3(mul(unity_ObjectToWorld, v.vertex).xyz - _WorldSpaceCameraPos).xyz );

			o.normalDir = normalDir;
			o.viewDir = viewDir;

			#ifdef Frenel_On
			o.frenel = saturate(  1 + dot( normalDir , viewDir)) ;
			#endif

			#ifdef LightMap_On
			o.lmap = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
			#endif

			return o;
		}
		
		fixed4 frag (vertOutput i) : SV_Target
		{
			float3 col = tex2D(_MainTex, i.uv);
			float3 mask = tex2D(_MaskTex, i.uv);
			
			float3 reflectDir = normalize( reflect(i.viewDir, i.normalDir));

			float v = reflectDir.x;
			if ( reflectDir.z < 0)
				v = (abs(v) * (1-_uvClampThreshold) + _uvClampThreshold ) *sign(v) ;//* (1-);

			

			half3 r01 = fixed3(v, reflectDir.yz);
			r01 =  r01 *0.5 +0.5;
			float angleUV = tex2D( _mathTex, half2( r01.z, r01.x)).r;
			float upAngleUV = tex2D(_mathTex, half2(r01.y, 0.5)).g;
			// float upAngleUV = tex2D(_mathTex, half2(r01.z, r01.x)).b;

			//wired if don't tweak the value, the result is wrong in sm 2.0, 3.0 is ok
			half2 rUV = half2(angleUV*2, upAngleUV*2)/2;
			

			#ifdef DetailMap_On
				fixed2 mid = fixed2(0.5,0.5);
				fixed2 detail = tex2D(_detailTex, i.uv1).rg;
				rUV += (detail-mid) * _detailAmount;
			#endif

			#ifdef Scroll_On
				rUV += - _speed.xy * _Time.yy;
			#endif

			#ifdef LightMap_On
				fixed3 lm = DecodeLightmap (UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lmap));
				col *= lm;
			#endif

			fixed3 reflection = tex2D(_CylindicalTex, rUV) * _reflectionColor*2*mask;

			#ifdef Frenel_On
				half frenel = clamp((i.frenel + _frenel.y) * _frenel.x, 0 ,100);
				reflection *= frenel;
			#endif
			return fixed4( reflection + col,1);
		}

	ENDCG


	Pass {  
		Tags { "Queue"="Geometry" "LightMode"="ForwardBase"  "IgnoreProjector"="True" "RenderType"="Opaque" }
		CGPROGRAM

			#pragma multi_compile LightMap_Off LightMap_On
			#pragma multi_compile DetailMap_Off DetailMap_On
			#pragma multi_compile Scroll_Off Scroll_On
			#pragma multi_compile Frenel_Off Frenel_On 

			#pragma target 2.0
			#pragma vertex vert
			#pragma fragment frag

		ENDCG
	}


}
CustomEditor "ReflectionShaderMaterialInspector"
}