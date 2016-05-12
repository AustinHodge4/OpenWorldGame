// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Lighting.cginc
/// @brief Includes all the common types and functions for lighting types.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FRAMEWORK_LIGHTING_CGINC
#define ALLOY_FRAMEWORK_LIGHTING_CGINC

// NOTE: Config comes first to override Unity settings!
#include "Assets/Alloy/Shaders/Config.cginc"
#include "Assets/Alloy/Shaders/Framework/Brdf.cginc"
#include "Assets/Alloy/Shaders/Framework/Surface.cginc"
#include "Assets/Alloy/Shaders/Framework/Utility.cginc"

#include "HLSLSupport.cginc"
#include "UnityCG.cginc"
#include "UnityLightingCommon.cginc"

#if !defined(ALLOY_DISABLE_AREA_LIGHTS) && (defined(USING_DIRECTIONAL_LIGHT) || defined(DIRECTIONAL) || defined(DIRECTIONAL_COOKIE))
	#define ALLOY_DISABLE_AREA_LIGHTS
#endif

// Use Unity's struct directly to avoid copying since the fields are the same.
#define AlloyIndirectDesc UnityIndirect

/// Collection of direct illumination data.
struct AlloyDirectDesc 
{
	/// Light color, attenuation, and cookies.
	/// Expects linear-space HDR color values.
	half3 color;
		
	/// Shadowing.
	/// Expects values in the range [0,1].
	half shadow;
	
	/// Light direction in world-space.
	/// Expects normalized vectors in the range [-1,1].
	half3 direction;
	
	/// Solid angle of light, used to obtain area normalization factor;
	/// Expects values in the range [0,n).
	half solidAngle;
};

/// Used to create a light data object with suitable default values. 
/// @return Initialized direct data object.
AlloyDirectDesc AlloyDirectDescInit()
{
	AlloyDirectDesc l;
	UNITY_INITIALIZE_OUTPUT(AlloyDirectDesc, l);
	l.color = 0.0h;
	l.shadow = 1.0h;
	l.direction = half3(0.0h, 1.0h, 0.0h);
	l.solidAngle = 0.0h;
		
	return l;
}

/// Generates values for calculating a spherical area light.
/// @param[in] 	lightSize			Light radius.
/// @param[in] 	lightRangeInverse	1 / lightRange.
/// @param[in] 	L					Light non-normalized vector.
/// @param[in] 	R					View reflection non-normalized vector.
/// @param[out] direction			Light direction in world-space.
/// @param[out] solidAngle			Solid angle of light, used to obtain area normalization factor;
/// @return 						Physical light attenuation.
half AlloySphereLight(
	half lightSize,
	half lightRangeInverse,
	float3 L,
	float3 R,
	out half3 direction,
	out half solidAngle)
{
#ifndef ALLOY_DISABLE_AREA_LIGHTS
	// Most Representative Point approximation for area lights.
	// cf http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf p14-16
	float3 centerToRay = dot(L, R) * R - L;
	direction = normalize(L + centerToRay * saturate(lightSize / length(centerToRay)));
#else
	direction = normalize(L);
#endif

	// For correct attenuation, distance must be to the light volume center!
	half lightDistanceSquared = dot(L, L);
	half lightDistance = sqrt(lightDistanceSquared);
	
#ifndef ALLOY_DISABLE_AREA_LIGHTS
	solidAngle = lightSize / (2.0h * lightDistance + ALLOY_EPSILON);
#else
	solidAngle = 0.0h;
#endif
	
	return AlloyAttenuation(lightDistance, lightDistanceSquared, lightRangeInverse);
}

/// Calculates the modified specular BRDF normalization factor for an area light.
/// @param 	a 			Beckmann roughness [0,1].
/// @param 	solidAngle	Light solid angle [0,1].
/// @return				Area light normalization factor.
half AlloyAreaLightNormalization(
	half a,
	half solidAngle)
{
#ifndef ALLOY_DISABLE_AREA_LIGHTS
	// Spherical Area Light normalization factor.
	// cf http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf pg14-16
	half aP = saturate(a + solidAngle);
	aP = a / aP; 
	return aP * aP;
#else
	return 1.0h;
#endif
}

#endif // ALLOY_FRAMEWORK_LIGHTING_CGINC
