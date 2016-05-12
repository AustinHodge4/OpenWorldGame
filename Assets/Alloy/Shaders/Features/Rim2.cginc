// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Rim2.cginc
/// @brief Secondary rim lighting effects.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FEATURES_RIM2_CGINC
#define ALLOY_FEATURES_RIM2_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef _RIM2_ON
	/// Secondary rim lighting tint color.
	/// Expects a linear HDR color.
	half3 _Rim2Color;
	
	/// Secondary rim effect texture.
	/// Expects an RGB map with sRGB sampling.
    ALLOY_SAMPLER2D_XFORM(_RimTex2);
	
	/// The weight of the secondary rim lighting effect.
	/// Expects linear space value in the range [0,1].
	half _Rim2Weight;
    
    /// Fills in the center of the secondary rim lighting effect.
    /// Expects linear-space values in the range [0,1].
	half _Rim2Bias;
	
	/// Controls the falloff of the secondary rim lighting effect.
    /// Expects values in the range [0.01,n].
	half _Rim2Power;
#endif

/// Applies the Rim Lighting feature to the given material data.
/// @param[in,out]	s	Material surface data.
void AlloyRim2(
	inout AlloySurfaceDesc s)
{	
#ifdef _RIM2_ON 
	half3 rim2 = _Rim2Color;

	#ifndef ALLOY_DISABLE_RIM2_EFFECTS_MAP
		float2 rimUv2 = ALLOY_XFORM_TEX_UV_SCROLL(_RimTex2, s);	
	    rim2 *= tex2D(_RimTex2, rimUv2).rgb;
    #endif
    
	s.emission += rim2 * (_Rim2Weight * AlloyGammaToLinear(s.mask) * AlloyRimLight(_Rim2Bias, _Rim2Power, s.NdotV));
#endif
} 

#endif // ALLOY_FEATURES_RIM2_CGINC
