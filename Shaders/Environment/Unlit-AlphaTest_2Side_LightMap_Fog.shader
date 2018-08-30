// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "* Unlit/Transparent Cutout 2 Side (Support lightmap, Fog)" {
	Properties {
		[ShowWhenHasKeyword(VERTEX_COLOR_ON)] _VertexColorAmount( "Vertex Color Amount", Range(0,1)) = 1
		_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.50
		[HideInInspector] _SunRange ("sun Range Multiplier", Range(0.01, 100)) = 2
		_BackLightAmount ("BackLight Multiplier", Range(0, 10)) = 1
		_darknessLimit ("Darkness Limit", Range(0,2) ) = 0.4
		_brightnessLimit ("Brightness Limit", Range(0,2) ) = 0.8
	}

	CGINCLUDE
		#include "../CGIncludes/WokInclude.cginc"
		#include "Lighting.cginc"
		#include "../CGIncludes/ZL_CGInclude.cginc"

		float _darknessLimit;
		float _brightnessLimit;
		float4 unity_Lightmap_ST;
		sampler2D _MainTex;
		float4 _MainTex_ST;
		fixed _Cutoff;
		#ifdef VERTEX_COLOR_ON
			float _VertexColorAmount;
		#endif
		float _BackLightAmount;

		float wokLeafCutOff;
		struct appdata_t {
			float4 vertex : POSITION;
			float2 texcoord : TEXCOORD0;
			float2 texcoord1 : TEXCOORD1;

			// #ifdef VERTEX_COLOR_ON
				float4 color : COLOR;
			// #endif
		};

		struct v2f {
			float4 pos : SV_POSITION;
			half2 texcoord : TEXCOORD0;
			#ifdef VERTEX_COLOR_ON
				float4 color : COLOR;
			#endif
			float2 lmap : TEXCOORD1;
			WOK_FOG_COORDS(2)
			float4 worldPos : TEXCOORD3;
		};

		struct v2f_500 {
			float4 pos : SV_POSITION;
			half2 texcoord : TEXCOORD0;
			#ifdef VERTEX_COLOR_ON
				float4 color : COLOR;
			#endif
			float2 lmap : TEXCOORD1;
			WOK_FOG_COORDS(2)
			half4 backLight : TEXCOORD3;
			float4 worldPos : TEXCOORD4;
		};

		v2f vert (appdata_t v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex * step(wokLeafCutOff, v.color.a ));
			o.worldPos = mul( UNITY_MATRIX_M, v.vertex );
			o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
			#ifdef VERTEX_COLOR_ON
				o.color = v.color;
				o.color.rgb = lerp(fixed3(1,1,1), o.color,  _VertexColorAmount );
			#endif
			o.lmap = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;

			o.fogCoord = WOK_TRANSFER_ALTITUDE_FOG(o.pos.z, o.worldPos, wokAltitudeFogParams);

			return o;
		}

		v2f_500 vert_500 (appdata_t v)
		{
			v2f_500 o;
			o.pos = UnityObjectToClipPos(v.vertex * step(wokLeafCutOff, v.color.a ));
			o.worldPos = mul( UNITY_MATRIX_M, v.vertex );
			o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
			#ifdef VERTEX_COLOR_ON
				o.color = v.color;
				o.color.rgb = lerp(fixed3(1,1,1), o.color,  _VertexColorAmount );
			#endif
			o.lmap = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;

			o.fogCoord = WOK_TRANSFER_ALTITUDE_FOG(o.pos.z, o.worldPos, wokAltitudeFogParams);

			half dotLight =  saturate(dot ( normalize( mul (UNITY_MATRIX_M, v.vertex) - _WorldSpaceCameraPos), normalize(_WorldSpaceLightPos0) ));
			o.backLight = half4(dotLight * dotLight *_BackLightAmount * _LightColor0.rgb, dotLight );

			o.fogCoord = WOK_TRANSFER_ALTITUDE_FOG(o.pos.z, o.worldPos, wokAltitudeFogParams);
			return o;
		}
		
		half4 frag (v2f i) : SV_Target
		{
			half4 col = tex2D(_MainTex, i.texcoord);
			clip(col.a - _Cutoff);

			#ifdef VERTEX_COLOR_ON
				col.rgb *= i.color.rgb;
			#endif

			#if WOK_LIGHTMAP_ON
			//col.rgb *= WokLightmap( i.lmap);
			fixed3 lightmapColor = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap,i.lmap));
			col.rgb *= Remap(lightmapColor,_darknessLimit,_brightnessLimit);
			#endif

			col.rgb = WOK_APPLY_FOG_COLOR( col.rgb,  i.worldPos, i.fogCoord, wokAltitudeFogParams);

			UNITY_APPLY_FOG(i.fogCoord.x, col);
			
			return col;
		}

		half4 frag_500 (v2f_500 i) : SV_Target
		{
			half4 col = tex2D(_MainTex, i.texcoord);
			clip(col.a - _Cutoff);

			#ifdef VERTEX_COLOR_ON
				col.rgb *= i.color.rgb;
			#endif

			#if WOK_LIGHTMAP_ON
			//col.rgb *= WokLightmap( i.lmap);
			fixed3 lightmapColor = DecodeLightmapRGBM(UNITY_SAMPLE_TEX2D(unity_Lightmap,i.lmap));
			col.rgb *= Remap(lightmapColor,_darknessLimit,_brightnessLimit);
			#endif
			
			half l =  Luminance( col.rgb );
			col.rgb += l * col.rgb * i.backLight.rgb ;

			
			col.rgb = WOK_APPLY_FOG_COLOR( col.rgb,  i.worldPos, i.fogCoord, wokAltitudeFogParams);
			return col;
		}

	ENDCG


	SubShader {
		Tags { "Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		Cull Off Lighting Off ZWrite On 
		LOD 500
		
		Pass {  
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
				#pragma vertex vert_500
				#pragma fragment frag_500
				#pragma multi_compile_fog
				#pragma multi_compile  ZL_LIGHTMAP_OFF ZL_LIGHTMAP_ON
				#pragma multi_compile  VERTEX_COLOR_OFF VERTEX_COLOR_ON
				#pragma multi_compile WOK_ALTITUDE_FOG_OFF WOK_ALTITUDE_FOG_ON
			ENDCG
		}
	}

	SubShader {
		Tags { "Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		Cull Off Lighting Off ZWrite On 
		LOD 100
		Pass {  
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_fog
				#pragma multi_compile  ZL_LIGHTMAP_OFF ZL_LIGHTMAP_ON
				#pragma multi_compile  VERTEX_COLOR_OFF VERTEX_COLOR_ON
				#pragma multi_compile WOK_ALTITUDE_FOG_OFF WOK_ALTITUDE_FOG_ON
			ENDCG
		}
	}
	CustomEditor "UnlitTransparentCutoutInspector"
}
     