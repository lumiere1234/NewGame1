// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// ---------
// | B | A |
// ---------
// | R | G |
// ---------
Shader "Custom/Seven Equip OneMask..Host" {
	Properties
	{
		//MatCapSimple MatCapMultiEnvOneMask MatCapMultiEnvTwoMask
		_MainTex ("Base (RGB)", 2D) = "grey" {}
		_colDiffuse ("Diffuse Color", Color) = (1,1,1,1)
		_fDiffusePower ("Diffuse Power", float) = 1
		_MaskTex ("Mask (RGB)", 2D) = "grey" {}
		[ShowWhenHasKeyword(transparentCullout_On)]_AlphaRef ("AlphaTest Ref", Range(0,1)) = 0.5
		// [ShowWhenHasKeyword(TwoMask_On)]_MaskBMap ("MaskB (R:alpha G:empty B:tint)", 2D) = "white" {}
		
		_NoiseTex("NoiseTex", 2D) = "white" {}
		_NoiseThreshold("NoiseThreshold", float) = 0.75

		_RampMap("RampMap", 2D) = "grey" {}
		_LightTex("LightTex", 2D) = "white" {}

		_MMultiplier ("MMultiplier", float) = 5
		_SpecPower ("SpecPower", float) = 25
		_SpecMultiplier ("SpecMultiplier", float) = 1
		_NoiseColor("_NoiseColor", Color ) = (1,1,0,1)
		_SpecColor("SpecColor", Color ) = (1,1,1,1)
		_AmbientColor("AmbientColor", Color ) = (0,0.2,0.2,1)

		_RimColor("Rim Light外部颜色", Color) = (0,0,0,1)
		_RimDiffuse("Rim Light漫反射倍增", float ) = 1.5
		_Scroll2X ("Scroll2X", float) = 1
		_Scroll2Y ("Scroll2Y", float) = 1


		_Tint1 ("装备换色 ", Color) = (0.5,0.5,0.5,1)
		_Tint2 ("装备换色2 ", Color) = (0.5,0.5,0.5,1)
		_Tint3 ("头发换色", Color) = (0.5,0.5,0.5,1)

		_SelfIlluminateColor("自发光颜色", Color) = (0,0,0,0)
		_SelfIlluminated("自发光倍增", float ) = 1.0
	}
	
	CGINCLUDE
		#include "UnityCG.cginc"
		#include "AutoLight.cginc"

		sampler2D _MainTex;
		float4 _MainTex_ST;
		float4 _colDiffuse;
		float  _fDiffusePower;
		
		sampler2D _RampMap;
		sampler2D _MaskTex;
		// sampler2D _MaskBMap;

		float _AlphaRef;

		sampler2D _LightTex;

		
		sampler2D _NoiseTex;
		float4 _NoiseTex_ST;
		float _NoiseThreshold;

		float _MMultiplier;
		float _SpecPower;
		float _SpecMultiplier;


		fixed3 _AmbientColor;
		fixed3 _NoiseColor;
		half3 _SpecColor;

		float4 _RimColor;
		float  _RimDiffuse;

		half Scroll2X;
		half _Scroll2Y;


		fixed4 _Tint1;
		fixed4 _Tint2;
		fixed4 _Tint3;

		float4 _SelfIlluminateColor;
		float  _SelfIlluminated;


		struct appdata {
		    float4 vertex : POSITION;
		    fixed4 color : COLOR;
		    float3 normal : NORMAL;
		    float4 tangent : TANGENT;
		    float4 texcoord : TEXCOORD0;
		}
		;
		struct v2f
		{
			float4 pos	: SV_POSITION;
			float4 color : COLOR0;
			float4 uv : TEXCOORD0;
			half3 normal : TEXCOORD1;
			half3 ViewDir : TEXCOORD2;
			half3 LightDir : TEXCOORD3;
			half2 capCoord : TEXCOORD4;
			
		};

		struct appdata1 {
			float4 vertex	: POSITION;
			float2 uv		: TEXCOORD0;
		};

		struct v2f1 {
			float4 pos : SV_POSITION;
			float2 uvBase           : TEXCOORD0;
		};
		
		v2f vert (appdata v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos (v.vertex);
			o.color = v.color;
			o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);

			o.uv.zw =  TRANSFORM_TEX(v.texcoord,_NoiseTex) + frac( half2(_Scroll2Y, _Scroll2Y) * _Time.x);
			

			half3 normalInView = mul (UNITY_MATRIX_MV, fixed4(v.normal,0)).xyz;
			o.capCoord = half2((normalize(normalInView).xy * 0.5) + 0.5);		//R: lowerLf
			
			
			float4 worldView = fixed4 ( WorldSpaceViewDir(v.vertex), 1);
			

			o.normal = (v.normal);

			o.ViewDir =  (ObjSpaceViewDir(v.vertex));
			o.LightDir = (ObjSpaceLightDir(v.vertex));

			
			return o;
		}

		float4 frag (v2f i) : COLOR
		{

		 	fixed3 col = tex2D(_MainTex, i.uv.xy).rgb;
		 	fixed3 maskColor = tex2D(_MaskTex, i.uv.xy).rgb;
		 // 	#ifdef TwoMask_On
		 // 		float3 maskB = tex2D(_MaskBMap, i.uv.xy).rgb;

			//  	#ifdef transparentCullout_On
			//  	fixed alpha = maskB.r;
			//  	clip( alpha - _AlphaRef);	
			//  	#endif


			//  	fixed2 t = saturate ( fixed2(2*maskB.b-1, -2*maskB.b +1 )) ;
			//  	fixed base = saturate(-t.x-t.y + i.color.r);
			//  	col.rgb *= fixed3(base,base,base) + 2* ( saturate(i.color.r)*( t.x *  _Tint1.rgb + t.y * _Tint2.rgb)  +  (1-i.color.r) * _Tint3.rgb );
			// #endif
		 	
		 	
			fixed3 normal =  normalize( i.normal);
			
			
			half3 nh = max (0.0, dot (normal, normalize(  (i.ViewDir + i.LightDir) )));
			fixed nDotL =  (dot (normal, i.LightDir) * 0.5) + 0.5;
			fixed nDotV = saturate( dot( normal, normalize( i.ViewDir)) );
			fixed rim = 1 - nDotV ;
			float3 rimLight = rim * _RimDiffuse * _RimColor; 

			fixed2 rampUV = fixed2( nDotL, 0.5);
			fixed3 texRamp = tex2D(_RampMap, rampUV);

			fixed gloss =  maskColor.r;

  			fixed4 texNoise = tex2D (_NoiseTex, i.uv.zw);
  
  			fixed3 noise = (texNoise.xyz * (col.xyz * _NoiseColor));

  			float v = saturate(saturate(maskColor.g - _NoiseThreshold)*4);
  			noise *=  v * _MMultiplier;

			float3 albedo ;
			fixed2 capCoord = ((normalize(i.normal).xy * 0.5) + 0.5);


			albedo = maskColor.b* 2.0 * tex2D (_LightTex, i.capCoord).xyz +  col.xyz * _fDiffusePower * _colDiffuse.rgb + noise;

			

 			float3 result = (texRamp + _AmbientColor) * albedo;
 			result += 2.0 * _SpecColor * ((pow (nh, _SpecPower) * gloss) * _SpecMultiplier)  ;
			result += _SelfIlluminateColor.rgb * _SelfIlluminated;
			result += rimLight;

			return fixed4(result , 1);
		
		 }

		v2f1 vert1 (appdata1 v) {
			v2f1 o;
			o.pos = UnityObjectToClipPos( v.vertex );
			o.uvBase = v.uv;
			return o;
		}
        
		fixed4 frag1 (v2f1 Input) : COLOR0 
		{
			float4 colBaseTex  = tex2D(_MainTex,Input.uvBase); 
			float4 OutputColor = float4(0.5, 0.5, 1.0, 0.6 * colBaseTex.a);
			return OutputColor;
		}
	ENDCG


	Subshader
	{
		Tags { "Queue"="Geometry+1" "LightMode"="ForwardBase"  "IgnoreProjector"="True" "RenderType"="Opaque"}
		LOD 100
		Pass {
			AlphaTest Greater 0.1
			Cull Back Lighting Off ZWrite Off Fog { Mode Off }
			ZTest Greater
			
			Offset 0, -1200
			Blend SrcAlpha One

			CGPROGRAM

			#pragma exclude_renderers d3d11 xbox360
			#pragma vertex vert1
			#pragma fragment frag1
			#pragma fragmentoption ARB_precision_hint_fastest 


			ENDCG
		}	


		Pass
		{
			Cull Back Lighting Off ZWrite On Fog { Mode Off }
			CGPROGRAM
				#pragma exclude_renderers flash
				
				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest
				#pragma multi_compile transparentCullout_Off transparentCullout_On
				
			ENDCG
		}
		UsePass "Mobile/VertexLit/SHADOWCASTER"
	}

	
	CustomEditor "Wangzhe2MaterialInspector"
}