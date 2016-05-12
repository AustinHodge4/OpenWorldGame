// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

Shader "Alloy/Vertex Blend/4Splat TriPlanar" {
Properties {	
	// Triplanar Properties
	_TriplanarProperties ("'Triplanar Properties' {Section:{126, 41, 41}}", Float) = 0
	[KeywordEnum(Object, World)]
	_TriplanarMode ("'Mode' {Dropdown:{Object:{}, World:{}}}", Float) = 1
	_TriplanarBlendSharpness ("'Sharpness' {Min:1, Max:50}", Float) = 2
	
	// Splat0 Properties
	_Splat0Properties ("'Splat0 Properties' {Section:{126, 41, 41}}", Float) = 0
	_Splat0Tint ("'Tint' {}", Color) = (1,1,1)
	_Splat0 ("'Base Color(RGB) Rough(A)' {Visualize:{RGB, A}}", 2D) = "white" {}
	_Normal0 ("'Normals' {Visualize:{NRM}, Parent:_Splat0}", 2D) = "bump" {}
	_Metallic0 ("'Metallic' {Min:0, Max:1}", Float) = 0.0
	_SplatSpecularity0 ("'Specularity' {Min:0, Max:1}", Float) = 0.5
	_SplatSpecularTint0 ("'Specular Tint' {Min:0, Max:1}", Float) = 0.0
	_SplatRoughness0 ("'Roughness' {Min:0, Max:1}", Float) = 1.0

	// Splat1 Properties
	_Splat1Properties ("'Splat1 Properties' {Section:{126, 41, 41}}", Float) = 0
	_Splat1Tint ("'Tint' {}", Color) = (1,1,1)
	_Splat1 ("'Base Color(RGB) Rough(A)' {Visualize:{RGB, A}}", 2D) = "white" {}
	_Normal1 ("'Normals' {Visualize:{NRM}, Parent:_Splat1}", 2D) = "bump" {}
	_Metallic1 ("'Metallic' {Min:0, Max:1}", Float) = 0.0
	_SplatSpecularity1 ("'Specularity' {Min:0, Max:1}", Float) = 0.5
	_SplatSpecularTint1 ("'Specular Tint' {Min:0, Max:1}", Float) = 0.0
	_SplatRoughness1 ("'Roughness' {Min:0, Max:1}", Float) = 1.0

	// Splat2 Properties
	_Splat2Properties ("'Splat2 Properties' {Section:{126, 41, 41}}", Float) = 0
	_Splat2Tint ("'Tint' {}", Color) = (1,1,1)
	_Splat2 ("'Base Color(RGB) Rough(A)' {Visualize:{RGB, A}}", 2D) = "white" {}
	_Normal2 ("'Normals' {Visualize:{NRM}, Parent:_Splat2}", 2D) = "bump" {}
	_Metallic2 ("'Metallic' {Min:0, Max:1}", Float) = 0.0
	_SplatSpecularity2 ("'Specularity' {Min:0, Max:1}", Float) = 0.5
	_SplatSpecularTint2 ("'Specular Tint' {Min:0, Max:1}", Float) = 0.0
	_SplatRoughness2 ("'Roughness' {Min:0, Max:1}", Float) = 1.0
	
	// Splat3 Properties
	_Splat3Properties ("'Splat3 Properties' {Section:{126, 41, 41}}", Float) = 0
	_Splat3Tint ("'Tint' {}", Color) = (1,1,1)
	_Splat3 ("'Base Color(RGB) Rough(A)' {Visualize:{RGB, A}}", 2D) = "white" {}
	_Normal3 ("'Normals' {Visualize:{NRM}, Parent:_Splat3}", 2D) = "bump" {}
	_Metallic3 ("'Metallic' {Min:0, Max:1}", Float) = 0.0
	_SplatSpecularity3 ("'Specularity' {Min:0, Max:1}", Float) = 0.5
	_SplatSpecularTint3 ("'Specular Tint' {Min:0, Max:1}", Float) = 0.0
	_SplatRoughness3 ("'Roughness' {Min:0, Max:1}", Float) = 1.0
}

CGINCLUDE
	#define ALLOY_ENABLE_TRIPLANAR
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
				
		#pragma multi_compile_fwdbase
		#pragma multi_compile_fog
			
		#pragma vertex AlloyVertexForwardBase
		#pragma fragment AlloyFragmentForwardBase
		
		#define UNITY_PASS_FORWARDBASE
		
		#include "Assets/Alloy/Shaders/Definitions/VertexBlend.cginc"
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
		
		#pragma shader_feature _TRIPLANARMODE_OBJECT _TRIPLANARMODE_WORLD
		
		#pragma multi_compile_fwdadd_fullshadows
		#pragma multi_compile_fog
		
		#pragma vertex AlloyVertexForwardAdd
		#pragma fragment AlloyFragmentForwardAdd

		#define UNITY_PASS_FORWARDADD

		#include "Assets/Alloy/Shaders/Definitions/VertexBlend.cginc"
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
		
		#include "Assets/Alloy/Shaders/Definitions/VertexBlend.cginc"
		#include "Assets/Alloy/Shaders/Passes/Shadow.cginc"

		ENDCG
	}
	
	Pass {
		Name "DEFERRED"
		Tags { "LightMode" = "Deferred" }

		CGPROGRAM
		#pragma target 3.0
		#pragma exclude_renderers nomrt gles
		
		#pragma shader_feature _TRIPLANARMODE_OBJECT _TRIPLANARMODE_WORLD
				
		#pragma multi_compile_prepassfinal
		
		#pragma vertex AlloyVertexDeferred
		#pragma fragment AlloyFragmentDeferred
		
		#define UNITY_PASS_DEFERRED
		
		#include "Assets/Alloy/Shaders/Definitions/VertexBlend.cginc"
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
		
		#pragma shader_feature _TRIPLANARMODE_OBJECT _TRIPLANARMODE_WORLD
						
		#pragma vertex AlloyVertexMeta
		#pragma fragment AlloyFragmentMeta
		
		#define UNITY_PASS_META
		
		#include "Assets/Alloy/Shaders/Definitions/VertexBlend.cginc"
		#include "Assets/Alloy/Shaders/Passes/Meta.cginc"

		ENDCG
	}
}

Fallback "VertexLit"
CustomEditor "AlloyFieldBasedEditor"
}
