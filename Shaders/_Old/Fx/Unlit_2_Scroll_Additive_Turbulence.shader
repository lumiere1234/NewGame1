// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Chp/Scroll/Unlit Addtive 2 Scroll Turbulence " {
Properties {
	_MainTex("Main_Texture", 2D) = "white" {}
	_Color01("Main_Texture_Color", Color) = (0.5,0.5,0.5,1)
	_Blend_Texture("Blend_Texture", 2D) = "black" {}
	_Color02("Blend_Texture_Color", Color) = (0.5,0.5,0.5,1)
	_Blend_Texture01("Blend_Texture01", 2D) = "black" {}
	_Color03("Blend_Texture_Color", Color) = (0.5,0.5,0.5,1)
	_Speeds("TextureSpeeds", Vector) = (4,1,-2,0.6)
	
	_Lighten("Lighten", Float) = 1
}

SubShader {
	
	Tags { "Queue"="Geometry" "IgnoreProjector"="True" "RenderType"="Opaque" }
	Cull Off Lighting Off ZWrite On Fog { Mode Off }
		
	
	LOD 100
	
	CGINCLUDE
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
	float4 _Color03;
	float4 _Speeds;
	
	float _Lighten;
	
	struct vertexInput{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 texcoord : TEXCOORD0;
		float4 color : COLOR;
	};
	
	struct vertexOutput{
		float4 pos : SV_POSITION;
		
		float2 uv_MainTex :TEXCOORD0;
		float2 uv_Blend_Texture :TEXCOORD1;
		float2 uv_Blend_Texture01 :TEXCOORD2;
		float4 color : TEXCOORD3;
	};
	
	
	vertexOutput vert(vertexInput v){
		vertexOutput o;
		
		o.pos = UnityObjectToClipPos(v.vertex);
		
		float4 speeds = _Speeds * _Time.x;
		o.uv_MainTex = TRANSFORM_TEX(v.texcoord.xy,_MainTex);
		o.uv_Blend_Texture = TRANSFORM_TEX(v.texcoord.xy,_Blend_Texture) + frac(float2(speeds.x, speeds.y) );
		o.uv_Blend_Texture01 = TRANSFORM_TEX(v.texcoord.xy,_Blend_Texture01) + frac(float2(speeds.z, speeds.w) );
		
		o.color = v.color;
		
		return o;
	}
	ENDCG
	
		
	pass{
		CGPROGRAM
		//fragment function
		fixed4 frag(vertexOutput i) : COLOR
		{
			fixed4 color;
			
			fixed3 mainTex = tex2D(_MainTex,i.uv_MainTex)  * _Color01 *2;
			fixed3 blendTex = tex2D(_Blend_Texture,i.uv_Blend_Texture) * _Color02*2;
			fixed3 blendTex1 = tex2D(_Blend_Texture01,i.uv_Blend_Texture01)* _Color03*2;
			
			return fixed4( mainTex + (blendTex * blendTex1),1)*i.color * _Lighten;
			
			return color; 
		}
		ENDCG
	}
}
	
	//Fallback "Specular"
}