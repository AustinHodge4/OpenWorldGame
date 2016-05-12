// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Transmission.cginc
/// @brief Transmission surface shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_DEFINITIONS_TRANSMISSION_CGINC
#define ALLOY_DEFINITIONS_TRANSMISSION_CGINC

#include "Assets/Alloy/Shaders/Lighting/Transmission.cginc"
#include "Assets/Alloy/Shaders/Framework/Definition.cginc"

/// Transmission tint color.
/// Expects a linear LDR color.
half3 _TransColor;

/// Transmission color * thickness texture.
/// Expects an RGB map with sRGB sampling.
sampler2D _TransTex;

/// Weight of the transmission effect.
/// Expects linear-space values in the range [0,1].
half _TransScale;

/// Falloff of the transmission effect.
/// Expects values in the range [1,n).
half _TransPower;

/// Amount that the transmission is distorted by surface normals.
/// Expects values in the range [0,1].
half _TransDistortion;

/// Shadow influence on the transmission effect.
/// Expects values in the range [0,1].
half _TransShadowWeight;

/// Toggles inverting the backface normals.
/// Expects the values 0 or 1.
half _TransInvertBackNormal;

void AlloyVertex( 
	inout AlloyVertexDesc v)
{	
#ifdef ALLOY_PASS_BACKFACE
	v.normal *= -1.0h;
	v.tangent.w *= -1.0h;
#endif

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
	
	s.transmission = tex2D(_TransTex, s.baseUv).rgb;
	s.transmission *= _TransColor * _TransScale;	
	s.transmissionDistortion = _TransDistortion;
	s.transmissionPower = _TransPower;
	
#ifdef ALLOY_ENABLE_DOUBLESIDED
	s.transmissionShadowWeight = _TransShadowWeight;
#endif

	AlloyAo2(s);
	AlloyDetail(s);	
	AlloyTeamColor(s);
	AlloyDecal(s);
	
#ifdef ALLOY_PASS_BACKFACE
	s.normalTangent.xy = _TransInvertBackNormal < 0.5h ? s.normalTangent.xy : -s.normalTangent.xy;
#endif
	
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

#endif // ALLOY_DEFINITIONS_TRANSMISSION_CGINC
