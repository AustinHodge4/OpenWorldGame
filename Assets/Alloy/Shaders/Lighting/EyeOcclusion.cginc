// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file EyeOcclusion.cginc
/// @brief EyeOcclusion lighting model. Forward-only.
///////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_LIGHTING_EYE_OCCLUSION_CGINC
#define ALLOY_LIGHTING_EYE_OCCLUSION_CGINC

#define ALLOY_DISABLE_REFLECTION_PROBES

#include "Assets/Alloy/Shaders/Framework/Lighting.cginc"

void AlloyPreSurface(
	inout AlloySurfaceDesc s)
{

}

void AlloyPostSurface(
	inout AlloySurfaceDesc s)
{
	s.specularOcclusion = AlloySpecularOcclusion(s.ambientOcclusion, s.NdotV);
	s.opacity *= (1.0h - s.specularOcclusion);
}

half3 AlloyDirect( 
	AlloyDirectDesc d,
	AlloySurfaceDesc s)
{
	half NdotL = DotClamped(s.normalWorld, d.direction);
	return d.color * (d.shadow * NdotL * s.ambientOcclusion) * s.albedo;
}

half3 AlloyIndirect(
	AlloyIndirectDesc i,
	AlloySurfaceDesc s)
{
	return i.diffuse * s.ambientOcclusion * s.albedo;
}

#endif // ALLOY_LIGHTING_EYE_OCCLUSION_CGINC
