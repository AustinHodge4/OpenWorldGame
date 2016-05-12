// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Oriented.cginc
/// @brief Oriented Blend & Core shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_DEFINITIONS_ORIENTED_CGINC
#define ALLOY_DEFINITIONS_ORIENTED_CGINC

#define _ORIENTED_TEXTURES_ON

#include "Assets/Alloy/Shaders/Lighting/Standard.cginc"
#include "Assets/Alloy/Shaders/Framework/Definition.cginc"

void AlloyVertex( 
	inout AlloyVertexDesc v)
{	
	
}
	
void AlloySurface(
	inout AlloySurfaceDesc s)
{	
	// Set so that world textures blend can control opacity.
	s.opacity = 0.0h;
	
	AlloyOrientedTextures(s);
	AlloyCutout(s);
    
	s.NdotV = DotClamped(s.normalWorld, s.viewDirWorld);
}

void AlloyFinalColor(
	AlloySurfaceDesc s,
	inout half4 color)
{	
	UNITY_APPLY_FOG(s.fogCoord, color);
}

#endif // ALLOY_DEFINITIONS_ORIENTED_CGINC
