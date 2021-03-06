// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

Shader "Alloy/Tessellation/TriPlanar/Lite" {
Properties {
	// Settings
	_Lightmapping ("'GI' {LightmapEmissionProperty:{}}", Float) = 1
	
	// Triplanar Properties
	_TriplanarProperties ("'Triplanar Properties' {Section:{126, 41, 41}}", Float) = 0
	[KeywordEnum(Object, World)]
	_TriplanarMode ("'Mode' {Dropdown:{Object:{}, World:{}}}", Float) = 1
	_TriplanarBlendSharpness ("'Sharpness' {Min:1, Max:50}", Float) = 2
	
	// Primary Textures 
	_PrimaryTextures ("'Primary Textures' {Section:{126, 66, 41}}", Float) = 0
	_PrimaryColor ("'Tint' {}", Color) = (1,1,1,1)	
	_PrimaryMainTex ("'Base Color(RGB) Rough(A)' {Visualize:{RGB, A}}", 2D) = "white" {}
	_PrimaryMainTexVelocity ("Scroll", Vector) = (0,0,0,0) 
	_PrimaryBumpMap ("'Normals' {Visualize:{NRM}, Parent:_PrimaryMainTex}", 2D) = "bump" {}
	_PrimaryColorVertexTint ("'Vertex Color Tint' {Min:0, Max:1}", Float) = 0
	_PrimaryMetallic ("'Metallic' {Min:0, Max:1}", Float) = 0
	_PrimarySpecularity ("'Specularity' {Min:0, Max:1}", Float) = 0.5
	_PrimarySpecularTint ("'Specular Tint' {Min:0, Max:1}", Float) = 0
	_PrimaryRoughness ("'Roughness' {Min:0, Max:1}", Float) = 1
	_PrimaryBumpScale ("'Normal Strength' {}", Float) = 1
	
	// Secondary Textures 
	[Toggle(_SECONDARY_TRIPLANAR_ON)] 
	_SecondaryTextures ("'Secondary Textures' {Feature:{126, 92, 41}}", Float) = 0
	_SecondaryColor ("'Tint' {}", Color) = (1,1,1,1)	
	_SecondaryMainTex ("'Base Color(RGB) Rough(A)' {Visualize:{RGB, A}}", 2D) = "white" {}
	_SecondaryMainTexVelocity ("Scroll", Vector) = (0,0,0,0) 
	_SecondaryBumpMap ("'Normals' {Visualize:{NRM}, Parent:_SecondaryMainTex}", 2D) = "bump" {}
	_SecondaryColorVertexTint ("'Vertex Color Tint' {Min:0, Max:1}", Float) = 0
	_SecondaryMetallic ("'Metallic' {Min:0, Max:1}", Float) = 0
	_SecondarySpecularity ("'Specularity' {Min:0, Max:1}", Float) = 0.5
	_SecondarySpecularTint ("'Specular Tint' {Min:0, Max:1}", Float) = 0
	_SecondaryRoughness ("'Roughness' {Min:0, Max:1}", Float) = 1
	_SecondaryBumpScale ("'Normal Strength' {}", Float) = 1
	
	// Tertiary Textures 
	[Toggle(_TERTIARY_TRIPLANAR_ON)] 
	_TertiaryTextures ("'Tertiary Textures' {Feature:{126, 118, 41}}", Float) = 0
	_TertiaryColor ("'Tint' {}", Color) = (1,1,1,1)	
	_TertiaryMainTex ("'Base Color(RGB) Rough(A)' {Visualize:{RGB, A}}", 2D) = "white" {}
	_TertiaryMainTexVelocity ("Scroll", Vector) = (0,0,0,0) 
	_TertiaryBumpMap ("'Normals' {Visualize:{NRM}, Parent:_TertiaryMainTex}", 2D) = "bump" {}
	_TertiaryColorVertexTint ("'Vertex Color Tint' {Min:0, Max:1}", Float) = 0
	_TertiaryMetallic ("'Metallic' {Min:0, Max:1}", Float) = 0
	_TertiarySpecularity ("'Specularity' {Min:0, Max:1}", Float) = 0.5
	_TertiarySpecularTint ("'Specular Tint' {Min:0, Max:1}", Float) = 0
	_TertiaryRoughness ("'Roughness' {Min:0, Max:1}", Float) = 1
	_TertiaryBumpScale ("'Normal Strength' {}", Float) = 1

	// Quaternary Textures 
	[Toggle(_QUATERNARY_TRIPLANAR_ON)] 
	_QuaternaryTextures ("'Quaternary Textures' {Feature:{126, 144, 41}}", Float) = 0
	_QuaternaryColor ("'Tint' {}", Color) = (1,1,1,1)	
	_QuaternaryMainTex ("'Base Color(RGB) Rough(A)' {Visualize:{RGB, A}}", 2D) = "white" {}
	_QuaternaryMainTexVelocity ("Scroll", Vector) = (0,0,0,0) 
	_QuaternaryBumpMap ("'Normals' {Visualize:{NRM}, Parent:_QuaternaryMainTex}", 2D) = "bump" {}
	_QuaternaryColorVertexTint ("'Vertex Color Tint' {Min:0, Max:1}", Float) = 0
	_QuaternaryMetallic ("'Metallic' {Min:0, Max:1}", Float) = 0
	_QuaternarySpecularity ("'Specularity' {Min:0, Max:1}", Float) = 0.5
	_QuaternarySpecularTint ("'Specular Tint' {Min:0, Max:1}", Float) = 0
	_QuaternaryRoughness ("'Roughness' {Min:0, Max:1}", Float) = 1
	_QuaternaryBumpScale ("'Normal Strength' {}", Float) = 1
	
	// Tessellation Properties
	_TessellationProperties ("'Tessellation Properties' {Section:{109, 126, 41}}", Float) = 0
	_Phong ("'Phong Strength' {Min:0, Max:1}", Float) = 0.5
	_EdgeLength ("'Edge Length' {Min:2, Max:50}", Float) = 15

	// Rim Emission Properties 
	[Toggle(_RIM_ON)] 
	_Rim ("'Rim Emission Properties' {Feature:{41, 125, 126}}", Float) = 0
	[HDR]
	_RimColor ("'Tint' {}", Color) = (1,1,1)
	[Gamma]
	_RimWeight ("'Weight' {Min:0, Max:1}", Float) = 1
	[Gamma]
	_RimBias ("'Fill' {Min:0, Max:1}", Float) = 0
	_RimPower ("'Falloff' {Min:0.01}", Float) = 4
}

CGINCLUDE
	#define ALLOY_ENABLE_TESSELLATION
	#define _TESSELLATIONMODE_PHONG
ENDCG

SubShader {
    Tags { 
        "Queue"="Geometry" 
        "RenderType"="Opaque"
    }
    LOD 400

	Pass {
		Name "FORWARD" 
		Tags { "LightMode" = "ForwardBase" }

		CGPROGRAM
		#pragma target 3.0
		#pragma exclude_renderers gles
		
		#pragma shader_feature _TRIPLANARMODE_OBJECT _TRIPLANARMODE_WORLD
		#pragma shader_feature _SECONDARY_TRIPLANAR_ON
		#pragma shader_feature _TERTIARY_TRIPLANAR_ON
		#pragma shader_feature _QUATERNARY_TRIPLANAR_ON
		#pragma shader_feature _RIM_ON
		
		#pragma multi_compile_fwdbase
		#pragma multi_compile_fog
			
		#pragma hull AlloyHullTessellation
		#pragma vertex AlloyVertexTessellation
		#pragma domain AlloyDomainForwardBase
		#pragma fragment AlloyFragmentForwardBase
		
		#define UNITY_PASS_FORWARDBASE
		
		#include "Assets/Alloy/Shaders/Definitions/TriPlanar.cginc"
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
				
		#pragma shader_feature _TRIPLANARMODE_WORLD
		#pragma shader_feature _SECONDARY_TRIPLANAR_ON
		#pragma shader_feature _TERTIARY_TRIPLANAR_ON
		#pragma shader_feature _QUATERNARY_TRIPLANAR_ON
		
		#pragma multi_compile_fwdadd_fullshadows
		#pragma multi_compile_fog
		
		#pragma hull AlloyHullTessellation
		#pragma vertex AlloyVertexTessellation
		#pragma domain AlloyDomainForwardAdd
		#pragma fragment AlloyFragmentForwardAdd

		#define UNITY_PASS_FORWARDADD

		#include "Assets/Alloy/Shaders/Definitions/TriPlanar.cginc"
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

		#pragma hull AlloyHullTessellation
		#pragma vertex AlloyVertexTessellation
		#pragma domain AlloyDomainShadowCaster
		#pragma fragment AlloyFragmentShadowCaster
		
		#define UNITY_PASS_SHADOWCASTER
		
		#include "Assets/Alloy/Shaders/Definitions/TriPlanar.cginc"
		#include "Assets/Alloy/Shaders/Passes/Shadow.cginc"

		ENDCG
	}
	
	Pass {
		Name "DEFERRED"
		Tags { "LightMode" = "Deferred" }

		CGPROGRAM
		#pragma target 3.0
		#pragma exclude_renderers nomrt gles
		
		#pragma shader_feature _TRIPLANARMODE_WORLD
		#pragma shader_feature _SECONDARY_TRIPLANAR_ON
		#pragma shader_feature _TERTIARY_TRIPLANAR_ON
		#pragma shader_feature _QUATERNARY_TRIPLANAR_ON
		#pragma shader_feature _RIM_ON
		
		#pragma multi_compile_prepassfinal
		
		#pragma hull AlloyHullTessellation
		#pragma vertex AlloyVertexTessellation
		#pragma domain AlloyDomainDeferred
		#pragma fragment AlloyFragmentDeferred
		
		#define UNITY_PASS_DEFERRED
		
		#include "Assets/Alloy/Shaders/Definitions/TriPlanar.cginc"
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
		
		#pragma shader_feature _TRIPLANARMODE_WORLD
		#pragma shader_feature _SECONDARY_TRIPLANAR_ON
		#pragma shader_feature _TERTIARY_TRIPLANAR_ON
		#pragma shader_feature _QUATERNARY_TRIPLANAR_ON
		#pragma shader_feature _RIM_ON
				
		#pragma hull AlloyHullTessellation
		#pragma vertex AlloyVertexTessellation
		#pragma domain AlloyDomainMeta
		#pragma fragment AlloyFragmentMeta
		
		#define UNITY_PASS_META
		
		#include "Assets/Alloy/Shaders/Definitions/TriPlanar.cginc"
		#include "Assets/Alloy/Shaders/Passes/Meta.cginc"

		ENDCG
	}
}

FallBack "Alloy/TriPlanar/Lite"
CustomEditor "AlloyFieldBasedEditor"
}
