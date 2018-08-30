#ifndef ZL_CG_INCLUDE
#define ZL_CG_INCLUDE

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "TerrainEngine.cginc"


//带UV2的tangent结构体
struct appdata_tan_uv2 {
	float4 vertex : POSITION;
	float4 tangent : TANGENT;
	float3 normal : NORMAL;
	float4 texcoord : TEXCOORD0;
	float4 texcoord1 : TEXCOORD1;
};

//用于光照计算的结构
struct LightingVectors {
	float3 viewDir;
	float3 lightDir;
	float3 vertexNormal;
	float3 worldNormal;
	float3 normalMap;
	float2 lightmapUV;
	float3 specularParameters;//x:glossiness  y:specularLevel  z:specularControlTexture
	float shadow;
};

//w为worldSpaceNormal.x，用来算SH9和反射
#define TANGENT_SPACE_VERCTORS(idx1,idx2,idx3) \
	float4 tangentSpaceLightDir	: TEXCOORD##idx1; \
	float4 tangentSpaceViewDir	: TEXCOORD##idx2; \
	float4 tangentSpaceVertexNormal	: TEXCOORD##idx3;


//Unity自带的TANGENT_SPACE_ROTATION不会去normalize向量，缩放物体时法线贴图显示会出问题，也不会创建LightDir和ViewDir，
#define TANGENT_SPACE_CALCULATE \
	v.normal  = normalize(v.normal); \
	v.tangent  = normalize(v.tangent); \
	float3 binormal = normalize(cross(v.normal.xyz, v.tangent.xyz) * v.tangent.w); \
	float3x3 rotation = float3x3( v.tangent.xyz, binormal, v.normal ); \
	float3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal)); \
	o.tangentSpaceLightDir = float4(normalize(mul(rotation, ObjSpaceLightDir(v.vertex))), worldNormal.x);  \
	o.tangentSpaceViewDir = float4(normalize(mul(rotation, ObjSpaceViewDir(v.vertex))), worldNormal.y);  \
	o.tangentSpaceVertexNormal = float4(normalize(mul(rotation, v.normal)).xyz, worldNormal.z);


//世界距阵定义
#define WORLD_MATRIX(idx1,idx2,idx3) \
float4 worldMatrixRow0 : TEXCOORD##idx1; \
float4 worldMatrixRow1 : TEXCOORD##idx2; \
float4 worldMatrixRow2 : TEXCOORD##idx3;


//存worldPos是因为以后计算高度雾或者一些特殊效果有用。
#define CALCULATE_WORLD_MATRIX \
	float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz; \
	fixed3 worldNormal = UnityObjectToWorldNormal(v.normal); \
	fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz); \
	fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w; \
	fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign; \
	o.worldMatrixRow0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x); \
	o.worldMatrixRow1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y); \
	o.worldMatrixRow2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);


float ZL_LightMapContrast;
float ZL_LightMapMultiply;
//RGBM的解码Lightmap的方式，效果和原始的Lightmap一样
inline half3 DecodeLightmapRGBM (half4 lightmap)
{
	half d = saturate(  (lightmap.a - 0.22) * (ZL_LightMapContrast +1) + 0.22);
	half3 lm  = 5 * ZL_LightMapMultiply * d *  lightmap.rgb ;

	//half d = saturate(  (lightmap.a - 0.22) * (0 + 1) + 0.22);//wokLightMapContrast为0
	//half3 lm  = 5 * 1 * d *  lightmap.rgb;//wokLightMapMultiply为1
	return  lm;
}


//自已UmpackNormal，算法和UnpackNormal的DXT5nm方式一样，好处是可以使用NormalMap的B通道来控制高光，坏处是像素感明显
inline float3 UnpackNormalMap(fixed4 normalmapColor)
{
	float3 normal;
	normal.xy = normalmapColor.rg * 2 - 1;
	normal.z = sqrt(1 - saturate(dot(normal.xy, normal.xy)));
	return normal;
}


//计算NormalMap光照，并且返回normal
inline half CalculateNormalmap(float4 worldMatrixRow0,float4 worldMatrixRow1,float4 worldMatrixRow2, float4 normalmapColor, out fixed3 normal)
{
	normal = UnpackNormalMap(normalmapColor);
	//地形的Addpass用
	//normal = normalmapColor.rgb;

	fixed3 worldN;
	worldN.x = dot(worldMatrixRow0.xyz, normal);
	worldN.y = dot(worldMatrixRow1.xyz, normal);
	worldN.z = dot(worldMatrixRow2.xyz, normal);
	normal = worldN;
	half diff = saturate(dot(normalize(normal), _WorldSpaceLightPos0.xyz));
	return diff;
}


//传统的BulinnPhong高光：specularParameters  x:glossiness  y:specularLevel  z:specularControlTexture
inline float CalculateSpecular(float3 normal,float3 viewDir, float3 lightDir, float3 specularParameters)
{
	float3 halfVector = viewDir + lightDir;
	fixed nh = max (0.001, dot(normalize(normal), normalize(halfVector)));
	float spec = pow (nh, specularParameters.x) * specularParameters.y * specularParameters.z;
	return spec;
}

//传入参数，算出普通Lambert光照，方便修改
//gspecularParameters参数为：  x:glossiness  y:specularLevel  z:specularControlTexture
inline half3 SceneLighting(float3 mapNormal,float3 vertexNormal, float3 worldNormal,float2 lightmapUV, float3 lightDir, float3 viewDir, float3 specularParameters, float shadow)
{
	half3 finalLight = 1;
	half3 ambientLighting = ShadeSH9(float4(normalize(worldNormal),1));
	half lambertLight = saturate(dot(normalize(mapNormal), normalize(lightDir)));

	#if ZL_LIGHTMAP_ON
		//finalLight *= DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap,lightmapUV));
		half3 lightmapColor = DecodeLightmapRGBM(UNITY_SAMPLE_TEX2D(unity_Lightmap,lightmapUV));
		finalLight *= lightmapColor;
	#else
		finalLight *= lerp(ambientLighting, _LightColor0.rgb, lambertLight);
	#endif

	#if ZL_NORMALMAP_ON
		//这种方法用在室内场景感觉并不是很好，先用回旧方法
		//#if ZL_LIGHTMAP_ON
		//	float f = dot( lightmapColor, half3(0.2,0.7,0.1) ) - _DarknessThreshold;
		//	finalLight *= lerp(1 ,_RealtimeLightMulti * diff , f);
		//#else
		//	finalLight *= diff;
		//#endif
		#if ZL_LIGHTMAP_ON
			half normalmapLighting = lambertLight;//直接使用finalLight来做计算不行
			float darknessClamp = 1 - saturate(dot(normalize(vertexNormal), normalize(lightDir)));
			normalmapLighting += darknessClamp;//去除无法线贴图影响的实时光照暗部，否则lightmap的暗部太黑
			finalLight *= normalmapLighting;
		#endif
	#endif


	#if ZL_SPECULAR_ON
		float3 specValue = CalculateSpecular(mapNormal,viewDir,lightDir,specularParameters) * _LightColor0.rgb;

		#if ZL_LIGHTMAP_ON
		specValue *= lightmapColor;
		#endif

		finalLight += specValue;
	#endif

	finalLight = lerp(ambientLighting * finalLight, finalLight, shadow);

	return finalLight;
}

//树叶、草顶点动画
float4 _TranslationDistance;//移动距离
float4 _TranslationOffset;//起始偏移距离
float _TranslationSpeed;//移动速度
float4 _TurbulentSpeed;//扰动速度
float4 _TurbulentRange;//扰动幅度
inline float4 AnimateVertexInWorldSpace(float4 vertex, float4 vertexColor, float _TranslationSpeed, float4 _TranslationDistance, float4 _TranslationOffset, float4 _TurbulentSpeed, float4 _TurbulentRange)
{
	//乱流
	float4 vWavesIn = _Time.y * _TurbulentSpeed;
	// 1.975, 0.793, 0.375, 0.193 are good frequencies
	float4 vWaves = (frac( vWavesIn * float4(1.975, 0.793, 0.375, 0.193) ) * 2.0 - 1.0);
	vWaves = SmoothTriangleWave( vWaves ) * vertexColor * _TurbulentRange;

	//移动速度0到1
	float translationLerp = sin(_Time * _TranslationSpeed) * 0.5 + 0.5;
	//距离
	float4 newTranslation = vertexColor * lerp(-_TranslationDistance + vWaves, _TranslationDistance + vWaves, translationLerp);
	//偏移
	_TranslationOffset *= vertexColor;

	//在世界空间操作，避免Batch后自身坐标位置就没了
	float4x4 translationMatrix = 
	{
		float4(1,0,0,newTranslation.x + _TranslationOffset.x),
		float4(0,1,0,newTranslation.y + _TranslationOffset.y),
		float4(0,0,1,newTranslation.z + _TranslationOffset.z),
		float4(0,0,0,1),
	};
	float4 mdlPos = mul(unity_ObjectToWorld, vertex);
	mdlPos = mul(translationMatrix, mdlPos);
	return mdlPos;
}


//
inline fixed3 Remap(fixed3 origionColor,fixed start,fixed end)
{
	fixed3 col = origionColor;
	col.r = lerp(start,end,origionColor.r);
	col.g = lerp(start,end,origionColor.g);
	col.b = lerp(start,end,origionColor.b);
	return col;
}



#endif