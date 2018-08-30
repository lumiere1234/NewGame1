// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Equip (third quarters) Tint" {
	Properties {
        _MainTex ("Base (RGB)", 2D) = "white" {}

 		_Tint ("装备换色 ", Color) = (1,1,1,0.5)

		_RimLightTex ("RimLight外部贴图 (RGB)", 2D) = "white" {}
		_ReflectTex ("反射贴图 (RGB)", 2D) = "white" {}


		_colDiffuse ("Diffuse Color", Color) = (1,1,1,1)
		_colAmbient2 ("Ambient2 Color", Color) = (0,0,0,0)
		_fDiffusePower ("Diffuse Power", float) = 0.5
		_Power("高光power", float) = 50.0
		_SpecularMultiple("高光增强倍数", float) = 1.0
		_colMtlSpecular("高光颜色", Color) = (1,1,1,1)
		_RimColor("Rim Light外部颜色", Color) = (0,0.5,0.5,1)
		_RimSpecular("Rim Light高光倍增", float ) = 0.35
		_RimDiffuse("Rim Light漫反射倍增", float ) = 1.5
		_Roughness("镜面光滑度", float ) = 1.0
		_colAniso("镜面光颜色", Color) = (1,1,1,1)
		_AnisoMultiple("镜面光增强倍数", float ) = 2.0
		_SelfIlluminateColor("自发光颜色", Color) = (0,0,0,0)
		_SelfIlluminated("自发光倍增", float ) = 1.0
		_colDiffuseFactor("diffuse系数", Color) = (1,1,1,1)
   }

	CGINCLUDE
	#include "UnityCG.cginc"
	#include "Lighting.cginc"

	//#pragma multi_compile NORMAL_ENABLE

	//common begin
	float3 glb_SamplerNormalMap(sampler2D NormalSampler, float2 TexCoord, float smoothNess=1.0f)
	{
		float3 Normal;
		Normal = 2 * tex2D(NormalSampler, TexCoord).xyz - 1;
		//Normal.z = sqrt(saturate(1 - Normal.x * Normal.x - Normal.y * Normal.y));
		Normal.z *= smoothNess;
		return normalize(Normal);	//	If consider mipmaps, normal should be normalized
	}

	float3 glb_CalcReflection(float3 N, float3 L)
	{
		return 2.0f * dot(N, L) * N  - L;
	}

	//common end

	sampler2D	_MainTex;

	fixed4 _Tint;

	sampler2D	_RimLightTex;
	sampler2D	_ReflectTex;

	float4 _colDiffuse;
	float4 _colAmbient2;
	float  _fDiffusePower;
	float  _Power;
	float  _SpecularMultiple;
	float4 _colMtlSpecular;
	float4 _RimColor;
	float  _RimSpecular;
	float  _RimDiffuse;
	float  _Roughness;
	float4 _colAniso;
	float  _AnisoMultiple;
	float4 _SelfIlluminateColor;
	float  _SelfIlluminated;
	float4 _colDiffuseFactor;



    struct appdata {
        float4 vertex	: POSITION;
		float3 normal	: NORMAL;
		float2 uv		: TEXCOORD0;
		//float2 lmuv		: TEXCOORD1;
    };

    struct v2f {
        float4 pos : SV_POSITION;
		float2 uvBase           : TEXCOORD0;
		float3 normal			: TEXCOORD1;	//object space
		float3 ViewDir          : TEXCOORD2;	//object space
		float3 LightDir         : TEXCOORD3;	//object space
		//float2 lmuv		    	: TEXCOORD4;
    };
        
    v2f vert (appdata v) {
        v2f o;
        o.pos = UnityObjectToClipPos( v.vertex );

        fixed3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
        //fixed3 vLightDir = normalize(ObjSpaceLightDir(v.vertex));
		fixed3 vLightDir = normalize(ObjSpaceLightDir(v.vertex) + viewDir *1.2);
              
        //float3 binormal = cross( normalize(v.normal), normalize(v.tangent.xyz) )*v.tangent.w;
       	//float3x3 rotation = float3x3( v.tangent.xyz, -binormal, v.normal );
       	//o.ViewDir  = mul(rotation, viewDir);
     	//o.LightDir = mul(rotation, vLightDir);

		o.ViewDir = viewDir;
		o.LightDir = vLightDir;
	//	o.LightDir = vLightDir + float3(0,0,1);
		o.normal = normalize(v.normal);

		o.uvBase = v.uv;
		//o.lmuv = v.lmuv;
        return o;
    }
        
    fixed4 frag (v2f Input) : COLOR0 
	{ 
		float3 Normal = 0.0;
		float3 NormalDetail = 0.0;
		float3 colDiffuse = 0.0;
		float3 colAmbient = 0.0;
		float3 colSpecular = 0.0;
		float3 colAniso = 0;

		float3 colDiffusePoint = 0.0;
		float3 colSpecularPoint = 0.0;

		float4 RimLight = 0.0;
		float4 InnerLight = 0.0;

		float2 luv = float2( Input.uvBase.x , Input.uvBase.y);
		float2 ruv = float2( Input.uvBase.x * 0.5 +0.5 , Input.uvBase.y*0.5 );


		float3 colSunDiffuse = _colDiffuse.rgb * _fDiffusePower;

		Normal = normalize(Input.normal);

		//Normal *= vFaceDir;
		float3 LightDir	= normalize(Input.LightDir ) ;
		float3 ViewDir  = normalize(Input.ViewDir);
		float3 LightReflection = glb_CalcReflection(Normal, LightDir);
		float3 ViewReflection = glb_CalcReflection(Normal, ViewDir);

		//Sample Tex
		//float4 colBaseTex  = tex2Dbias(_MainTex, float4(luv, 0.0f, -2.0f));
		float4 colBaseTex  = tex2D(_MainTex,luv);

		#pragma multi_compile	_ALPHATEST_
		#ifdef _ALPHATEST_
			clip(colBaseTex.a - 0.5f);
		#endif

		#ifdef UNLIT_ENABLE
			return colBaseTex;
		#endif

		//#ifdef LIGHT_MAP_ENABLE
		//	float4 colLightMap = tex2D(_LightmapTex, Input.lmuv);
		//	colLightMap.rgb *= _MaxLight;
		//	return colBaseTex * colLightMap;
		//#endif

		float4 colSpecularTex = tex2D(_MainTex, ruv);//R:power  G: gloss B: Reflect
		colBaseTex = lerp( colBaseTex, colBaseTex * (_Tint.a * 2) * fixed4(_Tint.rgb,1), colSpecularTex.r);

		float fNDotL = dot(Normal, LightDir);
		float fA1 = saturate(-fNDotL);
		float fA2 = saturate(1 - abs(fNDotL));
		//float fRDotV = fNDotL > 0.0f ? saturate(dot(LightReflection, ViewDir)) : 0.0f;
		float fNdotV = saturate(dot(Normal,ViewDir));
	
		float fVRDotL = saturate(dot(ViewReflection, LightDir));
		float fVRDotV = saturate(dot(ViewReflection, ViewDir));

		//DirLight BRDF	
		#if defined	(HALF_LAMBERT_ENABLE)
			fNDotL = fNDotL*0.5f+0.5f;
		#endif

		fNDotL = saturate(fNDotL);
		colDiffuse = colSunDiffuse * fNDotL;

		//Ambient
		colAmbient = (UNITY_LIGHTMODEL_AMBIENT.rgb * fA1) + (_colAmbient2.rgb * fA2*1.3);

		//Specular
		float fSpecPower = 0;
		float3 vSpecColor = 0;	
    
			fSpecPower = _Power;
			vSpecColor = _SpecularMultiple * _colMtlSpecular.rgb * colSpecularTex.g;

	

	
			colSpecular = vSpecColor * pow(fVRDotL+0.001, fSpecPower);    



		//#ifdef RIMLIGHT_MAP_ENABLE
			RimLight.rgb = tex2D(_RimLightTex, float2(fNdotV, 0.0)).rgb * _RimColor.rgb;
			colSpecular += RimLight.rgb * _RimSpecular;
			colDiffuse += RimLight.rgb * _RimDiffuse;
		//#endif
    
		//Combine Shader
		float3 ResultColor = (colDiffuse.rgb + colAmbient.rgb) * colBaseTex.rgb;

		//#ifdef REFLECT_ENABLE 
			float2 vReflectUV = float2(ViewReflection.x, ViewReflection.z) * _Roughness + 0.5f;
			//float4 colReflectTex = tex2Dbias(_ReflectTex, float4(vReflectUV, 0, 0));
			float4 colReflectTex = tex2D(_ReflectTex, vReflectUV);
			float fRef = colSpecularTex.b;

			float3 colReflect = _colAniso.rgb * colReflectTex.rgb;
			//return float4(fNDotL, fVRDotV, 0, 1);
			colReflect *= _AnisoMultiple * fRef;
			//ResultColor *= 1.0 - fRef;
			colSpecular += colReflect;
		//#endif

		ResultColor += colSpecular;

		//#ifdef SELF_ILLUMINATED_ENABLE
			ResultColor += _SelfIlluminateColor.rgb * _SelfIlluminated;
		//#endif

		float4 OutputColor = float4(ResultColor, colBaseTex.a) * _colDiffuseFactor;
		return OutputColor;

	}

	ENDCG

SubShader {
	Tags { "Queue"="Geometry+1" "LightMode"="ForwardBase"  "IgnoreProjector"="True" "RenderType"="Opaque" }	
	LOD  200

    Pass {
		Cull Back
		Lighting Off
		Fog { Mode Off }
		
        CGPROGRAM

		#pragma exclude_renderers d3d11 xbox360
        #pragma vertex vert
        #pragma fragment frag
		#pragma fragmentoption ARB_precision_hint_fastest 


        ENDCG
    }
}
}

