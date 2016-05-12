// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file SecondaryTextures.cginc
/// @brief Secondary set of textures.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FEATURES_SECONDARY_TEXTURES_CGINC
#define ALLOY_FEATURES_SECONDARY_TEXTURES_CGINC

#ifdef _RIM2_ON
	#ifndef ALLOY_ENABLE_VIEW_VECTOR_TANGENT
		#define ALLOY_ENABLE_VIEW_VECTOR_TANGENT
	#endif
#endif

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef _SECONDARY_TEXTURES_ON
	/// The secondary tint color.
	/// Expects a linear LDR color with alpha.
	half4 _Color2;
	
	/// The secondary color map.
	/// Expects an RGB(A) map with sRGB sampling.
	ALLOY_SAMPLER2D_XFORM(_MainTex2);
	
	/// The secondary packed material map.
	/// Expects an RGBA data map.
	sampler2D _MaterialMap2;

	/// The secondary normal map.
	/// Expects a compressed normal map.
	sampler2D _BumpMap2;
	
	/// Toggles tinting the secondary color by the vertex color.
	/// Expects values in the range [0,1].
	half _BaseColorVertexTint2;

	/// The secondary metallic scale.
	/// Expects values in the range [0,1].
	half _Metallic2;

	/// The secondary specularity scale.
	/// Expects values in the range [0,1].
	half _Specularity2;
	
	/// The secondary roughness scale.
	/// Expects values in the range [0,1].
	half _Roughness2;
	
	/// Ambient Occlusion strength.
	/// Expects values in the range [0,1].
	half _Occlusion2;

	/// Normal map XY scale.
	half _BumpScale2;
#endif

void AlloySecondaryTextures(
	inout AlloySurfaceDesc s)
{
#ifdef _SECONDARY_TEXTURES_ON
	float2 baseUv2 = ALLOY_XFORM_TEX_UV_SCROLL(_MainTex2, s);
	half4 base2 = _Color2 * tex2D(_MainTex2, baseUv2);
	base2.rgb *= LerpWhiteTo(s.vertexColor.rgb, _BaseColorVertexTint2);
	
	s.baseColor = lerp(s.baseColor, base2.rgb, s.mask);
	s.opacity = lerp(s.opacity, base2.a, s.mask);
    
    half4 material2 = tex2D(_MaterialMap2, baseUv2);  
	half ao = LerpOneTo(AlloyGammaToLinear(material2.y), _Occlusion2);      
	s.metallic = lerp(s.metallic, _Metallic2 * material2.x, s.mask);
	s.ambientOcclusion = lerp(s.ambientOcclusion, ao, s.mask);
	s.specularity = lerp(s.specularity, _Specularity2 * material2.z, s.mask);
	s.roughness = lerp(s.roughness, _Roughness2 * material2.w, s.mask);
	
	half3 normal2 = UnpackScaleNormal(tex2D(_BumpMap2, baseUv2), _BumpScale2);
	s.normalTangent = normalize(lerp(s.normalTangent, normal2, s.mask)); 

	// NOTE: These are applied in here so we can use baseUv2.
	float2 baseUv = s.baseUv;
	s.baseUv = baseUv2;
	AlloyEmission2(s);

	#ifdef _RIM2_ON
		s.NdotV = DotClamped(s.normalTangent, s.viewDirTangent);
		AlloyRim2(s);
	#endif
	
	s.baseUv = baseUv;
#endif
}

#endif // ALLOY_FEATURES_SECONDARY_TEXTURES_CGINC
