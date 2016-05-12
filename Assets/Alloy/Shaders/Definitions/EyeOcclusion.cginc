// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file EyeOcclusion.cginc
/// @brief Eye Occlusion surface shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_DEFINITIONS_EYE_OCCLUSION_CGINC
#define ALLOY_DEFINITIONS_EYE_OCCLUSION_CGINC

#include "Assets/Alloy/Shaders/Lighting/EyeOcclusion.cginc"
#include "Assets/Alloy/Shaders/Framework/Definition.cginc"
	
/// Ambient Occlusion map.
/// Expects an RGB map with sRGB sampling
sampler2D _AoMap;

void AlloyVertex( 
	inout AlloyVertexDesc v)
{	
	v.color.rgb = AlloyGammaToLinear(v.color.rgb);
}

void AlloySurface(
	inout AlloySurfaceDesc s)
{
	AlloySetBaseUv(s);
	AlloyDissolve(s);
		
	half4 base = _Color * AlloySampleBaseColor(s);
	s.albedo = base.rgb * AlloyBaseVertexColor(s);
	s.opacity = base.a;
	s.ambientOcclusion = LerpOneTo(tex2D(_AoMap, s.baseUv).g, _Occlusion); // This one needs to stay linear.
	
	s.NdotV = DotClamped(s.normalWorld, s.viewDirWorld);
}

void AlloyFinalColor(
	AlloySurfaceDesc s,
	inout half4 color)
{	
	UNITY_APPLY_FOG(s.fogCoord, color);
}

#endif // ALLOY_DEFINITIONS_EYE_OCCLUSION_CGINC
