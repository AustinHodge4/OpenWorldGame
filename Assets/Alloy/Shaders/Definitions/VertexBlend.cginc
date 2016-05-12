// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file VertexBlend4Splat.cginc
/// @brief Vertex Blend 4Splat shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_DEFINITIONS_VERTEX_BLEND_4SPLAT_CGINC
#define ALLOY_DEFINITIONS_VERTEX_BLEND_4SPLAT_CGINC

#define ALLOY_ENABLE_SURFACE_SPECULAR_TINT
#define ALLOY_DISABLE_DETAIL_MASK

#include "Assets/Alloy/Shaders/Lighting/Standard.cginc"
#include "Assets/Alloy/Shaders/Framework/Definition.cginc"
#include "Assets/Alloy/Shaders/Framework/TriPlanarSplat.cginc"

#ifdef ALLOY_ENABLE_TRIPLANAR
	half _TriplanarBlendSharpness;
#endif

half3 _Splat0Tint;
ALLOY_SAMPLER2D_XFORM(_Splat0);
sampler2D _Normal0;
half _Metallic0;
half _SplatSpecularity0;
half _SplatSpecularTint0;
half _SplatRoughness0;

half3 _Splat1Tint;
ALLOY_SAMPLER2D_XFORM(_Splat1);
sampler2D _Normal1;
half _Metallic1;
half _SplatSpecularity1;
half _SplatSpecularTint1;
half _SplatRoughness1;

half3 _Splat2Tint;
ALLOY_SAMPLER2D_XFORM(_Splat2);
sampler2D _Normal2;
half _Metallic2;
half _SplatSpecularity2;
half _SplatSpecularTint2;
half _SplatRoughness2;

half3 _Splat3Tint;
ALLOY_SAMPLER2D_XFORM(_Splat3);
sampler2D _Normal3;
half _Metallic3;
half _SplatSpecularity3;
half _SplatSpecularTint3;
half _SplatRoughness3;
	
void AlloyVertex( 
	inout AlloyVertexDesc v)
{	
	// Leave vertex color unmodified, since it is a collection of masks.
}
	
void AlloySurface(
	inout AlloySurfaceDesc s)
{	
	half4 splatControl = s.vertexColor;
	half weight = dot(splatControl, half4(1.0h, 1.0h, 1.0h, 1.0h));
	
	splatControl /= (weight + ALLOY_EPSILON);

#ifdef ALLOY_ENABLE_TRIPLANAR
	half3 flatNormalWorld = s.normalWorld;
	AlloyTriPlanarSplatDesc top = AlloyTriPlanarSplatDescInit(s, _TriplanarBlendSharpness);

	AlloySurfaceZeroMaterial(s);

	sampler2D topBase = _Splat0;
	sampler2D topBump = _Normal0;
	top.mask = splatControl.r;
	top.tint = _Splat0Tint;
	top.metallic = _Metallic0;
	top.specularity = _SplatSpecularity0;
	top.specularTint = _SplatSpecularTint0;
	top.roughness = _SplatRoughness0;
	top.texcoords = _Splat0_ST;

	AlloyTriplanarSplat(
		s,
		top,
		topBase,
		topBump);
		
	topBase = _Splat1;
	topBump = _Normal1;
	top.mask = splatControl.g;
	top.tint = _Splat1Tint;
	top.metallic = _Metallic1;
	top.specularity = _SplatSpecularity1;
	top.specularTint = _SplatSpecularTint1;
	top.roughness = _SplatRoughness1;
	top.texcoords = _Splat1_ST;

	AlloyTriplanarSplat(
		s,
		top,
		topBase,
		topBump);
		
	topBase = _Splat2;
	topBump = _Normal2;
	top.mask = splatControl.b;
	top.tint = _Splat2Tint;
	top.metallic = _Metallic2;
	top.specularity = _SplatSpecularity2;
	top.specularTint = _SplatSpecularTint2;
	top.roughness = _SplatRoughness2;
	top.texcoords = _Splat2_ST;

	AlloyTriplanarSplat(
		s,
		top,
		topBase,
		topBump);
		
	topBase = _Splat3;
	topBump = _Normal3;
	top.mask = splatControl.a;
	top.tint = _Splat3Tint;
	top.metallic = _Metallic3;
	top.specularity = _SplatSpecularity3;
	top.specularTint = _SplatSpecularTint3;
	top.roughness = _SplatRoughness3;
	top.texcoords = _Splat3_ST;

	AlloyTriplanarSplat(
		s,
		top,
		topBase,
		topBump);
		
	#ifndef _TRIPLANARMODE_WORLD
		s.normalWorld = mul((half3x3)unity_ObjectToWorld, s.normalWorld);
	#endif
	
	s.normalWorld = normalize(s.normalWorld);
#else
	float2 splat0Uv = ALLOY_XFORM_TEX_UV_SCROLL(_Splat0, s);
	float2 splat1Uv = ALLOY_XFORM_TEX_UV_SCROLL(_Splat1, s);
	float2 splat2Uv = ALLOY_XFORM_TEX_UV_SCROLL(_Splat2, s);
	float2 splat3Uv = ALLOY_XFORM_TEX_UV_SCROLL(_Splat3, s);

	half4 mixedDiffuse = 0.0f;
	mixedDiffuse += splatControl.r * half4(_Splat0Tint,_SplatRoughness0) * tex2D(_Splat0, splat0Uv);
	mixedDiffuse += splatControl.g * half4(_Splat1Tint,_SplatRoughness1) * tex2D(_Splat1, splat1Uv);
	mixedDiffuse += splatControl.b * half4(_Splat2Tint,_SplatRoughness2) * tex2D(_Splat2, splat2Uv);
	mixedDiffuse += splatControl.a * half4(_Splat3Tint,_SplatRoughness3) * tex2D(_Splat3, splat3Uv);
	s.baseColor = mixedDiffuse.rgb;	
	s.roughness = mixedDiffuse.a;

	half4 nrm = 0.0f;
	nrm += splatControl.r * tex2D(_Normal0, splat0Uv);
	nrm += splatControl.g * tex2D(_Normal1, splat1Uv);
	nrm += splatControl.b * tex2D(_Normal2, splat2Uv);
	nrm += splatControl.a * tex2D(_Normal3, splat3Uv);
	s.normalTangent = UnpackNormal(nrm);

	s.metallic = dot(splatControl, half4(_Metallic0, _Metallic1, _Metallic2, _Metallic3));	
	s.specularity = dot(splatControl, half4(_SplatSpecularity0, _SplatSpecularity1, _SplatSpecularity2, _SplatSpecularity3));
	s.specularTint = dot(splatControl, half4(_SplatSpecularTint0, _SplatSpecularTint1, _SplatSpecularTint2, _SplatSpecularTint3));
	
	AlloyDetail(s);
	AlloySetNormalData(s);
#endif
}

void AlloyFinalColor(
	AlloySurfaceDesc s,
	inout half4 color)
{	
	UNITY_APPLY_FOG(s.fogCoord, color);
}

#endif // ALLOY_DEFINITIONS_VERTEX_BLEND_4SPLAT_CGINC
