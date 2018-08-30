Shader "Hidden/Navigation/Colored" {
	Category {
	Tags { "Queue"="Transparent+2000" "IgnoreProjector"="True" "RenderType"="Transparent" }
	SubShader { 
		Pass {  
			Blend  SrcAlpha OneMinusSrcAlpha 
			ZWrite Off 
			Cull Off
			BindChannels 
			{ 
				Bind "vertex", vertex Bind "color", color }
			} 
		} 
	} 
}