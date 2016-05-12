// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file StandardTransmission.cginc
/// @brief Standard lighting model with simple transmission. Deferred+Forward.
///////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_LIGHTING_STANDARD_TRANSMISSION_CGINC
#define ALLOY_LIGHTING_STANDARD_TRANSMISSION_CGINC

#define ALLOY_SURFACE_CUSTOM_DATA 	\
	half transmission;				\
	half materialId;				

#include "Assets/Alloy/Shaders/Framework/Lighting.cginc"

half _DeferredTransmissionWeight;
half _DeferredTransmissionFalloff;
half _DeferredTransmissionBumpDistortion;
half _DeferredTransmissionAmbient;
half _DeferredTransmissionShadowWeight;

void AlloyPreSurface(
	inout AlloySurfaceDesc s)
{
	s.transmission = 0.0h;
	s.materialId = 1.0h;
}

void AlloyPostSurface(
	inout AlloySurfaceDesc s)
{
	AlloySetPbrData(s);
	AlloySetSpecularData(s); 
	s.transmission *= 1.0h - s.metallic;
}

half4 AlloyGbuffer(
	AlloySurfaceDesc s,
	out half4 diffuseAo,
	out half4 specSmoothness,
	out half4 normalId)
{
	diffuseAo = half4(s.albedo, s.ambientOcclusion);
	specSmoothness = half4(s.f0, 1.0h - s.roughness);
	normalId = half4(s.normalWorld * 0.5h + 0.5h, s.materialId);
	return half4(s.emission, 1.0h - s.transmission);
}

half3 AlloyDirect( 
	AlloyDirectDesc d,
	AlloySurfaceDesc s)
{	
	half3 illum;
	half3 H = normalize(d.direction + s.viewDirWorld);
	half LdotH = DotClamped(d.direction, H);
	half NdotH = DotClamped(s.normalWorld, H);
	half NdotL = DotClamped(s.normalWorld, d.direction);
	
	// Punctual light equation, with Cook-Torrance microfacet model.
	illum = (d.shadow * NdotL) * (
			AlloyDiffuseBrdf(s.albedo, s.roughness, LdotH, NdotL, s.NdotV)
			+ (s.specularOcclusion
				* AlloySpecularBrdf(s.f0, s.beckmannRoughness, LdotH, NdotH, NdotL, s.NdotV)));
				
//	// Skin
//	// Sample blurred normals.
//	// Look up and apply lighting.
//	//color.rgb = tex2D(_DeferredBlurredNormalBuffer, uv).rgb;
	
	// Transmission 
	// cf http://www.farfarer.com/blog/2012/09/11/translucent-shader-unity3d/
	half3 transmissionColor = (_DeferredTransmissionWeight * s.transmission).rrr;
	
	// TODO: Apply skin depth absorption tint.
	
	half3 transLightDir = d.direction + s.normalWorld * _DeferredTransmissionBumpDistortion;
	half transLight = pow(DotClamped(s.viewDirWorld, -transLightDir), _DeferredTransmissionFalloff);
	
	transLight *= LerpOneTo(d.shadow, _DeferredTransmissionShadowWeight);
	transLight += _DeferredTransmissionAmbient;
	illum.rgb += s.albedo * transmissionColor * transLight;

	return d.color * illum;
}

half3 AlloyIndirect(
	AlloyIndirectDesc i,
	AlloySurfaceDesc s)
{
	return AlloyIndirectBrdf(s.albedo, s.f0, s.roughness, s.ambientOcclusion, s.specularOcclusion, s.NdotV, i.diffuse, i.specular);
}

#endif // ALLOY_LIGHTING_STANDARD_TRANSMISSION_CGINC
