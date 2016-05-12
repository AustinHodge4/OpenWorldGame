// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file Hair.cginc
/// @brief Hair lighting model. Forward-only.
///////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_LIGHTING_HAIR_CGINC
#define ALLOY_LIGHTING_HAIR_CGINC

// Anisotropy and our area light approximation don't play well together.
#define ALLOY_DISABLE_AREA_LIGHTS

#define ALLOY_SURFACE_CUSTOM_DATA 	\
	half diffuseWrap;				\
	half3 highlightTangent;			\
	half3 highlightTint0;			\
	half highlightShift0;			\
	half highlightWidth0;			\
	half3 highlightTint1;			\
	half highlightShift1;			\
	half highlightWidth1;			\
									\
	half3 highlightTangentWorld; 	\
	half3 specularColor0; 			\
	half roughness0;				\
	half3 specularColor1; 			\
	half roughness1;

#include "Assets/Alloy/Shaders/Framework/Lighting.cginc"

/// Kajiya-Kay anisotropic specular.
/// @param 	f0			Fresnel reflectance at incidence zero, LDR color.
/// @param 	roughness 	Linear roughness [0,1].
/// @param 	shift		Amount to shift the highlight along the normal [0,1].
/// @param 	T			Highlight Tangent vector.
/// @param 	N			Normal vector.
/// @param 	H			Half-angle vector.
/// @return				Kajiya-Kay specular.
half3 AlloyKajiyaKay(
	half3 f0,
	half roughness,
	half shift,
	half3 T,
	half3 N,
	half3 H)
{	
	// Convert Beckmann roughness to Blinn Phong specular power.
	// cf http://graphicrants.blogspot.com/2013/08/specular-brdf-reference.html
	half a = AlloyConvertRoughness(roughness);
	half sp = (2.0h / (a * a)) - 2.0h;
	
	// Modified Kajiya-kay.
	// cf http://developer.amd.com/wordpress/media/2012/10/Scheuermann_HairRendering.pdf
	half tdhm = dot(normalize(T + N * shift), H);
	
	// HACK: Treat like Normalized Blinn Phong NDF, with 1/4 precombined.
	// Semi-physical, and looks more consistent with the IBL.
	half d = (sp * 0.125h + 0.25h) * pow(sqrt(1.0h - tdhm * tdhm), sp);
	
	/// Only use spec color since fresnel makes wide highlights white at edges.
	return f0 * d;
}

void AlloyPreSurface(
	inout AlloySurfaceDesc s)
{
	s.diffuseWrap = 0.25h;
	s.highlightTangent = half3(0.0h, 1.0h, 0.0h);
	s.highlightTint0 = half3(1.0h, 1.0h, 1.0h);
	s.highlightShift0 = 0.0h;
	s.highlightWidth0 = 0.25h;
	s.highlightTint1 = half3(1.0h, 1.0h, 1.0h);
	s.highlightShift1 = 0.0h;
	s.highlightWidth1 = 0.25h;
}

void AlloyPostSurface(
	inout AlloySurfaceDesc s)
{	
	AlloySetPbrData(s);
	AlloySetSpecularData(s);
	
	// Tangent
	s.highlightTangentWorld = ALLOY_XFORM_NORMAL(s, s.highlightTangent);
	
	// Hair data.	
	s.specularColor0 = s.f0 * s.highlightTint0;
	s.roughness0 = lerp(s.roughness, 1.0h, s.highlightWidth0);
	
	s.specularColor1 = s.f0 * s.highlightTint1; 
	s.roughness1 = lerp(s.roughness, 1.0h, s.highlightWidth1);
	
	// Average values from the two highlights for IBL.
	s.f0 = (s.specularColor0 + s.specularColor1) * 0.5h;
	s.roughness = (s.roughness0 + s.roughness1) * 0.5h;
}

half3 AlloyDirect( 
	AlloyDirectDesc d,
	AlloySurfaceDesc s)
{	
	half3 H = normalize(d.direction + s.viewDirWorld);
	half NdotLm = dot(s.normalWorld, d.direction);
	half NdotL = max(0.0h, NdotLm);
	
	// Energy-conserving wrap lighting.
	// cf http://seblagarde.wordpress.com/2012/01/08/pi-or-not-to-pi-in-game-lighting-equation/
	half denom = (1.0h + s.diffuseWrap);
	half3 diffuse = s.albedo * saturate((NdotLm + s.diffuseWrap) / (denom * denom));
	
	// Scheuermann hair lighting
	// cf http://www.shaderwrangler.com/publications/hairsketch/hairsketch.pdf
	half3 d0 = AlloyKajiyaKay(s.specularColor0, s.roughness0, s.highlightShift0, s.highlightTangentWorld, s.normalWorld, H);
	half3 d1 = AlloyKajiyaKay(s.specularColor1, s.roughness1, s.highlightShift1, s.highlightTangentWorld, s.normalWorld, H);
		
	// max() for energy conservation where the specular highlights overlap.
	return d.color * d.shadow * (
			diffuse
			+ ((s.specularOcclusion * NdotL) * max(d0, d1)));
}

half3 AlloyIndirect(
	AlloyIndirectDesc i,
	AlloySurfaceDesc s)
{	
	// Yoshiharu Gotanda's fake interreflection for specular occlusion.
	// Modified to better account for surface f0.
	// cf http://research.tri-ace.com/Data/cedec2011_RealtimePBR_Implementation_e.pptx pg65
	half3 ambient = i.diffuse * s.ambientOcclusion;
	
	// No environment BRDF, as it makes the hair look greasy.
	return ambient * s.albedo
		     + s.f0 * lerp(ambient, i.specular, s.specularOcclusion);
}

#endif // ALLOY_LIGHTING_HAIR_CGINC
