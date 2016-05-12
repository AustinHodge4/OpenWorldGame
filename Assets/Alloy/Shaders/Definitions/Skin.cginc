// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Skin.cginc
/// @brief Skin surface shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_DEFINITIONS_SKIN_CGINC
#define ALLOY_DEFINITIONS_SKIN_CGINC

#include "Assets/Alloy/Shaders/Lighting/PreIntegratedSkin.cginc"
#include "Assets/Alloy/Shaders/Framework/Definition.cginc"

/// Biases the thickness value used to look up in the skin LUT.
/// Expects values in the range [0,1].
half _SssBias;

/// Scales the thickness value used to look up in the skin LUT.
/// Expects values in the range [0,1].
half _SssScale;

/// Amount to colorize and darken AO to simulate local scattering.
/// Expects values in the range [0,1].
half _SssAoSaturation;

/// Increases the bluriness of the normal map for diffuse lighting.
/// Expects values in the range [0,1].
half _SssBumpBlur;

/// Transmission tint color.
/// Expects a linear LDR color.
half3 _TransColor;

/// Weight of the transmission effect.
/// Expects linear space value in the range [0,1].
half _TransScale;

/// Falloff of the transmission effect.
/// Expects values in the range [1,n).
half _TransPower;

/// Amount that the transmission is distorted by surface normals.
/// Expects values in the range [0,1].
half _TransDistortion;

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
	AlloySetVirtualCoord(s);
	
	half4 base = _Color * AlloySampleBaseColor(s);
	s.baseColor = base.rgb * AlloyBaseVertexColor(s);
	
    half4 material = AlloySampleBaseMaterial(s);
	s.skinMask = material.x;
	s.ambientOcclusion = AlloyBaseAmbientOcclusion(material.y); 
	s.specularity = _Specularity * material.z;
	s.roughness = _Roughness * material.w;
	
	s.normalTangent = AlloySampleBaseBump(s);
	
	s.scattering = saturate(base.a * _SssScale + _SssBias);
	s.occlusionSaturation = _SssAoSaturation;
	s.transmission = _TransColor * (AlloyGammaToLinear(base.a) * _TransScale);
	s.transmissionDistortion = _TransDistortion;
	s.transmissionPower = _TransPower;

	AlloyDetail(s);
	AlloyTeamColor(s);
	AlloyDecal(s);
	
	half3 blurredNormal = AlloySampleBaseBumpBias(s, ALLOY_SKIN_BUMP_BLUR_BIAS);
	s.blurredNormalTangent = normalize(lerp(s.normalTangent, blurredNormal, _SssBumpBlur));
	
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

#endif // ALLOY_DEFINITIONS_SKIN_CGINC
