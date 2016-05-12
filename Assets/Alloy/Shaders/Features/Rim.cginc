// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Rim.cginc
/// @brief Rim lighting effects.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FEATURES_RIM_CGINC
#define ALLOY_FEATURES_RIM_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef _RIM_ON
	/// Rim lighting tint color.
	/// Expects a linear HDR color.
	half3 _RimColor;
	
	/// Rim effect texture.
	/// Expects an RGB map with sRGB sampling.
    ALLOY_SAMPLER2D_XFORM(_RimTex);
	
	/// The weight of the rim lighting effect.
	/// Expects linear space value in the range [0,1].
	half _RimWeight;
    
    /// Fills in the center of the rim lighting effect.
    /// Expects linear-space values in the range [0,1].
	half _RimBias;
	
	/// Controls the falloff of the rim lighting effect.
    /// Expects values in the range [0.01,n].
	half _RimPower;
#endif

/// Applies the Rim Lighting feature to the given material data.
/// @param[in,out]	s	Material surface data.
void AlloyRim(
	inout AlloySurfaceDesc s)
{	
#ifdef _RIM_ON 
	half3 rim = _RimColor;

	#ifndef ALLOY_DISABLE_RIM_EFFECTS_MAP
		float2 rimUv = ALLOY_XFORM_TEX_UV_SCROLL(_RimTex, s);
	    rim *= tex2D(_RimTex, rimUv).rgb;
    #endif
    
	s.emission += rim * (_RimWeight * AlloyGammaToLinear(s.mask) * AlloyRimLight(_RimBias, _RimPower, s.NdotV));
#endif
} 

#endif // ALLOY_FEATURES_RIM_CGINC
