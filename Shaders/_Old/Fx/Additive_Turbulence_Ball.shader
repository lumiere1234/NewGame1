// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Chp/FX/Additive Turbulence Ball " {
Properties {
	_MainTex("Main_Texture", 2D) = "white" {}
	_Color01("Main_Texture_Color", Color) = (1,1,1,1)
	_Blend_Texture("Blend_Texture", 2D) = "white" {}
	_Color02("Blend_Texture_Color", Color) = (1,1,1,1)
	_Blend_Texture01("Blend_Texture01", 2D) = "white" {}

	_Speeds("TextureSpeeds", Vector) = (10,-20,0,0)
	
	_Lighten("Lighten", Float) = 5
	_MMultiplier ("Edge Range ", float) = 0.3
}

	
SubShader {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	
	Blend SrcAlpha One
	Cull Back Lighting Off ZWrite Off Fog { Mode Off }
	LOD 100
	
	
	
	CGINCLUDE
// Upgrade NOTE: excluded shader from DX11 and Xbox360; has structs without semantics (struct v2f members posWorld,normalDir)
#pragma exclude_renderers d3d11 xbox360
	#pragma vertex vert
	#pragma fragment frag
	#include "UnityCG.cginc"
	
	sampler2D _MainTex;
	float4 _MainTex_ST;
	sampler2D _Blend_Texture;
	float4 _Blend_Texture_ST;
	sampler2D _Blend_Texture01;
	float4 _Blend_Texture01_ST;
	
	float4 _Color01;
	float4 _Color02;

	float4 _Speeds;
	float _MMultiplier;
	float _Lighten;
	

	struct v2f {
		float4 vertex : SV_POSITION;
		
		float2 uv_MainTex :TEXCOORD0;
		
		//float4 posWorld :TEXCOORD1;
		//float3 normalDir :TEXCOORD2;
		
		float2 uv_Blend_Texture :TEXCOORD1;
		float2 uv_Blend_Texture01 :TEXCOORD2;
		float4 color : TEXCOORD3;
	};

	struct vertexIn{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 texcoord : TEXCOORD0;
		float4 color : COLOR;
	};
	
	v2f vert (vertexIn v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		//o.posWorld = mul(_Object2World, v.vertex);
		
	//	o.normalDir = normalize( mul( float4(v.normal, 0.0), _World2Object ).xyz );
		
		float3 speeds = _Speeds * _Time.xxx;
		o.uv_MainTex = TRANSFORM_TEX(v.texcoord.xy,_MainTex) + frac(float2(0, speeds.x) );
		o.uv_Blend_Texture = TRANSFORM_TEX(v.texcoord.xy,_Blend_Texture) + frac(float2(0, speeds.y) );
		o.uv_Blend_Texture01 = TRANSFORM_TEX(v.texcoord.xy,_Blend_Texture01) + frac(float2(0, speeds.z) );
		
		float3 normalDirection = normalize( mul( float4( v.normal, 0.0 ), unity_WorldToObject ).xyz );
		float3 viewDirection = normalize( _WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex) );
		
		
		float rim = pow( saturate(dot(viewDirection, normalDirection)), clamp(  _MMultiplier, 0.01, 5 ));
		
		
		o.color = fixed4(v.color.rgb, v.color.a * rim);
				
		
		return o;
	}
	ENDCG


	Pass {
		CGPROGRAM
		
//		#pragma fragmentoption ARB_precision_hint_fastest		
		fixed4 frag (v2f i) : COLOR
		{
			
			float4 mainTex = tex2D(_MainTex,i.uv_MainTex);
			float4 blendTex = tex2D(_Blend_Texture,i.uv_Blend_Texture);
			float4 blendTex1 = tex2D(_Blend_Texture01,i.uv_Blend_Texture01);
			
			float rim = 1-pow( i.color.a, _MMultiplier);
			
			
			float4  color;
			color = (mainTex * _Color01 + blendTex * _Color02) * mainTex * blendTex * _Lighten * blendTex1 * rim ;
						
			return color;
		}
		ENDCG 
	}	
}

}
