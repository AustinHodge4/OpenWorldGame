// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Particle.cginc
/// @brief Common particle functions and constants.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FRAMEWORK_PARTICLE_CGINC
#define ALLOY_FRAMEWORK_PARTICLE_CGINC

#include "Assets/Alloy/Shaders/Framework/Utility.cginc"

#include "UnityCG.cginc"
#include "UnityShaderVariables.cginc"
			
struct AlloyVertexDescParticle {
	float4 vertex : POSITION;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD0;
#if defined(_RIM_FADE_ON) || defined(ALLOY_ENABLE_PARTICLE_VERTEX_LIGHTS)
	half3 normal : NORMAL;
#endif
};

struct AlloyVertexOutputParticle {
	float4 vertex : SV_POSITION;
	float4 color : COLOR;
	float2 uv_MainTex : TEXCOORD0;
#ifdef _PARTICLE_EFFECTS_ON
	float2 uv_ParticleEffectMask1 : TEXCOORD1;
	float2 uv_ParticleEffectMask2 : TEXCOORD2;
#endif
	UNITY_FOG_COORDS(3)
#if defined(SOFTPARTICLES_ON) || defined(_DISTANCE_FADE_ON)
	float4 projPos : TEXCOORD4;
#endif
#if defined(_RIM_FADE_ON) || defined(ALLOY_ENABLE_PARTICLE_VERTEX_LIGHTS)
	half3 normalWorld : TEXCOORD5;
	half4 viewDirWorld : TEXCOORD6;
#endif
};
		
sampler2D_float _CameraDepthTexture;

half4 _TintColor;
ALLOY_SAMPLER2D_XFORM(_MainTex);	
half _TintWeight;
float _InvFade;

#ifdef _PARTICLE_EFFECTS_ON
	ALLOY_SAMPLER2D_XFORM(_ParticleEffectMask1);
	ALLOY_SAMPLER2D_XFORM(_ParticleEffectMask2);
#endif

#ifdef _RIM_FADE_ON
	half _RimFadeWeight; // Expects linear-space values
	half _RimFadePower;
#endif

float _DistanceFadeNearFadeCutoff;
float _DistanceFadeRange;

AlloyVertexOutputParticle AlloyVertexParticle(
	AlloyVertexDescParticle v)
{
	AlloyVertexOutputParticle o;
	UNITY_INITIALIZE_OUTPUT(AlloyVertexOutputParticle, o);
	
	o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
#if defined(SOFTPARTICLES_ON) || defined(_DISTANCE_FADE_ON)
	o.projPos = ComputeScreenPos (o.vertex);
	COMPUTE_EYEDEPTH(o.projPos.z);
#endif
	o.color = v.color;
	
#ifndef ALLOY_DISABLE_VERTEX_COLOR_DEGAMMA
	o.color.rgb = AlloyGammaToLinear(o.color.rgb);
#endif
	
	o.uv_MainTex = ALLOY_XFORM_TEX_SCROLL_SPIN(_MainTex, v.texcoord);
	
#ifdef _PARTICLE_EFFECTS_ON
    o.uv_ParticleEffectMask1 = ALLOY_XFORM_TEX_SCROLL_SPIN(_ParticleEffectMask1, v.texcoord);
	o.uv_ParticleEffectMask2 = ALLOY_XFORM_TEX_SCROLL_SPIN(_ParticleEffectMask2, v.texcoord);
#endif

#if defined(_RIM_FADE_ON) || defined(ALLOY_ENABLE_PARTICLE_VERTEX_LIGHTS)
	float4 positionWorld = mul(unity_ObjectToWorld, v.vertex);
	o.normalWorld = UnityObjectToWorldNormal(v.normal);
	o.viewDirWorld.xyz = UnityWorldSpaceViewDir(positionWorld.xyz);
#endif
	
#ifdef ALLOY_ENABLE_PARTICLE_VERTEX_LIGHTS			
	// Combine vertex lighting with color to save interpolator!	
	o.color.rgb *= (ShadeSH9(half4(o.normalWorld, 1.0h))
					+ AlloyVertexLights(positionWorld.xyz, o.normalWorld));
#endif
	
	UNITY_TRANSFER_FOG(o,o.vertex);
	return o;
}

/// Controls how the particle is faded out based on scene intersection, rim, 
/// and camera distance.
half AlloyFadeParticle(
	AlloyVertexOutputParticle i)
{
	half fade = 1.0h;

#ifdef SOFTPARTICLES_ON
	float sceneZ = DECODE_EYEDEPTH(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
	float partZ = i.projPos.z;
	fade = saturate(_InvFade * (sceneZ - partZ));
#endif
#ifdef _DISTANCE_FADE_ON
	// Alpha clip.
	// cf http://wiki.unity3d.com/index.php?title=AlphaClipsafe
	fade *= saturate((i.projPos.z - _DistanceFadeNearFadeCutoff) / _DistanceFadeRange);
#endif
#ifdef _RIM_FADE_ON
	half3 normal = normalize(i.normalWorld);
	half3 viewDir = normalize(i.viewDirWorld.xyz);
	half NdotV = abs(dot(normal, viewDir));
	half bias = 1.0h - _RimFadeWeight;
	fade *= AlloyRimLight(bias, _RimFadePower, 1.0h - NdotV);
#endif
	
	return fade;
}

/// Applies transforming effects mask textures to the particle.
half4 AlloyParticleEffects(
	AlloyVertexOutputParticle i)
{
	half4 color = half4(1.0h, 1.0h, 1.0h, 1.0h);
#ifdef _PARTICLE_EFFECTS_ON
	color *= tex2D(_ParticleEffectMask1, i.uv_ParticleEffectMask1);
	color *= tex2D(_ParticleEffectMask2, i.uv_ParticleEffectMask2);
#endif
	return color;
}

#endif // ALLOY_FRAMEWORK_PARTICLE_CGINC
