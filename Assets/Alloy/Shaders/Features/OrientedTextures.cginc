// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file OrientedTextures.cginc
/// @brief Secondary set of textures using world/object position XZ as their UVs.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FEATURES_ORIENTED_TEXTURES_CGINC
#define ALLOY_FEATURES_ORIENTED_TEXTURES_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef _ORIENTED_TEXTURES_ON
	/// The world-oriented tint color.
	/// Expects a linear LDR color with alpha.
	half4 _OrientedColor;
	
	/// The world-oriented color map.
	/// Expects an RGB(A) map with sRGB sampling.
	ALLOY_SAMPLER2D_XFORM(_OrientedMainTex);
	
	/// The world-oriented packed material map.
	/// Expects an RGBA data map.
	sampler2D _OrientedMaterialMap;

	/// The world-oriented normal map.
	/// Expects a compressed normal map.
	sampler2D _OrientedBumpMap;
	
	/// Toggles tinting the world-oriented color by the vertex color.
	/// Expects values in the range [0,1].
	half _OrientedColorVertexTint;

	/// The world-oriented metallic scale.
	/// Expects values in the range [0,1].
	half _OrientedMetallic;

	/// The world-oriented specularity scale.
	/// Expects values in the range [0,1].
	half _OrientedSpecularity;
	
	/// The world-oriented roughness scale.
	/// Expects values in the range [0,1].
	half _OrientedRoughness;

	/// Ambient Occlusion strength.
	/// Expects values in the range [0,1].
	half _OrientedOcclusion;
	
	/// Normal map XY scale.
	half _OrientedNormalMapScale;
#endif

void AlloyOrientedTextures(
	inout AlloySurfaceDesc s)
{
#ifdef _ORIENTED_TEXTURES_ON
	// Unity uses a Left-handed axis, so it requires clumsy remapping.
	half3 normalWorld = s.tangentToWorld[2].xyz;
	const half3x3 yTangentToWorld = half3x3(half3(1.0h, 0.0h, 0.0h), half3(0.0h, 0.0h, 1.0h), normalWorld);
	
	float2 orientedUv = ALLOY_XFORM_TEX_SCROLL(_OrientedMainTex, s.positionWorld.xz);
	half4 base2 = _OrientedColor * tex2D(_OrientedMainTex, orientedUv);
	base2.rgb *= LerpWhiteTo(s.vertexColor.rgb, _OrientedColorVertexTint);
		
	half mask = s.mask * base2.a;
	s.baseColor = lerp(s.baseColor, base2.rgb, mask);
	s.opacity = lerp(s.opacity, 1.0h, mask);
     
    half4 material2 = tex2D(_OrientedMaterialMap, orientedUv); 
    half ao = LerpOneTo(AlloyGammaToLinear(material2.y), _OrientedOcclusion);
	s.metallic = lerp(s.metallic, _OrientedMetallic * material2.x, mask);
	s.ambientOcclusion = lerp(s.ambientOcclusion, ao, mask);
	s.specularity = lerp(s.specularity, _OrientedSpecularity * material2.z, mask);
	s.roughness = lerp(s.roughness, _OrientedRoughness * material2.w, mask);
	s.emission *= (1.0h - mask);

	half3 normal = UnpackScaleNormal(tex2D(_OrientedBumpMap, orientedUv), _OrientedNormalMapScale);
	normal = mul(normal, yTangentToWorld);
	s.normalWorld = normalize(lerp(s.normalWorld, normal, mask));
#endif
}

#endif // ALLOY_FEATURES_ORIENTED_TEXTURES_CGINC
