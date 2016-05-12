// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Shadow.cginc
/// @brief Shadow vertex & fragment passes.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_PASSES_SHADOW_CGINC
#define ALLOY_PASSES_SHADOW_CGINC

#include "Assets/Alloy/Shaders/Framework/Pass.cginc"
#include "Assets/Alloy/Shaders/Framework/Surface.cginc"
#include "Assets/Alloy/Shaders/Framework/Tessellation.cginc"

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "UnityShaderVariables.cginc"
#include "UnityStandardConfig.cginc"

// ------------------------------------------------------------------
//  Shadow Caster pass

// Do dithering for alpha blended shadows on SM3+/desktop;
// on lesser systems do simple alpha-tested shadows
#if defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
	#if !(defined (SHADER_API_MOBILE) || defined(SHADER_API_D3D11_9X) || defined (SHADER_API_PSP2) || defined (SHADER_API_PSM))
		#define UNITY_STANDARD_USE_DITHER_MASK 1
	#endif
#endif

// Need to output UVs in shadow caster, since we need to sample texture and do clip/dithering based on it
#if !defined(ALLOY_ENABLE_SURFACE_IN_SHADOW_PASS) && (defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON))
	#define ALLOY_ENABLE_SURFACE_IN_SHADOW_PASS
#endif

// Has a non-empty shadow caster output struct (it's an error to have empty structs on some platforms...)
#if !defined(V2F_SHADOW_CASTER_NOPOS_IS_EMPTY) || defined(ALLOY_ENABLE_SURFACE_IN_SHADOW_PASS)
	#define UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT 1
#endif
				
#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
	struct AlloyVertexOutputShadowCaster 
	{
		V2F_SHADOW_CASTER_NOPOS
		
	#ifdef ALLOY_ENABLE_SURFACE_IN_SHADOW_PASS
		float4 texcoords 	: TEXCOORD1;
		half4 color 		: TEXCOORD2;
	#endif
	};
#endif

#ifdef UNITY_STANDARD_USE_DITHER_MASK
	sampler3D	_DitherMaskLOD;
#endif

// We have to do these dances of outputting SV_POSITION separately from the vertex shader,
// and inputting VPOS in the pixel shader, since they both map to "POSITION" semantic on
// some platforms, and then things don't go well.

void AlloyVertexShadowCaster(
	AlloyVertexDesc v,
#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
	out AlloyVertexOutputShadowCaster o,
#endif
	out float4 opos : SV_POSITION)
{
	AlloyVertex(v);
	TRANSFER_SHADOW_CASTER_NOPOS(o, opos)
	
#ifdef ALLOY_ENABLE_SURFACE_IN_SHADOW_PASS
	o.texcoords.xy = v.uv0.xy;
	o.texcoords.zw = v.uv1.xy;
	o.color = v.color;
#endif
}

#ifdef ALLOY_ENABLE_TESSELLATION
	[UNITY_domain("tri")]
	void AlloyDomainShadowCaster(
		UnityTessellationFactors tessFactors, 
		const OutputPatch<AlloyVertexOutputTessellation,3> vi, 
		float3 bary : SV_DomainLocation,
	#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
		out AlloyVertexOutputShadowCaster o,
	#endif
		out float4 opos : SV_POSITION) 
	{
		AlloyVertexDesc v = AlloyInterpolateVertex(vi, bary);
		AlloyVertex(v);
		TRANSFER_SHADOW_CASTER_NOPOS(o, opos)
	
		// NOTE: This code is duplicated to make D3D11 stop complaining about
		// non-initialized "out" parameters!
	#ifdef ALLOY_ENABLE_SURFACE_IN_SHADOW_PASS
		o.texcoords.xy = v.uv0.xy;
		o.texcoords.zw = v.uv1.xy;
		o.color = v.color;
	#endif
	}
#endif

half4 AlloyFragmentShadowCaster(
#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
	AlloyVertexOutputShadowCaster i
#endif
#ifdef UNITY_STANDARD_USE_DITHER_MASK
	, UNITY_VPOS_TYPE vpos : VPOS
#endif
	) : SV_Target
{
#ifdef ALLOY_ENABLE_SURFACE_IN_SHADOW_PASS
	AlloySurfaceDesc s = AlloySurfaceDescInit();
	s.uv01 = i.texcoords;
	s.vertexColor = i.color;
		
	AlloyPreSurface(s);
	AlloySurface(s);
	AlloyPostSurface(s);
	
	#if defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
		#ifdef UNITY_STANDARD_USE_DITHER_MASK
			// Use dither mask for alpha blended shadows, based on pixel position xy
			// and alpha level. Our dither texture is 4x4x16.
			half alphaRef = tex3D(_DitherMaskLOD, float3(vpos.xy * 0.25f, s.opacity * 0.9375f)).a;
			clip(alphaRef - 0.01h);
//		#else
//			clip(alpha - _Cutoff);
		#endif
	#endif
#endif

	SHADOW_CASTER_FRAGMENT(i)
}		
			
#endif // ALLOY_PASSES_SHADOW_CGINC
