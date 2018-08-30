// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "* Billboard/Billboard_SpaceDistortion_AlphaBlend" {
Properties {
        _TintColor ("Tint Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB) Gloss (A)", 2D) = "black" {}
        _BumpMap ("Normalmap", 2D) = "bump" {}
		_ColorStrength ("Color Strength", Float) = 1
		_BumpAmt ("Distortion", Float) = 10

		_VerticalBillboarding("VerticalBillboarding", Range(0,1)) = 1
		_DistanceOffset("DistanceOffset", Float) = 1.0
		_Scale("Scale", Float) = 1.0
}

Category {

	Tags { "Queue"="Transparent"  "IgnoreProjector"="True"  "RenderType"="Transparent" }
	Blend SrcAlpha OneMinusSrcAlpha
	Cull Off 
	Lighting Off 
	ZWrite Off 
	Fog { Mode Off}

	CGINCLUDE
	#include "UnityCG.cginc"

	struct vin {
		float4 vertex : POSITION;
		float2 texcoord: TEXCOORD0;
		float2 texcoord1: TEXCOORD1;
		float4 color: Color;
	};

	struct v2f {
		float4 vertex : POSITION;
		float4 uvgrab : TEXCOORD0;
		float2 uvbump : TEXCOORD1;
		float2 uvmain : TEXCOORD2;
	};

	sampler2D _MainTex;
	sampler2D _BumpMap;

	float _BumpAmt;
	float _ColorStrength;
	sampler2D _GrabTextureMobile;
	float4 _GrabTextureMobile_TexelSize;
	fixed4 _TintColor;

	float4 _BumpMap_ST;
	float4 _MainTex_ST;

	fixed _VerticalBillboarding;
	fixed _DistanceOffset;
	float _Scale;

	void CalcOrthonormalBasis(float3 dir,out float3 right,out float3 up)
	{
		up = abs(dir.y) > 0.999f ? float3(0,0,1) : float3(0,1,0);		
		right = normalize(cross(up,dir));		
		up = cross(dir,right);	
	}

	void CalcBillboardVertxPos(float4 inColor, float2 inTexcoord1, float4 inVertex, out float3 BBLocalPos)
	{
		float3 centerOffs  = float3(float(0.5).xx - inColor.rg,0) * inTexcoord1.xyy;
		float3 centerLocal = inVertex.xyz + centerOffs.xyz;
		float3 viewerLocal = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));			
		float3 localDir = viewerLocal - centerLocal;
				
		localDir[1] = lerp(0,localDir[1],_VerticalBillboarding);
		
		float3 rightLocal;
		float3 upLocal;
		float3 localDirN = normalize(localDir);
		CalcOrthonormalBasis(localDirN ,rightLocal,upLocal);

		//float3 BBNormal = rightLocal * v.normal.x + upLocal * v.normal.y;
		BBLocalPos = centerLocal - (rightLocal * centerOffs.x + upLocal * centerOffs.y) *_Scale + localDirN * _DistanceOffset; 
	}

	v2f vert (vin v)
	{
		v2f o;

		float3 BBLocalPos;
		CalcBillboardVertxPos(v.color, v.texcoord1, v.vertex, BBLocalPos);
		o.vertex = UnityObjectToClipPos(float4(BBLocalPos,1));

		#if UNITY_UV_STARTS_AT_TOP
		float scale = -1.0;
		#else
		float scale = 1.0;
		#endif
		o.uvgrab.xy = (float2(o.vertex.x, o.vertex.y*scale) + o.vertex.w) * 0.5;
		o.uvgrab.zw = o.vertex.zw;
		o.uvbump = TRANSFORM_TEX( v.texcoord, _BumpMap );
		o.uvmain = TRANSFORM_TEX( v.texcoord, _MainTex );
	
		return o;
	}

	half4 frag( v2f i ) : COLOR
	{


		// calculate perturbed coordinates
		half2 bump = UnpackNormal(tex2D( _BumpMap, i.uvbump )).rg;
		float2 offset = bump * _BumpAmt * _GrabTextureMobile_TexelSize.xy;
		i.uvgrab.xy = offset * i.uvgrab.z + i.uvgrab.xy;
	
		half4 col = tex2Dproj( _GrabTextureMobile, UNITY_PROJ_COORD(i.uvgrab));
		//half4 tint = tex2D( _MainTex, i.uvmain );
		//return col * tint;
		fixed4 tex = tex2D(_MainTex, i.uvmain);
		fixed4 emission = col + tex * _ColorStrength * _TintColor;
	    emission.a = _TintColor.a * tex.a;
		return emission;
	}

	v2f vert100 (vin v)
	{
		v2f o;
		UNITY_INITIALIZE_OUTPUT(v2f,o);
		float3 BBLocalPos;
		CalcBillboardVertxPos(v.color, v.texcoord1, v.vertex, BBLocalPos);
		o.vertex = UnityObjectToClipPos(float4(BBLocalPos,1));
		o.uvmain = TRANSFORM_TEX( v.texcoord, _MainTex );
	
		return o;
	}

	half4 frag100( v2f i ) : COLOR
	{
		fixed4 tex = tex2D(_MainTex, i.uvmain);
		fixed4 emission = tex * _ColorStrength * _TintColor;
	    emission.a = _TintColor.a * tex.a;
		return emission;
	}
	
	ENDCG

	SubShader {
		LOD 998

		GrabPass { "_GrabTextureMobile" }
 		
		Pass {
			Name "BASE"
			//Tags { "LightMode" = "Always" }
			
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma exclude_renderers flash
		ENDCG

		}
	}

	SubShader {
		LOD 100
		Blend SrcAlpha One
		Pass {
			Name "BASE"

		CGPROGRAM
			#pragma vertex vert100
			#pragma fragment frag100
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma exclude_renderers flash
		ENDCG
		}
	}


}

}

