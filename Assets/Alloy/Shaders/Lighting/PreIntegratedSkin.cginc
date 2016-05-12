// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file PreIntegratedSkin.cginc
/// @brief Pre-Integrated Skin lighting model. Forward-only.
///////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_LIGHTING_PRE_INTEGRATED_SKIN_CGINC
#define ALLOY_LIGHTING_PRE_INTEGRATED_SKIN_CGINC

// Jon Moore recommended this value in his blog post.
#define ALLOY_SKIN_BUMP_BLUR_BIAS 3.0

// NOTE: The example shader used calculated curvature, but it looked terrible. 
// We're using a translucency map, and getting much better results.
#define ALLOY_SURFACE_CUSTOM_DATA 	\
	half skinMask;					\
	half occlusionSaturation;		\
	half scattering;				\
	half transmissionDistortion;	\
	half transmissionPower;			\
	half3 transmission;				\
	half3 blurredNormalTangent;		\
									\
	half3 sharpNormalWorld;			

#include "Assets/Alloy/Shaders/Framework/Lighting.cginc"

sampler2D _SssBrdfTex;

void AlloyPreSurface(
	inout AlloySurfaceDesc s)
{
	s.skinMask = 1.0h;
	s.occlusionSaturation = 0.5h;
	s.scattering = 1.0h;
	s.transmission = 0.1h;
	s.transmissionDistortion = 0.1h;
	s.transmissionPower = 1.0h;
	s.blurredNormalTangent = ALLOY_FLAT_NORMAL;
}

void AlloyPostSurface(
	inout AlloySurfaceDesc s)
{
	// Sharp normals for specular & reflections.
	AlloySetPbrData(s);
	AlloySetSpecularData(s);
		
	// Blurred normals for diffuse.
	s.sharpNormalWorld = s.normalWorld;
	s.normalWorld = ALLOY_XFORM_NORMAL(s, s.blurredNormalTangent);  
}

half3 AlloyDirect( 
	AlloyDirectDesc d,
	AlloySurfaceDesc s)
{
	half3 illum = 0.0h;
	half3 H = normalize(d.direction + s.viewDirWorld);
	half LdotH = DotClamped(d.direction, H);
	half NdotH = DotClamped(s.sharpNormalWorld, H);
	half NdotL = DotClamped(s.sharpNormalWorld, d.direction);
	
	// Punctual light equation, with Cook-Torrance microfacet model.
	illum = (d.shadow * NdotL) * (
				AlloyDiffuseBrdf(s.albedo, s.roughness, LdotH, NdotL, s.NdotV) * (1.0h - s.skinMask) 
				+ (s.specularOcclusion
					* AlloySpecularBrdf(s.f0, s.beckmannRoughness, LdotH, NdotH, NdotL, s.NdotV)));
	
	// Scattering
	// cf http://www.farfarer.com/blog/2013/02/11/pre-integrated-skin-shader-unity-3d/
	float ndlBlur = dot(s.normalWorld, d.direction) * 0.5h + 0.5h;
	float2 sssLookupUv = float2(ndlBlur, s.scattering * AlloyLuminance(d.color));
	half3 sss = tex2D(_SssBrdfTex, sssLookupUv).rgb;	
		
#if !defined(SHADOWS_SCREEN) && !defined(SHADOWS_DEPTH) && !defined(SHADOWS_CUBE)
	// If shadows are off, we need to reduce the brightness
	// of the scattering on polys facing away from the light.		
	sss *= saturate(ndlBlur * 4.0h - 1.0h); // [-1,3], then clamp
#else
	sss *= d.shadow;
#endif
		
	// Transmission 
	// cf http://www.farfarer.com/blog/2012/09/11/translucent-shader-unity3d/
	half3 transLightDir = d.direction + s.normalWorld * s.transmissionDistortion;
	half3 transLight = s.transmission * pow(DotClamped(s.viewDirWorld, -transLightDir), s.transmissionPower);
										
	illum += s.albedo * (sss + transLight) * s.skinMask;
					
	return illum * d.color;
}

half3 AlloyIndirect(
	AlloyIndirectDesc i,
	AlloySurfaceDesc s)
{	
	// Saturated AO.
	// cf http://www.iryoku.com/downloads/Next-Generation-Character-Rendering-v6.pptx pg110
	half saturation = s.skinMask * s.occlusionSaturation;
	half3 saturatedAlbedo = pow(s.albedo, (1.0h + saturation) - saturation * s.ambientOcclusion);
	
	return AlloyIndirectBrdf(saturatedAlbedo, s.f0, s.roughness, s.ambientOcclusion, s.specularOcclusion, s.NdotV, i.diffuse, i.specular);
}

#endif // ALLOY_LIGHTING_PRE_INTEGRATED_SKIN_CGINC
