Shader "Hidden/Navigation/Colored over all" { 
	Category { 
	Tags { "Queue"="Transparent+2000" "IgnoreProjector"="True" "RenderType"="Transparent" }
	SubShader { 
		Pass { 
			Blend  SrcAlpha OneMinusSrcAlpha 
			ZTest Off   
			ZWrite Off 
			Cull Off
			BindChannels 
			{ 
				Bind "vertex", vertex Bind "color", color } 
			} 
		} 
	} 
}