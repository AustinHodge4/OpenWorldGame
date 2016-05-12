// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Utility.cginc
/// @brief Minimum functions and constants common to surfaces and particles.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FRAMEWORK_UTILITY_CGINC
#define ALLOY_FRAMEWORK_UTILITY_CGINC

#include "Assets/Alloy/Shaders/Config.cginc"

#include "UnityShaderVariables.cginc"

/// A value close to zero.
/// This is used for preventing NaNs in cases where you can divide by zero.
#define ALLOY_EPSILON (1e-6f)

/// Flat normal in tangent space.
#define ALLOY_FLAT_NORMAL (half3(0.0h, 0.0h, 1.0h))

/// Defines all texture transform uniform variables, inlcuding additional transforms.
/// Spin is in radians.
#define ALLOY_SAMPLER2D_XFORM(name) \
	sampler2D name; \
	float4 name##_ST; \
	float2 name##Velocity; \
	float name##Spin; \
	float name##UV;

// NOTE: To make it rotate around a "center" point, the order of operations
// needs to be offset, rotate, scale. So that means that we have to apply 
// offset & scroll first divided by tiling. Then when we apply tiling later 
// it will cancel.

/// Applies our scrolling effect.
#define ALLOY_XFORM_SCROLL(name) ((name##Velocity * _Time.y + name##_ST.zw) / name##_ST.xy)

/// Applies our spinning effect.
#define ALLOY_XFORM_SPIN(name, tex) (AlloyTextureRotation(name##Spin * _Time.y, tex.xy))

/// Applies Unity texture transforms plus our spinning effect. 
#define ALLOY_XFORM_TEX_SPIN(name, tex) (ALLOY_XFORM_SPIN(name, tex + (name##_ST.zw / name##_ST.xy)) * name##_ST.xy)

/// Applies Unity texture transforms plus our spinning and scrolling effects.
#define ALLOY_XFORM_TEX_SCROLL(name, tex) ((tex + ALLOY_XFORM_SCROLL(name)) * name##_ST.xy)

/// Applies Unity texture transforms plus our spinning and scrolling effects.
#define ALLOY_XFORM_TEX_SCROLL_SPIN(name, tex) (ALLOY_XFORM_SPIN(name, tex + ALLOY_XFORM_SCROLL(name)) * name##_ST.xy)

/// Applies 2D texture rotation around the point (0.5,0.5) in UV-space.
/// @param	rotation	Rotation in radians.
/// @param	texcoords	Texture coordinates to be rotated.
/// @return				Rotated texture coordinates.
float2 AlloyTextureRotation(
	float rotation,
	float2 texcoords)
{
	// Texture Rotation
	// cf http://forum.unity3d.com/threads/rotation-of-texture-uvs-directly-from-a-shader.150482/#post-1031763 
	float2 centerOffset = float2(0.5f, 0.5f);
	float sinTheta = sin(rotation);
	float cosTheta = cos(rotation);
	float2x2 rotationMatrix = float2x2(cosTheta, -sinTheta, sinTheta, cosTheta);
	return mul(texcoords - centerOffset, rotationMatrix) + centerOffset;
}

/// Converts a value from gamma space to linear space with a fast approximation. 
/// Useful when you want to scale a color by a value, and want it to have a
/// perceptually linear gain in intensity. 
/// @param	value	Gamma-space scalar.
/// @return			Linear-space scalar.
half AlloyGammaToLinear(
	half value) 
{
	// Cubic approximation to the official sRGB curve.
  	// cf http://chilliant.blogspot.de/2012/08/srgb-approximations-for-hlsl.html
  	return value * (value * (value * 0.305306011h + 0.682171111h) + 0.012522878h);
}

/// Converts a color from gamma space to linear space with a fast approximation. 
/// @param	value	Gamma-space color.
/// @return			Linear-space color.
half3 AlloyGammaToLinear(
	half3 value) 
{
	// Cubic approximation to the official sRGB curve.
  	// cf http://chilliant.blogspot.de/2012/08/srgb-approximations-for-hlsl.html
  	return value * (value * (value * 0.305306011h + 0.682171111h) + 0.012522878h);
}

/// Converts a color from linear space to gamma space with a fast approximation. 
/// Used for cases when you pull a value from a color texture that isn't
/// supposed to be a color and you need to undo the automatic sRGB. 
/// @param	color	Linear-space color.
/// @return			Gamma-space color.
half3 AlloyLinearToGamma(
	half3 color) 
{
	// Cubic approximation to the official sRGB curve.
  	// cf http://chilliant.blogspot.de/2012/08/srgb-approximations-for-hlsl.html
  	half3 S1 = sqrt(color);
	half3 S2 = sqrt(S1);
	half3 S3 = sqrt(S2);
  
  	return 0.662002687h * S1 + 0.684122060h * S2 - 0.323583601h * S3 - 0.225411470h * color;
}

/// Calculates a linear color's luminance.
/// @param	color	Linear LDR color.
/// @return			Color's chromaticity.
half AlloyLuminance(
	half3 color) 
{
	// Linear-space luminance coefficients.
	// cf https://en.wikipedia.org/wiki/Luma_(video)
	return dot(color, half3(0.2126h, 0.7152h, 0.0722h));
}

/// Calculates a linear color's chromaticity.
/// @param	color	Linear LDR color.
/// @return			Color's chromaticity.
half3 AlloyChromaticity(
	half3 color) 
{
	return color / max(AlloyLuminance(color), ALLOY_EPSILON).rrr;
}

/// Clamp HDR output to avoid excess bloom and blending errors.
/// @param 	value	Linear HDR value.
/// @return 		Range-limited HDR color [0,32].
half AlloyHdrClamp(
	half value)
{
#if ALLOY_CONFIG_ENABLE_HDR_CLAMP
	value = min(value, ALLOY_CONFIG_HDR_CLAMP_MAX_INTENSITY);
#endif
	return value;
}

/// Clamp HDR output to avoid excess bloom and blending errors.
/// @param 	color	Linear HDR color.
/// @return 		Range-limited HDR color [0,32].
half3 AlloyHdrClamp(
	half3 color)
{
#if ALLOY_CONFIG_ENABLE_HDR_CLAMP
	color = min(color, (ALLOY_CONFIG_HDR_CLAMP_MAX_INTENSITY).rrr);
#endif
	return color;
}

/// Clamp HDR output to avoid excess bloom and blending errors.
/// @param 	color	Linear HDR color.
/// @return 		Range-limited HDR color [0,32].
half4 AlloyHdrClamp(
	half4 color)
{
#if ALLOY_CONFIG_ENABLE_HDR_CLAMP
	color = min(color, (ALLOY_CONFIG_HDR_CLAMP_MAX_INTENSITY).rrrr);
#endif
	return color;
}

/// Used to calculate a rim light effect.
/// @param	bias	Bias rim towards constant emission.
/// @param	power 	Rim falloff.
/// @param	NdotV	Normal and view vector dot product.
/// @return 		Rim lighting.
half AlloyRimLight(
	half bias, 
	half power, 
	half NdotV) 
{
	return lerp(bias, 1.0h, pow(1.0h - NdotV, power));
}

/// Applies four closest lights per-vertex using Alloy's attenuation.
/// @param	lightPosX		Four lights' position X in world-space.
/// @param	lightPosY		Four lights' position Y in world-space.
/// @param	lightPosZ		Four lights' position Z in world-space.
/// @param	lightColor0		First light color.
/// @param	lightColor1		Second light color.
/// @param	lightColor2		Third light color.
/// @param	lightColor3		Fourth light color.
/// @param	lightAttenSq	Four lights' Unity attenuation.
/// @param	pos				Position in world-space.
/// @param	normal			Normal in world-space.
/// @return 				Per-vertex direct lighting.
float3 AlloyShade4PointLights (
	float4 lightPosX, float4 lightPosY, float4 lightPosZ,
	float3 lightColor0, float3 lightColor1, float3 lightColor2, float3 lightColor3,
	float4 lightAttenSq,
	float3 pos, float3 normal)
{
	// to light vectors
	float4 toLightX = lightPosX - pos.x;
	float4 toLightY = lightPosY - pos.y;
	float4 toLightZ = lightPosZ - pos.z;
	// squared lengths
	float4 lengthSq = 0;
	lengthSq += toLightX * toLightX;
	lengthSq += toLightY * toLightY;
	lengthSq += toLightZ * toLightZ;
	// NdotL
	float4 ndotl = 0;
	ndotl += toLightX * normal.x;
	ndotl += toLightY * normal.y;
	ndotl += toLightZ * normal.z;
	// correct NdotL
	float4 corr = rsqrt(lengthSq);
	ndotl = max (float4(0,0,0,0), ndotl * corr);
	
	// attenuation
	// NOTE: Get something close to Alloy attenuation by undoing Unity's calculations.
	// http://forum.unity3d.com/threads/easiest-way-to-change-point-light-attenuation-with-deferred-path.254337/#post-1681835
	float4 invRangeSqr = lightAttenSq / 25.0f;
	
	// Inverse Square attenuation, with light range falloff.
	// cf http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf p12
	float4 ratio2 = lengthSq * invRangeSqr;
	float4 num = saturate(float4(1.0f, 1.0f, 1.0f, 1.0f) - (ratio2 * ratio2));
	float4 atten = (num * num) / (lengthSq + float4(1.0f, 1.0f, 1.0f, 1.0f));
	
	float4 diff = ndotl * atten;
	// final color
	float3 col = 0;
	col += lightColor0 * diff.x;
	col += lightColor1 * diff.y;
	col += lightColor2 * diff.z;
	col += lightColor3 * diff.w;
	return col;
}

/// Applies 4 closest lights per-vertex using Alloy's attenuation.
/// @param	positionWorld	Position in world-space.
/// @param	normalWorld		Normal in world-space.
/// @return 				Per-vertex direct lighting.
float3 AlloyVertexLights(
	float3 positionWorld, 
	float3 normalWorld) 
{
	return AlloyShade4PointLights(
		unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
		unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
		unity_4LightAtten0, positionWorld, normalWorld);
}

#endif // ALLOY_FRAMEWORK_UTILITY_CGINC
