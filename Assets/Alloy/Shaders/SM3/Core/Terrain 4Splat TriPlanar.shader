// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

Shader "Alloy/Terrain/4Splat TriPlanar" {
Properties {
	// Triplanar Properties
	_TriplanarProperties ("'Triplanar Properties' {Section:{126, 41, 41}}", Float) = 0
	_TriplanarBlendSharpness ("'Sharpness' {Min:1, Max:50}", Float) = 2

	// Terrain Properties
	_TerrainProperties ("'Terrain Properties' {Section:{126, 41, 41}}", Float) = 0
	_SplatSpecularity0 ("'Specularity 0' {Min:0, Max:1}", Float) = 0.5
	_SplatSpecularTint0 ("'Specular Tint 0' {Min:0, Max:1}", Float) = 0.0
	_SplatSpecularity1 ("'Specularity 1' {Min:0, Max:1}", Float) = 0.5
	_SplatSpecularTint1 ("'Specular Tint 1' {Min:0, Max:1}", Float) = 0.0
	_SplatSpecularity2 ("'Specularity 2' {Min:0, Max:1}", Float) = 0.5
	_SplatSpecularTint2 ("'Specular Tint 2' {Min:0, Max:1}", Float) = 0.0
	_SplatSpecularity3 ("'Specularity 3' {Min:0, Max:1}", Float) = 0.5
	_SplatSpecularTint3 ("'Specular Tint 3' {Min:0, Max:1}", Float) = 0.0
	
	// Distant Terrain Properties
	_DistantTerrainProperties ("'Distant Terrain Properties' {Section:{126, 66, 41}}", Float) = 0
	_FadeDist ("'Fade Distance' {Min:0}", Float) = 500.0
	_FadeRange ("'Fade Range' {Min:1}", Float) = 100.0
	_DistantSpecularity ("'Specularity' {Min:0, Max:1}", Float) = 0.5
	_DistantSpecularTint ("'Specular Tint' {Min:0, Max:1}", Float) = 0
	_DistantRoughness ("'Roughness' {Min:0, Max:1}", Float) = 0.5
	
	// set by terrain engine
	_Control ("Control (RGBA)", 2D) = "red" {}
	_Splat3 ("Layer 3 (A)", 2D) = "white" {}
	_Splat2 ("Layer 2 (B)", 2D) = "white" {}
	_Splat1 ("Layer 1 (G)", 2D) = "white" {}
	_Splat0 ("Layer 0 (R)", 2D) = "white" {}
	_Normal3 ("Normal 3 (A)", 2D) = "bump" {}
	_Normal2 ("Normal 2 (B)", 2D) = "bump" {}
	_Normal1 ("Normal 1 (G)", 2D) = "bump" {}
	_Normal0 ("Normal 0 (R)", 2D) = "bump" {}
	_Metallic0 ("Metallic 0", Range(0.0, 1.0)) = 0.0	
	_Metallic1 ("Metallic 1", Range(0.0, 1.0)) = 0.0	
	_Metallic2 ("Metallic 2", Range(0.0, 1.0)) = 0.0	
	_Metallic3 ("Metallic 3", Range(0.0, 1.0)) = 0.0
	
	// used in fallback on old cards & base map
	_MainTex ("BaseMap (RGB)", 2D) = "white" {}
	_Color ("Main Color", Color) = (1,1,1,1)
}

CGINCLUDE
	#define ALLOY_ENABLE_TRIPLANAR
ENDCG

SubShader {
	Tags {
		"SplatCount" = "4"
		"Queue" = "Geometry-100"
		"RenderType" = "Opaque"
	}

	Pass {
		Name "FORWARD" 
		Tags { "LightMode" = "ForwardBase" }

		CGPROGRAM
		#pragma target 3.0
		#pragma exclude_renderers gles
		
		#pragma multi_compile __ _TERRAIN_NORMAL_MAP
		
		#pragma multi_compile_fwdbase
		#pragma multi_compile_fog
			
		#pragma vertex AlloyVertexForwardBase
		#pragma fragment AlloyFragmentForwardBase
		
		#define UNITY_PASS_FORWARDBASE
		
		#include "Assets/Alloy/Shaders/Definitions/Terrain.cginc"
		#include "Assets/Alloy/Shaders/Passes/Forward.cginc"

		ENDCG
	}
	
	Pass {
		Name "FORWARD_DELTA"
		Tags { "LightMode" = "ForwardAdd" }
		
		Blend One One
		ZWrite Off

		CGPROGRAM
		#pragma target 3.0
		#pragma exclude_renderers gles
		
		#pragma multi_compile __ _TERRAIN_NORMAL_MAP
		
		#pragma multi_compile_fwdadd_fullshadows
		#pragma multi_compile_fog
		
		#pragma vertex AlloyVertexForwardAdd
		#pragma fragment AlloyFragmentForwardAdd

		#define UNITY_PASS_FORWARDADD

		#include "Assets/Alloy/Shaders/Definitions/Terrain.cginc"
		#include "Assets/Alloy/Shaders/Passes/Forward.cginc"

		ENDCG
	}
	
	Pass {
		Name "SHADOWCASTER"
		Tags { "LightMode" = "ShadowCaster" }
		
		CGPROGRAM
		#pragma target 3.0
		#pragma exclude_renderers gles
		
		#pragma multi_compile_shadowcaster

		#pragma vertex AlloyVertexShadowCaster
		#pragma fragment AlloyFragmentShadowCaster
		
		#define UNITY_PASS_SHADOWCASTER
		
		#include "Assets/Alloy/Shaders/Definitions/Terrain.cginc"
		#include "Assets/Alloy/Shaders/Passes/Shadow.cginc"

		ENDCG
	}
	
	Pass {
		Name "DEFERRED"
		Tags { "LightMode" = "Deferred" }

		CGPROGRAM
		#pragma target 3.0
		#pragma exclude_renderers nomrt gles
		
		#pragma multi_compile __ _TERRAIN_NORMAL_MAP
				
		#pragma multi_compile_prepassfinal
		
		#pragma vertex AlloyVertexDeferred
		#pragma fragment AlloyFragmentDeferred
		
		#define UNITY_PASS_DEFERRED
		
		#include "Assets/Alloy/Shaders/Definitions/Terrain.cginc"
		#include "Assets/Alloy/Shaders/Passes/Deferred.cginc"

		ENDCG
	}
	
	Pass {
		Name "Meta"
		Tags { "LightMode" = "Meta" }
		Cull Off

		CGPROGRAM
		#pragma target 3.0
		#pragma exclude_renderers nomrt gles
		
		#pragma multi_compile __ _TERRAIN_NORMAL_MAP
						
		#pragma vertex AlloyVertexMeta
		#pragma fragment AlloyFragmentMeta
		
		#define UNITY_PASS_META
		
		#include "Assets/Alloy/Shaders/Definitions/Terrain.cginc"
		#include "Assets/Alloy/Shaders/Passes/Meta.cginc"

		ENDCG
	}
}

Dependency "BaseMapShader" = "Hidden/Alloy/Terrain/Distant"

Fallback "Hidden/Alloy/Terrain/Distant"
CustomEditor "AlloyFieldBasedEditor"
}
