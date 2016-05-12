// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Distort.cginc
/// @brief Distort pass inputs and entry points.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_PASSES_DISTORT_CGINC
#define ALLOY_PASSES_DISTORT_CGINC

#include "Assets/Alloy/Shaders/Framework/Pass.cginc"
#include "Assets/Alloy/Shaders/Framework/Surface.cginc"
#include "Assets/Alloy/Shaders/Framework/Tessellation.cginc"
#include "Assets/Alloy/Shaders/Framework/Utility.cginc"

#include "HLSLSupport.cginc"
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "UnityShaderVariables.cginc"
#include "UnityStandardUtils.cginc"

#ifndef ALLOY_DISTORT_TEXTURE
	#define ALLOY_DISTORT_TEXTURE _GrabTexture
#endif

#ifndef ALLOY_DISTORT_TEXELSIZE
	#define ALLOY_DISTORT_TEXELSIZE _GrabTexture_TexelSize
#endif

struct AlloyVertexOutputDistort 
{
	float4 pos							: SV_POSITION;
	float4 texcoords					: TEXCOORD0;
	half4 viewDirWorldAndDepth 			: TEXCOORD1;
	half4 tangentToWorldAndParallax0	: TEXCOORD2;	
	half4 tangentToWorldAndParallax1	: TEXCOORD3;	
	half4 tangentToWorldAndParallax2	: TEXCOORD4;	
	float4 positionWorld				: TEXCOORD5;
	half4 color 						: TEXCOORD6;
    float3 normalProjection 			: TEXCOORD7;
	float4 grabUv 						: TEXCOORD8;
	UNITY_FOG_COORDS(9)
};

AlloyVertexOutputDistort AlloyVertexDistort(
	AlloyVertexDesc v)
{
	AlloyVertexOutputDistort o;
	UNITY_INITIALIZE_OUTPUT(AlloyVertexOutputDistort, o);
	
	AlloyTransferVertexData(
		v,
		o.positionWorld,
		o.texcoords,
		o.viewDirWorldAndDepth,
		o.tangentToWorldAndParallax0,
		o.tangentToWorldAndParallax1,
		o.tangentToWorldAndParallax2,
		o.color);   
	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
	
#if UNITY_UV_STARTS_AT_TOP
	float4 scale = float4(1.0f, -1.0f, 0.0f, 0.0f); // Invert Y
#else
	float4 scale = float4(1.0f, 1.0f, 0.0f, 0.0f);
#endif

	// Modify XY, pass through ZW.
	o.grabUv = (o.pos.xyyy * scale + o.pos.wwzw) * float4(0.5f, 0.5f, 1.0f, 1.0f);
    o.normalProjection = mul((float3x3)UNITY_MATRIX_MVP, v.normal);
	
	UNITY_TRANSFER_FOG(o, o.pos);
	return o;
}

#ifdef ALLOY_ENABLE_TESSELLATION
	[UNITY_domain("tri")]
	AlloyVertexOutputDistort AlloyDomainDistort(
		UnityTessellationFactors tessFactors, 
		const OutputPatch<AlloyVertexOutputTessellation,3> vi, 
		float3 bary : SV_DomainLocation) 
	{
		return AlloyVertexDistort(AlloyInterpolateVertex(vi, bary));
	}
#endif

float _DistortWeight;
float _DistortIntensity;
float _DistortGeoWeight;
sampler2D ALLOY_DISTORT_TEXTURE;
float4 ALLOY_DISTORT_TEXELSIZE;

half4 AlloyFragmentDistort(
	AlloyVertexOutputDistort i) : SV_Target
{
	AlloySurfaceDesc s = AlloySurfaceFromVertexData(
		i.positionWorld.xyz,
		i.texcoords,
		i.viewDirWorldAndDepth,
		i.tangentToWorldAndParallax0,
		i.tangentToWorldAndParallax1,
		i.tangentToWorldAndParallax2,
		i.color);
	
	// Combine normals.
	half3 combinedNormals = BlendNormals(s.normalTangent, normalize(i.normalProjection));
	combinedNormals = lerp(s.normalTangent, combinedNormals, _DistortGeoWeight);
	
	// Calculate perturbed coordinates.
	float4 grabUv = i.grabUv;
	float2 offset = combinedNormals.xy * ALLOY_DISTORT_TEXELSIZE.xy;
	grabUv.xy += offset * (grabUv.z * _DistortWeight * _DistortIntensity);
	
	// Sample and combine textures.
	half3 refr = tex2Dproj(ALLOY_DISTORT_TEXTURE, UNITY_PROJ_COORD(grabUv)).rgb;	
	half4 col = half4(s.baseColor * refr, 1.0h);
	
	ALLOY_SET_FOGCOORDS(i, s);	
	AlloyFinalColor(s, col);
	return col;
}

#endif // ALLOY_PASSES_DISTORT_CGINC
