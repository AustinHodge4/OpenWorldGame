// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file GI.cginc
/// @brief Abstracts lightmapping, light probes, reflection probes, etc.
///////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FRAMEWORK_GI_CGINC
#define ALLOY_FRAMEWORK_GI_CGINC

#include "Assets/Alloy/Shaders/Framework/Lighting.cginc"
#include "Assets/Alloy/Shaders/Framework/Surface.cginc"

#include "HLSLSupport.cginc"
#include "UnityGlobalIllumination.cginc"
#include "UnityLightingCommon.cginc"
#include "UnityStandardBRDF.cginc"
#include "UnityShaderVariables.cginc"

#if !defined(ALLOY_DISABLE_REFLECTION_PROBES) && defined(UNITY_PASS_DEFERRED) && UNITY_ENABLE_REFLECTION_BUFFERS
	#define ALLOY_DISABLE_REFLECTION_PROBES
#endif

/// Calculates direct lighting from UnityLight object.
/// @param	s		Material surface data.
/// @param	light 	UnityLight populated with data.
/// @return 		Direct illumination.
half3 AlloyDirectFromUnityLight(
	AlloySurfaceDesc s,
	UnityLight light)
{	
	AlloyDirectDesc d = AlloyDirectDescInit();
	d.color = light.color;
	d.direction = light.dir;

	return AlloyDirect(d, s);
}

/// Calculates indirect lighting from UnityGI object.
/// @param	s		Material surface data.
/// @param	gi 		UnityGI populated with data.
/// @return 		Indirect illumination.
half3 AlloyIndirectFromUnityGi(
	AlloySurfaceDesc s, 
	UnityGI gi)
{
	half3 c = AlloyIndirect(gi.indirect, s);
	
	#ifdef DIRLIGHTMAP_SEPARATE
		half3 albedo = s.albedo;
		s.albedo *= s.ambientOcclusion;
	
		#ifdef LIGHTMAP_ON
			// Static Indirect
			c += AlloyDirectFromUnityLight(s, gi.light2);
		#endif
		#ifdef DYNAMICLIGHTMAP_ON
			// Dynamic
			c += AlloyDirectFromUnityLight(s, gi.light3);
		#endif
		
		s.albedo = albedo;
		
		#ifdef LIGHTMAP_ON
			// Static Direct
			c += AlloyDirectFromUnityLight(s, gi.light);
		#endif
	#endif
    
	return c;
}

/// Calculates global illumination.
/// @param	s					Material surface data.
/// @param	ambientOrLightmapUV Vertex ambient or lightmap UV.
/// @param	shadow 				Forward Base directional light shadow.
/// @return 					Global illumination.
half3 AlloyGlobalIllumination(
	AlloySurfaceDesc s,
	half4 ambientOrLightmapUV,
	half shadow)
{	
	UnityGIInput d;
	UNITY_INITIALIZE_OUTPUT(UnityGIInput, d);
	d.worldPos = s.positionWorld;
	d.worldViewDir = -s.viewDirWorld; // ???
	d.atten = shadow;
	
#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
	d.ambient = 0;
	d.lightmapUV = ambientOrLightmapUV;
#else
	d.ambient = ambientOrLightmapUV.rgb;
	d.lightmapUV = 0;
#endif
	
	d.boxMax[0] = unity_SpecCube0_BoxMax;
	d.boxMin[0] = unity_SpecCube0_BoxMin;
	d.probePosition[0] = unity_SpecCube0_ProbePosition;
	d.probeHDR[0] = unity_SpecCube0_HDR;

	d.boxMax[1] = unity_SpecCube1_BoxMax;
	d.boxMin[1] = unity_SpecCube1_BoxMin;
	d.probePosition[1] = unity_SpecCube1_ProbePosition;
	d.probeHDR[1] = unity_SpecCube1_HDR;
	
	// Pass 1.0 for occlusion so we can apply it later in AlloyIndirect().
	UnityGI gi = UnityGI_Base(d, 1.0h, s.normalWorld);
	
#ifdef ALLOY_DISABLE_REFLECTION_PROBES
	gi.indirect.specular = 0.0h;
#else
	Unity_GlossyEnvironmentData g;
	UNITY_INITIALIZE_OUTPUT(Unity_GlossyEnvironmentData, g);
	g.roughness = s.roughness;
	g.reflUVW = s.reflectionVectorWorld;
	
	gi.indirect.specular = UnityGI_IndirectSpecular(d, 1.0h, s.normalWorld, g);
#endif
	
	return AlloyIndirectFromUnityGi(s, gi);
}

#endif // ALLOY_FRAMEWORK_GI_CGINC
