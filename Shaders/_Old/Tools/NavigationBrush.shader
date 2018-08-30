// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/NavigationBrush" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
   }

	CGINCLUDE

	float4 _Color;
	
    struct appdata {
        float4 vertex	: POSITION;
        fixed4 color : COLOR0;
    };

    struct v2f {
        float4 pos : SV_POSITION;
        fixed4 color : COLOR0;
    };
        
    v2f vert (appdata v) {
        v2f o;
        o.pos = UnityObjectToClipPos( v.vertex );
        o.color = v.color;
        return o;
    }
        
    fixed4 frag (v2f Input) : COLOR0 
	{ 
		return fixed4(_Color);
	}

	ENDCG

	SubShader {
		Tags { "Queue"="Transparent+2001" "LightMode"="ForwardBase"  "IgnoreProjector"="True" "RenderType"="Transparent" }

        Pass {
        	Blend One OneMinusSrcAlpha
        	ZWrite Off
			Cull Off
			Lighting Off
			
			ZTest LEqual

	        CGPROGRAM

			#pragma exclude_renderers xbox360 flash
	        #pragma vertex vert
	        #pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest 

	        ENDCG
	    }
	}
}

