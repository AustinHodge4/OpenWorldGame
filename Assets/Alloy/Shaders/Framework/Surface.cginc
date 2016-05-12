// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Surface.cginc
/// @brief SurfaceDesc structure, and related methods.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FRAMEWORK_SURFACE_CGINC
#define ALLOY_FRAMEWORK_SURFACE_CGINC

#include "Assets/Alloy/Shaders/Config.cginc"
#include "Assets/Alloy/Shaders/Framework/Brdf.cginc"
#include "Assets/Alloy/Shaders/Framework/Utility.cginc"

#include "HLSLSupport.cginc"
#include "UnityCG.cginc"
#include "UnityStandardBRDF.cginc"
#include "UnityStandardUtils.cginc"

/// Maximum linear-space surface specular reflectivity.
#define ALLOY_MAX_DIELECTRIC_F0 (0.08h)

/// Minimum roughness that won't cause area light specular artifacts.
#define ALLOY_MIN_AREA_ROUGHNESS (0.05h)

#ifndef ALLOY_SURFACE_CUSTOM_DATA
	#define ALLOY_SURFACE_CUSTOM_DATA
#endif

#if defined(UNITY_PASS_SHADOWCASTER) || defined(UNITY_PASS_META)
	#define ALLOY_XFORM_NORMAL(s, normalTangent) s.tangentToWorld[2].xyz
#else
	#define ALLOY_XFORM_NORMAL(s, normalTangent) normalize(mul(normalTangent, s.tangentToWorld))
#endif

/// Picks either UV0 or UV1.
#define ALLOY_XFORM_UV(name, s) ((name##UV < 0.5f) ? s.uv01.xy : s.uv01.zw)

/// Applies Unity texture transforms plus UV-switching effect.
#define ALLOY_XFORM_TEX_UV(name, s) (TRANSFORM_TEX(ALLOY_XFORM_UV(name, s), name))

/// Applies Unity texture transforms plus UV-switching and our scrolling effects.
#define ALLOY_XFORM_TEX_UV_SCROLL(name, s) (ALLOY_XFORM_TEX_SCROLL(name, ALLOY_XFORM_UV(name, s)))

/// Contains ALL data and state for rendering a surface.
/// Can set state to control how features are combined into the surface data.
struct AlloySurfaceDesc 
{
	/////////////////////////////////////////////////////////////////////////////
	// Vertex Inputs.
	/////////////////////////////////////////////////////////////////////////////
	
	/// Unity's fog data.
	float fogCoord;

	/// The model's UV0 & UV1 texture coordinate data.
	/// Be aware that it can have parallax precombined with it.
	float4 uv01;
		
	/// Tangent space to World space rotation matrix.
	half3x3 tangentToWorld;

	/// Position in world space.
	float3 positionWorld;
		
	/// View direction in world space.
	/// Expects a normalized vector.
	half3 viewDirWorld;
		
	/// View direction in tangent space.
	/// Expects a normalized vector.
	half3 viewDirTangent;
	
	/// Distance from the camera to the given fragement.
	/// Expects values in the range [0,n].
	half viewDepth;
	
	/// Vertex color.
	/// Expects linear-space LDR color values.
	half4 vertexColor;


	/////////////////////////////////////////////////////////////////////////////
	// Feature layering options.
	/////////////////////////////////////////////////////////////////////////////
	
	/// Masks where the next feature layer will be applied.
	/// Expects values in the range [0,1].
	half mask;
		
	/// The base map's texture transform tiling amount.
	float2 baseTiling;
		
	/// Transformed texture coordinates for the base map.
	/// Be aware that it can have parallax precombined with it.
	float2 baseUv;
	
#ifdef _VIRTUALTEXTURING_ON
	/// Stores the virtual texture coordinates.
	VirtualCoord baseVirtualCoord;
#endif


	/////////////////////////////////////////////////////////////////////////////
	// Material data.
	/////////////////////////////////////////////////////////////////////////////
	
	/// Controls opacity or cutout regions.
	/// Expects values in the range [0,1].
	half opacity;
		
	/// Diffuse ambient occlusion.
	/// Expects values in the range [0,1].
	half ambientOcclusion;
	
	/// Albedo and/or Metallic f0 based on settings. Used by Enlighten.
	/// Expects linear-space LDR color values.
	half3 baseColor;
	
	/// Linear control of dielectric f0 from [0.00,0.08].
	/// Expects values in the range [0,1].
	half specularity;
	
#ifdef ALLOY_ENABLE_SURFACE_SPECULAR_TINT
	/// Tints the dielectric specularity by the base color chromaticity.
	/// Expects values in the range [0,1].
	half specularTint;
#endif
#ifdef ALLOY_ENABLE_SURFACE_CLEARCOAT
	/// Strength of clearcoat layer, used to apply masks.
	/// Expects values in the range [0,1].
	half clearCoatWeight;
	
	/// Roughness of clearcoat layer.
	/// Expects values in the range [0,1].
	half clearCoatRoughness;
#endif
	
	/// Interpolates material from dielectric to metal.
	/// Expects values in the range [0,1].
	half metallic;
		
	/// Linear roughness value, where zero is smooth and one is rough.
	/// Expects values in the range [0,1].
	half roughness;
	
	/// Normal in tangent space.
	/// Expects a normalized vector.
	half3 normalTangent;
	
	/// Light emission by the material. Used by Enlighten.
	/// Expects linear-space HDR color values.
	half3 emission;


	/////////////////////////////////////////////////////////////////////////////
	// Lighting inputs.
	/////////////////////////////////////////////////////////////////////////////
	
	/// Diffuse albedo.
	/// Expects linear-space LDR color values.
	half3 albedo;
	
	/// Fresnel reflectance at incidence zero.
	/// Expects linear-space LDR color values.
	half3 f0;
	
	/// Beckmann roughness.
	/// Expects values in the range [0,1].
	half beckmannRoughness;
	
	/// Specular occlusion.
	/// Expects values in the range [0,1].
	half specularOcclusion;
	
	/// Normal in world space.
	/// Expects normalized vectors in the range [-1,1].
	half3 normalWorld;
	
	/// View reflection vector in world space.
	/// Expects a non-normalized vector.
	half3 reflectionVectorWorld;
	
	/// Clamped N.V.
	/// Expects values in the range [0,1].
	half NdotV;
	
	ALLOY_SURFACE_CUSTOM_DATA
};

/// Used to create a surface data object with suitable default values. 
/// @return Initialized surface data object.
AlloySurfaceDesc AlloySurfaceDescInit()
{
	AlloySurfaceDesc s;
	UNITY_INITIALIZE_OUTPUT(AlloySurfaceDesc, s);
	
	s.mask = 1.0h;
	s.opacity = 1.0h;
	s.baseColor = 1.0h;
#ifdef ALLOY_ENABLE_SURFACE_SPECULAR_TINT
	s.specularTint = 0.0h;
#endif
#ifdef ALLOY_ENABLE_SURFACE_CLEARCOAT
	s.clearCoatWeight = 0.0h;
	s.clearCoatRoughness = 0.0h;
#endif
	s.metallic = 0.0h;
	s.specularity = 0.5h;
	s.roughness = 1.0h; 
	s.emission = 0.0h;
	s.ambientOcclusion = 1.0h;
	s.normalTangent = ALLOY_FLAT_NORMAL;
	
	return s;
}

/// Zeroes out the material properties of the sruface. 
/// @param[in,out]	s	Material surface data.
void AlloySurfaceZeroMaterial(
	inout AlloySurfaceDesc s) 
{
	s.baseColor = 0.0h;
	s.metallic = 0.0h;
	s.ambientOcclusion = 0.0h;
	s.specularity = 0.0h;
#ifdef ALLOY_ENABLE_SURFACE_SPECULAR_TINT
	s.specularTint = 0.0h;
#endif
#ifdef ALLOY_ENABLE_SURFACE_CLEARCOAT
	s.clearCoatWeight = 0.0h;
	s.clearCoatRoughness = 0.0h;
#endif
	s.roughness = 0.0h;
	s.emission = 0.0h;
	s.normalTangent = 0.0h;
	s.normalWorld = 0.0h;
}

/// Calculates the fresnel at incidence zero from the normalized specularity.
/// @param	specularity	Normalized specularity [0,1].
/// @return				F0 [0,0.08].
half3 AlloySpecularityToF0(
	half specularity)
{
	return (specularity * ALLOY_MAX_DIELECTRIC_F0).rrr;
}

/// Sets PBR material inputs for the lighting function.
/// @param[in,out]	s	Material surface data.
void AlloySetPbrData(
	inout AlloySurfaceDesc s) 
{
	half metallicInv = 1.0h - s.metallic;
	half3 dielectricF0 = AlloySpecularityToF0(s.specularity);
	
	// Ensures energy-conserving color when using weird detail modes.
	half3 baseColor = min(s.baseColor, half3(1.0h, 1.0h, 1.0h)); 
	
#ifdef ALLOY_ENABLE_SURFACE_SPECULAR_TINT
	// Brent Burley's approach to tinted dielectric specular.
	// Subject to Apache License, version 2.0
	// cf https://github.com/wdas/brdf/blob/master/src/brdfs/disney.brdf
	half3 tint = AlloyChromaticity(baseColor);
	dielectricF0 *= LerpWhiteTo(tint, s.specularTint);
#endif
	
	s.albedo = baseColor * metallicInv;
	s.f0 = lerp(dielectricF0, baseColor, s.metallic);
	
#ifdef ALLOY_ENABLE_SURFACE_CLEARCOAT
	// Specularity of 0.5 gives us a polyurethane like coating.
	s.f0 += AlloySpecularityToF0(0.5h * s.clearCoatWeight);
	s.f0 = min(s.f0, half3(1.0h, 1.0h, 1.0h)); 
	s.roughness = lerp(s.roughness, s.clearCoatRoughness, s.clearCoatWeight);
#endif
#ifdef _ALPHAPREMULTIPLY_ON
	// Interpolate from a translucent dielectric to an opaque metal.
	s.opacity = s.metallic + metallicInv * s.opacity;
	
	// Premultiply opacity with albedo for translucent shaders.
	s.albedo *= s.opacity;
#endif
}

/// Convert linear roughness to Beckmann roughness.
/// @param 	roughness 	Linear roughness [0,1].
/// @return				Beckmann Roughness.
half AlloyConvertRoughness(
	half roughness)
{
	// Remap to [0.05,1] to prevent specular artifacts.
	roughness = lerp(ALLOY_MIN_AREA_ROUGHNESS, 1.0h, roughness); 
	return roughness * roughness;
}

/// Calculates lighting inputs that are required for specular.
/// @param[in,out]	s	Material surface data.
void AlloySetSpecularData(
	inout AlloySurfaceDesc s) 
{
	s.beckmannRoughness = AlloyConvertRoughness(s.roughness);
	s.reflectionVectorWorld = reflect(-s.viewDirWorld, s.normalWorld);
	s.specularOcclusion = AlloySpecularOcclusion(s.ambientOcclusion, s.NdotV); 
}

#endif // ALLOY_FRAMEWORK_SURFACE_CGINC
