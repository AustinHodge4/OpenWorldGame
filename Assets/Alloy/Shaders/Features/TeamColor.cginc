// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file TeamColor.cginc
/// @brief Team Color via texture color component masks and per-mask tint colors.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FEATURES_TEAMCOLOR_CGINC
#define ALLOY_FEATURES_TEAMCOLOR_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef _TEAMCOLOR_ON
	/// Team Color mask mode.
	/// Expects either 0 or 1.
	half _TeamColorMode;
	
	/// The red channel mask tint color.
	/// Expects a linear LDR color.
	half3 _TeamColor0;
	
	/// The green channel mask tint color.
	/// Expects a linear LDR color.
	half3 _TeamColor1;
	
	/// The blue channel mask tint color.
	/// Expects a linear LDR color.
	half3 _TeamColor2;
	
	/// The alpha channel mask tint color.
	/// Expects a linear LDR color.
	half3 _TeamColor3;
	
	/// Mask map that stores a tint mask in each channel.
	/// Expects an RGB(A) data map.
	sampler2D _TeamColorMaskMap;
#endif

/// Applies the TeamColor feature to the given material data.
/// @param[in,out]	s	Material surface data.
void AlloyTeamColor(
	inout AlloySurfaceDesc s) 
{
#ifdef _TEAMCOLOR_ON
	half4 masks = s.mask * tex2D(_TeamColorMaskMap, s.baseUv);
	masks.a *= _TeamColorMode;
	
	half weight = dot(masks, half4(1.0h, 1.0h, 1.0h, 1.0h));
	
	// Renormalize masks when their combined weight sums to greater than one.
	masks /= max(1.0h, weight);
	
	// Combine colors, then fill to white where weights sum to less than one.
	s.baseColor *= _TeamColor0 * masks.r 
				+ _TeamColor1 * masks.g 
				+ _TeamColor2 * masks.b 
				+ _TeamColor3 * masks.a 
				+ (1.0h - min(1.0h, weight)).rrr;
#endif
} 

#endif // ALLOY_FEATURES_TEAMCOLOR_CGINC
