// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Meta.cginc
/// @brief Meta vertex & fragment passes.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_PASSES_META_CGINC
#define ALLOY_PASSES_META_CGINC

#include "Assets/Alloy/Shaders/Framework/Pass.cginc"
#include "Assets/Alloy/Shaders/Framework/Surface.cginc"
#include "Assets/Alloy/Shaders/Framework/Tessellation.cginc"
#include "Assets/Alloy/Shaders/Framework/Utility.cginc"

#include "HLSLSupport.cginc"
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "UnityMetaPass.cginc"
#include "UnityShaderVariables.cginc"
#include "UnityStandardUtils.cginc"

struct AlloyVertexOutputMeta 
{
	float4 pos							: SV_POSITION;
	float4 texcoords					: TEXCOORD0;
	half4 viewDirWorldAndDepth 			: TEXCOORD1;
	half4 tangentToWorldAndParallax0	: TEXCOORD2;	
	half4 tangentToWorldAndParallax1	: TEXCOORD3;	
	half4 tangentToWorldAndParallax2	: TEXCOORD4;	
	float4 positionWorld				: TEXCOORD5;
	half4 color 						: TEXCOORD6;
};

AlloyVertexOutputMeta AlloyVertexMeta(
	AlloyVertexDesc v)
{
	AlloyVertexOutputMeta o;
	UNITY_INITIALIZE_OUTPUT(AlloyVertexOutputMeta, o);
	
	AlloyTransferVertexData(
		v,
		o.positionWorld,
		o.texcoords,
		o.viewDirWorldAndDepth,
		o.tangentToWorldAndParallax0,
		o.tangentToWorldAndParallax1,
		o.tangentToWorldAndParallax2,
		o.color);   
	o.pos = UnityMetaVertexPosition(v.vertex, v.uv1.xy, v.uv2.xy, unity_LightmapST, unity_DynamicLightmapST);
	
	return o;
}

#ifdef ALLOY_ENABLE_TESSELLATION
	[UNITY_domain("tri")]
	AlloyVertexOutputMeta AlloyDomainMeta(
		UnityTessellationFactors tessFactors, 
		const OutputPatch<AlloyVertexOutputTessellation,3> vi, 
		float3 bary : SV_DomainLocation) 
	{
		return AlloyVertexMeta(AlloyInterpolateVertex(vi, bary));
	}
#endif

half4 AlloyFragmentMeta(
	AlloyVertexOutputMeta i) : SV_Target
{	
	AlloySurfaceDesc s = AlloySurfaceFromVertexData(
		i.positionWorld.xyz,
		i.texcoords,
		i.viewDirWorldAndDepth,
		i.tangentToWorldAndParallax0,
		i.tangentToWorldAndParallax1,
		i.tangentToWorldAndParallax2,
		i.color);
	
	UnityMetaInput o;
	UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);
	
	o.Albedo = s.baseColor;
	o.Emission = AlloyHdrClamp(s.emission);

	return UnityMetaFragment(o);
}
			
#endif // ALLOY_PASSES_META_CGINC
