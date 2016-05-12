// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Transition.cginc
/// @brief Transition & Weighted Blend shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_DEFINITIONS_TRANSITION_CGINC
#define ALLOY_DEFINITIONS_TRANSITION_CGINC

#define _TRANSITION_BLEND_ON
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
	
	float4 uv01 = s.uv01;
	AlloyParallax(s);
	float4 parallaxUv01 = s.uv01;
	
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
	AlloyDecal(s);
	AlloyTransitionBlend(s);
	
	s.uv01 = uv01;
	AlloySecondaryTextures(s);		
	AlloyCutout(s);
	
	half mask = s.mask;
	s.mask = 1.0h;
	s.uv01 = lerp(parallaxUv01, uv01, mask);
	AlloyDissolve(s);
	
	AlloySetNormalData(s);
		
	s.mask = 1.0h - mask;
	s.uv01 = parallaxUv01;
	AlloyRim(s);
	AlloyEmission(s);
}

void AlloyFinalColor(
	AlloySurfaceDesc s,
	inout half4 color)
{	
	UNITY_APPLY_FOG(s.fogCoord, color);
}

#endif // ALLOY_DEFINITIONS_TRANSITION_CGINC
