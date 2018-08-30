// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "* Water/WaterFull Cloud alphaBlend Scroll Fresnel(流水)" {
Properties {
	_MainTex ("Base layer (RGB)", 2D) = "white" {}
	_MaskTex( "mask (RGB)", 2D) = "white" {}
	_ScrollX ("Base layer Scroll speed X", Float) = 1.0
	_ScrollY ("Base layer Scroll speed Y", Float) = 0.0
	
	_AMultiplier ("Layer Multiplier", Float) = 2
	_Color("Color(Used Alpha)", Color) = (1,1,1,1)
	_RimCol("Rim Color", Color) = (1,1,1,1)
	_FresnelPower("Fresnel Power",Range(0,5))=0.5
}


SubShader {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	
	Blend SrcAlpha OneMinusSrcAlpha
	Cull Back 
	//Lighting Off ZWrite Off Fog { Mode Off }
	//LOD 100
	
		
	CGINCLUDE
	#include "UnityCG.cginc"
	#include "../CGIncludes/ZL_CGInclude.cginc"

	sampler2D _MainTex;
	float4 _MainTex_ST;
	
	sampler2D _MaskTex;
	float4 _MaskTex_ST;
	
	float _ScrollX;
	float _ScrollY;

	float _AMultiplier;
	float4 _Color;
	fixed3 _RimCol;
	float _FresnelPower;
	
	struct v2f {
		float4 pos : SV_POSITION;
		float4 uv : TEXCOORD0;
		float2 uv1 : TEXCOORD1;
		fixed4 color : TEXCOORD2;	
		fixed vdotn : TEXCOORD3; 	
		UNITY_FOG_COORDS(7)
	};
	
	v2f vert (appdata_full v)
	{
		v2f o;
		UNITY_INITIALIZE_OUTPUT(v2f,o);

		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv.xy = TRANSFORM_TEX(v.texcoord.xy,_MainTex) + frac(float2(_ScrollX, _ScrollY) * float2(_Time.y, _Time.y));
		#if ZL_LIGHTMAP_ON
			o.uv.zw = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		#endif

		o.uv1 = TRANSFORM_TEX(v.texcoord.xy,_MaskTex);
		
		o.color = v.color;
		o.vdotn=clamp(dot(v.normal,normalize(ObjSpaceViewDir( v.vertex))),0,0.99999);
		
		UNITY_TRANSFER_FOG(o,o.pos);
		return o;
	}
	ENDCG


	Pass {
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile ZL_LIGHTMAP_OFF ZL_LIGHTMAP_ON
		#pragma fragmentoption ARB_precision_hint_fastest		
		#pragma multi_compile_fog

		fixed4 frag (v2f i) : COLOR
		{
			fixed4 o;
			fixed4 tex = tex2D (_MainTex, i.uv);
			fixed4 mask = tex2D (_MaskTex, i.uv1);
			float3 rimCol = _RimCol * 2 * pow(1 - i.vdotn, _FresnelPower);
			half3 waterColor = _AMultiplier * _Color.rgb;
			o.rgb = tex.rgb * mask.rgb * waterColor + rimCol;
			#if ZL_LIGHTMAP_ON
				o.rgb *= saturate(DecodeLightmapRGBM(UNITY_SAMPLE_TEX2D(unity_Lightmap,i.uv.zw)));
			#endif
			o.a = i.color.a * _Color.a;

			UNITY_APPLY_FOG(i.fogCoord, o);
			return o;
		}
		ENDCG 
	}	
}
}
     