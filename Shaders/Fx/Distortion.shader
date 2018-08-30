// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "* FX/Distortion Fade Out By Vertex Color"
{
 Properties {  
        _BumpAmt  ("Distortion", range (0,128)) = 10  
        _BumpMap ("Normalmap", 2D) = "bump" {} 
		_AlphaMask ("Alpha Mask", 2D) = "white" {}
    }  
  
    Category {  
        // We must be transparent, so other objects are drawn before this one.  
        Tags { "Queue"="Transparent+100" "RenderType"="Transparent" }  
  
        SubShader {  
              
            ZWrite Off  
            Cull Off  
            Fog {Mode Off}  
            Lighting Off  
			Blend SrcAlpha OneMinusSrcAlpha

            // This pass grabs the screen behind the object into a texture.  
            // We can access the result in the next pass as _GrabTexture  
            GrabPass {                            
                Name "BASE"  
                Tags { "LightMode" = "Always" }  
            }  
          
            // Main pass: Take the texture grabbed above and use the bumpmap to perturb it  
            // on to the screen  
            Pass {  
                Name "BASE"  
                Tags { "LightMode" = "Always" }  
              
                CGPROGRAM  
                #pragma vertex vert  
                #pragma fragment frag  
                #pragma fragmentoption ARB_precision_hint_fastest  
                #include "UnityCG.cginc"  
  
                struct appdata_t {  
                    float4 vertex : POSITION;  
                    float2 texcoord: TEXCOORD0;  
					float4 vertexColor: COLOR;
                };  
  
                struct v2f {  
                    float4 vertex : POSITION;  
                    float4 uvgrab : TEXCOORD0;  
                    float2 uvbump : TEXCOORD1; 
					float2 modeluv : TEXCOORD2;
					float4 vertexColor: TEXCOORD3;
                };  
  
                float _BumpAmt;  
                float4 _BumpMap_ST;  
				float4 _AlphaMask_ST;
  
                v2f vert (appdata_t v)  
                {  
                    v2f o;  
                    o.vertex = UnityObjectToClipPos(v.vertex);  
   
                    //计算该模型顶点在屏幕坐标的纹理信息  
                    o.uvgrab = ComputeGrabScreenPos(o.vertex);  
  
                    o.uvbump = TRANSFORM_TEX( v.texcoord, _BumpMap );  
					o.modeluv = v.texcoord;
					o.vertexColor = v.vertexColor;
                    return o;  
                }  
  
                sampler2D _GrabTexture;  
                float4 _GrabTexture_TexelSize;  
                sampler2D _BumpMap; 
				sampler2D _AlphaMask;
  
                half4 frag( v2f i ) : COLOR  
                {  
                    // calculate perturbed coordinates  
                    half2 bump = UnpackNormal(tex2D( _BumpMap, i.uvbump )).rg; // we could optimize this by just reading the x & y without reconstructing the Z  
  
                    // _GrabTexture_TexelSize 就是 _GrabTexture的大小  
                    float2 offset = bump * _BumpAmt * _GrabTexture_TexelSize.xy;  
  
                    // 扰动方式  
					 i.uvgrab.xy = offset * i.uvgrab.z + i.uvgrab.xy;  
					

                    //对_GrabTexture纹理进行取样  
                    //half4 col = tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(i.uvgrab));  
                      
                    //也可以使用tex2D进行采样，为什么要除以i.uvgrab.w，  
                    float newUvX = i.uvgrab.x / i.uvgrab.w;  
                    float newUvY = i.uvgrab.y / i.uvgrab.w;  
  
                    half4 col = tex2D(_GrabTexture, float2(newUvX, newUvY)); 
  					fixed alphaColor = tex2D(_AlphaMask, i.modeluv).r;
					col.a = alphaColor * i.vertexColor.r;
                    return col;  
                }  
                ENDCG  
            }  
        }  
  
        // ------------------------------------------------------------------  
        // Fallback for older cards and Unity non-Pro  
      
        SubShader {  
            Blend DstColor Zero  
            Pass {  
                Name "BASE"  
                SetTexture [_MainTex] { combine texture }  
            }  
        }  
    }  
  
}  