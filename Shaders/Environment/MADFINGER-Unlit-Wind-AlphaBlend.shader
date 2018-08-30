// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "* Environment/Wind AlphaBlend" {
Properties {
	_MainTex ("Base (RGB)", 2D) = "white" {}
	//_LightmapBrightness ("光照图暗部限制", Range(0,1) ) = 0.2

	[ShowWhenHasKeyword(ZL_VERTEX_ANIMATION_ON)]_TranslationDistance("移动距离",Vector) = (0,1,0,0)
	[ShowWhenHasKeyword(ZL_VERTEX_ANIMATION_ON)]_TranslationOffset("偏移距离",Vector) = (0,0,0,0)
	[ShowWhenHasKeyword(ZL_VERTEX_ANIMATION_ON)]_TranslationSpeed("移动速度",Float) = 10
	[ShowWhenHasKeyword(ZL_VERTEX_ANIMATION_ON)]_TurbulentSpeed("扰动速度",Vector) = (0.5,0.5,0.5,0)
	[ShowWhenHasKeyword(ZL_VERTEX_ANIMATION_ON)]_TurbulentRange( "扰动幅度", Vector) = (0.2,0.2,0.2,0)
}

SubShader {
	Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "LightMode"="ForwardBase"}
	LOD 100
	
	Cull Off ZWrite Off
	Blend SrcAlpha OneMinusSrcAlpha
	
	
	CGINCLUDE
	#include "UnityCG.cginc"
	#include "TerrainEngine.cginc"
	#include "../CGIncludes/ZL_CGInclude.cginc"
	sampler2D _MainTex;
	float4 _MainTex_ST;
	samplerCUBE _ReflTex;
	float4 unity_Lightmap_ST;
	//float _LightmapBrightness;

	float4 _direction;
	float _fDetailAmp;
	//float _Cutoff;
	
	float _WindEdgeFlutter;
	float _WindEdgeFlutterFreqScale;



	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float2 lightmapUV : TEXCOORD1;
		fixed3 spec : TEXCOORD2;
		UNITY_FOG_COORDS(3)
	};



inline float4 AnimateVertex2(float4 pos, float3 normal, float4 animParams,float4 wind,float2 time, float fDetailAmp, float3 direction)
{	
	// animParams stored in color
	// animParams.x = branch phase 			
	// animParams.y = edge flutter factor	
	// animParams.z = primary factor		
	// animParams.w = secondary factor		

	float fBranchAmp = 0.3f;

	float fObjPhase = dot(unity_ObjectToWorld[3].xyz, 1);

	float fBranchPhase = fObjPhase + animParams.x;
	
	float fVtxPhase = dot(pos.xyz * _direction, animParams.y + fBranchPhase);

	float2 vWavesIn = time  + float2(fVtxPhase, fBranchPhase );
	// 1.975, 0.793, 0.375, 0.193 are good frequencies
	float4 vWaves = (frac( vWavesIn.xxyy * float4(1.975, 0.793, 0.375, 0.193) ) * 2.0 - 1.0);

	
	vWaves = SmoothTriangleWave( vWaves );
	float2 vWavesSum = vWaves.xz + vWaves.yw;

	float3 bend = animParams.y * fDetailAmp * normalize(normal.xyz);
	bend.y = animParams.w * fBranchAmp;
	pos.xyz += ((vWavesSum.xyx * bend) + (wind.xyz * vWavesSum.y * animParams.w)) * wind.w; 

	pos.xyz += animParams.z * wind.xyz;

	return pos;
}



	ENDCG


	Pass {
		CGPROGRAM
		#pragma debug
		#pragma vertex vert
		#pragma fragment frag
		#pragma fragmentoption ARB_precision_hint_fastest		
		#pragma multi_compile_fog
		#pragma multi_compile ZL_VERTEX_ANIMATION_OFF ZL_VERTEX_ANIMATION_ON

		v2f vert (appdata_full v)
		{
			v2f o;
		
			#ifdef ZL_VERTEX_ANIMATION_ON
				float4 mdlPos = AnimateVertexInWorldSpace(v.vertex, v.color,  _TranslationSpeed,  _TranslationDistance,  _TranslationOffset,  _TurbulentSpeed,  _TurbulentRange);
				o.pos = mul(UNITY_MATRIX_VP, mdlPos );
			#else 
				o.pos = UnityObjectToClipPos(v.vertex);
			#endif 

			o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
			//o.lightmapUV = TRANSFORM_TEX(v.texcoord1,unity_Lightmap);
			o.lightmapUV = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;

			o.spec = v.color;
		
			UNITY_TRANSFER_FOG(o, o.pos);
			return o;
		}

		half4 frag (v2f i) : COLOR
		{
			half4 col = tex2D (_MainTex, i.uv);
			half3 lightmapColor = DecodeLightmapRGBM(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lightmapUV.xy));
			col.rgb *= lightmapColor;
			//col.rgb *= lerp(lightmapColor, 1,  _LightmapBrightness);

			UNITY_APPLY_FOG(i.fogCoord, col);
			return col;
		}

		ENDCG 
	}	

}
CustomEditor "EnvirmentWindMaterialInspector"
}


     