// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file DirectionalBlend.cginc
/// @brief Directional Blend shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_DEFINITIONS_DIRECTIONAL_BLEND_CGINC
#define ALLOY_DEFINITIONS_DIRECTIONAL_BLEND_CGINC

#define _DIRECTIONAL_BLEND_ON
#define _SECONDARY_TEXTURES_ON

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
	AlloyTeamColor(s);
	AlloyEmission(s);
	AlloyDecal(s);
	
	s.normalWorld = ALLOY_XFORM_NORMAL(s, s.normalTangent);

	AlloyDirectionalBlend(s);
	AlloySecondaryTextures(s);	
	s.mask = 1.0h;
	
	AlloyCutout(s);
	AlloyDissolve(s);
	
	AlloySetNormalData(s);
	AlloyRim(s);
}

void AlloyFinalColor(
	AlloySurfaceDesc s,
	inout half4 color)
{	
	UNITY_APPLY_FOG(s.fogCoord, color);
}

#endif // ALLOY_DEFINITIONS_DIRECTIONAL_BLEND_CGINC
