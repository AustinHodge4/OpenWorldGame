// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Core.cginc
/// @brief Core & Glass surface shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_DEFINITIONS_CORE_CGINC
#define ALLOY_DEFINITIONS_CORE_CGINC

#include "Assets/Alloy/Shaders/Lighting/Standard.cginc"
#include "Assets/Alloy/Shaders/Framework/Definition.cginc"

#ifdef ALLOY_ENABLE_PROTOTYPING
	/// Metallic map.
	/// Expects an RGB map with sRGB sampling
	sampler2D _MetallicMap;
	
	/// Ambient Occlusion map.
	/// Expects an RGB map with sRGB sampling
	sampler2D _AoMap;
	
	/// Specularity map.
	/// Expects an RGB map with sRGB sampling
	sampler2D _SpecularityMap;
	
	/// Roughness map.
	/// Expects an RGB map with sRGB sampling
	sampler2D _RoughnessMap;
#endif

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
	
    half4 material = 0.0h;
    
#ifdef ALLOY_ENABLE_PROTOTYPING
	// Assumes that the user hasn't changed the textures' default import settings.
	// So we assume the system applied the sRGB curve, and we need to undo it.
	material.x = tex2D(_MetallicMap, s.baseUv).g; 
	material.z = tex2D(_SpecularityMap, s.baseUv).g;
	material.w = tex2D(_RoughnessMap, s.baseUv).g;
	material.xzw = AlloyLinearToGamma(material.xzw);
	material.y = LerpOneTo(tex2D(_AoMap, s.baseUv).g, _Occlusion); // This one needs to stay linear.
#else
	material = AlloySampleBaseMaterial(s);
	material.y = AlloyBaseAmbientOcclusion(material.y); 
#endif
	
	s.metallic = _Metal * material.x;
	s.ambientOcclusion = material.y;
	s.specularity = _Specularity * material.z;
	s.roughness = _Roughness * material.w;
	
	s.normalTangent = AlloySampleBaseBump(s);

	AlloyAo2(s);
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

#endif // ALLOY_DEFINITIONS_CORE_CGINC
