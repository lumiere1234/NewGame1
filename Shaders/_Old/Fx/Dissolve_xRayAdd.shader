// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'


Shader "Chp/Disslove/Disslove xRay Add"
{
	Properties
	{
        _MainTex ("主贴图", 2D) = "white" {}
		_DissolveTex ("溶解图", 2D) = "white" {}
		_Tint ("染色", Color) = (1,0.5,0,1)
		_Tint2 ("染色2", Color) = (0.8,0.8,1,1)
		_TintAmount("染色强度",Range(0,1)) = 1
		_Lighten("亮度",Float) = 2
		// _BurnSize("BurnSize", Range ( 0.0, 0.5 ) )	= 0.25
		 
		_Range("边缘范围",Range (0.001,3)) = 1
		_Mix("半透明 （x控制边缘， y 控制中间， z 整体）", Vector) = (1,0.5,1,0)
		_Dissolve("溶解",Range(0,1)) = 0
		//_Transparent("透明",Range(0,1)) = 0
    }

	CGINCLUDE

	#include "UnityCG.cginc"
	#pragma multi_compile FlowingLightOn FlowingLightOff

	sampler2D _MainTex,_DissolveTex;
	fixed4 _Tint;
	fixed4 _Tint2;
	fixed4 _MainTex_ST;
	float4 _DissolveTex_ST;
	fixed4 _FlowingColor;
	fixed _Lighten;
	half _Range;
	half _Dissolve;
	fixed _TintAmount;
	// fixed _BurnSize;
	half4 _Mix;

	//fixed _Transparent;

	struct appdata
	{
		float4 vertex : POSITION;
		float4 tangent : TANGENT;
		float3 normal : NORMAL;
		half4 texcoord : TEXCOORD0;
		
	};

    struct v2f
	{
		float4 pos	: SV_POSITION;
		half2 uv : TEXCOORD0;
		half2 uv2 : TEXCOORD1;
		
		half frenel : TEXCOORD3;
	};
        
    v2f vert (appdata v)
	{
		v2f o;
		o.pos = UnityObjectToClipPos (v.vertex);
		o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
		o.uv2 = TRANSFORM_TEX(v.texcoord, _DissolveTex);

		
		
		float3 normalDir = normalize( mul(float4(v.normal, 0.0), unity_WorldToObject).xyz );
		float3 viewDir =  normalize( float3(mul(unity_ObjectToWorld, v.vertex).xyz - _WorldSpaceCameraPos).xyz );
		o.frenel = saturate(  1 + dot( normalDir , viewDir)) ;
		//TANGENT_SPACE_ROTATION;
		//o.capCoord = half2(mul(rotation, UNITY_MATRIX_IT_MV[0].xyz).z, mul(rotation, UNITY_MATRIX_IT_MV[1].xyz).z) * 0.5 + 0.5;
		return o;
	}

    fixed4 frag (v2f i) : COLOR0 
	{
		float edge = pow(i.frenel, _Range);
		fixed3 color = tex2D(_MainTex,i.uv) ;
		float l = saturate( Luminance(color.rgb) + _Mix.w);
		half alpha =  (edge * _Mix.x + l * _Mix.y ) * _Mix.z;
		
		color *= _Tint2;
		color += _Tint * edge * _Lighten;

	
		half c =  tex2D(_DissolveTex,i.uv2).r +0.2;
		c = step(  _Dissolve*1.2 , c);
		alpha *= c;



		fixed4 output = fixed4(color , alpha);// _Transparent * Luminance(color.rgb));
		return output;

	}

	fixed4 fragZ (v2f Input) : COLOR0
	{
		return fixed4(0,0,0,1);
	}

	ENDCG

	SubShader
	{
		Tags { "Queue"="Transparent" "LightMode"="ForwardBase"  "IgnoreProjector"="True" }

		Pass
		{
			Cull Back
			Lighting Off
			ZWrite On
			Fog { Mode Off }
			Blend Zero One

			CGPROGRAM

			#pragma exclude_renderers d3d11 xbox360 flash
			#pragma vertex vert
			#pragma fragment fragZ
			#pragma fragmentoption ARB_precision_hint_fastest

			ENDCG
		}

		Pass
		{
			Cull Back
			Lighting Off
			ZWrite Off
			Fog { Mode Off }
			Blend SrcAlpha One

			CGPROGRAM

			#pragma exclude_renderers d3d11 xbox360 flash
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest

			ENDCG
		}
	}

	CustomEditor "WeaponMaterialInspector"
}

