// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file TriPlanar.cginc
/// @brief TriPlanar texture mapping.
///////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FRAMEWORK_TRIPLANAR_CGINC
#define ALLOY_FRAMEWORK_TRIPLANAR_CGINC

#include "Assets/Alloy/Shaders/Framework/Surface.cginc"

/// The shared data for applying a TriPlanar terrain splat.
struct AlloyTriPlanarSplatDesc {
	/// X-axis TriPlanar tangent to world matrix.
	half3x3 xTangentToWorld;
	
	/// Y-axis TriPlanar tangent to world matrix.
	half3x3 yTangentToWorld;
	
	/// Z-axis TriPlanar tangent to world matrix.
	half3x3 zTangentToWorld;
	
	/// Blend weights between the top, middle, and bottom TriPlanar axis.
	half3 blendWeights;
	
	/// Position in either world or object-space.
	float4 position;
	
	/// World or object-space texture coordinates.
	float4 texcoords;
	
	/// Base color tint.
	/// Expects linear-space LDR color values.
	half3 tint;
	
	/// Interpolates material from dielectric to metal.
	/// Expects values in the range [0,1].
	half metallic;
	
	/// Linear control of dielectric f0 from [0.00,0.08].
	/// Expects values in the range [0,1].
	half specularity;
	
#ifndef ALLOY_ENABLE_FULL_TRIPLANAR
	/// Tints the dielectric specularity by the base color chromaticity.
	/// Expects values in the range [0,1].
	half specularTint;
#endif
	
	/// Linear roughness value, where zero is smooth and one is rough.
	/// Expects values in the range [0,1].
	half roughness;
	
	/// Splat mask.
	half mask;
};

/// Extracts vertex data from a surface object into a TriPlanar splat object.
/// @param	s			Material surface data.
/// @param	sharpness	Sharpness of the border blend between TriPlanar axis.
/// @return 			Initialized TriPlanar object.
AlloyTriPlanarSplatDesc AlloyTriPlanarSplatDescInit(
	AlloySurfaceDesc s,
	half sharpness) 
{
	AlloyTriPlanarSplatDesc tr;
	UNITY_INITIALIZE_OUTPUT(AlloyTriPlanarSplatDesc, tr);
	
	// Triplanar mapping
	// cf http://www.gamedev.net/blog/979/entry-2250761-triplanar-texturing-and-normal-mapping/
#ifdef _TRIPLANARMODE_WORLD
	tr.position = float4(s.positionWorld, 1.0f);
	half3 geoNormal = s.normalWorld;
#else
	tr.position = mul(unity_WorldToObject, float4(s.positionWorld, 1.0f));
	half3 geoNormal = mul((half3x3)unity_WorldToObject, s.normalWorld);
#endif

	// Unity uses a Left-handed axis, so it requires clumsy remapping.
	tr.xTangentToWorld = half3x3(half3(0.0h, 0.0h, 1.0h), half3(0.0h, 1.0h, 0.0h), geoNormal);
	tr.yTangentToWorld = half3x3(half3(1.0h, 0.0h, 0.0h), half3(0.0h, 0.0h, 1.0h), geoNormal);
	tr.zTangentToWorld = half3x3(half3(1.0h, 0.0h, 0.0h), half3(0.0h, 1.0h, 0.0h), geoNormal);
	
	half3 blending = abs(geoNormal);
	blending = normalize(max(blending, ALLOY_EPSILON));
	blending = pow(blending, sharpness);
	blending /= dot(blending, half3(1.0h, 1.0h, 1.0h));
	tr.blendWeights = blending;
	
	return tr;
}

/// Applies a TriPlanar splat axis onto a surface.
/// @param[in,out]	s			Material surface data.
/// @param[in]		tr			TriPlanar splat data.
/// @param[in]		baseColor	Splat base color texture.
/// @param[in]		bump		Splat normal map.
/// @param[in]		tbn			TriPlanar axis tangent to world matrix.
/// @param[in]		uv			TriPlanar axis texture coordinates.
/// @param[in]		mask		Splatmap mask.
void AlloyTriplanarSplatAxis(
	inout AlloySurfaceDesc s,
	AlloyTriPlanarSplatDesc tr,
	sampler2D baseColor,
	sampler2D bump,
	half3x3 tbn,
	float2 uv,
	half mask)
{
	half4 base2 = tex2D(baseColor, uv);
	base2.rgb *= tr.tint;
	s.baseColor += mask * base2.rgb;
     
    half4 material2 = 1.0h; 
    material2.w *= base2.a;
	s.ambientOcclusion += mask;
#ifndef ALLOY_ENABLE_FULL_TRIPLANAR
    s.specularTint += mask * tr.specularTint;
#endif
	s.metallic += mask * tr.metallic * material2.x;
	s.specularity += mask * tr.specularity * material2.z;
	s.roughness += mask * tr.roughness * material2.w;

	half3 normal = UnpackScaleNormal(tex2D(bump, uv), 1.0h);
	s.normalWorld += mask * mul(normal, tbn);
}

/// Applies a TriPlanar splat onto a surface.
/// @param[in,out]	s			Material surface data.
/// @param[in]		tr			TriPlanar splat data.
/// @param[in]		baseColor	Splat base color texture.
/// @param[in]		bump		Splat normal map.
void AlloyTriplanarSplat(
	inout AlloySurfaceDesc s,
	AlloyTriPlanarSplatDesc tr,
	sampler2D baseColor,
	sampler2D bump) 
{	
	half3 blendWeights = tr.blendWeights * tr.mask;

	AlloyTriplanarSplatAxis(
		s, 
		tr, 
		baseColor,
		bump,
		tr.xTangentToWorld,
		tr.texcoords.xy * tr.position.zy + tr.texcoords.zw,
		blendWeights.x);
		
	AlloyTriplanarSplatAxis(
		s, 
		tr, 
		baseColor,
		bump,
		tr.yTangentToWorld,
		tr.texcoords.xy * tr.position.xz + tr.texcoords.zw,
		blendWeights.y);
		
	AlloyTriplanarSplatAxis(
		s, 
		tr, 
		baseColor,
		bump,
		tr.zTangentToWorld,
		tr.texcoords.xy * tr.position.xy + tr.texcoords.zw,
		blendWeights.z);
}

#endif // ALLOY_FRAMEWORK_TRIPLANAR_CGINC
