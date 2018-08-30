// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "* Water/ClearWater CB(清水)" { 
Properties {
	// Textures
	_envCube( "env Map", Cube) = "white" {}
	//_ReflectionTex ("Internal reflection", 2D) = "white" {}
	_DepthMap("Depth Map", 2D) = "white"{}

	_BumpMap ("Normals ", 2D) = "bump" {}
	
	//Surface normal params
	_DistortParams ("Distortions (Bump waves, Reflection, Fresnel power, Fresnel bias)", Vector) = (1.75 ,0.5, 2.6, -0.2)
	_BumpTiling ("Bump Tiling", Vector) = (48, 48, 4, 4 )
	_BumpDirection ("Bump Direction & Speed", Vector) = (0.2, 1, 1, -0.4)
	_Speed ("Speed", Range (-1, 1)) = -0.05
	_FresnelScale ("FresnelScale", Range (0.15, 4.0)) = 0.4	

	//For high quality water
	_InvRange("inverse Alpha, Depth, and Ccolor ", Vector) = (3, 1.2, 1.5 ,0.05)

	_SandColor ("Sand color HQ", COLOR)  = ( 0.816, 0.756, 0.5,0.5)	
	_BaseColor ("Base color HQ", COLOR)  = ( 0.067, 0.149,0.184, 0.5)	
	_ShallowColor ("Shallow Color", Color ) = (0.149, 0.855, 0.678, 0.5)
	_ReflectionColor ("Reflection color HQ", COLOR)  = (0.898, 0.533, 0.259, 0.5)	
	_SpecularColor ("Specular color HQ", COLOR)  = ( 0.823, 0.533, 0.259, 1)
	
	// //For high mid and low water
	// _BaseColorMQ ("Base color MQ", COLOR)  = ( .54, .95, .99, 0.5)	
	// _ReflectionColorMQ ("Reflection color MQ", COLOR)  = ( .54, .95, .99, 0.5)	
	// _SpecularColorMQ ("Specular color MQ", COLOR)  = ( .72, .72, .72, 1)

	//Specular params
	// _WorldLightDir ("Specular light direction", Vector) = (0.0, 0.1, -0.5, 0.0)
	_Shininess ("Shininess", Range (2.0, 500.0)) = 360.0	
	_Far ("Falloff", Range (0, 20)) = 2
} 


CGINCLUDE
	
	#include "UnityCG.cginc"
	#include "../CGIncludes/ZL_CGInclude.cginc"

	struct appdata 
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 texcoord : TEXCOORD0;
	};

	struct v2f
	{
		float4 pos : SV_POSITION;
		float4 uv : TEXCOORD0;
		float4 bumpCoords : TEXCOORD1;

		float3 worldNormal : TEXCOORD2;
		float3 viewInterpolator : TEXCOORD3; 	
		float3 worldLightDir : TEXCOORD4;	
		float4 uvgrab : TEXCOORD5;
		UNITY_FOG_COORDS(6)
	};
		
	struct v2f_simple
	{
		float4 pos : SV_POSITION;
		float3 viewInterpolator : TEXCOORD0; 	
		float4 bumpCoords : TEXCOORD1;
	};	

	// textures
	sampler2D _DepthMap;
	sampler2D _BumpMap;
	sampler2D _ReflectionTex;

	uniform float4 _DistortParams;
	uniform float _FresnelScale;	
	uniform float4 _BumpTiling;
	uniform float4 _BumpDirection;
	float _Speed;

	sampler2D _GrabBlurTexture;
	float4 _GrabBlurTexture_TexelSize;

	uniform float4 _SpecularColor;
	uniform float4 _BaseColor;
	float4 _SandColor;
	float4 _ShallowColor;
	uniform float4 _ReflectionColor;

	samplerCUBE _envCube;
	half4 _InvRange;

	// uniform float4 _BaseColorMQ ;
	// uniform float4 _ReflectionColorMQ;
	// uniform float4 _SpecularColorMQ ;

	uniform float _Shininess;
	float _Far;

	// shortcuts
	#define PER_PIXEL_DISPLACE _DistortParams.x
	#define REALTIME_DISTORTION _DistortParams.y
	#define FRESNEL_POWER _DistortParams.z
	#define FRESNEL_BIAS _DistortParams.w
	

	inline float3 PerPixelNormal(sampler2D bumpMap, float4 coords, float3 vertexNormal, float bumpStrength) 
	{
		float4 bump = tex2D(bumpMap, coords.xy) + tex2D(bumpMap, coords.zw);
	#if defined(UNITY_NO_DXT5nm)
		bump.xy = bump.xy - float2(1.0, 1.0);
	#else
		bump.xy = bump.wy - float2(1.0, 1.0);
	#endif
		float3 worldNormal = vertexNormal + bump.xxy * bumpStrength * float3(1,0,1);
		return normalize(worldNormal);
	} 

	inline float Fresnel(float3 viewVector, float3 worldNormal, float bias, float power)
	{
		float facing =  clamp(1.0-max(dot(-viewVector, worldNormal), 0.0), 0.0,1.0);	
		float refl2Refr = saturate(bias+(1.0-bias) * pow(facing,power));	
		return refl2Refr;	
	}
	inline float3 glb_CalcReflection(float3 N, float3 L)
	{
		return 2.0f * dot(N, L) * N  - L;
	}
	//
	// HQ VERSION
	//
	v2f vert500(appdata_full v)
	{
		v2f o;
		UNITY_INITIALIZE_OUTPUT(v2f,o);
		
		float3 worldSpaceVertex = mul(unity_ObjectToWorld,(v.vertex)).xyz;
				
		float4 tileOffset = frac( _Speed * _Time.xxxx * _BumpDirection.xyzw *_BumpTiling.xyzw);    
			
		o.bumpCoords.xyzw = v.texcoord.xyxy * -_BumpTiling.xyzw + tileOffset.xyzw ;

		o.viewInterpolator.xyz = worldSpaceVertex - _WorldSpaceCameraPos;

		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv.xy = v.texcoord.xy;
		#if ZL_LIGHTMAP_ON
			o.uv.zw = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		#endif

		o.worldNormal =  (mul(unity_ObjectToWorld, half4(v.normal,0) ));

		o.worldLightDir =  normalize(WorldSpaceLightDir(v.vertex));
		#if UNITY_UV_STARTS_AT_TOP
		float scale = -1.0;
		#else
		float scale = 1.0;
		#endif
		o.uvgrab.xy = (float2(o.pos.x, o.pos.y*scale) + o.pos.w) * 0.5;
		o.uvgrab.zw = o.pos.zw;
		UNITY_TRANSFER_FOG(o,o.pos);
		return o;
	}

	half4 frag500( v2f i ) : SV_Target
	{		
		// return half4( i.worldLightDir.xyz, 1);
		float3 worldNormal = PerPixelNormal(_BumpMap, i.bumpCoords, i.worldNormal, PER_PIXEL_DISPLACE);
		float3 viewVector = normalize(i.viewInterpolator.xyz);
		// return half4( worldNormal, 1);
		// return half4(viewVector.rgb,1);
	

		float4 distortOffset = float4(worldNormal.xz * REALTIME_DISTORTION , 0, 0);
		fixed4 depth = tex2D(_DepthMap, i.uv.xy + distortOffset );
		
		i.uvgrab.xy += distortOffset.xy * _GrabBlurTexture_TexelSize.xy * min( i.uvgrab.z, _Far) * 100 ;
		half4 grabed = tex2Dproj (_GrabBlurTexture, UNITY_PROJ_COORD(i.uvgrab));
		// return half4( grabed.rgb *0.9, 1);

		float3 reflectVector = normalize(reflect(viewVector, worldNormal));          
		float4 rtReflections  = texCUBE( _envCube, reflectVector );

		float3 h = normalize ( -i.worldLightDir.xyz + viewVector.xyz);
		// return half4(h, 1);
		float nh = max (0, dot (worldNormal, -h));
		float spec = max(0.0, pow (nh, _Shininess));	
		// return half4(i.worldNormal,1);
		// return half4(spec.rrr, 1);
		worldNormal.xz *= _FresnelScale;		
		float refl2Refr = Fresnel(viewVector, worldNormal, FRESNEL_BIAS, FRESNEL_POWER);


		half3 ranges = saturate( _InvRange.xyz * (depth.g - _InvRange.w) );
		
		half4 baseColor = lerp(fixed4(_BaseColor.rgb,1),fixed4(grabed.rgb,1),_BaseColor.a);

		// baseColor.rgb = lerp( _ShallowColor.rgb, baseColor.rgb,  ranges.y);
		// baseColor.rgb = lerp( _SandColor.rgb, baseColor.rgb,  ranges.z );
		
		// return half4( ranges.yyy,1);
		//baseColor.rgb = grabed.rgb;
		
		baseColor = lerp (baseColor, lerp (rtReflections , _ReflectionColor,_ReflectionColor.a), saturate(refl2Refr));
		baseColor = baseColor + spec * _SpecularColor;
		baseColor.a =  ranges.x;

		#if ZL_LIGHTMAP_ON
			baseColor.rgb *= DecodeLightmapRGBM(UNITY_SAMPLE_TEX2D(unity_Lightmap,i.uv.zw));
		#endif

		UNITY_APPLY_FOG(i.fogCoord, baseColor);
		return baseColor;
	}	



ENDCG

Subshader 
{ 
	Tags { "Queue"="transparent-1" "IgnoreProjector"="True" "LightMode"="ForwardBase"   "RenderType"="Opaque" }
	// Tags {"Queue"="Transparent-20" "LightMode"="ForwardBase" "IgnoreProjector"="True" "RenderType"="Transparent"}
	 
	//Lod 500
	Cull Off Lighting Off ZWrite On 

	Pass {
		 	Tags { }
			ZTest LEqual
			Cull Off
			// blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			
			//#pragma target 2.0 
			
			#pragma vertex vert500
			#pragma fragment frag500
			#pragma multi_compile_fog
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile ZL_LIGHTMAP_OFF ZL_LIGHTMAP_ON
			#pragma multi_compile transparentCullout_Off transparentCullout_On	

			ENDCG
	}
}


}
     