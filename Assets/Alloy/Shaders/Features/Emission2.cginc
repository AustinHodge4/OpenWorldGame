// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Emission2.cginc
/// @brief Secondary emission effects.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FEATURES_EMISSION2_CGINC
#define ALLOY_FEATURES_EMISSION2_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef _EMISSION2_ON
	/// Secondary emission tint color.
	/// Expects a linear LDR color.
	half3 _Emission2Color;
	
	//// Secondary emission mask texture.
	/// Expects an RGB map with sRGB sampling.
	sampler2D _EmissionMap2;

	/// Secondary emission effect texture.
	/// Expects an RGB map with sRGB sampling.
	ALLOY_SAMPLER2D_XFORM(_IncandescenceMap2);
	
	/// The weight of the secondary emission effect.
	/// Expects linear space value in the range [0,1].
	half _Emission2Weight;
#endif

/// Applies the Emission feature to the given material data.
/// @param[in,out]	s	Material surface data.
void AlloyEmission2(
	inout AlloySurfaceDesc s)
{
#ifdef _EMISSION2_ON
	half3 emission = _Emission2Color;

	#ifndef ALLOY_DISABLE_EMISSION2_COLOR_MAP
		emission *= tex2D(_EmissionMap2, s.baseUv).rgb; 
	#endif

	#ifndef ALLOY_DISABLE_EMISSION2_EFFECTS_MAP
		float2 incandescenceUv2 = ALLOY_XFORM_TEX_UV_SCROLL(_IncandescenceMap2, s);
		emission *= tex2D(_IncandescenceMap2, incandescenceUv2).rgb;
	#endif
	
	s.emission += emission * (_Emission2Weight * AlloyGammaToLinear(s.mask));
#endif
} 

#endif // ALLOY_FEATURES_EMISSION2_CGINC
