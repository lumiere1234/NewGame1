// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// ---------
// | B | A |
// ---------
// | R | G |
// ---------
Shader "CHP/Test/WangZhe_1" {
	Properties
	{
		//MatCapSimple MatCapMultiEnvOneMask MatCapMultiEnvTwoMask
		_MainTex ("Base (RGB)", 2D) = "grey" {}
		_MaskTex ("Mask (RGB)", 2D) = "grey" {}
		//_BumpMap ("Normal(RG) Mask (B) ", 2D) = "bump" {}
		_ReflectionLV ("Reflection Multiplier", Float) = 2
 		_Reflection ("Reflection", 2D) = "white" {}
 		 _RimPower ("Rim Power", Range(1,3)) = 1
		_NoiseTex("NoiseTex", 2D) = "white" {}
		_NoiseColor("_NoiseColor", Color ) = (1,1,0,1)

		
		_LightTex("LightTex", 2D) = "white" {}

		_MMultiplier ("MMultiplier", float) = 5

		_Scroll2X ("Scroll2X", float) = 1
		_Scroll2Y ("Scroll2Y", float) = 1
		_ShadowColor("ShadowColor", Color ) = (0,0.3,0.2,1)
	}
	
	CGINCLUDE
		#include "UnityCG.cginc"
		#include "AutoLight.cginc"

		sampler2D _MainTex;
		sampler2D _BumpMap;
		
		sampler2D _MaskTex;
		sampler2D _Reflection;

		sampler2D _LightTex;

		float4 _MainTex_ST;
		sampler2D _NoiseTex;
		float4 _NoiseTex_ST;

		float _RimPower;
		float _ReflectionLV;
		float _MMultiplier;
		float4 _NoiseColor;



		half Scroll2X;
		half _Scroll2Y;


		fixed3 _ShadowColor;


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
			float4 uv : TEXCOORD0;
			half3 normalInView : TEXCOORD1;
			half3 ViewDir : TEXCOORD2;
			half3 LightDir : TEXCOORD3;

			LIGHTING_COORDS(4,5)
			// float3 c0  : TEXCOORD6;
			// float3 c1  : TEXCOORD7;
		};

		
		v2f vert (appdata v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos (v.vertex);
			o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);

			o.uv.zw =  TRANSFORM_TEX(v.texcoord,_NoiseTex) + frac( half2(_Scroll2Y, _Scroll2Y) * _Time.x);
			

			
			TANGENT_SPACE_ROTATION;
			
			float4 worldView = fixed4 ( WorldSpaceViewDir(v.vertex), 1);
			

			o.normalInView = mul (UNITY_MATRIX_MV, fixed4(v.normal,0)).xyz;

			o.ViewDir =  normalize (mul(rotation, ObjSpaceViewDir(v.vertex).xyz ));
			o.LightDir = normalize(mul(rotation , mul(unity_WorldToObject , fixed4((_WorldSpaceLightPos0.xyz) ,0) ).xyz));;

			// o.c0 = mul(rotation, UNITY_MATRIX_IT_MV[0].xyz);
			// o.c1 = mul(rotation, UNITY_MATRIX_IT_MV[1].xyz);
			TRANSFER_VERTEX_TO_FRAGMENT(o);
			return o;
		}

		float4 frag (v2f i) : COLOR
		{

		 	fixed3 col = tex2D(_MainTex, i.uv.xy);
		 	fixed3 maskColor = tex2D(_MaskTex, i.uv.xy);

		 	// return fixed4(maskColor.bbb,1);
		 	// return fixed4(maskColor.ggg,1);
		 	// return fixed4(maskColor.rrr,1);

			//fixed3 packedNormal =  normalize( UnpackNormal(tex2D(_BumpMap, i.uv)));
			
			//fixed3 nh = max (0.0, dot (packedNormal, normalize(  (i.ViewDir + i.LightDir) )));

			//fixed nDotL =  (dot (packedNormal, i.LightDir) * 0.5) + 0.5;;
			//return fixed4(nDotL, nDotL, nDotL, 1);


			

  			fixed4 texNoise = tex2D (_NoiseTex, i.uv.zw);
  
  			fixed3 noise = (texNoise.xyz * (col.xyz * _NoiseColor));;
  			noise *= maskColor.y * _MMultiplier;

			
			fixed2 capCoord = ((normalize(i.normalInView).xy * 0.5) + 0.5);
			fixed3 lightTex = tex2D (_LightTex, capCoord);
			half3 reflectionTex = tex2D(_Reflection, capCoord) ;//+ fixed3(1,1,1);
			//return fixed4(reflectionTex,1);
			//return fixed4(capCoord.xy,1, 1);

			half3 colorWithLight = col.xyz * (tex2D (_LightTex, capCoord) * 2.0).xyz;
			

			float attenuation = LIGHT_ATTENUATION(i);

			//return fixed4(attenuation,attenuation,attenuation,1);
			// return fixed4(maskColor.xxx,1);
			//return fixed4(colorWithLight, 1);
			half3 reflection = pow (reflectionTex, _RimPower) * _ReflectionLV ;
			float3 mixed = lerp( colorWithLight, colorWithLight * (  reflection), maskColor.xxx);

			//return fixed4(mixed,1);	
			//return fixed4( colorWithLight * pow (reflectionTex, fixed3(_RimPower,_RimPower,_RimPower)),1);
			mixed += noise;
			//return fixed4(mixed * attenuation, 1);
 			// float3 result = (mixed *attenuation
    // 			+ (texRamp + _AmbientColor) * albedo_13);
			float3 darkColor = mixed * _ShadowColor;
			

			return fixed4(lerp(  darkColor,mixed , attenuation) , 1);

			
		
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
				#pragma multi_compile_fwdbase
				
			ENDCG
		}
		UsePass "Mobile/VertexLit/SHADOWCASTER"
	}

	
	
}