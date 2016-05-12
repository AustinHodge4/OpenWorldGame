// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file Eyeball.cginc
/// @brief Eyeball lighting model. Forward-only.
///////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_LIGHTING_EYEBALL_CGINC
#define ALLOY_LIGHTING_EYEBALL_CGINC

#define ALLOY_ENABLE_VIEW_VECTOR_TANGENT
#define ALLOY_PARALLAXMAP_CHANNEL w

#define ALLOY_SURFACE_CUSTOM_DATA 	\
	half scattering;				\
	half irisMask; 					\
	half corneaSpecularity;			\
	half corneaRoughness;			\
									\
	half3 corneaNormalWorld; 		\
	half3 irisF0; 					\
	half irisSpecularOcclusion; 	\
	half irisRoughness; 			\
	half irisBeckmannRoughness; 	\
	half irisNdotV;

#include "Assets/Alloy/Shaders/Framework/Lighting.cginc"

/// Implements a scattering diffuse BRDF affected by roughness.
/// @param 	albedo 		Diffuse albedo LDR color.
/// @param 	subsurface 	Blend value between diffuse and scattering [0,1].
/// @param 	roughness 	Linear roughness [0,1].
/// @param 	LdotH 		Light and half-angle clamped dot product [0,1].
/// @param 	NdotL 		Normal and light clamped dot product [0,1].
/// @param 	NdotV 		Normal and view clamped dot product [0,1].
/// @return				Direct diffuse BRDF.
half3 AlloyDiffuseBssrdf(
	half3 albedo,
	half subsurface,
	half roughness,
	half LdotH,
	half NdotL,
	half NdotV)
{
	// Impelementation of Brent Burley's diffuse scattering BRDF.
	// Subject to Apache License, version 2.0
	// cf https://github.com/wdas/brdf/blob/master/src/brdfs/disney.brdf
	half FL = AlloyFresnel(NdotL);
	half FV = AlloyFresnel(NdotV);
	half Fss90 = LdotH * LdotH * roughness;
	half Fd90 = 0.5h + (2.0h * Fss90);
	half Fd = LerpOneTo(Fd90, FL) * LerpOneTo(Fd90, FV);
	half Fss = LerpOneTo(Fss90, FL) * LerpOneTo(Fss90, FV);
    half ss = 1.25h * (Fss * (1.0h / max(NdotL + NdotV, ALLOY_EPSILON) - 0.5h) + 0.5h);
	
	// Pi is cancelled by implicit punctual lighting equation.
	// cf http://seblagarde.wordpress.com/2012/01/08/pi-or-not-to-pi-in-game-lighting-equation/
	return albedo * lerp(Fd, ss, subsurface);
}

void AlloyPreSurface(
	inout AlloySurfaceDesc s)
{
	s.scattering = 0.0h;
	s.irisMask = 0.0h;
	s.corneaSpecularity = 0.36h;
	s.corneaRoughness = 0.0h;
}

void AlloyPostSurface(
	inout AlloySurfaceDesc s)
{
	// Tint the iris specular to fake caustics.
	// cf http://game.watch.impress.co.jp/docs/news/20121129_575412.html
	AlloySetPbrData(s);

	// Iris & Sclera
	s.irisNdotV = s.NdotV; 
	s.irisSpecularOcclusion = AlloySpecularOcclusion(s.ambientOcclusion, s.irisNdotV);
	s.irisF0 = s.f0;
	s.irisRoughness = s.roughness;
	s.irisBeckmannRoughness = AlloyConvertRoughness(s.irisRoughness);

	// Cornea
	half3 corneaNormal = lerp(s.normalTangent, ALLOY_FLAT_NORMAL, s.irisMask);
	s.corneaNormalWorld = ALLOY_XFORM_NORMAL(s, corneaNormal);

	s.reflectionVectorWorld = reflect(-s.viewDirWorld, s.corneaNormalWorld);
	s.NdotV = DotClamped(s.corneaNormalWorld, s.viewDirWorld);
	
	s.specularOcclusion = lerp(s.irisSpecularOcclusion, 1.0h, s.irisMask);
	s.f0 = lerp(s.f0, AlloySpecularityToF0(s.corneaSpecularity), s.irisMask);
	s.roughness = lerp(s.roughness, s.corneaRoughness, s.irisMask);
	s.beckmannRoughness = AlloyConvertRoughness(s.roughness);
}

half3 AlloyDirect( 
	AlloyDirectDesc d,
	AlloySurfaceDesc s)
{
	half3 illum = 0.0h;
	half3 H = normalize(d.direction + s.viewDirWorld);
	half LdotH = DotClamped(d.direction, H);
	
	// Iris & Sclera
	half NdotH = DotClamped(s.normalWorld, H);
	half NdotL = DotClamped(s.normalWorld, d.direction);
		
	illum = NdotL * (
				AlloyDiffuseBssrdf(s.albedo, s.scattering, s.irisRoughness, LdotH, NdotL, s.irisNdotV)
				+ (s.irisSpecularOcclusion * AlloyAreaLightNormalization(s.irisBeckmannRoughness, d.solidAngle)
					* AlloySpecularBrdf(s.irisF0, s.irisBeckmannRoughness, LdotH, NdotH, NdotL, s.irisNdotV)));
						
	// Cornea
	NdotH = DotClamped(s.corneaNormalWorld, H);
	NdotL = DotClamped(s.corneaNormalWorld, d.direction);
	
	illum += (s.irisMask * NdotL * s.specularOcclusion) 
				* AlloySpecularBrdf(s.f0, s.beckmannRoughness, LdotH, NdotH, NdotL, s.NdotV);
	
	return illum * d.color * d.shadow;
}

half3 AlloyIndirect(
	AlloyIndirectDesc i,
	AlloySurfaceDesc s)
{
	return AlloyIndirectBrdf(s.albedo, s.f0, s.roughness, s.ambientOcclusion, s.specularOcclusion, s.NdotV, i.diffuse, i.specular);
}

#endif // ALLOY_LIGHTING_EYEBALL_CGINC
