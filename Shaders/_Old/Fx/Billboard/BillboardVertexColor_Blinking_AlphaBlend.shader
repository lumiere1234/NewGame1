// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Billboard/VertexColor/Billboard_Blinking_AlphaBlend" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_TintColor ("Tint Color", Color) = (1,1,1,1)
		_VerticalBillboarding("垂直方向是否billboard", Range(0,1)) = 1
		_Scale("自身缩放", Float) = 1.0
		_DistanceOffset("距原位置距离", Float) = 0.0

		_TimeOnDuration("ON duration",float) = 0.5
		_TimeOffDuration("OFF duration",float) = 0.5
		_BlinkingTimeOffsScale("Blinking time offset scale (seconds)",float) = 5
		_NoiseAmount("Noise amount (when zero, pulse wave is used)", Range(0,0.5)) = 0
		_Bias("Bias",float) = 0
	}
	
	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off Lighting Off ZWrite Off Fog { Mode Off }
	
		CGINCLUDE	
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float _FadeOutDistNear;
			float _FadeOutDistFar;
			fixed4 _TintColor;
			fixed _VerticalBillboarding;
			fixed _DistanceOffset;
			float _Scale;
			float _TimeOnDuration;
			float _TimeOffDuration;
			float _BlinkingTimeOffsScale;
			float _NoiseAmount;
			float _Bias;

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				fixed4 color : TEXCOORD1;
			};

			void CalcOrthonormalBasis(float3 dir,out float3 right,out float3 up)
			{
				up = float3(0, 1 - step(0.999, dir.y), step(0.999, dir.y));
				right = normalize(cross(up,dir));		
				up = cross(dir,right);	
			}


	
			v2f vert (appdata_full v)
			{
				v2f o; 
			
				float3 centerOffs = v.texcoord1.xyz;
				float3 centerLocal = v.vertex.xyz;

				float3 viewerLocal = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));
				float3 localDir = viewerLocal - centerLocal;
				
				localDir.y = (lerp(0, localDir.y, _VerticalBillboarding));
				localDir = normalize(localDir);
		
				float3 rightLocal;
				float3 upLocal;
				CalcOrthonormalBasis(localDir, rightLocal, upLocal);

				float time = _Time.y + _BlinkingTimeOffsScale * v.color.b;
				float fracTime = fmod(time,_TimeOnDuration + _TimeOffDuration);
				float wave = smoothstep(0,_TimeOnDuration * 0.25,fracTime)  * (1 - smoothstep(_TimeOnDuration * 0.75,_TimeOnDuration,fracTime));
				float noiseTime = time *  (6.2831853f / _TimeOnDuration);
				float noise = sin(noiseTime) * (0.5f * cos(noiseTime * 0.6366f + 56.7272f) + 0.5f);
				float noiseWave = _NoiseAmount * noise + (1 - _NoiseAmount);
			
				wave = _NoiseAmount < 0.01f ? wave : noiseWave;
				wave += _Bias;
		
				float3 BBLocalPos = centerLocal - (rightLocal * centerOffs.x + upLocal * centerOffs.y) *_Scale + localDir * _DistanceOffset;
				o.uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
				o.pos = UnityObjectToClipPos(float4(BBLocalPos,1));
				o.color = v.color * wave * _TintColor;

						
				return o;
			}
		ENDCG

		Pass {
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest		
				fixed4 frag (v2f i) : COLOR
				{		

					return tex2D (_MainTex, i.uv.xy) * i.color;
				}
			ENDCG 
		}	
	}
}
