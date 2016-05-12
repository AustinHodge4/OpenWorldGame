// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file Pass.cginc
/// @brief Shader pass constants and functions.
///////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FRAMEWORK_PASS_CGINC
#define ALLOY_FRAMEWORK_PASS_CGINC

#include "Assets/Alloy/Shaders/Framework/Surface.cginc"
#include "Assets/Alloy/Shaders/Framework/Utility.cginc"
#include "Assets/Alloy/Shaders/Framework/Vertex.cginc"

#include "UnityShaderVariables.cginc"
#include "UnityStandardBRDF.cginc"

#if (!defined(ALLOY_DISABLE_NORMALMAP) || !DIRLIGHTMAP_OFF || defined(ALLOY_ENABLE_VIEW_VECTOR_TANGENT))
	#define ALLOY_ENABLE_TANGENT_TO_WORLD 1 
#endif

#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
	#define ALLOY_SET_FOGCOORDS(i, s) s.fogCoord = i.fogCoord;
#else
	#define ALLOY_SET_FOGCOORDS(i, s) s.fogCoord = 0.0f;
#endif

/// Transfers the per-vertex surface data to the pixel shader.
/// @param[in]	v							Vertex input data.
/// @param[out]	positionWorld				Position in world space.
/// @param[out]	texcoords					UV0 in XY, UV1 in ZW.
/// @param[out]	viewDirWorldAndDepth		View in world space in XYZ, linear view depth in W.
/// @param[out]	tangentToWorldAndParallax0	Tangent in world space.
/// @param[out]	tangentToWorldAndParallax1	Bitangent in world space.
/// @param[out]	tangentToWorldAndParallax2	Normal in world space.
/// @param[out]	color						Vertex color.
void AlloyTransferVertexData(
	AlloyVertexDesc v,
	out float4 positionWorld,
	out float4 texcoords,
	out half4 viewDirWorldAndDepth,
	out half4 tangentToWorldAndParallax0,
	out half4 tangentToWorldAndParallax1,
	out half4 tangentToWorldAndParallax2,
	out half4 color)
{
	AlloyVertex(v);
	
	positionWorld = mul(unity_ObjectToWorld, v.vertex);
	texcoords.xy = v.uv0.xy;
	texcoords.zw = v.uv1.xy;
	viewDirWorldAndDepth.xyz = UnityWorldSpaceViewDir(positionWorld.xyz);
	COMPUTE_EYEDEPTH(viewDirWorldAndDepth.w);
	
	float3 normalWorld = UnityObjectToWorldNormal(v.normal);
	
#ifdef ALLOY_ENABLE_TANGENT_TO_WORLD
	float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
	float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);

	tangentToWorldAndParallax0.xyz = tangentToWorld[0];
	tangentToWorldAndParallax1.xyz = tangentToWorld[1];
	tangentToWorldAndParallax2.xyz = tangentToWorld[2];
#else
	tangentToWorldAndParallax0.xyz = 0.0h;
	tangentToWorldAndParallax1.xyz = 0.0h;
	tangentToWorldAndParallax2.xyz = normalWorld;
#endif

	tangentToWorldAndParallax0.w = 0.0h;
	tangentToWorldAndParallax1.w = 0.0h;
	tangentToWorldAndParallax2.w = 0.0h;
	
	// Gamma-space vertex color, unless the shader modifies it.
	color = v.color;
}

/// Transfers the per-vertex lightmapping or SH data to the pixel shader.
/// @param	v			Vertex input data.
/// @param	normalWorld	World-space normal.
/// @return 			Vertex ambient or lightmap UV.
half4 AlloyTransferAmbientData(
	AlloyVertexDesc v,
	half3 normalWorld)
{
	half4 ambientOrLightmapUV = 0.0h;

#ifndef LIGHTMAP_OFF
	ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
	ambientOrLightmapUV.zw = 0.0h;
#elif UNITY_SHOULD_SAMPLE_SH
	#if UNITY_SAMPLE_FULL_SH_PER_PIXEL
		ambientOrLightmapUV.rgb = 0.0h;
	#else
		ambientOrLightmapUV.rgb = ShadeSH3Order(half4(normalWorld, 1.0h));
	#endif
#endif

#ifdef DYNAMICLIGHTMAP_ON
	ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#endif

	return ambientOrLightmapUV;
}

/// Create a SurfaceDesc populated with data from the vertex shader.
/// @param	positionWorld				Position in world space.
/// @param	texcoords					UV0 in XY, UV1 in ZW.
/// @param	viewDirWorldAndDepth		View in world space in XYZ, linear view depth in W.
/// @param	tangentToWorldAndParallax0	Tangent in world space.
/// @param	tangentToWorldAndParallax1	Bitangent in world space.
/// @param	tangentToWorldAndParallax2	Normal in world space.
/// @param	vertexColor					Vertex color.
/// @return 							Initialized surface data object.
AlloySurfaceDesc AlloySurfaceFromVertexData(
	float3 positionWorld,
	float4 texcoords,
	half4 viewDirWorldAndDepth,
	half4 tangentToWorldAndParallax0,
	half4 tangentToWorldAndParallax1,
	half4 tangentToWorldAndParallax2,
	half4 vertexColor)
{
	AlloySurfaceDesc s = AlloySurfaceDescInit();
	
	s.positionWorld = positionWorld;
	s.uv01 = texcoords;
	s.viewDirWorld = normalize(viewDirWorldAndDepth.xyz);
	s.viewDepth = viewDirWorldAndDepth.w;
	s.vertexColor = vertexColor;
	
#ifdef ALLOY_ENABLE_TANGENT_TO_WORLD
	half3 t = tangentToWorldAndParallax0.xyz;
	half3 b = tangentToWorldAndParallax1.xyz;
	half3 n = tangentToWorldAndParallax2.xyz;
		
	#if UNITY_TANGENT_ORTHONORMALIZE
		n = normalize(n);
	
		// ortho-normalize Tangent
		t = normalize (t - n * dot(t, n));

		// recalculate Binormal
		half3 newB = cross(n, t);
		b = newB * sign (dot (newB, b));
	#endif

	s.tangentToWorld = half3x3(t, b, n);
#else
	s.tangentToWorld = half3x3(0.0h, 0.0h, 0.0h, 0.0h, 0.0h, 0.0h, 0.0h, 0.0h, 0.0h);
#endif
	
#ifdef ALLOY_ENABLE_VIEW_VECTOR_TANGENT
	// IMPORTANT: Had to calculate in pixel shader to fix distortion issues in POM!
	s.viewDirTangent = normalize(mul(s.tangentToWorld, s.viewDirWorld));
#else
	s.viewDirTangent = half3(0.0h, 0.0h, 1.0h);
#endif

	// Give these sane defaults in case the surface shader doesn't set them.
	s.normalWorld = normalize(tangentToWorldAndParallax2.xyz);
	s.NdotV = DotClamped(s.normalWorld, s.viewDirWorld);
	
	AlloyPreSurface(s);
	AlloySurface(s);
	AlloyPostSurface(s);
	return s;
}

#endif // ALLOY_FRAMEWORK_PASS_CGINC
