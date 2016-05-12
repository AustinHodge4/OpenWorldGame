// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Emission.cginc
/// @brief Surface emission effects.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FEATURES_EMISSION_CGINC
#define ALLOY_FEATURES_EMISSION_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef _EMISSION
	/// Emission tint color.
	/// Expects a linear LDR color.
	half3 _EmissionColor;
	
	/// Emission mask texture.
	/// Expects an RGB map with sRGB sampling.
	sampler2D _EmissionMap;

	/// Emission effect texture.
	/// Expects an RGB map with sRGB sampling.
	ALLOY_SAMPLER2D_XFORM(_IncandescenceMap);
	
	/// The weight of the emission effect.
	/// Expects linear space value in the range [0,1].
	half _EmissionWeight;
#endif

/// Applies the Emission feature to the given material data.
/// @param[in,out]	s	Material surface data.
void AlloyEmission(
	inout AlloySurfaceDesc s)
{
#ifdef _EMISSION 
	half3 emission = _EmissionColor;

	#ifndef ALLOY_DISABLE_EMISSION_COLOR_MAP
		emission *= tex2D(_EmissionMap, s.baseUv).rgb;
	#endif

	#ifndef ALLOY_DISABLE_EMISSION_EFFECTS_MAP
		float2 incandescenceUv = ALLOY_XFORM_TEX_UV_SCROLL(_IncandescenceMap, s);
		emission *= tex2D(_IncandescenceMap, incandescenceUv).rgb;
	#endif
	
	s.emission += emission * (_EmissionWeight * AlloyGammaToLinear(s.mask));
#endif
} 

#endif // ALLOY_FEATURES_EMISSION_CGINC
