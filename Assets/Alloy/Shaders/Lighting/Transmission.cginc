// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file Transmission.cginc
/// @brief Transmission lighting model. Forward-only.
///////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_LIGHTING_TRANSMISSION_CGINC
#define ALLOY_LIGHTING_TRANSMISSION_CGINC

#define ALLOY_SURFACE_CUSTOM_DATA 	\
	half3 transmission;				\
	half transmissionDistortion;	\
	half transmissionPower;			\
	half transmissionShadowWeight;			

#include "Assets/Alloy/Shaders/Framework/Lighting.cginc"

void AlloyPreSurface(
	inout AlloySurfaceDesc s)
{
	s.transmission = 1.0h;
	s.transmissionDistortion = 0.1h;
	s.transmissionPower = 1.0h;
	s.transmissionShadowWeight = 0.0h;
}

void AlloyPostSurface(
	inout AlloySurfaceDesc s)
{
	AlloySetPbrData(s);
	AlloySetSpecularData(s);  
	s.transmission *= 1.0h - s.metallic;
}

half3 AlloyDirect( 
	AlloyDirectDesc d,
	AlloySurfaceDesc s)
{	
	half3 illum = 0.0h;		
	half3 H = normalize(d.direction + s.viewDirWorld);
	half LdotH = DotClamped(d.direction, H);
	half NdotH = DotClamped(s.normalWorld, H);
	half NdotL = DotClamped(s.normalWorld, d.direction);
	
	// Punctual light equation, with Cook-Torrance microfacet model.
	illum = (d.shadow * NdotL) * (
				AlloyDiffuseBrdf(s.albedo, s.roughness, LdotH, NdotL, s.NdotV)
				+ (s.specularOcclusion
					* AlloySpecularBrdf(s.f0, s.beckmannRoughness, LdotH, NdotH, NdotL, s.NdotV)));
	
	// Transmission 
	// cf http://www.farfarer.com/blog/2012/09/11/translucent-shader-unity3d/
	half3 transLightDir = d.direction + s.normalWorld * s.transmissionDistortion;
	half3 transLight = s.transmission * pow(DotClamped(s.viewDirWorld, -transLightDir), s.transmissionPower);
	
	illum += s.albedo * transLight * LerpOneTo(d.shadow, s.transmissionShadowWeight);
						
	return illum * d.color;
}

half3 AlloyIndirect(
	AlloyIndirectDesc i,
	AlloySurfaceDesc s)
{
	return AlloyIndirectBrdf(s.albedo, s.f0, s.roughness, s.ambientOcclusion, s.specularOcclusion, s.NdotV, i.diffuse, i.specular);
}

#endif // ALLOY_LIGHTING_TRANSMISSION_CGINC
