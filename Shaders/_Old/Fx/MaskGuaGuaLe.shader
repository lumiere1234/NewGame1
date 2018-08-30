// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/GuaGuaLe/Mask_GuaGuaLe" {
Properties {
	_MainTex("Main_Texture", 2D) = "white" {}
	_UpperTex("Upper_Texture", 2D) = "black"{}
	_Blend_Texture("MaskTexture", 2D) = "white" {}
	
	
	
	_Lighten("Lighten", Float) = 1
}

SubShader {
	
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	Cull Off Lighting Off ZWrite Off Fog { Mode Off }
	
	Blend SrcAlpha OneMinusSrcAlpha
	
	LOD 100
	
	CGINCLUDE
	#pragma vertex vert
	#pragma fragment frag
	#include "UnityCG.cginc"
	
	sampler2D _MainTex;
	float4 _MainTex_ST;
	sampler2D _Blend_Texture;
	float4 _Blend_Texture_ST;
	sampler2D _UpperTex;
	float4 _UpperTex_ST;
	
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
		float2 uv_UpperTex : TEXCOORD2;
		float4 color : TEXCOORD3;
	};
	
	
	vertexOutput vert(vertexInput v){
		vertexOutput o;
		
		o.pos = UnityObjectToClipPos(v.vertex);
		
		
		o.uv_MainTex = TRANSFORM_TEX(v.texcoord.xy,_MainTex);
		o.uv_Blend_Texture = TRANSFORM_TEX(v.texcoord.xy,_Blend_Texture) ;
		o.uv_UpperTex = TRANSFORM_TEX(v.texcoord.xy,_UpperTex) ;
		
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
			
			fixed4 mainTex = tex2D(_MainTex,i.uv_MainTex)  ;
			fixed4 blendTex = tex2D(_Blend_Texture,i.uv_Blend_Texture) ;
			fixed4 upperTex = tex2D(_UpperTex,i.uv_UpperTex) ;
			fixed3 col = lerp(mainTex.rgb, upperTex.rgb, upperTex.a);
			color = fixed4( col   * _Lighten , blendTex.a *mainTex.a) * i.color ;
			return color; 
		}
		ENDCG
	}
}
	
	//Fallback "Specular"
}