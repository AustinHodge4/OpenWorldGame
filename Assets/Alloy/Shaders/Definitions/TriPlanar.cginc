// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file TriPlanar.cginc
/// @brief TriPlanar shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_DEFINITIONS_TRIPLANAR_CGINC
#define ALLOY_DEFINITIONS_TRIPLANAR_CGINC

#ifndef ALLOY_ENABLE_FULL_TRIPLANAR
	#define ALLOY_ENABLE_SURFACE_SPECULAR_TINT
#endif

#ifdef ALLOY_ENABLE_FULL_TRIPLANAR
	#define ALLOY_TRIPLANAR_SAMPLERS(s) s##Base, s##Material, s##Bump 
#else
	#define ALLOY_TRIPLANAR_SAMPLERS(s) s##Base, s##Bump 
#endif

#define ALLOY_DISABLE_RIM_EFFECTS_MAP

#include "Assets/Alloy/Shaders/Lighting/Standard.cginc"
#include "Assets/Alloy/Shaders/Framework/Definition.cginc"
#include "Assets/Alloy/Shaders/Framework/TriPlanarSplat.cginc"

struct AlloyTriPlanarZoneDesc {
	float2 uv;
	half4 tint;
	half vertexColorTint;
	half metallic;
	half specularity;
	half specularTint;
	half roughness;
	half occlusionStrength;
	half bumpScale;
};
	
void AlloyTriplanar(
	inout AlloySurfaceDesc s,
	AlloyTriPlanarZoneDesc t,
	sampler2D baseColor,
#ifdef ALLOY_ENABLE_FULL_TRIPLANAR
	sampler2D material,
#endif
	sampler2D bump,
	half3x3 tbn,
	half mask)
{
	half4 base2 = t.tint * tex2D(baseColor, t.uv);
	base2.rgb *= LerpWhiteTo(s.vertexColor.rgb, t.vertexColorTint);
	s.baseColor += mask * base2.rgb;
     
#ifdef ALLOY_ENABLE_FULL_TRIPLANAR
    half4 material2 = tex2D(material, t.uv);    
	s.ambientOcclusion += mask * LerpOneTo(AlloyGammaToLinear(material2.y), t.occlusionStrength);
#else
    half4 material2 = 1.0h; 
    material2.w *= base2.a;
	s.ambientOcclusion += mask;
    s.specularTint += mask * t.specularTint;
#endif
	s.metallic += mask * t.metallic * material2.x;
	s.specularity += mask * t.specularity * material2.z;
	s.roughness += mask * t.roughness * material2.w;

	half3 normal = UnpackScaleNormal(tex2D(bump, t.uv), t.bumpScale);
	s.normalWorld += mask * mul(normal, tbn);
}

half _TriplanarBlendSharpness;
	
half4 _PrimaryColor;
ALLOY_SAMPLER2D_XFORM(_PrimaryMainTex);
sampler2D _PrimaryMaterialMap;
sampler2D _PrimaryBumpMap;
half _PrimaryColorVertexTint;
half _PrimaryMetallic;
half _PrimarySpecularity;
half _PrimarySpecularTint;
half _PrimaryOcclusion;
half _PrimaryRoughness;
half _PrimaryBumpScale;

#ifdef _SECONDARY_TRIPLANAR_ON
	half4 _SecondaryColor;
	ALLOY_SAMPLER2D_XFORM(_SecondaryMainTex);
	sampler2D _SecondaryMaterialMap;
	sampler2D _SecondaryBumpMap;
	half _SecondaryColorVertexTint;
	half _SecondaryMetallic;
	half _SecondarySpecularity;
	half _SecondarySpecularTint;
	half _SecondaryOcclusion;
	half _SecondaryRoughness;
	half _SecondaryBumpScale;
#endif

#ifdef _TERTIARY_TRIPLANAR_ON
	half4 _TertiaryColor;
	ALLOY_SAMPLER2D_XFORM(_TertiaryMainTex);
	sampler2D _TertiaryMaterialMap;
	sampler2D _TertiaryBumpMap;
	half _TertiaryColorVertexTint;
	half _TertiaryMetallic;
	half _TertiarySpecularity;
	half _TertiarySpecularTint;
	half _TertiaryOcclusion;
	half _TertiaryRoughness;
	half _TertiaryBumpScale;
#endif

#ifdef _QUATERNARY_TRIPLANAR_ON
	half4 _QuaternaryColor;
	ALLOY_SAMPLER2D_XFORM(_QuaternaryMainTex);
	sampler2D _QuaternaryMaterialMap;
	sampler2D _QuaternaryBumpMap;
	half _QuaternaryColorVertexTint;
	half _QuaternaryMetallic;
	half _QuaternarySpecularity;
	half _QuaternarySpecularTint;
	half _QuaternaryRoughness;
	half _QuaternaryBumpScale;
#endif
	
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

	// Triplanar mapping
	// cf http://www.gamedev.net/blog/979/entry-2250761-triplanar-texturing-and-normal-mapping/
	half3 normalWorld = s.tangentToWorld[2].xyz;
	
#ifdef _TRIPLANARMODE_WORLD
	float4 position = float4(s.positionWorld, 1.0f);
	half3 geoNormal = normalWorld;
#else
	float4 position = mul(unity_WorldToObject, float4(s.positionWorld, 1.0f));
	half3 geoNormal = mul((half3x3)unity_WorldToObject, normalWorld);
#endif

	// Unity uses a Left-handed axis, so it requires clumsy remapping.
	half3x3 yTangentToWorld = half3x3(half3(1.0h, 0.0h, 0.0h), half3(0.0h, 0.0h, 1.0h), geoNormal);
	half3x3 xTangentToWorld = half3x3(half3(0.0h, 0.0h, 1.0h), half3(0.0h, 1.0h, 0.0h), geoNormal);
	half3x3 zTangentToWorld = half3x3(half3(1.0h, 0.0h, 0.0h), half3(0.0h, 1.0h, 0.0h), geoNormal);
	
	half3 blending = abs(geoNormal);
	blending = normalize(max(blending, 0.00001h));
	half3 blendWeights = pow(blending, _TriplanarBlendSharpness);
	blendWeights /= dot(blendWeights, half3(1.0h, 1.0h, 1.0h));
	AlloySurfaceZeroMaterial(s);
	
	AlloyTriPlanarZoneDesc top;		
	sampler2D topBase = _PrimaryMainTex;
#ifdef ALLOY_ENABLE_FULL_TRIPLANAR
	sampler2D topMaterial = _PrimaryMaterialMap;
#endif
	sampler2D topBump = _PrimaryBumpMap;
	
	UNITY_INITIALIZE_OUTPUT(AlloyTriPlanarZoneDesc, top);
	top.uv = ALLOY_XFORM_TEX_SCROLL(_PrimaryMainTex, position.xz);
	top.tint = _PrimaryColor;
	top.vertexColorTint = _PrimaryColorVertexTint;
	top.metallic = _PrimaryMetallic;
	top.specularity = _PrimarySpecularity;
#ifndef ALLOY_ENABLE_FULL_TRIPLANAR
	top.specularTint = _PrimarySpecularTint;
#else
	top.occlusionStrength = _PrimaryOcclusion;
#endif
	top.roughness = _PrimaryRoughness;
	top.bumpScale = _PrimaryBumpScale;
			
#if defined(_SECONDARY_TRIPLANAR_ON) || defined(_TERTIARY_TRIPLANAR_ON)
	half topBlend = step(0.0h, geoNormal.y);
#else
	half topBlend = 1.0h;
#endif

	AlloyTriplanar(
		s, 
		top, 
		ALLOY_TRIPLANAR_SAMPLERS(top),
		yTangentToWorld,
		blendWeights.y * topBlend);
	
#ifdef _SECONDARY_TRIPLANAR_ON		
	sampler2D xSideBase = _SecondaryMainTex;
	#ifdef ALLOY_ENABLE_FULL_TRIPLANAR
		sampler2D xSideMaterial = _SecondaryMaterialMap;
	#endif
	sampler2D xSideBump = _SecondaryBumpMap;
	
	top.uv = ALLOY_XFORM_TEX_SCROLL(_SecondaryMainTex, position.zy);
	top.tint = _SecondaryColor;
	top.vertexColorTint = _SecondaryColorVertexTint;
	top.metallic = _SecondaryMetallic;
	top.specularity = _SecondarySpecularity;
	#ifndef ALLOY_ENABLE_FULL_TRIPLANAR
		top.specularTint = _SecondarySpecularTint;
	#else
		top.occlusionStrength = _SecondaryOcclusion;
	#endif
	top.roughness = _SecondaryRoughness;
	top.bumpScale = _SecondaryBumpScale;
#else
	sampler2D xSideBase = topBase;
	#ifdef ALLOY_ENABLE_FULL_TRIPLANAR
		sampler2D xSideMaterial = topMaterial;
	#endif
	sampler2D xSideBump = topBump;
	
	top.uv = ALLOY_XFORM_TEX_SCROLL(_PrimaryMainTex, position.zy);
#endif
	
	AlloyTriplanar(
		s, 
		top, 
		ALLOY_TRIPLANAR_SAMPLERS(xSide),
		xTangentToWorld,
		blendWeights.x);

#ifdef _QUATERNARY_TRIPLANAR_ON	
	sampler2D zSideBase = _QuaternaryMainTex;
	#ifdef ALLOY_ENABLE_FULL_TRIPLANAR
		sampler2D zSideMaterial = _QuaternaryMaterialMap;
	#endif
	sampler2D zSideBump = _QuaternaryBumpMap;
	
	top.uv = ALLOY_XFORM_TEX_SCROLL(_QuaternaryMainTex, position.xy);
	top.tint = _QuaternaryColor;
	top.vertexColorTint = _QuaternaryColorVertexTint;
	top.metallic = _QuaternaryMetallic;
	top.specularity = _QuaternarySpecularity;
	#ifndef ALLOY_ENABLE_FULL_TRIPLANAR
		top.specularTint = _QuaternarySpecularTint;
	#endif
	top.roughness = _QuaternaryRoughness;
	top.bumpScale = _QuaternaryBumpScale;
#else
	sampler2D zSideBase = xSideBase;
	#ifdef ALLOY_ENABLE_FULL_TRIPLANAR
		sampler2D zSideMaterial = xSideMaterial;
	#endif
	sampler2D zSideBump = xSideBump;
	
	#ifdef _SECONDARY_TRIPLANAR_ON
		top.uv = ALLOY_XFORM_TEX_SCROLL(_SecondaryMainTex, position.xy);
	#else
		top.uv = ALLOY_XFORM_TEX_SCROLL(_PrimaryMainTex, position.xy);
	#endif
#endif
	
	AlloyTriplanar(
		s, 
		top, 
		ALLOY_TRIPLANAR_SAMPLERS(zSide),
		zTangentToWorld,
		blendWeights.z);

#ifdef _TERTIARY_TRIPLANAR_ON		
	sampler2D bottomBase = _TertiaryMainTex;
	#ifdef ALLOY_ENABLE_FULL_TRIPLANAR
		sampler2D bottomMaterial = _TertiaryMaterialMap;
	#endif
	sampler2D bottomBump = _TertiaryBumpMap;
	
	top.uv = ALLOY_XFORM_TEX_SCROLL(_TertiaryMainTex, position.xz);
	top.tint = _TertiaryColor;
	top.vertexColorTint = _TertiaryColorVertexTint;
	top.metallic = _TertiaryMetallic;
	top.specularity = _TertiarySpecularity;
	#ifndef ALLOY_ENABLE_FULL_TRIPLANAR
		top.specularTint = _TertiarySpecularTint;
	#else
		top.occlusionStrength = _TertiaryOcclusion;
	#endif
	top.roughness = _TertiaryRoughness;
	top.bumpScale = _TertiaryBumpScale;
#else	
	sampler2D bottomBase = xSideBase;
	#ifdef ALLOY_ENABLE_FULL_TRIPLANAR
		sampler2D bottomMaterial = xSideMaterial;
	#endif
	sampler2D bottomBump = xSideBump;
	
	#ifdef _SECONDARY_TRIPLANAR_ON
		top.uv = ALLOY_XFORM_TEX_SCROLL(_SecondaryMainTex, position.xz);
	#else
		top.uv = ALLOY_XFORM_TEX_SCROLL(_PrimaryMainTex, position.xz);
	#endif
#endif
	
#if defined(_SECONDARY_TRIPLANAR_ON) || defined(_TERTIARY_TRIPLANAR_ON)
	AlloyTriplanar(
		s, 
		top, 
		ALLOY_TRIPLANAR_SAMPLERS(bottom),
		yTangentToWorld,
		blendWeights.y * (1.0h - topBlend));
#endif
	
#ifndef _TRIPLANARMODE_WORLD
	s.normalWorld = mul((half3x3)unity_ObjectToWorld, s.normalWorld);
#endif
	
	s.normalWorld = normalize(s.normalWorld);
	s.NdotV = DotClamped(s.normalWorld, s.viewDirWorld);
	
	AlloyRim(s);
}

void AlloyFinalColor(
	AlloySurfaceDesc s,
	inout half4 color)
{	
	UNITY_APPLY_FOG(s.fogCoord, color);
}

#endif // ALLOY_DEFINITIONS_TRIPLANAR_CGINC
