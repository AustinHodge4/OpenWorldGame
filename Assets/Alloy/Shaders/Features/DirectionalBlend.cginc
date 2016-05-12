// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file DirectionalBlend.cginc
/// @brief Allows blending based how much a normal faces a given direction.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FEATURES_DIRECTIONAL_BLEND_CGINC
#define ALLOY_FEATURES_DIRECTIONAL_BLEND_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef _DIRECTIONAL_BLEND_ON
	/// Direction around which the blending occurs.
	/// Expects a normalized direction vector.
	half3 _DirectionalBlendDirection;
	
	/// Directional Blend weight.
	/// Expects values in the range [0,1].
	half _OrientedScale;
	
	/// Hemispherical cutoff where blend begins.
	/// Expects values in the range [0,1].
	half _OrientedCutoff;
	
	/// Offset from cutoff where smooth blending occurs.
	/// Expects values in the range [0,1].
	half _OrientedBlend;
#endif

void AlloyDirectionalBlend(
	inout AlloySurfaceDesc s)
{
#ifdef _DIRECTIONAL_BLEND_ON
	half3 normal;
	half blendCutoff = 1.0h - 1.01h * _OrientedCutoff;
	
	#ifdef _DIRECTIONALBLENDMODE_WORLD
		normal = s.normalWorld;
	#else
		normal = normalize(mul((half3x3)unity_WorldToObject, s.normalWorld));
	#endif	
	
	half mask = dot(normal, _DirectionalBlendDirection) * 0.5h + 0.5h;
	mask = smoothstep(blendCutoff - _OrientedBlend, blendCutoff, mask);
	s.mask *= mask * _OrientedScale;
#endif
}

#endif // ALLOY_FEATURES_DIRECTIONAL_BLEND_CGINC
