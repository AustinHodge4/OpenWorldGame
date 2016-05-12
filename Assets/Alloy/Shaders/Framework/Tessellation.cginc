// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file Tessellation.cginc
/// @brief Callbacks and data structures for tessellation.
///////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_FRAMEWORK_TESSELLATION_CGINC
#define ALLOY_FRAMEWORK_TESSELLATION_CGINC

#include "Assets/Alloy/Shaders/Config.cginc"
#include "Assets/Alloy/Shaders/Framework/Vertex.cginc"
#include "Assets/Alloy/Shaders/Framework/Pass.cginc"
#include "Assets/Alloy/Shaders/Framework/Utility.cginc"

#include "HLSLSupport.cginc"
#include "UnityCG.cginc"
#include "Tessellation.cginc"
#include "Lighting.cginc"
#include "UnityShaderVariables.cginc"

#if defined(ALLOY_ENABLE_TESSELLATION) && defined(UNITY_CAN_COMPILE_TESSELLATION)	
	#if defined(_TESSELLATIONMODE_COMBINED)
		#define _TESSELLATIONMODE_DISPLACEMENT
		#define _TESSELLATIONMODE_PHONG
	#endif
	
	struct AlloyVertexOutputTessellation 
	{
  		float4 vertex : INTERNALTESSPOS;
		half3 normal : NORMAL;
		float2 uv0 : TEXCOORD0;
		float2 uv1 : TEXCOORD1;
	#ifdef ALLOY_ENABLE_UV2
		float2 uv2 : TEXCOORD2;
	#endif
	#ifdef ALLOY_ENABLE_TANGENT_TO_WORLD
		half4 tangent : TANGENT;
	#endif
	  	half4 color 	: COLOR;
	};
    
    float _EdgeLength;
    
    #if ALLOY_CONFIG_ENABLE_TESSELLATION_MIN_EDGE_LENGTH
    	float _MinEdgeLength;
    #endif

	#ifdef _TESSELLATIONMODE_DISPLACEMENT
		ALLOY_SAMPLER2D_XFORM(_DispTex);
	    float _Displacement;
	#endif
	#ifdef _TESSELLATIONMODE_PHONG
		float _Phong;
	#endif

	/// Takes in vertices representing a triangle and barycentric coordinates
	/// in order to generate data for a vertex somewhere in between.
	AlloyVertexDesc AlloyInterpolateVertex(
		const OutputPatch<AlloyVertexOutputTessellation,3> vi, 
		float3 bary)
	{
		AlloyVertexDesc v;
		UNITY_INITIALIZE_OUTPUT(AlloyVertexDesc, v);

		v.vertex = vi[0].vertex * bary.x + vi[1].vertex * bary.y + vi[2].vertex * bary.z;
		v.normal = vi[0].normal * bary.x + vi[1].normal * bary.y + vi[2].normal * bary.z;
		v.uv0 = vi[0].uv0 * bary.x + vi[1].uv0 * bary.y + vi[2].uv0 * bary.z;
		v.uv1 = vi[0].uv1 * bary.x + vi[1].uv1 * bary.y + vi[2].uv1 * bary.z;	 

	#ifdef ALLOY_ENABLE_UV2
		v.uv2 = vi[0].uv2 * bary.x + vi[1].uv2 * bary.y + vi[2].uv2 * bary.z;	  
	#endif
	#ifdef ALLOY_ENABLE_TANGENT_TO_WORLD
		v.tangent = vi[0].tangent * bary.x + vi[1].tangent * bary.y + vi[2].tangent * bary.z;
	#endif
		v.color = vi[0].color * bary.x + vi[1].color * bary.y + vi[2].color * bary.z;

	#ifdef _TESSELLATIONMODE_PHONG
		float3 pp[3];
		
		for (int i = 0; i < 3; ++i)
			pp[i] = v.vertex.xyz - vi[i].normal * (dot(v.vertex.xyz, vi[i].normal) - dot(vi[i].vertex.xyz, vi[i].normal));
		
		float3 displacedPosition = pp[0] * bary.x + pp[1] * bary.y + pp[2] * bary.z;
		v.vertex.xyz = lerp(v.vertex.xyz, displacedPosition, _Phong);
	#endif
	
	// NOTE: This has to come second, since the Phong mode references the 
	// unmodified vertices in order to work!
	#ifdef _TESSELLATIONMODE_DISPLACEMENT
		float d = _Displacement;
		float oscillation = _Time.y;
    	float2 tessUv = TRANSFORM_TEX(v.uv0.xy, _DispTex) + (_DispTexVelocity * oscillation);
    	
		#ifdef _VIRTUALTEXTURING_ON
			d *= VTVertexSampleDisplacement(tessUv);
		#else
        	d *= tex2Dlod(_DispTex, float4(tessUv, 0.0f, 0.0f)).g;
		#endif
    	
        v.vertex.xyz += v.normal * d;
	#endif
		
		return v;
	}
	
	AlloyVertexOutputTessellation AlloyVertexTessellation(
		AlloyVertexDesc v) 
	{
		AlloyVertexOutputTessellation o;
		UNITY_INITIALIZE_OUTPUT(AlloyVertexOutputTessellation, o);
		o.vertex = v.vertex;
		o.normal = v.normal;
		o.uv0 = v.uv0;
		o.uv1 = v.uv1;
	  
	#ifdef ALLOY_ENABLE_UV2
  		o.uv2 = v.uv2;
	#endif
	#ifdef ALLOY_ENABLE_TANGENT_TO_WORLD
  		o.tangent = v.tangent;
	#endif
		o.color = v.color;

	  	return o;
	}

	// tessellation hull constant shader
	UnityTessellationFactors AlloyHullConstantTessellation(
		InputPatch<AlloyVertexOutputTessellation,3> v) 
	{
		UnityTessellationFactors o;
		float4 tf;
		AlloyVertexDesc vi[3];
		
		vi[0].vertex = v[0].vertex;
		vi[0].normal = v[0].normal;
		vi[0].uv0 = v[0].uv0;
		vi[0].uv1 = v[0].uv1;

		vi[1].vertex = v[1].vertex;
		vi[1].normal = v[1].normal;
		vi[1].uv0 = v[1].uv0;
		vi[1].uv1 = v[1].uv1;

		vi[2].vertex = v[2].vertex;
		vi[2].normal = v[2].normal;
		vi[2].uv0 = v[2].uv0;
		vi[2].uv1 = v[2].uv1;

	#ifdef ALLOY_ENABLE_UV2
		vi[0].uv2 = v[0].uv2;
		vi[1].uv2 = v[1].uv2;
		vi[2].uv2 = v[2].uv2;
	#endif
	#ifdef ALLOY_ENABLE_TANGENT_TO_WORLD
		vi[0].tangent = v[0].tangent;
		vi[1].tangent = v[1].tangent;
		vi[2].tangent = v[2].tangent;
	#endif
		vi[0].color = v[0].color;
		vi[1].color = v[1].color;
		vi[2].color = v[2].color;
  	
	  	float maxDisplacement = 0.0f;
	
	#ifdef _TESSELLATIONMODE_DISPLACEMENT
		maxDisplacement = 1.5f * _Displacement;
	#endif
	
		float edgeLength = _EdgeLength;
		
    #if ALLOY_CONFIG_ENABLE_TESSELLATION_MIN_EDGE_LENGTH
    	edgeLength = max(_MinEdgeLength, edgeLength);
    #endif
	  
		tf = UnityEdgeLengthBasedTessCull(vi[0].vertex, v[1].vertex, v[2].vertex, edgeLength, maxDisplacement);

		o.edge[0] = tf.x; 
		o.edge[1] = tf.y; 
		o.edge[2] = tf.z; 
		o.inside = tf.w;
		return o;
	}

	// tessellation hull shader
	[UNITY_domain("tri")]
	[UNITY_partitioning("fractional_odd")]
	[UNITY_outputtopology("triangle_cw")]
	[UNITY_patchconstantfunc("AlloyHullConstantTessellation")]
	[UNITY_outputcontrolpoints(3)]
	AlloyVertexOutputTessellation AlloyHullTessellation(
		InputPatch<AlloyVertexOutputTessellation,3> v, 
		uint id : SV_OutputControlPointID) 
	{
		return v[id];
	}
#endif

#endif // ALLOY_FRAMEWORK_TESSELLATION_CGINC