// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "* Water/WaterFall"{
	Properties {
		_WaveScale ("Wave scale", float) = 1
		_GroundMap("Ground Map", 2D) = "balck"{}
		_BumpMap ("Normal Texture", 2D) = "bump" {}
		_BumpDepth ("Bump Depth", Range(0.01,1)) = 1
		_Cube( "env Map", Cube) = "black" {}
		_RefScale ("reflect Scale", Range(1,20)) = 1
		_WaveOffset ("Wave speed (map1 x,y; map2 x,y)", Vector) = (7,4,-6,-3)
		_Color0("Shallow Color", Color ) = (0.6,0.9,1,1)
		_Color1("Deep Color", Color ) = (0,0.15, 0.2)
		_Shininess ("Shininess", Float) = 100
		_InvRange("inverse Alpha, Depth, and Ccolor ", Vector) = (1, 0.17,0.17,0.25)
		_Fresnel ("Fresnel ", 2D) = "grey" {}
	}
	SubShader {
		Pass {
			Tags{ "Queue"="Geometry" "IgnoreProjector"="True" "LightMode"="ForwardBase" "RenderType"="Opaque"}
			Blend SrcAlpha OneMinusSrcAlpha
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma exclude_renderers d3d11 xbox360
			#include "UnityCG.cginc"
			
			//user defined variables
			
			half _WaveScale;
			half4 _WaveOffset;
	
			sampler2D _BumpMap;
			sampler2D _GroundMap;
			sampler2D _Fresnel;
			
			fixed4 _SpecColor;
			fixed4 _RimColor;
			half _Shininess;
			fixed _BumpDepth;
			fixed _RefScale;
			
			fixed4 _Color0;
			fixed4 _Color1;
			
			half4 _InvRange;
			
			samplerCUBE _Cube;
			
			//base input structs
			struct vertexInput{
				half4 vertex : POSITION;
				half3 normal : NORMAL;
				half4 texcoord : TEXCOORD0;
				half4 tangent : TANGENT;
			};
			struct vertexOutput{
				half4 pos : SV_POSITION;
				half2 tex : TEXCOORD0;
				fixed4 lightDirection : TEXCOORD1;
				fixed3 viewDirection : TEXCOORD2;
				fixed3 normalWorld : TEXCOORD3;
				fixed3 tangentWorld : TEXCOORD4;
				fixed3 binormalWorld : TEXCOORD5;
				float2  bumpuv0 : TEXCOORD6;
				float2  bumpuv1 : TEXCOORD7;
			};
			
			//vertex Function
			
			vertexOutput vert(vertexInput v){
				vertexOutput o;
				
				o.normalWorld = normalize( mul( half4( v.normal, 0.0 ), unity_WorldToObject ).xyz );
				o.tangentWorld = normalize( mul( unity_ObjectToWorld, v.tangent ).xyz );
				o.binormalWorld = normalize( cross(o.normalWorld, o.tangentWorld) * v.tangent.w );
				
				half4 posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.tex = v.texcoord.xy;

				float4 temp;
				temp.xyzw = (v.vertex.xzxz * _WaveScale + _WaveOffset * _Time.xxxx*0.1);

				o.bumpuv0 = temp.xy;
				o.bumpuv1 = temp.wz;
				
				o.viewDirection = normalize(  posWorld.xyz  - _WorldSpaceCameraPos.xyz);
			
				half3 fragmentToLightSource = _WorldSpaceLightPos0.xyz - posWorld.xyz;
				
				o.lightDirection = fixed4(
					normalize( lerp(_WorldSpaceLightPos0.xyz , fragmentToLightSource, _WorldSpaceLightPos0.w) ),
				lerp(1.0 , 1.0/length(fragmentToLightSource), _WorldSpaceLightPos0.w)
				);
				
				return o;
			}
			
			//fragment function
			
			fixed4 frag(vertexOutput i) : COLOR
			{
				//Texture Maps
				fixed4 texN = (tex2D(_BumpMap, i.bumpuv0) + tex2D(_BumpMap, i.bumpuv1) )* 0.5;
				
				fixed4 ground = tex2D(_GroundMap, i.tex.xy +(texN-.5)*0.07);
				
				fixed depth = ground.a;
				
				//unpackNormal function
				fixed3 localCoords = fixed3( 1,1,1);
				#if (defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)) && defined(SHADER_API_MOBILE)
					localCoords = normalize( fixed3(2.0 * texN.rg - float2(1.0, 1.0), _BumpDepth) );
				#else
					localCoords = normalize( fixed3(2.0 * texN.ag - float2(1.0, 1.0), _BumpDepth) );
				#endif
				fixed3 reflectCoord = fixed3( localCoords.rg, localCoords.b * _RefScale);
				
				
				
				//normal transpose matrix
				fixed3x3 local2WorldTranspose = fixed3x3(
					i.tangentWorld,
					i.binormalWorld,
					i.normalWorld
				);
				
				//calculate normal direction
				fixed3 normalDirection = normalize( mul( localCoords, local2WorldTranspose ) );
				fixed3 reflectNormal = normalize( mul( reflectCoord, local2WorldTranspose ) );
				
				half fresnel = dot( normalize(-i.viewDirection), normalDirection);	
				fresnel = tex2D(_Fresnel, fixed2( fresnel, 0) );
				
				half3 ranges = saturate( _InvRange.xyz * depth  );
				ranges.y = 1 - ranges.y;
				
				fixed nDotL = saturate(dot(normalDirection, i.lightDirection.xyz));
				
				fixed3 specularReflection = nDotL * pow(saturate(dot(reflect(i.lightDirection.xyz, normalDirection), i.viewDirection)) , _Shininess) ;
		
				half4 col = (1,1,1,1);
				col.rgb = lerp( _Color1.rgb , _Color0.rgb, ranges.y);
				col.a = ranges.x;
				half3 refraction = ground.rgb;
		
				refraction =  lerp( refraction, refraction * col.rgb, ranges.z);
				refraction =  lerp( lerp( col.rgb,col.rgb * refraction, ranges.y), refraction, ranges.y);
				
				float3 reflectDir = reflect(i.viewDirection, reflectNormal);

				fixed3 envColor = texCUBE( _Cube, reflectDir)  + (1- nDotL);
				
				//return fixed4( lerp(refraction  , envColor  ,fresnel )+specularReflection , ranges.x) ;
				return fixed4( lerp(refraction  , envColor  ,fresnel )+specularReflection , 1.0) ;

			}
			ENDCG
		}
	}
	//Fallback "Specular"
}