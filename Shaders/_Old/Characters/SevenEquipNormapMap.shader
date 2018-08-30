// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// ---------
// | B | A |
// ---------
// | R | G |
// ---------
Shader "Custom/Seven Equip NormapMap.." {
	Properties
	{
		//MatCapSimple MatCapMultiEnvOneMask MatCapMultiEnvTwoMask
		_MainTex ("Base (RGB)", 2D) = "grey" {}
		_MaskTex ("Mask (RGB)", 2D) = "grey" {}
		_AlphaRef ("AlphaTest Ref", Range(0,1)) = 0.5
		_MaskBMap ("MaskB (R:alpha G:empty B:tint)", 2D) = "white" {}
		_BumpMap ("Normal(RG) Mask (B) ", 2D) = "bump" {}
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

		_Scroll2X ("Scroll2X", float) = 1
		_Scroll2Y ("Scroll2Y", float) = 1


		_Tint1 ("装备换色 ", Color) = (0.5,0.5,0.5,1)
		_Tint2 ("装备换色2 ", Color) = (0.5,0.5,0.5,1)
		_Tint3 ("头发换色", Color) = (0.5,0.5,0.5,1)


	}
	
	CGINCLUDE
		#include "UnityCG.cginc"
		#include "AutoLight.cginc"

		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _RampMap;
		sampler2D _MaskTex;
		sampler2D _MaskBMap;

		float _AlphaRef;

		sampler2D _LightTex;

		float4 _MainTex_ST;
		sampler2D _NoiseTex;
		float4 _NoiseTex_ST;
		float _NoiseThreshold;

		float _MMultiplier;
		float _SpecPower;
		float _SpecMultiplier;


		fixed3 _AmbientColor;
		fixed3 _NoiseColor;
		fixed3 _SpecColor;

		half Scroll2X;
		half _Scroll2Y;


		fixed4 _Tint1;
		fixed4 _Tint2;
		fixed4 _Tint3;




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

		
		v2f vert (appdata v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos (v.vertex);
			o.color = v.color;
			o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);

			o.uv.zw =  TRANSFORM_TEX(v.texcoord,_NoiseTex) + frac( half2(_Scroll2Y, _Scroll2Y) * _Time.x);
			

			half3 normalInView = mul (UNITY_MATRIX_MV, fixed4(v.normal,0)).xyz;
			o.capCoord = half2((normalize(normalInView).xy * 0.5) + 0.5);		//R: lowerLf
			
			TANGENT_SPACE_ROTATION;
			
			float4 worldView = fixed4 ( WorldSpaceViewDir(v.vertex), 1);
			

			o.normal = (v.normal);

			o.ViewDir =  normalize (mul(rotation, ObjSpaceViewDir(v.vertex).xyz ));
			o.LightDir = normalize(mul(rotation , mul(unity_WorldToObject , fixed4((_WorldSpaceLightPos0.xyz) ,0) ).xyz));;

			
			return o;
		}

		float4 frag (v2f i) : COLOR
		{

		 	fixed3 col = tex2D(_MainTex, i.uv.xy).rgb;
		 	fixed3 maskColor = tex2D(_MaskTex, i.uv.xy).rgb;
		 	float3 maskB = tex2D(_MaskBMap, i.uv.xy).rgb;

		 	#ifdef transparentCullout_On
		 	fixed alpha = maskB.r;
		 	clip( alpha - _AlphaRef);	
		 	#endif

		 	fixed2 t = saturate ( fixed2(2*maskB.b-1, -2*maskB.b +1 )) ;
		 	fixed base = saturate(-t.x-t.y + i.color.r);
		 	col.rgb *= fixed3(base,base,base) + 2* ( saturate(i.color.r)*( t.x *  _Tint1.rgb + t.y * _Tint2.rgb)  +  (1-i.color.r) * _Tint3.rgb );

		 	
		 	
			fixed3 normal =  normalize( UnpackNormal(tex2D(_BumpMap, i.uv.xy)));
			
			
			fixed3 nh = max (0.0, dot (normal, normalize(  (i.ViewDir + i.LightDir) )));
			fixed nDotL =  (dot (normal, i.LightDir) * 0.5) + 0.5;

			fixed2 rampUV = fixed2( nDotL, 0.5);
			fixed3 texRamp = tex2D(_RampMap, rampUV);

			fixed gloss =  maskColor.r;

  			fixed4 texNoise = tex2D (_NoiseTex, i.uv.zw);
  
  			fixed3 noise = (texNoise.xyz * (col.xyz * _NoiseColor));

  			float v = saturate(saturate(maskColor.g - _NoiseThreshold)*4);
  			noise *=  v * _MMultiplier;

			float3 albedo ;
			fixed2 capCoord = ((normalize(i.normal).xy * 0.5) + 0.5);
			fixed3 lightTex = tex2D (_LightTex, capCoord);


			albedo = maskColor.b* 2.0 * tex2D (_LightTex, i.capCoord).xyz +  col.xyz + noise;

			

 			float3 result = (_SpecColor * ( ((pow (nh, _SpecPower) * gloss) * _SpecMultiplier) * 2.0) 
    			+ (texRamp + _AmbientColor) * albedo);
			

			return fixed4(result , 1);
		
		 }
	ENDCG


	Subshader
	{
		Tags { "Queue"="Geometry" "LightMode"="ForwardBase"  "IgnoreProjector"="True" "RenderType"="Opaque"}
		LOD 100
		Cull Back Lighting Off ZWrite On Fog { Mode Off }
		Pass
		{
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