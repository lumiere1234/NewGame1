// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "* Character/New Hair"
{
	Properties
	{
		_MainTex ("Base Color", 2D) = "white" {}
		[NoScaleOffset]_MaskTex ("Mask(R:高光 G：高光散射 B：Alpha)", 2D) = "white" {}
		_AlphaCutout("Alpha Cut Out",Range(0,1)) = 0.1
		_Shift("高光散射度", Range(0,1)) = 0.3
		[NoScaleOffset]_LUTTex("高光层级LUT",2D) = "white" {}
		_HairTint1("染色(顶点色 R 通道白染黑不染)",Color) = (0.32, 0.15, 0.15, 1)
		_Power("高光大小",Float) = 2
		_Amount("高光强度",Float) = 0.2
		_SpecularColor("高光颜色",Color) = (1, 1, 1, 1)
		[Space][Space][Space]_animParams("扰动(xyz控制扰动，w控制强度,顶点色 G 通道黑动白不动))",Vector) = (1.975, 0.793, 0.375, 0.193)
		[Space][Space][Space]_Wind("偏移(xyz控制位移距离，w控制强度,顶点色 G 通道黑动白不动)",Vector) = (0,0,0,1)
		_SelfIlluminateColor("Emission Color",Color) = (0,0,0)
	}

	
	CGINCLUDE
	#include "../CGIncludes/ZL_CGInclude.cginc"
	#include "Lighting.cginc"
	#include "AutoLight.cginc"
	#include "TerrainEngine.cginc"

	sampler2D	_MainTex;
	sampler2D	_LUTTex;
	sampler2D	_MaskTex;
	float4 _MainTex_ST;
	float _Power;
	float _Amount;
	float4 _HairTint1;
	float _Shift;
	float4 _SpecularColor;
	float4 _animParams;
	float _AlphaCutout;
	float4 _SelfIlluminateColor;
	ENDCG
	


	SubShader
	{
		//Tags { "Queue"="Transparent" "LightMode"="ForwardBase"  "IgnoreProjector"="False" "RenderType"="TransparentCutout"}
		//Tags { "Queue"="AlphaTest"  "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		Tags { "Queue"="Geometry"  "IgnoreProjector"="False" "RenderType"="TransparentCutout"}

		Cull Off

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
				float4 pos : SV_POSITION;
				float4 uv: TEXCOORD0;
				float4 color : COLOR;
				TANGENT_SPACE_VERCTORS(1,2,3)
				SHADOW_COORDS(6)
				UNITY_FOG_COORDS(7)
			};

			
			v2f vert (appdata_full v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);

				float4 newPos = AnimateVertex(v.vertex, v.normal, _animParams);
				v.vertex = lerp(v.vertex, newPos,1 - v.color.g);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				TANGENT_SPACE_CALCULATE
				TRANSFER_SHADOW(o);
				UNITY_TRANSFER_FOG(o,o.pos);
				o.color = v.color;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//Base color
				fixed4 col = tex2D (_MainTex, i.uv.xy);
				fixed4 specTexColor = tex2D(_MaskTex, i.uv);

				float3 worldNormal = float3(i.tangentSpaceLightDir.w, i.tangentSpaceViewDir.w, i.tangentSpaceVertexNormal.w);
				float3 normal = i.tangentSpaceVertexNormal;
				float3 lightDir = i.tangentSpaceLightDir;
				float3 ViewDir = i.tangentSpaceViewDir;
				float3 halfVector = lightDir + ViewDir;

				half3 ambientLighting = ShadeSH9(float4(normalize(worldNormal),1));
				half3 lambertLight = saturate( dot(normalize(normal), normalize(lightDir)));

				lambertLight = lerp(ambientLighting, _LightColor0.rgb, lambertLight);

				float finalShift = (specTexColor.g * 2 - 1) * _Shift;
				float originalDot = dot(normalize(normal), normalize(halfVector));
				float2 specUV = float2(originalDot, originalDot) + finalShift;
				float4 lutColor = tex2D(_LUTTex, specUV);
				lutColor = pow(max (0.001, lutColor), _Power);
				float spec = lutColor *  _Amount * specTexColor.r;


				half4 tintedColor = lerp(1, _HairTint1, i.color.r) * 2; 
				col.rgb = col.rgb * tintedColor * lambertLight + spec * _SpecularColor.rgb;
				col.rgb = lerp(ambientLighting * col.rgb, col.rgb, SHADOW_ATTENUATION(i));

				fixed alpha = specTexColor.b - _AlphaCutout;
				clip (alpha);
				
				col.a = alpha;

				col += _SelfIlluminateColor;
				UNITY_APPLY_FOG(i.fogCoord, col);

				return col;
			}

			ENDCG
		}

		Pass
		{
			Tags { "LightMode"="ForwardBase"} 
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off ZWrite off ZTest Less 
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
			#pragma multi_compile_fog


			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 uv: TEXCOORD0;
				float4 color : COLOR;
				TANGENT_SPACE_VERCTORS(1,2,3)
				SHADOW_COORDS(6)
				UNITY_FOG_COORDS(7)
			};

			
			v2f vert (appdata_full v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);

				float4 newPos = AnimateVertex(v.vertex, v.normal, _animParams);
				v.vertex = lerp(v.vertex, newPos,1 - v.color.g);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				TANGENT_SPACE_CALCULATE
				TRANSFER_SHADOW(o);
				UNITY_TRANSFER_FOG(o,o.pos);
				o.color = v.color;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//Base color
				fixed4 col = tex2D (_MainTex, i.uv.xy);
				fixed4 specTexColor = tex2D(_MaskTex, i.uv);

				float3 worldNormal = float3(i.tangentSpaceLightDir.w, i.tangentSpaceViewDir.w, i.tangentSpaceVertexNormal.w);
				float3 normal = i.tangentSpaceVertexNormal;
				float3 lightDir = i.tangentSpaceLightDir;
				float3 ViewDir = i.tangentSpaceViewDir;
				float3 halfVector = lightDir + ViewDir;

				half3 ambientLighting = ShadeSH9(float4(normalize(worldNormal),1));
				half3 lambertLight = saturate( dot(normalize(normal), normalize(lightDir)));

				lambertLight = lerp(ambientLighting, _LightColor0.rgb, lambertLight);

				float finalShift = (specTexColor.g * 2 - 1) * _Shift;
				float originalDot = dot(normalize(normal), normalize(halfVector));
				float2 specUV = float2(originalDot, originalDot) + finalShift;
				float4 lutColor = tex2D(_LUTTex, specUV);
				lutColor = pow(max (0.001, lutColor), _Power);
				float spec = lutColor *  _Amount * specTexColor.r;


				half4 tintedColor = lerp(1, _HairTint1, i.color.r) * 2; 
				col.rgb = col.rgb * tintedColor * lambertLight + spec * _SpecularColor.rgb;
				col.rgb = lerp(ambientLighting * col.rgb, col.rgb, SHADOW_ATTENUATION(i));
				col += _SelfIlluminateColor;

				col.a =  saturate( specTexColor.b / _AlphaCutout );
				UNITY_APPLY_FOG(i.fogCoord, col);

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
				fixed4 texcol = tex2D( _MaskTex, i.uv );
				clip( texcol.b - _AlphaCutout );
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	

	}
}
     