// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file Standard.cginc
/// @brief Standard lighting model. Deferred+Forward.
///////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_LIGHTING_STANDARD_CGINC
#define ALLOY_LIGHTING_STANDARD_CGINC

#define ALLOY_SURFACE_CUSTOM_DATA 	\
	half materialId;				
	
#include "Assets/Alloy/Shaders/Framework/Lighting.cginc"

void AlloyPreSurface(
	inout AlloySurfaceDesc s)
{

}

void AlloyPostSurface(
	inout AlloySurfaceDesc s)
{
	AlloySetPbrData(s);
	AlloySetSpecularData(s); 
}

half4 AlloyGbuffer(
	AlloySurfaceDesc s,
	out half4 diffuseAo,
	out half4 specSmoothness,
	out half4 normalId)
{
	diffuseAo = half4(s.albedo, s.ambientOcclusion);
	specSmoothness = half4(s.f0, 1.0h - s.roughness);
	normalId = half4(s.normalWorld * 0.5h + 0.5h, 1.0h);
	return half4(s.emission, 1.0h);
}

half3 AlloyDirect( 
	AlloyDirectDesc d,
	AlloySurfaceDesc s)
{	
	half3 H = normalize(d.direction + s.viewDirWorld);
	half LdotH = DotClamped(d.direction, H);
	half NdotH = DotClamped(s.normalWorld, H);
	half NdotL = DotClamped(s.normalWorld, d.direction);
	
	// Punctual light equation, with Cook-Torrance microfacet model.
	return d.color * (d.shadow * NdotL) * (
			AlloyDiffuseBrdf(s.albedo, s.roughness, LdotH, NdotL, s.NdotV)
			+ (s.specularOcclusion
				* AlloySpecularBrdf(s.f0, s.beckmannRoughness, LdotH, NdotH, NdotL, s.NdotV)));
}

half3 AlloyIndirect(
	AlloyIndirectDesc i,
	AlloySurfaceDesc s)
{
	return AlloyIndirectBrdf(s.albedo, s.f0, s.roughness, s.ambientOcclusion, s.specularOcclusion, s.NdotV, i.diffuse, i.specular);
}

#endif // ALLOY_LIGHTING_STANDARD_CGINC
