// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

Shader "Alloy/Tessellation/Oriented/Core" {
Properties {
	// Settings
	_Mode ("'Rendering Mode' {RenderingMode:{Opaque:{_Cutoff}, Cutout:{}, Fade:{_Cutoff}, Transparent:{_Cutoff}}}", Float) = 0
	_SrcBlend ("__src", Float) = 0
	_DstBlend ("__dst", Float) = 0
	_ZWrite ("__zw", Float) = 1
	[LM_TransparencyCutOff] 
	_Cutoff ("'Alpha Cutoff' {Min:0, Max:1}", Float) = 0.5
		
	// Oriented Textures 
	_OrientedTextures ("'Oriented Textures' {Section:{41, 48, 126}}", Float) = 0
	_OrientedColor ("'Tint' {}", Color) = (1,1,1,1)	
	_OrientedMainTex ("'Base Color(RGB) Opacity(A)' {Visualize:{RGB, A}}", 2D) = "white" {}
	_OrientedMainTexVelocity ("Scroll", Vector) = (0,0,0,0) 
	_OrientedMaterialMap ("'Metal(R) AO(G) Spec(B) Rough(A)' {Visualize:{R, G, B, A}, Parent:_OrientedMainTex}", 2D) = "white" {}
	_OrientedBumpMap ("'Normals' {Visualize:{NRM}, Parent:_OrientedMainTex}", 2D) = "bump" {}
	_OrientedColorVertexTint ("'Vertex Color Tint' {Min:0, Max:1}", Float) = 0
	
	// Oriented Physical Properties 
	_OrientedPhysicalProperties ("'Oriented Physical Properties' {Section:{59, 41, 126}}", Float) = 0
	_OrientedMetallic ("'Metallic' {Min:0, Max:1}", Float) = 1
	_OrientedSpecularity ("'Specularity' {Min:0, Max:1}", Float) = 1
	_OrientedRoughness ("'Roughness' {Min:0, Max:1}", Float) = 1
	_OrientedOcclusion ("'Occlusion Strength' {Min:0, Max:1}", Float) = 1
	_OrientedNormalMapScale ("'Normal Strength' {}", Float) = 1
	
	// Tessellation Properties
	_TessellationProperties ("'Tessellation Properties' {Section:{109, 126, 41}}", Float) = 0
	[KeywordEnum(Displacement, Phong, Combined)] 
	_TessellationMode ("'Mode' {Dropdown:{Displacement:{_Phong}, Phong:{_DispTex, _Displacement}, Combined:{}}}", Float) = 0
	_DispTex ("'Heightmap(G)' {Visualize:{G}}", 2D) = "black" {}
	_DispTexVelocity ("Scroll", Vector) = (0,0,0,0)
	_Displacement ("'Displacement' {Min:0, Max:30}", Float) = 0.3	
	_Phong ("'Phong Strength' {Min:0, Max:1}", Float) = 0.5
	_EdgeLength ("'Edge Length' {Min:2, Max:50}", Float) = 15
}

CGINCLUDE
	#define ALLOY_ENABLE_TESSELLATION
ENDCG

SubShader {
	Tags { 
        "RenderType"="Opaque" 
        "PerformanceChecks"="False"
    }
	LOD 300

	Pass {
		Name "FORWARD" 
		Tags { "LightMode" = "ForwardBase" }

		Blend [_SrcBlend] [_DstBlend]
		ZWrite [_ZWrite]

		CGPROGRAM
		#pragma target 5.0
		#pragma exclude_renderers gles
		
		#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
		#pragma shader_feature _TESSELLATIONMODE_DISPLACEMENT _TESSELLATIONMODE_PHONG _TESSELLATIONMODE_COMBINED
		
		#pragma multi_compile_fwdbase
		#pragma multi_compile_fog
			
		#pragma hull AlloyHullTessellation
		#pragma vertex AlloyVertexTessellation
		#pragma domain AlloyDomainForwardBase
		#pragma fragment AlloyFragmentForwardBase
		
		#define UNITY_PASS_FORWARDBASE
		
		#include "Assets/Alloy/Shaders/Definitions/OrientedCore.cginc"
		#include "Assets/Alloy/Shaders/Passes/Forward.cginc"

		ENDCG
	}
	
	Pass {
		Name "FORWARD_DELTA"
		Tags { "LightMode" = "ForwardAdd" }
		
		Blend [_SrcBlend] One
		ZWrite Off

		CGPROGRAM
		#pragma target 5.0
		#pragma exclude_renderers gles
		
		#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
		#pragma shader_feature _TESSELLATIONMODE_DISPLACEMENT _TESSELLATIONMODE_PHONG _TESSELLATIONMODE_COMBINED
		
		#pragma multi_compile_fwdadd_fullshadows
		#pragma multi_compile_fog
		
		#pragma hull AlloyHullTessellation
		#pragma vertex AlloyVertexTessellation
		#pragma domain AlloyDomainForwardAdd
		#pragma fragment AlloyFragmentForwardAdd

		#define UNITY_PASS_FORWARDADD

		#include "Assets/Alloy/Shaders/Definitions/OrientedCore.cginc"
		#include "Assets/Alloy/Shaders/Passes/Forward.cginc"

		ENDCG
	}
	
	Pass {
		Name "SHADOWCASTER"
		Tags { "LightMode" = "ShadowCaster" }
		
		CGPROGRAM
		#pragma target 5.0
		#pragma exclude_renderers gles

		#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
		#pragma shader_feature _TESSELLATIONMODE_DISPLACEMENT _TESSELLATIONMODE_PHONG _TESSELLATIONMODE_COMBINED
		
		#pragma multi_compile_shadowcaster

		#pragma hull AlloyHullTessellation
		#pragma vertex AlloyVertexTessellation
		#pragma domain AlloyDomainShadowCaster
		#pragma fragment AlloyFragmentShadowCaster
		
		#define UNITY_PASS_SHADOWCASTER
		
		#include "Assets/Alloy/Shaders/Definitions/OrientedCore.cginc"
		#include "Assets/Alloy/Shaders/Passes/Shadow.cginc"

		ENDCG
	}
	
	Pass {
		Name "DEFERRED"
		Tags { "LightMode" = "Deferred" }

		CGPROGRAM
		#pragma target 5.0
		#pragma exclude_renderers nomrt gles
		
		#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
		#pragma shader_feature _TESSELLATIONMODE_DISPLACEMENT _TESSELLATIONMODE_PHONG _TESSELLATIONMODE_COMBINED
		
		#pragma multi_compile_prepassfinal
		
		#pragma hull AlloyHullTessellation
		#pragma vertex AlloyVertexTessellation
		#pragma domain AlloyDomainDeferred
		#pragma fragment AlloyFragmentDeferred
		
		#define UNITY_PASS_DEFERRED
		
		#include "Assets/Alloy/Shaders/Definitions/OrientedCore.cginc"
		#include "Assets/Alloy/Shaders/Passes/Deferred.cginc"

		ENDCG
	}
	
	Pass {
		Name "Meta"
		Tags { "LightMode" = "Meta" }
		Cull Off

		CGPROGRAM
		#pragma target 5.0
		#pragma exclude_renderers nomrt gles
						
		#pragma shader_feature _TESSELLATIONMODE_DISPLACEMENT _TESSELLATIONMODE_PHONG _TESSELLATIONMODE_COMBINED
				
		#pragma hull AlloyHullTessellation
		#pragma vertex AlloyVertexTessellation
		#pragma domain AlloyDomainMeta
		#pragma fragment AlloyFragmentMeta
		
		#define UNITY_PASS_META
		
		#include "Assets/Alloy/Shaders/Definitions/OrientedCore.cginc"
		#include "Assets/Alloy/Shaders/Passes/Meta.cginc"

		ENDCG
	}
}

FallBack "Alloy/Oriented/Core"
CustomEditor "AlloyFieldBasedEditor"
}
