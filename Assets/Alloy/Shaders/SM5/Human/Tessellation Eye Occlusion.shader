// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/
 
Shader "Alloy/Tessellation/Eye/Occlusion" {
Properties {
	// Main Textures
	_MainTextures ("'Main Textures' {Section:{126, 41, 41}}", Float) = 0
	_Color ("'Tint' {}", Color) = (1,1,1,1)	
	_MainTex ("'Base Color(RGB) Opacity(A)' {Visualize:{RGB, A}}", 2D) = "white" {}
	_MainTexVelocity ("Scroll", Vector) = (0,0,0,0) 
	_MainTexUV ("UV Set", Float) = 0
 	_AoMap ("'Ambient Occlusion(G)' {Visualize:{RGB}, Parent:_MainTex}", 2D) = "white" {}
	_BaseColorVertexTint ("'Vertex Color Tint' {Min:0, Max:1}", Float) = 0
	 
	// Main Physical Properties
	_MainPhysicalProperties ("'Main Physical Properties' {Section:{126, 66, 41}}", Float) = 0
	_Occlusion ("'Occlusion Strength' {Min:0, Max:1}", Float) = 1
	
	// Tessellation Properties
	_TessellationProperties ("'Tessellation Properties' {Section:{109, 126, 41}}", Float) = 0
	[KeywordEnum(Displacement, Phong, Combined)] 
	_TessellationMode ("'Mode' {Dropdown:{Displacement:{_Phong}, Phong:{_DispTex, _Displacement}, Combined:{}}}", Float) = 0
	_DispTex ("'Heightmap(G)' {Visualize:{G}}", 2D) = "black" {}
	_DispTexVelocity ("Scroll", Vector) = (0,0,0,0)
	_Displacement ("'Displacement' {Min:0, Max:30}", Float) = 0.3	
	_Phong ("'Phong Strength' {Min:0, Max:1}", Float) = 0.5
	_EdgeLength ("'Edge Length' {Min:2, Max:50}", Float) = 15

	// Dissolve Properties 
	[Toggle(_DISSOLVE_ON)] 
	_Dissolve ("'Dissolve Properties' {Feature:{41, 100, 126}}", Float) = 0
	[HDR]
	_DissolveGlowColor ("'Glow Tint' {}", Color) = (1,1,1,1)
	_DissolveTex ("'Glow Color(RGB) Trans(A)' {Visualize:{RGB, A}}", 2D) = "white" {} 
	_DissolveTexUV ("UV Set", Float) = 0
	_DissolveCutoff ("'Cutoff' {Min:0, Max:1}", Float) = 0
	[Gamma]
	_DissolveGlowWeight ("'Glow Weight' {Min:0, Max:1}", Float) = 1
	_DissolveEdgeWidth ("'Glow Width' {Min:0, Max:1}", Float) = 0.01
}

CGINCLUDE
	#define _ALPHAPREMULTIPLY_ON
	#define ALLOY_ENABLE_TESSELLATION
ENDCG

SubShader {
	Tags {
        "Queue"="Transparent-1" 
        "IgnoreProjector"="True" 
        "RenderType"="Transparent" 
        "ForceNoShadowCasting"="True"
    }
	LOD 400
	Offset -1,-1

	Pass {
		Name "FORWARD" 
		Tags { "LightMode" = "ForwardBase" }

		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off

		CGPROGRAM
		#pragma target 5.0
		#pragma exclude_renderers gles
		
		#pragma shader_feature _TESSELLATIONMODE_DISPLACEMENT _TESSELLATIONMODE_PHONG _TESSELLATIONMODE_COMBINED
		#pragma shader_feature _DISSOLVE_ON
		
		#pragma multi_compile_fwdbase
		#pragma multi_compile_fog
			
		#pragma hull AlloyHullTessellation
		#pragma vertex AlloyVertexTessellation
		#pragma domain AlloyDomainForwardBase
		#pragma fragment AlloyFragmentForwardBase
		
		#define UNITY_PASS_FORWARDBASE
		
		#include "Assets/Alloy/Shaders/Definitions/EyeOcclusion.cginc"
		#include "Assets/Alloy/Shaders/Passes/Forward.cginc"

		ENDCG
	}
}

FallBack "Alloy/Eye/Occlusion"
CustomEditor "AlloyFieldBasedEditor"
}
