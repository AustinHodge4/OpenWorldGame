// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file TransitionBlend.cginc
/// @brief Blending using an alpha mask and a cutoff, with a glow effect.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FEATURES_TRANSITION_BLEND_CGINC
#define ALLOY_FEATURES_TRANSITION_BLEND_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef _TRANSITION_BLEND_ON
	/// Transition glow tint color.
	/// Expects a linear HDR color with alpha.
	half4 _TransitionGlowColor; 
	
	/// Transition glow color with effect ramp in the alpha.
	/// Expects an RGBA map with sRGB sampling.
	ALLOY_SAMPLER2D_XFORM(_TransitionTex);
	
	/// The cutoff value for the transition effect in the ramp map.
    /// Expects values in the range [0,1].
	half _TransitionCutoff;
	
	/// The weight of the transition glow effect.
	/// Expects linear space value in the range [0,1].
	half _TransitionGlowWeight;
	
	/// The width of the transition glow effect.
    /// Expects values in the range [0,1].
	half _TransitionEdgeWidth;
#endif

void AlloyTransitionBlend(
	inout AlloySurfaceDesc s)
{
#ifdef _TRANSITION_BLEND_ON
	float2 transitionUv = ALLOY_XFORM_TEX_UV(_TransitionTex, s);
	half4 transitionBase = _TransitionGlowColor * tex2D(_TransitionTex, transitionUv);
	half transitionCutoff = _TransitionCutoff * 1.01h;
	half clipval = transitionBase.a - transitionCutoff;	
	half blend = step(0.0h, clipval);
		
	// Dissolve glow
	s.emission += transitionBase.rgb * (
				_TransitionGlowWeight
				* blend // Blend edge.
				* step(clipval, _TransitionEdgeWidth) // Outer edge.
				* step(0.01h, transitionCutoff)); // Kill when cutoff is zero.

	s.mask *= 1.0h - blend;
#endif
}

#endif // ALLOY_FEATURES_TRANSITION_BLEND_CGINC
