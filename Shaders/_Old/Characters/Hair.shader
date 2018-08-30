// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Hair" {
	Properties {
        _MainTex ("Base (RGB)", 2D) = "white" {}
		_AlphaTex("Alpha (A8)", 2D) = "white" {}
		_HairLUTSampler("HairLUT (RGB)", 2D) = "white" {}

		//_LightmapTex ("光照图 (RGB)", 2D) = "white" {}
 		//_MaxLight ("lightmap mul", float) = 1

		_colDiffuse ("Diffuse Color", Color) = (1,1,1,1)
		_SpecularMultiple("高光增强倍数", float) = 1.0
		//_colMtlSpecular("高光颜色", Color) = (1,1,1,1)
		_SelfIlluminateColor("自发光颜色", Color) = (0,0,0,0)
		_SelfIlluminated("自发光倍增", float) = 1.0
		_colDiffuseFactor("diffuse系数", Color) = (1,1,1,1)
		_colBaseTex("Base贴图系数",Color) = (0.392, 0.165, 0.188,1)
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

	float3 _ShfitTangent(float3 T, float3 N, float shift)
	{
		float3 vNewT = T + N * shift;
		return vNewT;
	}

	float _StrandSpecularTex(sampler2D LUTSampler,float3 T,float3 H, float3 V, float3 L, float fExp)
	{
		float  fDotTH = dot(T, H)*0.5+0.5;
		float2 LUTTexCoord = float2(fDotTH,fExp);
		float  fLUT = tex2D(LUTSampler, LUTTexCoord).x;
		return fLUT;
	}


	//common end

	sampler2D	_MainTex;
	sampler2D	_AlphaTex;
	sampler2D	_HairLUTSampler;

	//sampler2D	_LightmapTex;
	//float  _MaxLight;

	float4 _colDiffuse;
	float  _SpecularMultiple;
	//float4 _colMtlSpecular;
	float4 _SelfIlluminateColor;
	float  _SelfIlluminated;
	float4 _colDiffuseFactor;
	float4 _colBaseTex;



    struct appdata {
        float4 vertex	: POSITION;
		float3 normal	: NORMAL;
		float4 tangent	: TANGENT;
		float2 uv		: TEXCOORD0;
    };

    struct v2f {
        float4 pos : SV_POSITION;
		float2 uvBase           : TEXCOORD0;
		float3 normal			: TEXCOORD1;	//object space
		float3 ViewDir          : TEXCOORD2;	//object space
		float3 LightDir         : TEXCOORD3;	//object space
    };
        
    v2f vert (appdata v) {
        v2f o;
        o.pos = UnityObjectToClipPos( v.vertex );

        fixed3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
        fixed3 vLightDir = normalize(ObjSpaceLightDir(v.vertex));
              
        float3 binormal = cross( normalize(v.normal), normalize(v.tangent.xyz) )*v.tangent.w;
       	float3x3 rotation = float3x3( v.tangent.xyz, -binormal, v.normal );
       	
       	o.ViewDir  = mul(rotation, viewDir);
     	o.LightDir = mul(rotation, vLightDir);

		o.uvBase = v.uv;
        return o;
    }
        
    fixed4 frag (v2f Input) : COLOR0 
	{ 
		float4 HairShift = float4(0.0, 0.7, 0.4, 0.3);
		float3 colSpec1 = float3(0.576, 0.576, 0.576);
		float3 colSpec2 = float3(0.576, 0.576, 0.576);

		//Sample Tex
		float4 colBaseTex  = tex2D(_MainTex, Input.uvBase);
		float4 colBaseAlphaTex  = tex2D(_AlphaTex, Input.uvBase);
		colBaseAlphaTex.a = saturate(dot(colBaseAlphaTex, float4(1,0,0,0)));

		#pragma multi_compile	_ALPHATEST_
		//#ifdef _ALPHATEST_
			clip(colBaseAlphaTex.a - 0.5f);
		//#endif

		#ifdef UNLIT_ENABLE
			return colBaseTex;
		#endif

		float4 colSpecTex = float4(1,1,1,0);//R:power  G: gloss B: Reflect

		float4 colTex;
		colTex.rgb = colBaseTex.rgb * _colBaseTex.rgb;
		colTex.a = 1;

		float3 CusColor;
		CusColor.r = saturate(dot(colTex, float4(1,0,0,0)));
		CusColor.g = saturate(dot(colTex, float4(0,1,0,0)));
		CusColor.b = saturate(dot(colTex, float4(0,0,1,0)));

		float3 vLightDir = normalize(Input.LightDir);
		float3 vViewDir = normalize(Input.ViewDir);

		float3 vNormal = float3(0.0, 0.0, 1.0);
		float3 vTangent = float3(0.0, 1.0, 0.0);

		
		float fNDotL = dot(vNormal, vLightDir);
		//float fA1 = saturate(-fNDotL);
		//float fA2 = 1 - abs(fNDotL);
		//float fRDotV = fNDotL > 0.0f ? saturate(dot(LightReflection, ViewDir)) : 0.0f;

		//DirLight BRDF	
		#if defined	(HALF_LAMBERT_ENABLE)
			fNDotL = fNDotL*0.5f+0.5f;
		#endif
		fNDotL = saturate(fNDotL);

		float3 colDiffuse = saturate(lerp(0.25f, 1.0f,fNDotL)) * _colDiffuse.xyz;
		float3 colAmbient = UNITY_LIGHTMODEL_AMBIENT.rgb*2;

		// Diffuse
		float3 vDiffuse = colAmbient + colDiffuse;// + colPtDiffuse;

		// Specular
		float fBaseShift = colSpecTex.b - 0.5f;
		float3 t1 = _ShfitTangent(vTangent, vNormal, fBaseShift + HairShift.x);
		float3 t2 = _ShfitTangent(vTangent, vNormal, fBaseShift + HairShift.y);
		float3 H = normalize(vLightDir + vViewDir);

		float3 colSpecular1 = colSpec1 * _StrandSpecularTex(_HairLUTSampler,t1,H, vViewDir, vLightDir, HairShift.z);
		float3 colSpecular2 = colSpec2 * _StrandSpecularTex(_HairLUTSampler,t2,H, vViewDir, vLightDir, HairShift.w);

		float specularAttenuation = saturate(1.75 * dot(vNormal,vLightDir) + 0.25);
		float3 vSpec = (colSpecular1 + colSpecular2 * colSpecTex.g) * colSpecTex.r * _colDiffuse.rgb * specularAttenuation;// + colSpecular3 * colSpecTex.r * g_colDiffuse.rgb * 0.5;

		float3 ResultColor = vDiffuse * CusColor.xyz + vSpec * colBaseTex.xyz * _SpecularMultiple;
		ResultColor += _SelfIlluminateColor.rgb * _SelfIlluminated;


		float4 OutputColor = float4(ResultColor, colBaseAlphaTex.a) * _colDiffuseFactor;
		return OutputColor;

	}

	ENDCG

SubShader {
	Tags {"Queue"="Transparent-2" "LightMode"="ForwardBase"  "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
	LOD 200

    Pass {
		//Blend SrcAlpha OneMinusSrcAlpha
		AlphaTest Greater 0.5
		Fog { Mode Off }
		Cull Back
		Lighting Off

        CGPROGRAM

		#pragma exclude_renderers d3d11 xbox360
        #pragma vertex vert
        #pragma fragment frag
		#pragma fragmentoption ARB_precision_hint_fastest 


        ENDCG
    }
}
}

