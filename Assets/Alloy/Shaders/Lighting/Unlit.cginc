// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file Unlit.cginc
/// @brief Unlit lighting model. Deferred+Forward.
///////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_LIGHTING_UNLIT_CGINC
#define ALLOY_LIGHTING_UNLIT_CGINC

#define ALLOY_DISABLE_REFLECTION_PROBES

#include "Assets/Alloy/Shaders/Framework/Lighting.cginc"

void AlloyPreSurface(
	inout AlloySurfaceDesc s)
{

}

void AlloyPostSurface(
	inout AlloySurfaceDesc s)
{
	AlloySetPbrData(s); 
	
	s.emission += s.baseColor;
	s.baseColor = 0.0h;
}

half4 AlloyGbuffer(
	AlloySurfaceDesc s,
	out half4 diffuseAo,
	out half4 specSmoothness,
	out half4 normalId)
{
	// Allows it to be deferred for image effects, but not be lit.
	diffuseAo = 0.0h;
	specSmoothness = 0.0h;
	normalId = half4(s.normalWorld * 0.5h + 0.5h, 1.0h);
	return half4(s.emission, 1.0h);
}

half3 AlloyDirect( 
	AlloyDirectDesc d,
	AlloySurfaceDesc s)
{
	return 0.0h;
}

half3 AlloyIndirect(
	AlloyIndirectDesc i,
	AlloySurfaceDesc s)
{
	return 0.0h;
}

#endif // ALLOY_LIGHTING_UNLIT_CGINC
