// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Decal.cginc
/// @brief Handles vertex-weighted alpha-blended decals.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FEATURES_DECAL_CGINC
#define ALLOY_FEATURES_DECAL_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef _DECAL_ON
	/// The decal tint color.
	/// Expects a linear LDR color with alpha.
	half4 _DecalColor;
	
	/// Decal texture.
	/// Expects an RGBA map with sRGB sampling.
	ALLOY_SAMPLER2D_XFORM(_DecalTex);
	
	/// Weight of the decal effect.
    /// Expects values in the range [0,1].
	half _DecalWeight;
		
	/// The specularity that will be applied over the decal.
    /// Expects values in the range [0,1].
	half _DecalSpecularity;
	
	/// Toggles tinting the decal alpha by the vertex alpha.
	/// Expects either 0 or 1.
	half _DecalAlphaVertexTint;
#endif

/// Applies the Decal feature to the given material data.
/// @param[in,out]	s	Material surface data.
void AlloyDecal(
	inout AlloySurfaceDesc s)
{
#ifdef _DECAL_ON
	float2 detailUv = ALLOY_XFORM_TEX_UV(_DecalTex, s);
	half4 decal = _DecalColor * tex2D(_DecalTex, detailUv);
	half weight = s.mask * _DecalWeight * decal.a * LerpOneTo(s.vertexColor.a, _DecalAlphaVertexTint);
	
	s.baseColor = lerp(s.baseColor, decal.rgb, weight);
	s.metallic *= (1.0h - weight);
	s.specularity = lerp(s.specularity, _DecalSpecularity, weight);
#endif 
} 

#endif // ALLOY_FEATURES_DECAL_CGINC
