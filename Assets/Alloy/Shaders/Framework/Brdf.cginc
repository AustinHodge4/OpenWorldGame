// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file Brdf.cginc
/// @brief BRDF constants and functions for illuminating a surface.
///////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FRAMEWORK_BRDF_CGINC
#define ALLOY_FRAMEWORK_BRDF_CGINC

#include "Assets/Alloy/Shaders/Framework/Utility.cginc"

#include "UnityStandardUtils.cginc"

/// Calculates specular occlusion.
/// @param 	ao 		Linear ambient occlusion.
/// @param 	NdotV	Normal and eye vector dot product [0,1].
/// @return 		Specular occlusion.
half AlloySpecularOcclusion(
	half ao, 
	half NdotV) 
{	
	// Yoshiharu Gotanda's specular occlusion approximation:
	// cf http://research.tri-ace.com/Data/cedec2011_RealtimePBR_Implementation_e.pptx pg59
	half d = NdotV + ao;
	return saturate((d * d) - 1.0h + ao);
}

/// Calculates physical light attenuation with a range falloff.
/// @param 	lightDistance 			Distance from light center to surface.
/// @param 	lightDistanceSquared	Squared distance from light center to surface.
/// @param 	lightRangeInverse		1 / lightRange.
/// @return 						Physical light attenuation.
half AlloyAttenuation(
	half lightDistance,
	half lightDistanceSquared,
	half lightRangeInverse)
{
	// Inverse Square attenuation, with light range falloff.
	// cf http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf p12
	half ratio = lightDistance * lightRangeInverse;
	half ratio2 = ratio * ratio;
	half num = saturate(1.0h - (ratio2 * ratio2));
	return (num * num) / (lightDistanceSquared + 1.0h);
}

/// Blend weight portion of Schlick fresnel equation.
/// @param 	w	Clamped dot product of two normalized vectors.
/// @return		Fresnel blend weight.
half AlloyFresnel(
	half w) 
{
	// Sebastien Lagarde's spherical gaussian approximation of Schlick fresnel.
	// cf http://seblagarde.wordpress.com/2011/08/17/hello-world/
	return exp2((-5.55473h * w - 6.98316h) * w);
}

/// Implements a diffuse BRDF affected by roughness.
/// @param 	albedo 		Diffuse albedo LDR color.
/// @param 	roughness 	Linear roughness [0,1].
/// @param 	LdotH 		Light and half-angle clamped dot product [0,1].
/// @param 	NdotL 		Normal and light clamped dot product [0,1].
/// @param 	NdotV 		Normal and view clamped dot product [0,1].
/// @return				Direct diffuse BRDF.
half3 AlloyDiffuseBrdf(
	half3 albedo,
	half roughness,
	half LdotH,
	half NdotL,
	half NdotV)
{
	// Impelementation of Brent Burley's diffuse BRDF.
	// Subject to Apache License, version 2.0
	// cf https://github.com/wdas/brdf/blob/master/src/brdfs/disney.brdf
	half FL = AlloyFresnel(NdotL);
	half FV = AlloyFresnel(NdotV);
	half Fd90 = 0.5h + (2.0h * LdotH * LdotH * roughness);
	half Fd = LerpOneTo(Fd90, FL) * LerpOneTo(Fd90, FV);
	
	// Pi is cancelled by implicit punctual lighting equation.
	// cf http://seblagarde.wordpress.com/2012/01/08/pi-or-not-to-pi-in-game-lighting-equation/
	return albedo * Fd;
}

/// Calculates direct specular BRDF.
/// @param 	f0			Fresnel reflectance at incidence zero, LDR color.
/// @param 	a 			Beckmann roughness [0,1].
/// @param 	LdotH		Light and half-angle clamped dot product [0,1].
/// @param 	NdotH 		Normal and half-angle clamped dot product [0,1].
/// @param 	NdotL 		Normal and light clamped dot product [0,1].
/// @param 	NdotV 		Normal and view clamped dot product [0,1].
/// @return				Direct specular BRDF.
half3 AlloySpecularBrdf(
	half3 f0, 
	half a,
	half LdotH, 
	half NdotH, 
	half NdotL, 
	half NdotV) 
{	
	// Schlick's Fresnel approximation.
	half3 f = lerp(f0, half3(1.0h, 1.0h, 1.0h), AlloyFresnel(LdotH));

	// GGX (Trowbridge-Reitz) NDF
	// cf http://graphicrants.blogspot.com/2013/08/specular-brdf-reference.html
	half a2 = a * a;
	half denom = LerpOneTo(a2, NdotH * NdotH);
	
	// Pi is cancelled by implicit punctual lighting equation.
	// cf http://seblagarde.wordpress.com/2012/01/08/pi-or-not-to-pi-in-game-lighting-equation/
	half d = a2 / (denom * denom);

	// John Hable's visibility function.
	// cf http://www.filmicworlds.com/2014/04/21/optimizing-ggx-shaders-with-dotlh/
	half k = a * 0.5h;
	half v = lerp(k * k, 1.0h, LdotH * LdotH);

	// Cook-Torrance microfacet model.
	// cf http://graphicrants.blogspot.com/2013/08/specular-brdf-reference.html
	return f * (d / (4.0h * v));
}

/// Calculates the indirect illumination BRDF.
/// @param 	albedo 		Diffuse albedo LDR color.
/// @param 	f0			Fresnel reflectance at incidence zero, LDR color.
/// @param 	roughness 	Linear roughness [0,1].
/// @param 	ao 			Linear ambient occlusion.
/// @param 	so 			Specular occlusion.
/// @param 	NdotV 		Normal and view clamped dot product [0,1].
/// @param 	diffuse		Diffuse indirect illumination.
/// @param 	specular 	Specular indirect illumination.
/// @return				Indirect BRDF.
half3 AlloyIndirectBrdf(
	half3 albedo,
	half3 f0, 
	half roughness,
	half ao,
	half so,
	half NdotV,
	half3 diffuse,
	half3 specular) 
{
	// Brian Karis' modification of Dimitar Lazarov's Environment BRDF.
	// cf https://www.unrealengine.com/blog/physically-based-shading-on-mobile
	const half4 c0 = half4(-1.0h, -0.0275h, -0.572h, 0.022h);
	const half4 c1 = half4(1.0h, 0.0425h, 1.04h, -0.04h);
	half4 r = roughness * c0 + c1;
	half a004 = min(r.x * r.x, exp2(-9.28h * NdotV)) * r.x + r.y;
	half2 AB = half2(-1.04h, 1.04h) * a004 + r.zw;
	half3 envBrdf = f0 * AB.x + AB.yyy;
	
	// Yoshiharu Gotanda's fake interreflection for specular occlusion.
	// Modified to better account for surface f0.
	// cf http://research.tri-ace.com/Data/cedec2011_RealtimePBR_Implementation_e.pptx pg65
	half3 ambient = diffuse * ao;
	
	return ambient * albedo
		     + lerp(ambient * f0, specular * envBrdf, so);
}

#endif // ALLOY_FRAMEWORK_BRDF_CGINC
