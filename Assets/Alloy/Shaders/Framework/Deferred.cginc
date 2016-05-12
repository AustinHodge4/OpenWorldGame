// Upgrade NOTE: replaced '_CameraToWorld' with 'unity_CameraToWorld'
// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Deferred.cginc
/// @brief Functions and inputs for deferred shaders.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FRAMEWORK_DEFERRED_CGINC
#define ALLOY_FRAMEWORK_DEFERRED_CGINC

#include "Assets/Alloy/Shaders/Config.cginc"
#include "Assets/Alloy/Shaders/Framework/Surface.cginc"

#include "HLSLSupport.cginc"
#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"
#include "UnityStandardBRDF.cginc"
#include "UnityStandardUtils.cginc"
#include "UnityDeferredLibrary.cginc"

sampler2D _CameraGBufferTexture0;
sampler2D _CameraGBufferTexture1;
sampler2D _CameraGBufferTexture2;

/// Converts Unity's G-Buffer format into a surface description.

/// @param	positionWorld	Position in world-space.

/// @return					Material surface data.
AlloySurfaceDesc AlloySurfaceFromUnityGbuffer(
	unity_v2f_deferred i,
	float2 uv)
{
	AlloySurfaceDesc s = AlloySurfaceDescInit();

	// read depth and reconstruct world position
	float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
	depth = Linear01Depth (depth);
	float4 vpos = float4(i.ray * depth,1);
	float3 positionWorld = mul(unity_CameraToWorld, vpos).xyz;

	s.viewDepth = vpos.z;

	half4 diffuseAo = tex2D (_CameraGBufferTexture0, uv);
	half4 specSmoothness = tex2D (_CameraGBufferTexture1, uv);
	half4 normalId = tex2D (_CameraGBufferTexture2, uv);

	s.materialId = normalId.w;

	s.positionWorld = positionWorld;
	s.albedo = diffuseAo.rgb;
	s.f0 = specSmoothness.rgb;
	s.roughness = 1.0h - specSmoothness.a;
	s.ambientOcclusion = diffuseAo.a;
	s.normalWorld = normalize(normalId.xyz * 2.0h - 1.0h);
	s.viewDirWorld = normalize(UnityWorldSpaceViewDir(positionWorld));
	s.NdotV = DotClamped(s.normalWorld, s.viewDirWorld);
	AlloySetSpecularData(s);
	
	return s;
}

AlloyDirectDesc AlloyDirectFromUnityDeferred(
	inout AlloySurfaceDesc s,
	float2 uv)
{
	AlloyDirectDesc light = AlloyDirectDescInit();
	float fadeDist = UnityDeferredComputeFadeDistance(s.positionWorld, s.viewDepth);
	
	light.color = _LightColor.rgb;
	
#if defined (SPOT)|| defined (POINT) || defined (POINT_COOKIE)
	float3 tolight = _LightPos.xyz - s.positionWorld;
	half lightRangeInv = sqrt(_LightPos.w); // _LightPos.w = 1/r*r
	half lightRange = 1.0h / lightRangeInv;
	half lightSize = _LightColor.a * lightRange;
	
	light.color *= AlloySphereLight(lightSize, lightRangeInv, tolight, s.reflectionVectorWorld, light.direction, light.solidAngle);
	
	#if defined (SPOT)
		float4 uvCookie = mul(unity_WorldToLight, float4(s.positionWorld, 1.0f));
		light.color *= (uvCookie.w < 0.0f) * tex2Dproj(_LightTexture0, UNITY_PROJ_COORD(uvCookie)).w;
		light.shadow = UnityDeferredComputeShadow(s.positionWorld, fadeDist, uv);	
	#endif //SPOT

	#if defined (POINT) || defined (POINT_COOKIE)
		light.shadow = UnityDeferredComputeShadow(-tolight, fadeDist, uv);
				
		#if defined (POINT_COOKIE)
			light.color *= texCUBE(_LightTexture0, mul(unity_WorldToLight, float4(s.positionWorld, 1.0f)).xyz).w;
		#endif //POINT_COOKIE
	#endif //POINT || POINT_COOKIE
	
	s.specularOcclusion *= AlloyAreaLightNormalization(s.beckmannRoughness, light.solidAngle);
#endif

	// directional light case		
#if defined (DIRECTIONAL) || defined (DIRECTIONAL_COOKIE)
	light.direction = -_LightDir.xyz;
	light.shadow = UnityDeferredComputeShadow (s.positionWorld, fadeDist, uv);
		
	#if defined (DIRECTIONAL_COOKIE)
		#ifdef ALLOY_SUPPORT_REDLIGHTS
			light.color *= redLightFunctionLegacy(_LightTexture0, s.positionWorld, s.normalWorld, s.viewDirWorld, light.direction);
		#else
			light.color *= tex2D(_LightTexture0, mul(unity_WorldToLight, half4(s.positionWorld, 1.0h)).xy).w;
		#endif
	#endif //DIRECTIONAL_COOKIE
#endif //DIRECTIONAL || DIRECTIONAL_COOKIE

	return light;
}

#endif // ALLOY_FRAMEWORK_DEFERRED_CGINC
