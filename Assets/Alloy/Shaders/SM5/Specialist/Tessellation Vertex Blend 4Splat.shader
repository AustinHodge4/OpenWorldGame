// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

Shader "Alloy/Tessellation/Vertex Blend/4Splat" {
Properties {
	// Settings
	_Mode ("'Rendering Mode' {RenderingMode:{Opaque:{_Cutoff}, Cutout:{}, Fade:{_Cutoff}, Transparent:{_Cutoff}}}", Float) = 0
	_SrcBlend ("__src", Float) = 0
	_DstBlend ("__dst", Float) = 0
	_ZWrite ("__zw", Float) = 1
	[LM_TransparencyCutOff] 
	_Cutoff ("'Alpha Cutoff' {Min:0, Max:1}", Float) = 0.5
	
	// Splat0 Properties
	_Splat0Properties ("'Splat0 Properties' {Section:{126, 41, 41}}", Float) = 0
	_Splat0Tint ("'Tint' {}", Color) = (1,1,1)
	_Splat0 ("'Base Color(RGB) Rough(A)' {Visualize:{RGB, A}}", 2D) = "white" {}	
	_Splat0Velocity ("Scroll", Vector) = (0,0,0,0) 
	_Splat0UV ("UV Set", Float) = 0
	_Normal0 ("'Normals' {Visualize:{NRM}, Parent:_Splat0}", 2D) = "bump" {}
	_Metallic0 ("'Metallic' {Min:0, Max:1}", Float) = 0.0
	_SplatSpecularity0 ("'Specularity' {Min:0, Max:1}", Float) = 0.5
	_SplatSpecularTint0 ("'Specular Tint' {Min:0, Max:1}", Float) = 0.0
	_SplatRoughness0 ("'Roughness' {Min:0, Max:1}", Float) = 1.0

	// Splat1 Properties
	_Splat1Properties ("'Splat1 Properties' {Section:{126, 41, 41}}", Float) = 0
	_Splat1Tint ("'Tint' {}", Color) = (1,1,1)
	_Splat1 ("'Base Color(RGB) Rough(A)' {Visualize:{RGB, A}}", 2D) = "white" {}	
	_Splat1Velocity ("Scroll", Vector) = (0,0,0,0) 
	_Splat1UV ("UV Set", Float) = 0
	_Normal1 ("'Normals' {Visualize:{NRM}, Parent:_Splat1}", 2D) = "bump" {}
	_Metallic1 ("'Metallic' {Min:0, Max:1}", Float) = 0.0
	_SplatSpecularity1 ("'Specularity' {Min:0, Max:1}", Float) = 0.5
	_SplatSpecularTint1 ("'Specular Tint' {Min:0, Max:1}", Float) = 0.0
	_SplatRoughness1 ("'Roughness' {Min:0, Max:1}", Float) = 1.0

	// Splat2 Properties
	_Splat2Properties ("'Splat2 Properties' {Section:{126, 41, 41}}", Float) = 0
	_Splat2Tint ("'Tint' {}", Color) = (1,1,1)
	_Splat2 ("'Base Color(RGB) Rough(A)' {Visualize:{RGB, A}}", 2D) = "white" {}	
	_Splat2Velocity ("Scroll", Vector) = (0,0,0,0) 
	_Splat2UV ("UV Set", Float) = 0
	_Normal2 ("'Normals' {Visualize:{NRM}, Parent:_Splat2}", 2D) = "bump" {}
	_Metallic2 ("'Metallic' {Min:0, Max:1}", Float) = 0.0
	_SplatSpecularity2 ("'Specularity' {Min:0, Max:1}", Float) = 0.5
	_SplatSpecularTint2 ("'Specular Tint' {Min:0, Max:1}", Float) = 0.0
	_SplatRoughness2 ("'Roughness' {Min:0, Max:1}", Float) = 1.0
	
	// Splat3 Properties
	_Splat3Properties ("'Splat3 Properties' {Section:{126, 41, 41}}", Float) = 0
	_Splat3Tint ("'Tint' {}", Color) = (1,1,1)
	_Splat3 ("'Base Color(RGB) Rough(A)' {Visualize:{RGB, A}}", 2D) = "white" {}	
	_Splat3Velocity ("Scroll", Vector) = (0,0,0,0) 
	_Splat3UV ("UV Set", Float) = 0
	_Normal3 ("'Normals' {Visualize:{NRM}, Parent:_Splat3}", 2D) = "bump" {}
	_Metallic3 ("'Metallic' {Min:0, Max:1}", Float) = 0.0
	_SplatSpecularity3 ("'Specularity' {Min:0, Max:1}", Float) = 0.5
	_SplatSpecularTint3 ("'Specular Tint' {Min:0, Max:1}", Float) = 0.0
	_SplatRoughness3 ("'Roughness' {Min:0, Max:1}", Float) = 1.0
	
	// Tessellation Properties
	_TessellationProperties ("'Tessellation Properties' {Section:{109, 126, 41}}", Float) = 0
	[KeywordEnum(Displacement, Phong, Combined)] 
	_TessellationMode ("'Mode' {Dropdown:{Displacement:{_Phong}, Phong:{_DispTex, _Displacement}, Combined:{}}}", Float) = 0
	_DispTex ("'Heightmap(G)' {Visualize:{G}}", 2D) = "black" {}
	_DispTexVelocity ("Scroll", Vector) = (0,0,0,0)
	_Displacement ("'Displacement' {Min:0, Max:30}", Float) = 0.3	
	_Phong ("'Phong Strength' {Min:0, Max:1}", Float) = 0.5
	_EdgeLength ("'Edge Length' {Min:2, Max:50}", Float) = 15
		
	// Detail Properties
	[Toggle(_DETAIL_ON)] 
	_DetailT ("'Detail Properties' {Feature:{57, 126, 41}}", Float) = 0
	[Enum(Mul, 0, MulX2, 1)] 
	_DetailMode ("'Mode' {Dropdown:{Mul:{}, MulX2:{}}}", Float) = 0
	_DetailWeight ("'Weight' {Min:0, Max:1}", Float) = 1
	_DetailAlbedoMap ("'Color' {Visualize:{RGB}}", 2D) = "white" {} 
	_DetailAlbedoMapUV ("UV Set", Float) = 0
	_DetailMaterialMap ("'AO(G) Variance(A)' {Visualize:{G, A}, Parent:_DetailAlbedoMap}", 2D) = "white" {}
	_DetailNormalMap ("'Normals' {Visualize:{NRM}, Parent:_DetailAlbedoMap}", 2D) = "bump" {}
	_DetailOcclusion ("'Occlusion Strength' {Min:0, Max:1}", Float) = 1
	_DetailNormalMapScale ("'Normal Strength' {}", Float) = 1
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

		CGPROGRAM
		#pragma target 3.0
		#pragma exclude_renderers gles
		
		#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
		#pragma shader_feature _TESSELLATIONMODE_DISPLACEMENT _TESSELLATIONMODE_PHONG _TESSELLATIONMODE_COMBINED
		#pragma shader_feature _DETAIL_ON
		
		#pragma multi_compile_fwdbase
		#pragma multi_compile_fog
			
		#pragma hull AlloyHullTessellation
		#pragma vertex AlloyVertexTessellation
		#pragma domain AlloyDomainForwardBase
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
						
		#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
		#pragma shader_feature _TESSELLATIONMODE_DISPLACEMENT _TESSELLATIONMODE_PHONG _TESSELLATIONMODE_COMBINED
		#pragma shader_feature _DETAIL_ON
		
		#pragma multi_compile_fwdadd_fullshadows
		#pragma multi_compile_fog
		
		#pragma hull AlloyHullTessellation
		#pragma vertex AlloyVertexTessellation
		#pragma domain AlloyDomainForwardAdd
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
		
		#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
		#pragma shader_feature _TESSELLATIONMODE_DISPLACEMENT _TESSELLATIONMODE_PHONG _TESSELLATIONMODE_COMBINED
		
		#pragma multi_compile_shadowcaster

		#pragma hull AlloyHullTessellation
		#pragma vertex AlloyVertexTessellation
		#pragma domain AlloyDomainShadowCaster
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
				
		#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
		#pragma shader_feature _TESSELLATIONMODE_DISPLACEMENT _TESSELLATIONMODE_PHONG _TESSELLATIONMODE_COMBINED
		#pragma shader_feature _DETAIL_ON
				
		#pragma multi_compile_prepassfinal
		
		#pragma hull AlloyHullTessellation
		#pragma vertex AlloyVertexTessellation
		#pragma domain AlloyDomainDeferred
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
						
		#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
		#pragma shader_feature _TESSELLATIONMODE_DISPLACEMENT _TESSELLATIONMODE_PHONG _TESSELLATIONMODE_COMBINED
		#pragma shader_feature _DETAIL_ON
						
		#pragma hull AlloyHullTessellation
		#pragma vertex AlloyVertexTessellation
		#pragma domain AlloyDomainMeta
		#pragma fragment AlloyFragmentMeta
		
		#define UNITY_PASS_META
		
		#include "Assets/Alloy/Shaders/Definitions/VertexBlend.cginc"
		#include "Assets/Alloy/Shaders/Passes/Meta.cginc"

		ENDCG
	}
}

Fallback "Alloy/Vertex Blend/4Splat"
CustomEditor "AlloyFieldBasedEditor"
}
