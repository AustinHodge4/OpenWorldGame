// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Deferred.cginc
/// @brief Deferred g-buffer vertex & fragment passes.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_PASSES_DEFERRED_CGINC
#define ALLOY_PASSES_DEFERRED_CGINC

#include "Assets/Alloy/Shaders/Framework/GI.cginc"
#include "Assets/Alloy/Shaders/Framework/Pass.cginc"
#include "Assets/Alloy/Shaders/Framework/Surface.cginc"
#include "Assets/Alloy/Shaders/Framework/Tessellation.cginc"
#include "Assets/Alloy/Shaders/Framework/Utility.cginc"

#include "HLSLSupport.cginc"
#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "Lighting.cginc"
#include "UnityShaderVariables.cginc"
#include "UnityStandardUtils.cginc"

struct AlloyVertexOutputDeferred
{
	float4 pos							: SV_POSITION;
	float4 texcoords					: TEXCOORD0;
	half4 viewDirWorldAndDepth 			: TEXCOORD1;
	half4 tangentToWorldAndParallax0	: TEXCOORD2;	
	half4 tangentToWorldAndParallax1	: TEXCOORD3;	
	half4 tangentToWorldAndParallax2	: TEXCOORD4;	
	float4 positionWorld				: TEXCOORD5;
	half4 color 						: TEXCOORD6;
	half4 ambientOrLightmapUV			: TEXCOORD7;	// SH or Lightmap UV
};

AlloyVertexOutputDeferred AlloyVertexDeferred(
	AlloyVertexDesc v)
{
	AlloyVertexOutputDeferred o;
	UNITY_INITIALIZE_OUTPUT(AlloyVertexOutputDeferred, o);
	
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
	
	float3 normalWorld = o.tangentToWorldAndParallax2.xyz;
	o.ambientOrLightmapUV = AlloyTransferAmbientData(v, normalWorld);
	return o;
}

#ifdef ALLOY_ENABLE_TESSELLATION
	[UNITY_domain("tri")]
	AlloyVertexOutputDeferred AlloyDomainDeferred(
		UnityTessellationFactors tessFactors, 
		const OutputPatch<AlloyVertexOutputTessellation,3> vi, 
		float3 bary : SV_DomainLocation) 
	{
		return AlloyVertexDeferred(AlloyInterpolateVertex(vi, bary));
	}
#endif

void AlloyFragmentDeferred(
	AlloyVertexOutputDeferred i,
	out half4 diffuseAo : SV_Target0,
	out half4 specSmoothness : SV_Target1,
	out half4 normalId : SV_Target2,
	out half4 emission : SV_Target3)
{
	AlloySurfaceDesc s = AlloySurfaceFromVertexData(
		i.positionWorld.xyz,
		i.texcoords,
		i.viewDirWorldAndDepth,
		i.tangentToWorldAndParallax0,
		i.tangentToWorldAndParallax1,
		i.tangentToWorldAndParallax2,
		i.color);

	half4 illum = AlloyGbuffer(s, diffuseAo, specSmoothness, normalId);

	illum.rgb += AlloyGlobalIllumination(s, i.ambientOrLightmapUV, 1.0h);
	illum.rgb = AlloyHdrClamp(illum.rgb);
	
#ifndef UNITY_HDR_ON
	illum.rgb = exp2(-illum.rgb);
#endif
	emission = illum;
}					
			
#endif // ALLOY_PASSES_DEFERRED_CGINC
