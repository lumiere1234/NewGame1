// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "* Environment/Sky"
{
	Properties
	{
		[NoScaleOffset]
		_GradientTint ("天空渐变色", 2D) = "white" {}
		_GradientSamplePosition("采样位置",Range(0,1)) = 0
		_MainTex ("山体背景图", 2D) = "black" {}
		[Space][Space][Space]_Cloud ("RG分别代表两层浮云", 2D) = "white" {}
		_CloudMoveSpeed ("前2个控制R层云的UV速度，后2个控制G层云的UV速度", Vector) = (0.1,0,0.1,0)
		[Space][Space][Space]_Phase ("RG分别控制两层云的渐隐消散", 2D) = "white" {}
		_PhaseMoveSpeed ("前2个控制R层的UV速度，后2个控制G层的UV速度", Vector) = (0.1,0.01,-0.075,0.01)
		_CloudVisibleSpeed ("前2个控制RGB相位层的渐隐速度，后2个没用", Vector) = (1,1,0,0)
		[Space][Space][Space]_CloudColor ("浮云颜色（Alpha控制云层透明度）", Color) = (1,1,1,0.75)

		_GlobalEmission("整体亮度(不影响太阳和月亮)",Float) = 1

		[Space][Space][Space]_Sun ("太阳", 2D) = "white" {}
		_Moon ("月亮", 2D) = "white" {}
		_SunTint ("太阳颜色叠加（Alpha控制透明度）", Color) = (1,1,1,1)
		_MoonTint("月亮颜色叠加（Alpha控制透明度）", Color) = (1,1,1,1)

		_FogDensity("雾的浓度",Range(0,1)) = 0.2
	}
	SubShader
	{
		Tags { "Queue"="Background" "LightMode"="ForwardBase"  "IgnoreProjector"="False" "RenderType"="Opaque" }
		LOD 100
		Cull Front ZWrite Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma target 3.0
			#pragma multi_compile ZL_ADDTIONAL_CLOUD_OFF ZL_ADDTIONAL_CLOUD_ON
			#pragma multi_compile ZL_ADDTIONAL_MOON_OFF ZL_ADDTIONAL_MOON_ON
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 color : COLOR0;
				float4 MainTexUV : TEXCOORD0;
				//float4 GradientTintUV : TEXCOORD1;
				float4 AddtionalCloudUV : TEXCOORD2;
				float4 PhaseUV : TEXCOORD3;
				float4 MoonUV : TEXCOORD4;
				float4 SunUV : TEXCOORD5;
				UNITY_FOG_COORDS(7)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _GradientTint;
			float4 _GradientTint_ST;
			float _GradientSamplePosition;
			float _FogDensity;

			#if ZL_ADDTIONAL_MOON_ON
				sampler2D _Sun;
				float4 _Sun_ST;
				sampler2D _Moon;
				float4 _Moon_ST;
				float4 _SunTint;
				float4 _MoonTint;
			#endif

			sampler2D _Cloud;
			float4 _Cloud_ST;
			float4 _CloudMoveSpeed;

			sampler2D	_Phase;
			float4 _Phase_ST;
			float4 _PhaseMoveSpeed;
			float4 _CloudVisibleSpeed;

			float4 _CloudColor;
			float _GlobalEmission;
		
			float4 _camPos;

			v2f vert (appdata_full v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.color = v.color;

				o.MainTexUV.xy = TRANSFORM_TEX(v.texcoord1, _MainTex);
				o.MainTexUV.zw = TRANSFORM_TEX(v.texcoord, _GradientTint);
				o.MainTexUV.z = _GradientSamplePosition;
				float2 addtionCloudOrigionalUV = TRANSFORM_TEX(v.texcoord, _Cloud); 
				o.AddtionalCloudUV.xy = addtionCloudOrigionalUV + _Time * _CloudMoveSpeed.xy;
				o.AddtionalCloudUV.zw = addtionCloudOrigionalUV + _Time * _CloudMoveSpeed.zw;
				float2 phaseOrigionalUV = TRANSFORM_TEX(v.texcoord, _Phase); 
				o.PhaseUV.xy = phaseOrigionalUV + _Time * _PhaseMoveSpeed.xy;
				o.PhaseUV.zw = phaseOrigionalUV + _Time * _PhaseMoveSpeed.zw;
				#if ZL_ADDTIONAL_MOON_ON
					o.SunUV.xy = TRANSFORM_TEX(v.texcoord, _Sun);
					o.MoonUV.xy = TRANSFORM_TEX(v.texcoord, _Moon);
				#endif

				UNITY_TRANSFER_FOG(o,o.vertex);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 gradient = tex2D(_GradientTint,i.MainTexUV.zw) * _GlobalEmission;
				fixed4 bg = tex2D(_MainTex, i.MainTexUV.xy);
				fixed4 finalColor = lerp(gradient, bg, bg.a);
				fixed4 applyFogColor = finalColor;
				UNITY_APPLY_FOG(i.fogCoord, applyFogColor);
				finalColor = lerp(finalColor,applyFogColor, bg.a * _FogDensity);
				fixed OneMinusBGAlpha = 1 - bg.a;

				#if ZL_ADDTIONAL_MOON_ON
					fixed4 sun = tex2D(_Sun, i.SunUV.xy) * _SunTint;
					fixed4 moon = tex2D(_Moon, i.MoonUV.xy) * _MoonTint;
					finalColor = lerp(finalColor, sun, sun.a * _SunTint.a * OneMinusBGAlpha);
					finalColor = lerp(finalColor, moon, moon.a * _MoonTint.a * OneMinusBGAlpha);
				#endif

				#if ZL_ADDTIONAL_CLOUD_ON
					fixed4 phase1 = tex2D(_Phase,i.PhaseUV.xy).r;
					fixed4 phase2 = tex2D(_Phase,i.PhaseUV.zw).g;

					phase1 = sin(phase1 + _Time * _CloudVisibleSpeed.r);
					phase1 = phase1 - floor(phase1);
					phase1 = abs(phase1 * 2 - 1);

					phase2 = frac(phase2 + _Time * _CloudVisibleSpeed.g);
					phase2 = phase2 - floor(phase2);
					phase2 = abs(phase2 * 2 - 1);

					float cloud1 = tex2D(_Cloud, i.AddtionalCloudUV.xy).r;
					float cloud2 = tex2D(_Cloud, i.AddtionalCloudUV.zw).g;

					float cloudLerp = (cloud1 * phase1 + cloud2 * phase2) * _CloudColor.a * i.color * _GlobalEmission;
					fixed4 finalCloudColor = lerp(finalColor, _CloudColor, cloudLerp * OneMinusBGAlpha);

					return finalCloudColor;
				#endif

				return finalColor;
			}
			ENDCG
		}
	}
}
