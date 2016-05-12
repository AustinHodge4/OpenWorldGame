// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file OrientedBlend.cginc
/// @brief Oriented Blend shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_DEFINITIONS_ORIENTED_BLEND_CGINC
#define ALLOY_DEFINITIONS_ORIENTED_BLEND_CGINC

#define _DIRECTIONAL_BLEND_ON
#define _DIRECTIONALBLENDMODE_WORLD
#define _ORIENTED_TEXTURES_ON

#include "Assets/Alloy/Shaders/Lighting/Standard.cginc"
#include "Assets/Alloy/Shaders/Framework/Definition.cginc"

void AlloyVertex( 
	inout AlloyVertexDesc v)
{	
	v.color.rgb = AlloyGammaToLinear(v.color.rgb);
}
	
void AlloySurface(
	inout AlloySurfaceDesc s)
{	
	// Base layer
	AlloySetBaseUv(s);
	AlloyParallax(s);
	AlloySetVirtualCoord(s);

	half4 base = _Color * AlloySampleBaseColor(s);
	s.baseColor = base.rgb * AlloyBaseVertexColor(s);
	s.opacity = base.a;
		
    half4 material = AlloySampleBaseMaterial(s);
	s.metallic = _Metal * material.x;
	s.ambientOcclusion = AlloyBaseAmbientOcclusion(material.y); 
	s.specularity = _Specularity * material.z;
	s.roughness = _Roughness * material.w;
	
	s.normalTangent = AlloySampleBaseBump(s); 
	
	AlloyDetail(s);
	AlloyAo2(s);
	AlloyTeamColor(s);
	AlloyDecal(s);
	AlloyEmission(s);
	
	s.normalWorld = ALLOY_XFORM_NORMAL(s, s.normalTangent);

	AlloyDirectionalBlend(s);
	AlloyOrientedTextures(s);
	s.mask = 1.0h;
	
	s.NdotV = DotClamped(s.normalWorld, s.viewDirWorld);
	
	AlloyCutout(s);
	AlloyDissolve(s);
	AlloyRim(s);
}

void AlloyFinalColor(
	AlloySurfaceDesc s,
	inout half4 color)
{	
	UNITY_APPLY_FOG(s.fogCoord, color);
}

#endif // ALLOY_DEFINITIONS_ORIENTED_BLEND_CGINC
