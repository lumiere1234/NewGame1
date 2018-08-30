// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "* FX/XRay Particle"
{
	Properties
	{
        [NoScaleOffset]_MainTex ("主贴图", 2D) = "white" {}
		_Color("染色",Color) = (1,1,1,1)
		_Lighten("亮度",Float) = 2
		_Range("边缘范围",Range (0.001,3)) = 1
		_Mix("半透明 （x控制边缘， y 控制中间， z 整体）", Vector) = (1,0.25,1,0)
    }

	CGINCLUDE

	#include "UnityCG.cginc"

	sampler2D _MainTex;
	fixed4 _MainTex_ST,_Color;
	fixed _Lighten;
	half _Range;
	half4 _Mix;


    struct v2f
	{
		float4 pos	: SV_POSITION;
		half2 uv : TEXCOORD0;		
		half frenel : TEXCOORD3;
		float4 color : COLOR;
	};
        
    v2f vert (appdata_full v)
	{
		v2f o;
		o.pos = UnityObjectToClipPos (v.vertex);
		o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
		float3 normalDir = normalize( mul(float4(v.normal, 0.0), unity_WorldToObject).xyz );
		float3 viewDir =  normalize( float3(mul(unity_ObjectToWorld, v.vertex).xyz - _WorldSpaceCameraPos).xyz );
		o.frenel = saturate(1 + dot( normalDir , viewDir)) ;
		o.color = v.color;
		return o;
	}

    fixed4 frag (v2f i) : COLOR0 
	{
		float edge = pow(i.frenel, _Range) * _Lighten;
		float4 color = tex2D(_MainTex,i.uv) * _Color + edge;
		color.rgb *= i.color.rgb;
		float l = saturate( Luminance(color.rgb) + _Mix.w);
		half alpha =  (edge * _Mix.x + l * _Mix.y ) * _Mix.z * i.color.a;
			
		return fixed4(color.rgb, alpha);;
	}

	ENDCG

	SubShader
	{
		Tags { "Queue"="Transparent" "LightMode"="ForwardBase"  "IgnoreProjector"="True" }

		Pass
		{
			Cull Back
			Lighting Off
			ZWrite Off
			//ZTest Off
			//Fog { Mode Off }
			Blend SrcAlpha DstAlpha
			//Blend SrcAlpha DstColor

			CGPROGRAM

			#pragma exclude_renderers d3d11 xbox360 flash
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest

			ENDCG
		}
	}
}

