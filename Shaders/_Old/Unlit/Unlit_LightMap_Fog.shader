// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/Texture (Support lightmap, Fog)" {
Properties {
	_MainTex ("Base (RGB)", 2D) = "white" {}
}

SubShader {
	Tags { "RenderType"="Opaque" }
	Cull Back Lighting Off ZWrite On 

	LOD 100
	
	Pass { 
		Tags { "LightMode" = "ForwardBase" } 
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase
			#pragma multi_compile  Lightmap_Off Lightmap_On
			
			#include "../../CGIncludes/SevenInclude.cginc"
			#include "AutoLight.cginc"

			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				half2 texcoord : TEXCOORD0;
				float2 lmap : TEXCOORD1;
				SHADOW_COORDS(2)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata_t v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.lmap = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				TRANSFER_SHADOW(o);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.texcoord);
				#if Lightmap_On
				col.rgb *= SevenLightmap( i.lmap);
				#endif
				float attenuation = SHADOW_ATTENUATION(i);
				col.rgb *= attenuation;
				return col;
			}
		ENDCG
	}
	UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
}

}

