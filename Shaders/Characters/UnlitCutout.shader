Shader "* Unlit/Cutout(Support Shadow, Fog)"
{
	Properties
	{
		[NoScaleOffset]_MainTex ("Texture", 2D) = "white" {}
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		_SelfIlluminateColor("Emission Color",Color) = (0,0,0)
	}


	CGINCLUDE
		#include "UnityCG.cginc"
		#include "AutoLight.cginc"
		float _Cutoff;
		sampler2D _MainTex;
		float4 _MainTex_ST;
		float4 _SelfIlluminateColor;

	ENDCG


	SubShader
	{
	    Tags { "Queue"="Geometry" "IgnoreProjector"="True" "RenderType"="TransparentCutout" }	

		Pass
		{
			Tags { "LightMode"="ForwardBase"} 
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
			#pragma multi_compile_fog
			

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				SHADOW_COORDS(6)
				UNITY_FOG_COORDS(7)
			};

			
			v2f vert (appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				TRANSFER_SHADOW(o);
				UNITY_TRANSFER_FOG(o,o.pos);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				col.rgb += _SelfIlluminateColor.rgb;
				clip(col.a - _Cutoff);
				UNITY_APPLY_FOG(i.fogCoord, col);

				//SHADOW_ATTENUATION(i);
				return col;
			}
			ENDCG
		}

		
		//ShadowCaster
		Pass {
			Name "Caster"
			Tags { "LightMode" = "ShadowCaster" }
		
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0

			struct v2f 
			{ 
				V2F_SHADOW_CASTER;
				float2  uv : TEXCOORD1;
			};

			v2f vert( appdata_base v )
			{
				v2f o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}

			float4 frag( v2f i ) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				clip(col.a - _Cutoff);
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
		


	}
}
