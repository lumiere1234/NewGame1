// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "RegionColored" {
   Properties {
      _Color ("Main Color", Color) = (0.0, 0.0, 0.0, 0.5)
   }
   SubShader {
      Tags {"Queue" = "Transparent"} 

      Pass {   
         Cull Off
         ZWrite Off // don't write to depth buffer 
            // in order not to occlude other objects
         Blend SrcAlpha OneMinusSrcAlpha 
            // blend based on the fragment's alpha value
         
         CGPROGRAM
 
         #pragma vertex vert  
         #pragma fragment frag 

         float4 _Color; 
         // transparent black
 
         struct vertexInput {
            float4 vertex : POSITION;
         };
         struct vertexOutput {
            float4 pos : SV_POSITION;
         };
 
         vertexOutput vert(vertexInput input) 
         {
            vertexOutput output;
 
            output.pos = UnityObjectToClipPos(input.vertex);
            return output;
         }

         float4 frag(vertexOutput input) : COLOR
         {
            return _Color;
         }
 
         ENDCG
      }
   }
   Fallback "Unlit/Transparent"
}
