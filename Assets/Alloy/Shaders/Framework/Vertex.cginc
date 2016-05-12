// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file Vertex.cginc
/// @brief Vertex input data from the application.
///////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FRAMEWORK_VERTEX_CGINC
#define ALLOY_FRAMEWORK_VERTEX_CGINC

#if defined(DYNAMICLIGHTMAP_ON) || defined(UNITY_PASS_META)
	#define ALLOY_ENABLE_UV2
#endif

/// Vertex input from the model data.
struct AlloyVertexDesc 
{
	float4 vertex	: POSITION;
	half3 normal	: NORMAL;
	float2 uv0		: TEXCOORD0;
	float2 uv1		: TEXCOORD1;
	
#ifdef ALLOY_ENABLE_UV2
	float2 uv2		: TEXCOORD2;
#endif
// TODO: Figure out a way to disable these without having to copy data!
//#ifdef ALLOY_ENABLE_TANGENT_TO_WORLD
	half4 tangent	: TANGENT;
//#endif
  	half4 color 	: COLOR;
};

#endif // ALLOY_FRAMEWORK_VERTEX_CGINC
