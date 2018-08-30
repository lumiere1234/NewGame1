// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "* Unlit/Texture (Support lightmap, Fog)" {
Properties {
	_MainTex ("Base (RGB)", 2D) = "white" {}
	//_LightmapBrightness ("Lightmap Brightness", Range(0,1) ) = 0.2
	_ColorBleedInRender("色溢强度(烘焙时有效)",Range(0,1)) = 0
}

SubShader {


		//用于烘焙色溢的MetaPass，用UsePass会导致客户端变紫，原因不明
		Pass 
		{
			Name "Meta"
			Tags { "LightMode" = "Meta" }

			CGPROGRAM
				#include "UnityStandardMeta.cginc"
				#pragma vertex vert_meta
				#pragma fragment frag_meta2
				float _ColorBleedInRender = 0;//需要外接Properties变量，否则不生效
				float4 frag_meta2 (v2f_meta i): SV_Target
				{
					FragmentCommonData data = UNITY_SETUP_BRDF_INPUT (i.uv);
					UnityMetaInput o;
					UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);
					fixed4 c = tex2D (_MainTex, i.uv);
					o.Albedo = c.rgb * _ColorBleedInRender;
					o.Emission = Emission(i.uv.xy) * _ColorBleedInRender;
					return UnityMetaFragment(o);
				}
			ENDCG
		}



	Tags { "RenderType"="Opaque" }
	Cull Back Lighting Off ZWrite On 

	LOD 100
	
	Pass { 
		Tags {"LightMode"="ForwardBase"}
		

		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#pragma multi_compile  ZL_LIGHTMAP_OFF ZL_LIGHTMAP_ON
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
			
			#include "../CGIncludes/ZL_CGInclude.cginc"
			#include "AutoLight.cginc"



			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float4 worldPos : TEXCOORD1;
				half2 texcoord : TEXCOORD2;
				float2 lmap : TEXCOORD3;
				UNITY_FOG_COORDS(4)
				SHADOW_COORDS(5)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 unity_Lightmap_ST;
			//float _LightmapBrightness;


			v2f vert (appdata_t v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul( UNITY_MATRIX_M, v.vertex );
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.lmap = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				
				TRANSFER_SHADOW(o);
				UNITY_TRANSFER_FOG(o,o.pos);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.texcoord);
				#if ZL_LIGHTMAP_ON
				fixed3 lightmapColor = DecodeLightmapRGBM(UNITY_SAMPLE_TEX2D(unity_Lightmap,i.lmap));
				col.rgb *= lightmapColor;
				//col.rgb *= lerp(lightmapColor, 2, _LightmapBrightness);
				#endif

				float attenuation = SHADOW_ATTENUATION(i);
				col *= attenuation;

				UNITY_APPLY_FOG(i.fogCoord, col);

				return col;
			}
		ENDCG
	}
	UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
	//UsePass "Hidden/MetaPass/META"

}

}

     