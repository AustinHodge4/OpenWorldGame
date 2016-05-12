// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file AO2.cginc
/// @brief Secondary Ambient Occlusion, possibly on a different UV.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FEATURES_AO2_CGINC
#define ALLOY_FEATURES_AO2_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef _AO2_ON
	/// Secondary Ambient Occlusion map.
	/// Expects an RGB map with sRGB sampling
	ALLOY_SAMPLER2D_XFORM(_Ao2Map);

	/// Ambient Occlusion strength.
	/// Expects values in the range [0,1].
	half _Ao2Occlusion;
#endif

/// Applies the Secondary Ambient Occlusion feature to the given material data.
/// @param[in,out]	s	Material surface data.
void AlloyAo2(
	inout AlloySurfaceDesc s) 
{
#ifdef _AO2_ON
	float2 ao2Uv = ALLOY_XFORM_TEX_UV(_Ao2Map, s);
	s.ambientOcclusion *= LerpOneTo(tex2D(_Ao2Map, ao2Uv).g, _Ao2Occlusion * s.mask);
#endif
} 

#endif // ALLOY_FEATURES_AO2_CGINC
