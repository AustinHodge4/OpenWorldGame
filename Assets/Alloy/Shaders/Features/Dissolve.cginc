// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Dissolve.cginc
/// @brief Surface dissolve effects.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FEATURES_DISSOLVE_CGINC
#define ALLOY_FEATURES_DISSOLVE_CGINC

#ifndef ALLOY_ENABLE_SURFACE_IN_SHADOW_PASS
	#define ALLOY_ENABLE_SURFACE_IN_SHADOW_PASS
#endif

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef _DISSOLVE_ON
	/// Dissolve glow tint color.
	/// Expects a linear HDR color with alpha.
	half4 _DissolveGlowColor; 
	
	/// Dissolve glow color with effect ramp in the alpha.
	/// Expects an RGBA map with sRGB sampling.
	ALLOY_SAMPLER2D_XFORM(_DissolveTex);
	
	/// The cutoff value for the dissolve effect in the ramp map.
    /// Expects values in the range [0,1].
	half _DissolveCutoff;
	
	/// The weight of the dissolve glow effect.
	/// Expects linear space value in the range [0,1].
	half _DissolveGlowWeight;
	
	/// The width of the dissolve glow effect.
    /// Expects values in the range [0,1].
	half _DissolveEdgeWidth;
#endif

/// Applies the Dissolve feature to the given material data.
/// @param[in,out]	s	Material surface data.
void AlloyDissolve(
	inout AlloySurfaceDesc s) 
{
#ifdef _DISSOLVE_ON
	float2 dissolveUv = ALLOY_XFORM_TEX_UV(_DissolveTex, s);
	half4 dissolveBase = _DissolveGlowColor * tex2D(_DissolveTex, dissolveUv);
	half dissolveCutoff = s.mask * _DissolveCutoff * 1.01h;
	half clipval = dissolveBase.a - dissolveCutoff;	
	
	clip(clipval); // NOTE: Eliminates need for blend edge.
	
	// Dissolve glow
	s.emission += dissolveBase.rgb * (
				_DissolveGlowWeight
				* step(clipval, _DissolveEdgeWidth) // Outer edge.
				* step(0.01h, dissolveCutoff)); // Kill when cutoff is zero.
#endif
} 

#endif // ALLOY_FEATURES_DISSOLVE_CGINC
