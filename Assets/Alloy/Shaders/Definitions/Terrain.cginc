// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Terrain.cginc
/// @brief Terrain surface shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef ALLOY_DEFINITIONS_TERRAIN_CGINC
#define ALLOY_DEFINITIONS_TERRAIN_CGINC

#define _TRIPLANARMODE_WORLD
#define ALLOY_ENABLE_SURFACE_SPECULAR_TINT
#define ALLOY_DISABLE_DETAIL_MASK

#include "Assets/Alloy/Shaders/Lighting/Standard.cginc"
#include "Assets/Alloy/Shaders/Framework/Definition.cginc"
#include "Assets/Alloy/Shaders/Framework/TriPlanarSplat.cginc"

#include "UnityCG.cginc"

#ifdef ALLOY_ENABLE_TERRAIN_DISTANT
	sampler2D _MetallicTex;
#else	
	#ifdef ALLOY_ENABLE_TRIPLANAR
		half _TriplanarBlendSharpness;
	#endif

	ALLOY_SAMPLER2D_XFORM(_Control);
	
	ALLOY_SAMPLER2D_XFORM(_Splat0);
	sampler2D _Normal0;
	half _Metallic0;
	half _SplatSpecularity0;
	half _SplatSpecularTint0;

	ALLOY_SAMPLER2D_XFORM(_Splat1);
	sampler2D _Normal1;
	half _Metallic1;
	half _SplatSpecularity1;
	half _SplatSpecularTint1;

	ALLOY_SAMPLER2D_XFORM(_Splat2);
	sampler2D _Normal2;
	half _Metallic2;
	half _SplatSpecularity2;
	half _SplatSpecularTint2;

	ALLOY_SAMPLER2D_XFORM(_Splat3);
	sampler2D _Normal3;
	half _Metallic3;
	half _SplatSpecularity3;
	half _SplatSpecularTint3;
	
	half _FadeDist;
	half _FadeRange;
#endif

half _DistantSpecularity;
half _DistantSpecularTint;
half _DistantRoughness;

void AlloyVertex( 
	inout AlloyVertexDesc v)
{	
	v.tangent = float4(cross(v.normal, float3(0.0f, 0.0f, 1.0f)), -1.0f);
}

void AlloySurface(
	inout AlloySurfaceDesc s)
{
#ifdef ALLOY_ENABLE_TERRAIN_DISTANT
	AlloySetBaseUv(s);
	half4 col = AlloySampleBaseColor(s);
	
	s.baseColor = col.rgb;
	s.metallic = tex2D (_MetallicTex, s.baseUv).r;	
	s.specularity = _DistantSpecularity;
	s.specularTint = _DistantSpecularTint;
	s.roughness = col.a * _DistantRoughness;
	
	AlloyDetail(s);
	AlloySetNormalData(s);
#else
	// Create a smooth blend between near and distant terrain to hide transition.
	// NOTE: Can't kill specular completely since we have to worry about deferred.
	// cf http://wiki.unity3d.com/index.php?title=AlphaClipsafe
	half fade = s.viewDepth;
	fade = (fade - _FadeDist) / _FadeRange;
	fade = 1.0 - saturate(fade);

	half4 splatControl = tex2D(_Control, TRANSFORM_TEX(s.uv01.xy, _Control));
	half weight = dot(splatControl, half4(1.0h, 1.0h, 1.0h, 1.0h));
	
	splatControl /= (weight + ALLOY_EPSILON);

	#ifdef ALLOY_ENABLE_TRIPLANAR
		half3 flatNormalWorld = s.normalWorld;
		AlloyTriPlanarSplatDesc top = AlloyTriPlanarSplatDescInit(s, _TriplanarBlendSharpness);
		top.tint = 1.0h;
		top.roughness = 1.0h;
	
		AlloySurfaceZeroMaterial(s);
		
		sampler2D topBase = _Splat0;
		sampler2D topBump = _Normal0;
		top.mask = splatControl.r;
		top.metallic = _Metallic0;
		top.specularity = _SplatSpecularity0;
		top.specularTint = _SplatSpecularTint0;
		top.texcoords = _Splat0_ST;
		top.texcoords.xy /= 100.0f; // To match tiling rate for Distant shader.

		AlloyTriplanarSplat(
			s,
			top,
			topBase,
			topBump);
			
		topBase = _Splat1;
		topBump = _Normal1;
		top.mask = splatControl.g;
		top.metallic = _Metallic1;
		top.specularity = _SplatSpecularity1;
		top.specularTint = _SplatSpecularTint1;
		top.texcoords = _Splat1_ST;
		top.texcoords.xy /= 100.0f; // To match tiling rate for Distant shader.

		AlloyTriplanarSplat(
			s,
			top,
			topBase,
			topBump);
			
		topBase = _Splat2;
		topBump = _Normal2;
		top.mask = splatControl.b;
		top.metallic = _Metallic2;
		top.specularity = _SplatSpecularity2;
		top.specularTint = _SplatSpecularTint2;
		top.texcoords = _Splat2_ST;
		top.texcoords.xy /= 100.0f; // To match tiling rate for Distant shader.

		AlloyTriplanarSplat(
			s,
			top,
			topBase,
			topBump);
			
		topBase = _Splat3;
		topBump = _Normal3;
		top.mask = splatControl.a;
		top.metallic = _Metallic3;
		top.specularity = _SplatSpecularity3;
		top.specularTint = _SplatSpecularTint3;
		top.texcoords = _Splat3_ST;
		top.texcoords.xy /= 100.0f; // To match tiling rate for Distant shader.

		AlloyTriplanarSplat(
			s,
			top,
			topBase,
			topBump);

		s.roughness *= lerp(_DistantRoughness, 1.0h, fade);	
		s.specularity = lerp(_DistantSpecularity, s.specularity, fade);
		s.specularTint = lerp(_DistantSpecularTint, s.specularTint, fade);
		s.normalWorld = normalize(lerp(flatNormalWorld, s.normalWorld, fade));
	#else
		float2 splat0Uv = TRANSFORM_TEX(s.uv01.xy, _Splat0);
		float2 splat1Uv = TRANSFORM_TEX(s.uv01.xy, _Splat1);
		float2 splat2Uv = TRANSFORM_TEX(s.uv01.xy, _Splat2);
		float2 splat3Uv = TRANSFORM_TEX(s.uv01.xy, _Splat3);

		half4 mixedDiffuse = 0.0f;
		mixedDiffuse += splatControl.r * tex2D(_Splat0, splat0Uv);
		mixedDiffuse += splatControl.g * tex2D(_Splat1, splat1Uv);
		mixedDiffuse += splatControl.b * tex2D(_Splat2, splat2Uv);
		mixedDiffuse += splatControl.a * tex2D(_Splat3, splat3Uv);
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
			
		s.roughness *= lerp(_DistantRoughness, 1.0h, fade);	
		s.specularity = lerp(_DistantSpecularity, s.specularity, fade);
		s.specularTint = lerp(_DistantSpecularTint, s.specularTint, fade);
		
		s.normalTangent.xyz *= fade;
		s.normalTangent.z += (1.0h - fade); 
		
		AlloyDetail(s);
		AlloySetNormalData(s);
	#endif
#endif
}

void AlloyFinalColor(
	AlloySurfaceDesc s,
	inout half4 color)
{	
	UNITY_APPLY_FOG(s.fogCoord, color);
}

#endif // ALLOY_DEFINITIONS_TERRAIN_CGINC
