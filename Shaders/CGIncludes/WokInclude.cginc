
#ifndef WOK_CG_INCLUDED
#define WOK_CG_INCLUDED

#include "UnityCG.cginc"

float wokLightMapMultiply;
float wokLightMapContrast;
float4 wokAltitudeFogParams;
float4 wokAltitudeFogColor;

inline half3 WokLightmap (float2 uv)
{

	half4 lightmap = UNITY_SAMPLE_TEX2D (unity_Lightmap, uv);
	return DecodeLightmap(lightmap);//æ≈÷›¡Ÿ ±”√

	half d = saturate(  (lightmap.a - 0.22) * (wokLightMapContrast +1) + 0.22);
// #if defined(SHADER_API_GLES) || defined(SHADER_API_GLES3) || defined(SHADER_API_METAL)
	half3 lm  = 4 * wokLightMapMultiply * d *  lightmap.rgb ;
// #else
// 	half3 lm  = 4 * wokLightMapMultiply * d *  lightmap.rgb ;
// #endif
	


	// #if DIRLIGHTMAP_COMBINED
	// fixed4 bakedColorTexB = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap,  uv);
	// half3 bakedColorB = 4 * bakedColorTexB.a *  bakedColorTexB.rgb ;

	//lm = lerp( bakedColorB, lm, unity_FogColor.w);
	//#endif

	return  lm;
}


// inline float wokPow(float x, float n){
// 	// Sherical Gaussian approximation: pow(x,n) ~= exp((n+0.775)*(x-1))
// 	return exp((n+0.775) * (x-1));
// }

	#define WOK_FOG_COORDS(idx) UNITY_FOG_COORDS_PACKED(idx, float4)

	float4 WOK_TRANSFER_ALTITUDE_FOG(float z, float3 worldPos, float4 fogParams)
	{

		#if WOK_ALTITUDE_FOG_ON

		float3 camPos = _WorldSpaceCameraPos;
		
		float f = sign(fogParams.w);
		float3 _v = worldPos - camPos;

		float p = worldPos.y - fogParams.x;
		float c = camPos.y - fogParams.x;
		float k = 1- step( 0, (f * c));
		float fDotV =  f * _v.y ;
		float fDotP =  f * p;
		float fDotC =  f * c;
		
		float c1 = k * (fDotP + fDotC);
		float c2 = (1 - 2* k) * fDotP;
		return  float4(z, c1, c2, fDotV);
		#else
			return  float4(z, 0, 0 , 0);
		#endif 
	}



	float3 WOK_APPLY_FOG_COLOR( float3 col, float3 worldPos, float4 fogCoord, float4 fogParams)
	{
		#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
			UNITY_CALC_FOG_FACTOR(fogCoord.x);
			col.rgb = lerp((unity_FogColor).rgb, (col).rgb, saturate( unityFogFactor) );
		#endif

		#if WOK_ALTITUDE_FOG_ON 
			
			worldPos.y -= fogParams.x;

			float c1 = fogCoord.y;
			float c2 = fogCoord.z;
			float fDotV = fogCoord.w;

			float g = min( c2, 0);
			g = (fogParams.z * 0.5 * fogCoord.x) * (( c1 - g * g /abs(fDotV)));

			float f = saturate ( exp2(g) );
			col.rgb = lerp((wokAltitudeFogColor).rgb, (col).rgb,  f );
			return col;
		#else
			return col;
		#endif
	}

	float WOK_FOG_PRECENT( float3 col, float3 worldPos, float4 fogCoord, float4 fogParams)
	{
		float result = 1;
		#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
			UNITY_CALC_FOG_FACTOR(fogCoord.x);
			result = saturate( unityFogFactor);
		#endif

		#if WOK_ALTITUDE_FOG_ON 
			
			worldPos.y -= fogParams.x;

			float c1 = fogCoord.y;
			float c2 = fogCoord.z;
			float fDotV = fogCoord.w;

			float g = min( c2, 0);
			g = (fogParams.z * 0.5 * fogCoord.x) * (( c1 - g * g /abs(fDotV)));

			float f = saturate ( exp2(g) );
			result *= f;
		#endif

		return result;
	}


	float WOK_CALC_FOG_FACTOR(  float3 worldPos, float4 fogCoord, float4 fogParams)
	{
		#if WOK_ALTITUDE_FOG_ON 
		// half space fog
		worldPos.y -= fogParams.x;

		float c1 = fogCoord.y;
		float c2 = fogCoord.z;
		float fDotV = fogCoord.w;

		float g = min( c2, 0);
		g = (fogParams.z * 0.5 * fogCoord.x) * (( c1 - g * g /abs(fDotV)));

		return saturate( exp2(g) );
	#else 
		return 1;
	#endif
	}

#endif
