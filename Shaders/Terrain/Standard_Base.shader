// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "Hidden/Terrain/Standard_Base"
{
	Properties
	{
		[HideInInspector] _MainTex ("BaseMap (RGB)", 2D) = "white" {}
		_AddOnTex ("AddOn Map (RGB)", 2D) = "grey" {}
	} 


	SubShader
	{
		Tags { "Queue"="Geometry-100" "LightMode"="ForwardBase"  "IgnoreProjector"="False" "RenderType"="Opaque" }
		LOD 200


		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#pragma multi_compile ZL_LIGHTMAP_OFF ZL_LIGHTMAP_ON
			#pragma multi_compile ZL_DEBUG_MODE_OFF ZL_DEBUG_MODE_ON
			#pragma multi_compile ZL_LIGHTMAP_PAINT_OFF ZL_LIGHTMAP_PAINT_ON


			#include "UnityCG.cginc"
			#include "../CGIncludes/ZL_CGInclude.cginc"

			sampler2D	_MainTex;
			float4 _MainTex_ST;

			#if ZL_LIGHTMAP_PAINT_ON
			sampler2D _AddOnTex;
			#endif

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 uvBase : TEXCOORD0;	//Base and lightmapUV
				UNITY_FOG_COORDS(7)
			};

			
			v2f vert (appdata_tan v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.uvBase.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uvBase.zw = v.texcoord.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				UNITY_TRANSFER_FOG(o,o.pos);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//Base color
				fixed3 col = tex2D(_MainTex,i.uvBase);


				fixed3 finalLight = 1;

				//Additional lightmap paint mode
				#if ZL_LIGHTMAP_PAINT_ON
					finalLight *= 2 * tex2D(_AddOnTex, i.uvBase.zw).rgb ;
				#endif

				//Light map
				#if ZL_LIGHTMAP_ON
					finalLight *= DecodeLightmapRGBM(UNITY_SAMPLE_TEX2D(unity_Lightmap,i.uvBase.zw));
				#endif


				#if ZL_DEBUG_MODE_ON
					return fixed4(fixed3(0.25,0.25,0.5) * finalLight,1);
				#endif

				col.rgb *= finalLight;

				//Fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				return fixed4(col,1);
			}
			ENDCG
		}
	}
}
     