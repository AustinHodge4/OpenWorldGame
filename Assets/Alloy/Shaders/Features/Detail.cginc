// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Detail.cginc
/// @brief Surface detail materials and normals.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FEATURES_DETAIL_CGINC
#define ALLOY_FEATURES_DETAIL_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef _DETAIL_ON
	/// Detail base color blending mode.
	/// Expects either 0 or 1.
	float _DetailMode;
	
	/// Mask that controls the detail influence on the base material.
	/// Expects an alpha data map.
	sampler2D _DetailMask;
	
	/// Controls the detail influence on the base material.
    /// Expects values in the range [0,1].
	half _DetailWeight;
	
	/// Detail base color map.
	/// Expects an RGB map with sRGB sampling.
	ALLOY_SAMPLER2D_XFORM(_DetailAlbedoMap);
	
	/// Detail ambient occlusion(G) and specular AA(A).
	/// Expects an RGBA data map.
	ALLOY_SAMPLER2D_XFORM(_DetailMaterialMap);
	
	/// Detail normal map.
	/// Expects a compressed normal map..
	ALLOY_SAMPLER2D_XFORM(_DetailNormalMap);
	
	/// Ambient Occlusion strength.
	/// Expects values in the range [0,1].
	half _DetailOcclusion;
	
	/// Normal map XY scale.
	half _DetailNormalMapScale;
#endif

/// Applies the Detail feature to the given material data.
/// @param[in,out]	s	Material surface data.
void AlloyDetail(
	inout AlloySurfaceDesc s) 
{
#ifdef _DETAIL_ON
	half mask = s.mask * _DetailWeight;
	
	#ifndef ALLOY_DISABLE_DETAIL_MASK
		mask *= tex2D(_DetailMask, s.baseUv).a;
	#endif
	
	#ifndef ALLOY_DISABLE_DETAIL_COLOR_MAP
		float2 detailUv = ALLOY_XFORM_TEX_UV_SCROLL(_DetailAlbedoMap, s);
	#elif !defined(ALLOY_DISABLE_DETAIL_MATERIAL_MAP)
		float2 detailUv = ALLOY_XFORM_TEX_UV_SCROLL(_DetailMaterialMap, s);
	#else
		float2 detailUv = ALLOY_XFORM_TEX_UV_SCROLL(_DetailNormalMap, s);
	#endif
	
	#ifndef ALLOY_DISABLE_DETAIL_COLOR_MAP
		half3 detailAlbedo = tex2D(_DetailAlbedoMap, detailUv).rgb;
		half3 colorScale = _DetailMode < 0.5f ? half3(1.0h, 1.0h, 1.0h) : unity_ColorSpaceDouble.rgb;
		
		s.baseColor *= LerpWhiteTo(detailAlbedo * colorScale, mask);
	#endif
	
	#ifndef ALLOY_DISABLE_DETAIL_MATERIAL_MAP
		half4 detailMaterial = tex2D(_DetailMaterialMap, detailUv);
		
	    detailMaterial.y = AlloyGammaToLinear(detailMaterial.y);
	    s.ambientOcclusion *= LerpOneTo(detailMaterial.y, mask * _DetailOcclusion);
	    
		// Apply variance to roughness for detail Specular AA.
		// cf http://www.frostbite.com/wp-content/uploads/2014/11/course_notes_moving_frostbite_to_pbr.pdf pg92
		half a = s.roughness * s.roughness;
		a = sqrt(saturate((a * a) + detailMaterial.w * mask));
		s.roughness = sqrt(a);
	#endif

	#ifndef ALLOY_DISABLE_DETAIL_NORMAL_MAP
		half3 detailNormalTangent = UnpackScaleNormal(tex2D(_DetailNormalMap, detailUv), mask * _DetailNormalMapScale);
		s.normalTangent = BlendNormals(s.normalTangent, detailNormalTangent);
	#endif
#endif
} 

#endif // ALLOY_FEATURES_DETAIL_CGINC
