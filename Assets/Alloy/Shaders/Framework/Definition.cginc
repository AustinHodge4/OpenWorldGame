// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Definition.cginc
/// @brief Includes all the common headers for surface shader definitions.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FRAMEWORK_DEFINITION_CGINC
#define ALLOY_FRAMEWORK_DEFINITION_CGINC

// NOTE: Config comes first to override Unity settings!
#include "Assets/Alloy/Shaders/Config.cginc"
#include "Assets/Alloy/Shaders/Framework/Surface.cginc"
#include "Assets/Alloy/Shaders/Framework/Utility.cginc"
#include "Assets/Alloy/Shaders/Framework/Vertex.cginc"

// Features
#include "Assets/Alloy/Shaders/Features/AO2.cginc"
#include "Assets/Alloy/Shaders/Features/CarPaint.cginc"
#include "Assets/Alloy/Shaders/Features/Cutout.cginc"
#include "Assets/Alloy/Shaders/Features/Decal.cginc"
#include "Assets/Alloy/Shaders/Features/Detail.cginc"
#include "Assets/Alloy/Shaders/Features/DirectionalBlend.cginc"
#include "Assets/Alloy/Shaders/Features/Dissolve.cginc"
#include "Assets/Alloy/Shaders/Features/Emission.cginc"
#include "Assets/Alloy/Shaders/Features/Emission2.cginc"
#include "Assets/Alloy/Shaders/Features/HeightmapBlend.cginc"
#include "Assets/Alloy/Shaders/Features/OrientedTextures.cginc"
#include "Assets/Alloy/Shaders/Features/Parallax.cginc"
#include "Assets/Alloy/Shaders/Features/Rim.cginc"
#include "Assets/Alloy/Shaders/Features/Rim2.cginc"
#include "Assets/Alloy/Shaders/Features/SecondaryTextures.cginc"
#include "Assets/Alloy/Shaders/Features/TeamColor.cginc"
#include "Assets/Alloy/Shaders/Features/TransitionBlend.cginc"

#include "UnityCG.cginc"
#include "UnityStandardBRDF.cginc"
#include "UnityStandardUtils.cginc"

/// The base tint color.
/// Expects a linear LDR color with alpha.
half4 _Color;

/// Base color map.
/// Expects an RGB(A) map with sRGB sampling.
ALLOY_SAMPLER2D_XFORM(_MainTex);

/// Base packed material map.
/// Expects an RGBA data map.
sampler2D _SpecTex;

/// Base normal map.
/// Expects a compressed normal map.
sampler2D _BumpMap;

#ifndef ALLOY_DISABLE_BASE_COLOR_VERTEX_TINT
	/// Toggles tinting the base color by the vertex color.
	/// Expects values in the range [0,1].
	half _BaseColorVertexTint;
#endif

/// The base metallic scale.
/// Expects values in the range [0,1].
half _Metal; 

/// The base specularity scale.
/// Expects values in the range [0,1].
half _Specularity;

/// The base roughness scale.
/// Expects values in the range [0,1].
half _Roughness;

/// Ambient Occlusion strength.
/// Expects values in the range [0,1].
half _Occlusion;

/// Normal map XY scale.
half _BumpScale;

/// Sets base UV data for all further passes.
/// @param[in,out]	s	Material surface data.
void AlloySetBaseUv(
	inout AlloySurfaceDesc s) 
{
	s.baseUv = ALLOY_XFORM_TEX_UV_SCROLL(_MainTex, s);
	s.baseTiling = _MainTex_ST.xy;
}

/// Calculates texture coordinates for virtual texturing.
/// @param[in,out]	s	Material surface data.
void AlloySetVirtualCoord(
	inout AlloySurfaceDesc s) 
{
#ifdef _VIRTUALTEXTURING_ON
	s.baseVirtualCoord = VTComputeVirtualCoord(s.baseUv);
#endif
}

/// Applies vertex color based on weight parameter.
/// @param	s	Material surface data.
/// @return 	Vertex color tint.
half3 AlloyBaseVertexColor(
	AlloySurfaceDesc s) 
{
	half3 color = half3(1.0h, 1.0h, 1.0h);

#ifndef ALLOY_DISABLE_BASE_COLOR_VERTEX_TINT	
	color = LerpWhiteTo(s.vertexColor.rgb, _BaseColorVertexTint);
#endif
	
	return color;
}	

/// Converts AO from gamma to linear and applies based on weight parameter.
/// @param	ao	Gamma-space AO.
/// @return 	Modified linear-space AO.
half AlloyBaseAmbientOcclusion(
	half ao)
{
	return LerpOneTo(AlloyGammaToLinear(ao), _Occlusion); 
}

/// Calculates new world-space normal data from the tangent-space normal.
/// @param[in,out]	s	Material surface data.
void AlloySetNormalData(
	inout AlloySurfaceDesc s) 
{
	s.normalWorld = ALLOY_XFORM_NORMAL(s, s.normalTangent);
	s.NdotV = DotClamped(s.normalWorld, s.viewDirWorld);
}

/// Samples the base color map.
/// @param	s	Material surface data.
/// @return 	Base Color with alpha.
half4 AlloySampleBaseColor(
	AlloySurfaceDesc s) 
{
	half4 color = half4(1.0h, 1.0h, 1.0h, 1.0h);

#ifdef _VIRTUALTEXTURING_ON
	color = VTSampleBase(s.baseVirtualCoord);
#else
	color = tex2D(_MainTex, s.baseUv);
#endif
	
	return color;
}

/// Samples the base material map.
/// @param	s	Material surface data.
/// @return 	Packed material.
half4 AlloySampleBaseMaterial(
	AlloySurfaceDesc s) 
{
#ifdef _VIRTUALTEXTURING_ON
	return VTSampleSpecular(s.baseVirtualCoord);
#else
	return tex2D(_SpecTex, s.baseUv);
#endif
}

/// Samples the base bump map.
/// @param	s	Material surface data.
/// @return 	Normalized tangent-space normal.
half3 AlloySampleBaseBump(
	AlloySurfaceDesc s) 
{
	half4 result = 0.0h;

#ifdef _VIRTUALTEXTURING_ON
	result = VTSampleNormal(s.baseVirtualCoord);
#else
	result = tex2D(_BumpMap, s.baseUv);
#endif

	return UnpackScaleNormal(result, _BumpScale);  
}

/// Samples the base bump map biasing the mipmap level sampled.
/// @param	s	Material surface data.
/// @return 	Normalized tangent-space normal.
half3 AlloySampleBaseBumpBias(
	AlloySurfaceDesc s,
	float bias) 
{
	half4 result = 0.0h;

#ifdef _VIRTUALTEXTURING_ON
	result = VTSampleNormal(VTComputeVirtualCoord(s.baseUv, bias));
#else
	result = tex2Dbias(_BumpMap, float4(s.baseUv, 0.0h, bias));
#endif

	return UnpackScaleNormal(result, _BumpScale);  
}

#endif // ALLOY_FRAMEWORK_DEFINITION_CGINC
