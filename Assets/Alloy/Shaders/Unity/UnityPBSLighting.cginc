#ifndef UNITY_PBS_LIGHTING_INCLUDED
#define UNITY_PBS_LIGHTING_INCLUDED

#include "Assets/Alloy/Shaders/Lighting/Standard.cginc"
#include "Assets/Alloy/Shaders/Framework/GI.cginc"

#include "UnityShaderVariables.cginc"
#include "UnityStandardConfig.cginc"
#include "UnityLightingCommon.cginc"
#include "UnityGlobalIllumination.cginc"

//-------------------------------------------------------------------------------------
// Default BRDF to use:
#if !defined (UNITY_BRDF_PBS) // allow to explicitly override BRDF in custom shader
	#if (SHADER_TARGET < 30) || defined(SHADER_API_PSP2)
		// Fallback to low fidelity one for pre-SM3.0
		#define UNITY_BRDF_PBS BRDF3_Unity_PBS
	#elif defined(SHADER_API_MOBILE)
		// Somewhat simplified for mobile
		#define UNITY_BRDF_PBS BRDF2_Unity_PBS
	#else
		// Full quality for SM3+ PC / consoles
		#define UNITY_BRDF_PBS BRDF1_Unity_PBS
	#endif
#endif

//-------------------------------------------------------------------------------------
// BRDF for lights extracted from *indirect* directional lightmaps (baked and realtime).
// Baked directional lightmap with *direct* light uses UNITY_BRDF_PBS.
// For better quality change to BRDF1_Unity_PBS.
// No directional lightmaps in SM2.0.

#if !defined(UNITY_BRDF_PBS_LIGHTMAP_INDIRECT)
	#define UNITY_BRDF_PBS_LIGHTMAP_INDIRECT BRDF2_Unity_PBS
#endif
#if !defined (UNITY_BRDF_GI)
	#define UNITY_BRDF_GI BRDF_Unity_Indirect
#endif

//-------------------------------------------------------------------------------------


inline half3 BRDF_Unity_Indirect (half3 baseColor, half3 specColor, half oneMinusReflectivity, half oneMinusRoughness, half3 normal, half3 viewDir, half occlusion, UnityGI gi)
{
	half3 c = 0;
	#if defined(DIRLIGHTMAP_SEPARATE)
		gi.indirect.diffuse = 0;
		gi.indirect.specular = 0;

		#ifdef LIGHTMAP_ON
			c += UNITY_BRDF_PBS_LIGHTMAP_INDIRECT (baseColor, specColor, oneMinusReflectivity, oneMinusRoughness, normal, viewDir, gi.light2, gi.indirect).rgb * occlusion;
		#endif
		#ifdef DYNAMICLIGHTMAP_ON
			c += UNITY_BRDF_PBS_LIGHTMAP_INDIRECT (baseColor, specColor, oneMinusReflectivity, oneMinusRoughness, normal, viewDir, gi.light3, gi.indirect).rgb * occlusion;
		#endif
	#endif
	return c;
}

//-------------------------------------------------------------------------------------

// little helpers for GI calculation

#define UNITY_GLOSSY_ENV_FROM_SURFACE(x, s, data)				\
	Unity_GlossyEnvironmentData g;								\
	g.roughness		= 1 - s.Smoothness;							\
	g.reflUVW		= reflect(-data.worldViewDir, s.Normal);	\

// Alloy
#if defined(UNITY_PASS_DEFERRED) && UNITY_ENABLE_REFLECTION_BUFFERS
	#define UNITY_GI(x, s, data) x = UnityGlobalIllumination (data, 1.0h, s.Normal);
#else
	#define UNITY_GI(x, s, data) 								\
		UNITY_GLOSSY_ENV_FROM_SURFACE(g, s, data);				\
		x = UnityGlobalIllumination (data, 1.0h, s.Normal, g);
#endif


//-------------------------------------------------------------------------------------

half4 AlloyForwardOutput(
	AlloySurfaceDesc s, 
	UnityGI gi,
	half solidAngle)
{
	half4 c = 0.0h;

#ifdef UNITY_PASS_FORWARDBASE
	c.rgb = AlloyIndirectFromUnityGi(s, gi);
#else
	s.specularOcclusion *= AlloyAreaLightNormalization(s.beckmannRoughness, solidAngle);
#endif
#ifndef LIGHTMAP_ON
	c.rgb += AlloyDirectFromUnityLight(s, gi.light);
#endif
	c.a = s.opacity;
	
	c.rgb = AlloyHdrClamp(c.rgb);
	return c;
}

half4 AlloyDeferredOutput(
	AlloySurfaceDesc s, 
	UnityGI gi, 
	out half4 outDiffuseOcclusion, 
	out half4 outSpecSmoothness, 
	out half4 outNormal)
{
	half4 illum = AlloyGbuffer(s, outDiffuseOcclusion, outSpecSmoothness, outNormal);

	illum.rgb += AlloyIndirectFromUnityGi(s, gi);
	illum.rgb = AlloyHdrClamp(illum.rgb);
	return illum;
}

//-------------------------------------------------------------------------------------

// Surface shader output structure to be used with physically
// based shading model.

//-------------------------------------------------------------------------------------
// Metallic workflow

struct SurfaceOutputStandard
{
	fixed3 Albedo;		// base (diffuse or specular) color
	fixed3 Normal;		// tangent space normal, if written
	half3 Emission;
	half Metallic;		// 0=non-metal, 1=metal
	half Smoothness;	// 0=rough, 1=smooth
	half Occlusion;		// occlusion (default 1)
	fixed Alpha;		// alpha for transparencies
	half AreaLightSolidAngle;  // Alloy
};

AlloySurfaceDesc AlloySurfaceFromStandard(
	SurfaceOutputStandard si,
	half3 viewDir)
{
	AlloySurfaceDesc s = AlloySurfaceDescInit();
	s.opacity = si.Alpha;
	s.baseColor = si.Albedo;
	s.specularity = 0.5h;
	s.metallic = si.Metallic;
	s.roughness = 1.0h - si.Smoothness;
	s.ambientOcclusion = si.Occlusion;
	s.emission = si.Emission;
	s.normalWorld = normalize(si.Normal);
	s.viewDirWorld = viewDir;
	s.NdotV = DotClamped(s.normalWorld, s.viewDirWorld);
	AlloyPostSurface(s);
	return s;
}

inline half4 LightingStandard (SurfaceOutputStandard si, half3 viewDir, UnityGI gi)
{
	AlloySurfaceDesc s = AlloySurfaceFromStandard(si, viewDir);
	return AlloyForwardOutput(s, gi, si.AreaLightSolidAngle);
}

inline half4 LightingStandard_Deferred (SurfaceOutputStandard si, half3 viewDir, UnityGI gi, out half4 outDiffuseOcclusion, out half4 outSpecSmoothness, out half4 outNormal)
{
	AlloySurfaceDesc s = AlloySurfaceFromStandard(si, viewDir);
	return AlloyDeferredOutput(s, gi, outDiffuseOcclusion, outSpecSmoothness, outNormal);
}

inline void LightingStandard_GI (
	SurfaceOutputStandard s,
	UnityGIInput data,
	inout UnityGI gi)
{
	UNITY_GI(gi, s, data);
}

//-------------------------------------------------------------------------------------
// Specular workflow

struct SurfaceOutputStandardSpecular
{
	fixed3 Albedo;		// diffuse color
	fixed3 Specular;	// specular color
	fixed3 Normal;		// tangent space normal, if written
	half3 Emission;
	half Smoothness;	// 0=rough, 1=smooth
	half Occlusion;		// occlusion (default 1)
	fixed Alpha;		// alpha for transparencies
	half AreaLightSolidAngle;
};

AlloySurfaceDesc AlloySurfaceFromStandardSpecular(
	SurfaceOutputStandardSpecular si,
	half3 viewDir)
{
		// energy conservation
	half oneMinusReflectivity;
	si.Albedo = EnergyConservationBetweenDiffuseAndSpecular (si.Albedo, si.Specular, /*out*/ oneMinusReflectivity);

	// shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
	// this is necessary to handle transparency in physically correct way - only diffuse component gets affected by alpha
	half outputAlpha;
	si.Albedo = PreMultiplyAlpha (si.Albedo, si.Alpha, oneMinusReflectivity, /*out*/ outputAlpha);
	
	AlloySurfaceDesc s = AlloySurfaceDescInit();
	s.opacity = si.Alpha;
	s.albedo = si.Albedo;
	s.f0 = si.Specular;
	s.roughness = 1.0h - si.Smoothness;
	s.ambientOcclusion = si.Occlusion;
	s.emission = si.Emission;
	s.normalWorld = normalize(si.Normal);
	s.viewDirWorld = viewDir;
	s.NdotV = DotClamped(s.normalWorld, s.viewDirWorld);
	AlloySetSpecularData(s); 
	return s;
}

inline half4 LightingStandardSpecular (SurfaceOutputStandardSpecular si, half3 viewDir, UnityGI gi)
{
	AlloySurfaceDesc s = AlloySurfaceFromStandardSpecular(si, viewDir);
	return AlloyForwardOutput(s, gi, si.AreaLightSolidAngle);
}

inline half4 LightingStandardSpecular_Deferred (SurfaceOutputStandardSpecular si, half3 viewDir, UnityGI gi, out half4 outDiffuseOcclusion, out half4 outSpecSmoothness, out half4 outNormal)
{
	AlloySurfaceDesc s = AlloySurfaceFromStandardSpecular(si, viewDir);
	return AlloyDeferredOutput(s, gi, outDiffuseOcclusion, outSpecSmoothness, outNormal);
}

inline void LightingStandardSpecular_GI (
	SurfaceOutputStandardSpecular s,
	UnityGIInput data,
	inout UnityGI gi)
{
	UNITY_GI(gi, s, data);
}

#endif // UNITY_PBS_LIGHTING_INCLUDED
