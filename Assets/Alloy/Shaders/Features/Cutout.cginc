// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Cutout.cginc
/// @brief Cutout effect from base alpha.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FEATURES_CUTOUT_CGINC
#define ALLOY_FEATURES_CUTOUT_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef _ALPHATEST_ON
	/// Cutoff value that controls where cutout occurs over opacity.
	/// Expects values in the range [0,1].
	half _Cutoff;
#endif

/// Applies cutout effect.
/// @param	s	Material surface data.
void AlloyCutout(
	AlloySurfaceDesc s) 
{
#ifdef _ALPHATEST_ON
	clip(s.opacity - _Cutoff);
#endif
}

#endif // ALLOY_FEATURES_CUTOUT_CGINC
