// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Forward.cginc
/// @brief Forward lighting vertex & fragment passes.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_PASSES_FORWARD_CGINC
#define ALLOY_PASSES_FORWARD_CGINC

#include "Assets/Alloy/Shaders/Framework/GI.cginc"
#include "Assets/Alloy/Shaders/Framework/Lighting.cginc"
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

half4 AlloyOutputForward(
	half3 color,
	AlloySurfaceDesc s)
{
	half4 col;
	col.rgb = color;

#if defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
	col.a = s.opacity;
#else
	UNITY_OPAQUE_ALPHA(col.a);
#endif	

	AlloyFinalColor(s, col);
	col.rgb = AlloyHdrClamp(col.rgb);
	
	return col;
}

// ------------------------------------------------------------------
//  Base pass (directional light, emission, lightmaps, ...)
struct AlloyVertexOutputForwardBase
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
	SHADOW_COORDS(8)
	UNITY_FOG_COORDS(9)
};

AlloyVertexOutputForwardBase AlloyVertexForwardBase(
	AlloyVertexDesc v)
{
	AlloyVertexOutputForwardBase o;
	UNITY_INITIALIZE_OUTPUT(AlloyVertexOutputForwardBase, o);
	
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
	
	//We need this for shadow receving
	TRANSFER_SHADOW(o);
	
	float3 normalWorld = o.tangentToWorldAndParallax2.xyz;
	o.ambientOrLightmapUV = AlloyTransferAmbientData(v, normalWorld);

	// Add approximated illumination from non-important point lights
#if UNITY_SHOULD_SAMPLE_SH && defined(VERTEXLIGHT_ON)
	o.ambientOrLightmapUV.rgb += AlloyVertexLights(o.positionWorld, normalWorld);
#endif

	UNITY_TRANSFER_FOG(o, o.pos);
	return o;
}

#ifdef ALLOY_ENABLE_TESSELLATION
	[UNITY_domain("tri")]
	AlloyVertexOutputForwardBase AlloyDomainForwardBase(
		UnityTessellationFactors tessFactors, 
		const OutputPatch<AlloyVertexOutputTessellation,3> vi, 
		float3 bary : SV_DomainLocation) 
	{
		return AlloyVertexForwardBase(AlloyInterpolateVertex(vi, bary));
	}
#endif

half4 AlloyFragmentForwardBase(
	AlloyVertexOutputForwardBase i) : SV_Target
{
	AlloySurfaceDesc s = AlloySurfaceFromVertexData(
		i.positionWorld.xyz,
		i.texcoords,
		i.viewDirWorldAndDepth,
		i.tangentToWorldAndParallax0,
		i.tangentToWorldAndParallax1,
		i.tangentToWorldAndParallax2,
		i.color);
	
	half shadow = SHADOW_ATTENUATION(i);
	half3 illum = s.emission + AlloyGlobalIllumination(s, i.ambientOrLightmapUV, shadow);

#ifdef LIGHTMAP_OFF
	AlloyDirectDesc light = AlloyDirectDescInit();
	
	light.color = _LightColor0.rgb;
	light.direction = _WorldSpaceLightPos0.xyz;
	light.shadow = shadow;
	illum += AlloyDirect(light, s);
#endif

	ALLOY_SET_FOGCOORDS(i, s);
	return AlloyOutputForward(illum, s);
}

// ------------------------------------------------------------------
//  Additive pass (one light per pass)
struct AlloyVertexOutputForwardAdd 
{
	float4 pos							: SV_POSITION;
	float4 texcoords					: TEXCOORD0;
	half4 viewDirWorldAndDepth 			: TEXCOORD1;
	half4 tangentToWorldAndParallax0	: TEXCOORD2;	
	half4 tangentToWorldAndParallax1	: TEXCOORD3;	
	half4 tangentToWorldAndParallax2	: TEXCOORD4;	
	float4 positionWorldAndLightRange	: TEXCOORD5;
	half4 color 						: TEXCOORD6;
	LIGHTING_COORDS(7,8)
	UNITY_FOG_COORDS(9)
};

AlloyVertexOutputForwardAdd AlloyVertexForwardAdd(
	AlloyVertexDesc v)
{
	AlloyVertexOutputForwardAdd o;
	UNITY_INITIALIZE_OUTPUT(AlloyVertexOutputForwardAdd, o);
	
	AlloyTransferVertexData(
		v,
		o.positionWorldAndLightRange,
		o.texcoords,
		o.viewDirWorldAndDepth,
		o.tangentToWorldAndParallax0,
		o.tangentToWorldAndParallax1,
		o.tangentToWorldAndParallax2,
		o.color);
	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
	
	// We need this for shadow receving.
	TRANSFER_VERTEX_TO_FRAGMENT(o);

#ifdef USING_DIRECTIONAL_LIGHT
    o.positionWorldAndLightRange.w = 0.0h;
#else
	// Trick to obtain light range for point lights from projected coordinates.
	// cf http://forum.unity3d.com/threads/get-the-range-of-a-point-light-in-forward-add-mode.213430/#post-1433291
	float4 positionWorld = o.positionWorldAndLightRange;
	float3 lightVector = UnityWorldSpaceLightDir(positionWorld.xyz);
	float3 lightCoord = mul(unity_WorldToLight, positionWorld).xyz;
	o.positionWorldAndLightRange.w = length(lightVector) / length(lightCoord);
#endif

	UNITY_TRANSFER_FOG(o, o.pos);
	return o;
}

#ifdef ALLOY_ENABLE_TESSELLATION
	[UNITY_domain("tri")]
	AlloyVertexOutputForwardAdd AlloyDomainForwardAdd(
		UnityTessellationFactors tessFactors, 
		const OutputPatch<AlloyVertexOutputTessellation,3> vi, 
		float3 bary : SV_DomainLocation) 
	{
		return AlloyVertexForwardAdd(AlloyInterpolateVertex(vi, bary));
	}
#endif

half4 AlloyFragmentForwardAdd(
	AlloyVertexOutputForwardAdd i) : SV_Target
{
	AlloyDirectDesc light = AlloyDirectDescInit();
	AlloySurfaceDesc s = AlloySurfaceFromVertexData(
		i.positionWorldAndLightRange.xyz,
		i.texcoords,
		i.viewDirWorldAndDepth,
		i.tangentToWorldAndParallax0,
		i.tangentToWorldAndParallax1,
		i.tangentToWorldAndParallax2,
		i.color);
	
	light.color = _LightColor0.rgb;
	light.shadow = SHADOW_ATTENUATION(i);
	
#ifdef USING_DIRECTIONAL_LIGHT
	light.direction = _WorldSpaceLightPos0.xyz;
	
	#ifdef DIRECTIONAL_COOKIE
		#ifdef ALLOY_SUPPORT_REDLIGHTS
			light.color *= redLightCalculateForward(_LightTexture0, s.positionWorld, s.normalWorld, s.viewDirWorld, light.direction);
		#else
			light.color *= tex2D(_LightTexture0, i._LightCoord).w;
		#endif
	#endif
#else
	float3 lightVector = UnityWorldSpaceLightDir(s.positionWorld);
	half lightRange = i.positionWorldAndLightRange.w;
	half lightRangeInverse = 1.0h / lightRange;
	half lightSize = _LightColor0.a * lightRange;
	
	light.color *= AlloySphereLight(lightSize, lightRangeInverse, lightVector, s.reflectionVectorWorld, light.direction, light.solidAngle);
	
	#ifdef POINT_COOKIE
		light.color *= texCUBE(_LightTexture0, i._LightCoord).w;
	#endif

	#ifdef SPOT
		light.color *= (i._LightCoord.z > 0) * UnitySpotCookie(i._LightCoord);
	#endif
	
	s.specularOcclusion *= AlloyAreaLightNormalization(s.beckmannRoughness, light.solidAngle);
#endif
		
	half3 illum = AlloyDirect(light, s);
	ALLOY_SET_FOGCOORDS(i, s);
	return AlloyOutputForward(illum, s);
}			
			
#endif // ALLOY_PASSES_FORWARD_CGINC
