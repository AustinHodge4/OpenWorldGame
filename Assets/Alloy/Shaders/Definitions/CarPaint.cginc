// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file CarPaint.cginc
/// @brief Car Paint surface shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_DEFINITIONS_CAR_PAINT_CGINC
#define ALLOY_DEFINITIONS_CAR_PAINT_CGINC

#define _CAR_PAINT_ON

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
	AlloyDissolve(s);
	AlloySetVirtualCoord(s);
	
	half4 base = _Color * AlloySampleBaseColor(s);
	s.baseColor = base.rgb * AlloyBaseVertexColor(s);
	s.opacity = base.a;
	
	AlloyCutout(s);
	
    half4 material = AlloySampleBaseMaterial(s);
	s.metallic = _Metal * material.x;
	s.ambientOcclusion = AlloyBaseAmbientOcclusion(material.y); 
	s.specularity = _Specularity * material.z;
	s.roughness = _Roughness * material.w;

	s.normalTangent = AlloySampleBaseBump(s); 

	AlloyAo2(s);
	AlloyDetail(s);	
	AlloyTeamColor(s);
	AlloySetNormalData(s);
	
	s.mask = s.opacity;
	AlloyCarPaint(s);
	s.mask = 1.0h;
	
	AlloyDecal(s);
	AlloyEmission(s);
	AlloyRim(s);
}

void AlloyFinalColor(
	AlloySurfaceDesc s,
	inout half4 color)
{	
	UNITY_APPLY_FOG(s.fogCoord, color);
}

#endif // ALLOY_DEFINITIONS_CAR_PAINT_CGINC
