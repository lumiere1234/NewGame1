// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Chp/Tools/ShowVertexColor" {
Properties {
	_MMultiplier ("ShowVertex: RGB/A/RGBA ", range(0,1)) = 1
}

	
SubShader {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	
	Blend SrcAlpha OneMinusSrcAlpha
	Cull Off Lighting Off ZWrite Off Fog { Color (0,0,0,0) }
	
	LOD 100
	
	
	
	CGINCLUDE
	#pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
	#include "UnityCG.cginc"

	float _MMultiplier;
	struct v2f {
		float4 pos : SV_POSITION;
		
		fixed4 color : TEXCOORD1;
	};

	
	v2f vert (appdata_full v)
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		fixed b0 = 1 - step( 0.33f, _MMultiplier  );
		fixed b1 = (1 - step( 0.67f, _MMultiplier  )) * step( 0.33f, _MMultiplier  );
		
		fixed4 c0 = fixed4( v.color.r, v.color.g,v.color.b, 1);
		fixed4 c1 = fixed4( 1,1,1,v.color.a);

		
		o.color = c0*b0 + c1 * b1 +  v.color *step( 0.67f, _MMultiplier  );;
				
		
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
						
			return i.color;
		}
		ENDCG 
	}	
}

}
