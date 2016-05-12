// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

Shader "Alloy/Particles/Multiply" {
Properties {
	// Particle Properties 
	_ParticleProperties ("'Particle Properties' {Section:{126, 41, 41}}", Float) = 0
	[HDR]
	_TintColor ("'Tint' {}", Color) = (1,1,1,1)
	[LM_MasterTilingOffset] [LM_Albedo] 
	_MainTex ("'Color(RGB) Opacity(A)' {Visualize:{RGB, A}}", 2D) = "white" {}
	_MainTexVelocity ("Scroll", Vector) = (0,0,0,0)
	_MainTexSpin ("Spin", Float) = 0
	[Gamma]
	_TintWeight ("'Weight' {Min:0, Max:1}", Float) = 1
	_InvFade ("'Soft Particles Factor' {Min:0.01, Max:3}", Float) = 1
	
	// Particle Effects Properties 
	[Toggle(_PARTICLE_EFFECTS_ON)]
	_ParticleEffects ("'Particle Effects Properties' {Feature:{126, 66,41}}", Float) = 0
	_ParticleEffectMask1 ("'Mask 1' {Visualize:{RGB, A}}", 2D) = "white" {}
	_ParticleEffectMask1Velocity ("Scroll", Vector) = (0,0,0,0)
	_ParticleEffectMask1Spin ("Spin", Float) = 0
	_ParticleEffectMask2 ("'Mask 2' {Visualize:{RGB, A}}", 2D) = "white" {}
	_ParticleEffectMask2Velocity ("Scroll", Vector) = (0,0,0,0)
	_ParticleEffectMask2Spin ("Spin", Float) = 0
	
	// Rim Fade Properties 
	[Toggle(_RIM_FADE_ON)]
	_RimFadeProperties ("'Rim Fade Properties' {Feature:{126, 92, 41}}", Float) = 0
	[Gamma]
	_RimFadeWeight ("'Weight' {Min:0, Max:1}", Float) = 1
	_RimFadePower ("'Falloff' {Min:0.01}", Float) = 4
	
	// Distance Fade Properties 
	[Toggle(_DISTANCE_FADE_ON)]
	_DistanceFadeProperties ("'Distance Fade Properties' {Feature:{126, 118, 41}}", Float) = 0
	_DistanceFadeNearFadeCutoff ("'Near Fade Cutoff' {Min:0}", Float) = 1
	_DistanceFadeRange ("'Range' {Min:0.5}", Float) = 1
}

Category {
	Tags { 
        "Queue"="Transparent" 
        "IgnoreProjector"="True" 
        "RenderType"="Transparent" 
    }
	Blend Zero SrcColor
	Cull Off Lighting Off ZWrite Off
	
	SubShader {
		Pass {
			CGPROGRAM
			#pragma target 3.0
			
			#pragma shader_feature _PARTICLE_EFFECTS_ON
			#pragma shader_feature _RIM_FADE_ON
			#pragma shader_feature _DISTANCE_FADE_ON
			
			#pragma vertex AlloyVertexParticle
			#pragma fragment AlloyFragmentParticle
			#pragma multi_compile_particles
			#pragma multi_compile_fog

			#include "UnityCG.cginc"
			#include "Assets/Alloy/Shaders/Framework/Particle.cginc"
			#include "Assets/Alloy/Shaders/Framework/Utility.cginc"
			
			half4 AlloyFragmentParticle(
				AlloyVertexOutputParticle i) : SV_Target
			{
				i.color.a *= AlloyFadeParticle(i);
				
				half4 prev = i.color * _TintColor * tex2D(_MainTex, i.uv_MainTex);
				prev *= AlloyParticleEffects(i);
				prev.rgb *= _TintWeight;
				half4 col = lerp(half4(1,1,1,1), prev, prev.a);
				UNITY_APPLY_FOG_COLOR(i.fogCoord, col, fixed4(1,1,1,1)); // fog towards white due to our blend mode
				col.rgb = AlloyHdrClamp(col.rgb);
				return col;
			}
			ENDCG 
		}
	}
}
CustomEditor "AlloyFieldBasedEditor"
}
