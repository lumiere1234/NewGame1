// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// - Unlit
// - Per-vertex (virtual) camera space specular light
// - SUPPORTS lightmap

Shader "MADFINGER/Environment/Wind Opaque" {
Properties {
	_MainTex ("Base (RGB)", 2D) = "white" {}
	_Wind("Wind params",Vector) = (1,1,1,1)
	_WindEdgeFlutter("Wind edge fultter factor", float) = 0.5
	_WindEdgeFlutterFreqScale("Wind edge fultter freq scale",float) = 0.5
	_fDetailAmp ("DetailAmp", float ) = 0.1
	_direction( "Direction Multi", Vector) = (1,1,1)
}

SubShader {
	Tags {"Queue"="Geometry" "RenderType"="Opaque" "LightMode"="ForwardBase"}
	LOD 100
	
	Cull Off ZWrite On
	
	
	CGINCLUDE
	#include "UnityCG.cginc"
	#include "TerrainEngine.cginc"
	sampler2D _MainTex;
	float4 _MainTex_ST;
	samplerCUBE _ReflTex;
	
	float3 _direction;
	float _fDetailAmp;
	
	float _WindEdgeFlutter;
	float _WindEdgeFlutterFreqScale;

	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;

		fixed3 spec : TEXCOORD2;
	};

inline float4 AnimateVertex2(float4 pos, float3 normal, float4 animParams,float4 wind,float2 time, float fDetailAmp, float3 direction)
{	
	// animParams stored in color
	// animParams.x = branch phase 			
	// animParams.y = edge flutter factor	
	// animParams.z = primary factor		
	// animParams.w = secondary factor		

	// float fDetailAmp = 0.1f;
	float fBranchAmp = 0.3f;
	
	// Phases (object, vertex, branch)
	float fObjPhase = dot(unity_ObjectToWorld[3].xyz, 1);
	float fBranchPhase = fObjPhase + animParams.x;
	
	float fVtxPhase = dot(pos.xyz * _direction, animParams.y + fBranchPhase);
	
	// x is used for edges; y is used for branches
	float2 vWavesIn = time  + float2(fVtxPhase, fBranchPhase );
	
	// 1.975, 0.793, 0.375, 0.193 are good frequencies
	float4 vWaves = (frac( vWavesIn.xxyy * float4(1.975, 0.793, 0.375, 0.193) ) * 2.0 - 1.0);
	
	vWaves = SmoothTriangleWave( vWaves );
	float2 vWavesSum = vWaves.xz + vWaves.yw;

	// Edge (xz) and branch bending (y)
	float3 bend = animParams.y * fDetailAmp * normal.xyz;
	bend.y = animParams.w * fBranchAmp;
	pos.xyz += ((vWavesSum.xyx * bend) + (wind.xyz * vWavesSum.y * animParams.w)) * wind.w; 

	// Primary bending
	// Displace position
	pos.xyz += animParams.z * wind.xyz;
	
	return pos;
}


	
	v2f vert (appdata_full v)
	{
		v2f o;
		
		float4	wind;
		
		float			bendingFact	= v.color.a;
		
		wind.xyz	= mul((float3x3)unity_WorldToObject,_Wind.xyz);
		wind.w		= _Wind.w  * bendingFact;
		
		
		float4	windParams	= float4(0,_WindEdgeFlutter,bendingFact.xx);
		float 		windTime 		= _Time.y * float2(_WindEdgeFlutterFreqScale,1);

		float4	mdlPos	= AnimateVertex2(v.vertex,v.normal,windParams,wind,windTime , _fDetailAmp, _direction);
		
		o.pos = UnityObjectToClipPos(mdlPos);
		o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
		
		o.spec = v.color;
		

		
		return o;
	}
	ENDCG


	Pass {
		CGPROGRAM
		#pragma debug
		#pragma vertex vert
		#pragma fragment frag
		#pragma fragmentoption ARB_precision_hint_fastest		
		fixed4 frag (v2f i) : COLOR
		{
			fixed3 tex = tex2D (_MainTex, i.uv);
			
			fixed4 c;
			c = fixed4( tex, 1);

			
			return c;
		}
		ENDCG 
	}	
}
}

