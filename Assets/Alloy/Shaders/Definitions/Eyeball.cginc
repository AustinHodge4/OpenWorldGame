// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Eyeball.cginc
/// @brief Eyeball surface shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_DEFINITIONS_EYEBALL_CGINC
#define ALLOY_DEFINITIONS_EYEBALL_CGINC

#define ALLOY_ENABLE_SURFACE_SPECULAR_TINT
#define ALLOY_DISABLE_DETAIL_MASK

#include "Assets/Alloy/Shaders/Lighting/Eyeball.cginc"
#include "Assets/Alloy/Shaders/Framework/Definition.cginc"

/// Schlera tint color.
/// Expects a linear LDR color.
half3 _EyeSchleraColor;

/// Schlera diffuse scattering amount.
/// Expects values in the range [0,1].
half _EyeScleraScattering;

/// Cornea specularity.
/// Expects values in the range [0,1].
half _EyeSpecularity;

/// Cornea roughness.
/// Expects values in the range [0,1].
half _EyeRoughness;

/// Iris tint color.
/// Expects a linear LDR color.
half3 _EyeColor;

/// Iris diffuse scattering amount.
/// Expects values in the range [0,1].
half _EyeIrisScattering;

/// Iris specular tint by base color.
/// Expects values in the range [0,1].
half _EyeSpecularTint;

/// Iris parallax depth scale.
/// Expects values in the range [0,1].
half _EyeParallax;

/// Iris pupil dilation.
/// Expects values in the range [0,1].
half _EyePupilSize;

void AlloyVertex( 
	inout AlloyVertexDesc v)
{	
	v.color.rgb = AlloyGammaToLinear(v.color.rgb);
}

void AlloySurface(
	inout AlloySurfaceDesc s)
{
	float4 uv01 = s.uv01;
		
	AlloySetBaseUv(s);
	
#if !defined(UNITY_PASS_SHADOWCASTER) && !defined(UNITY_PASS_META)
	// Cornea "Refraction".
	AlloyParallaxOcclusionMapping(s, _MainTex, _EyeParallax * _Color.a, 10.0f, 25.0f);
	//AlloyOffsetBumpMapping(s, _MainTex, _EyeParallax * _Color.a);
		
	// Pupil Dilation
	// HACK: Use the heightmap as the gradient, since it matches the other maps.
	// http://www.polycount.com/forum/showpost.php?p=1511423&postcount=13
    half mask = 1.0h - AlloySampleBaseColor(s).a;
    float2 centeredUv = frac(s.baseUv) + float2(-0.5f, -0.5f);
	s.baseUv -= centeredUv * mask * _EyePupilSize;
#endif		
	
	AlloyDissolve(s);
	AlloySetVirtualCoord(s);
	
	half4 base = _Color * AlloySampleBaseColor(s);
	s.baseColor = base.rgb * AlloyBaseVertexColor(s);
	
    half4 material = AlloySampleBaseMaterial(s);
    s.irisMask = material.x;
	s.ambientOcclusion = AlloyBaseAmbientOcclusion(material.y); 
	s.specularity = _Specularity * material.z;
	s.roughness = _Roughness * material.w;
	
	s.normalTangent = AlloySampleBaseBump(s);
	
	s.baseColor *= lerp(_EyeSchleraColor, _EyeColor, s.irisMask);
	s.specularTint = s.irisMask * _EyeSpecularTint;
	s.scattering = lerp(_EyeScleraScattering, _EyeIrisScattering, s.irisMask);
	s.corneaSpecularity = _EyeSpecularity;
	s.corneaRoughness = _EyeRoughness;
	
	// Don't allow detail normals in the iris.
	s.mask = 1.0h - s.irisMask;
	AlloyDetail(s); 
	s.mask = 1.0h;
	
	AlloySetNormalData(s);
	AlloyEmission(s);
	AlloyRim(s);
	
	// Remove parallax so this appears on top of the cornea!
	s.uv01 = uv01;
	AlloyDecal(s); 
}

void AlloyFinalColor(
	AlloySurfaceDesc s,
	inout half4 color)
{	
	UNITY_APPLY_FOG(s.fogCoord, color);
}

#endif // ALLOY_DEFINITIONS_EYEBALL_CGINC
