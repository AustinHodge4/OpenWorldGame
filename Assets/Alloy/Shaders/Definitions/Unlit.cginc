// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Unlit.cginc
/// @brief Unlit surface shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_DEFINITIONS_UNLIT_CGINC
#define ALLOY_DEFINITIONS_UNLIT_CGINC

#define ALLOY_DISABLE_DETAIL_MATERIAL_MAP

#include "Assets/Alloy/Shaders/Lighting/Unlit.cginc"
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
		
	s.normalTangent = AlloySampleBaseBump(s);
	
	AlloyDetail(s);
	AlloyTeamColor(s);
	AlloyDecal(s);
	AlloySetNormalData(s);	
	AlloyRim(s);
	AlloyEmission(s); 
}

void AlloyFinalColor(
	AlloySurfaceDesc s,
	inout half4 color)
{	
	UNITY_APPLY_FOG(s.fogCoord, color);
}

#endif // ALLOY_DEFINITIONS_UNLIT_CGINC
