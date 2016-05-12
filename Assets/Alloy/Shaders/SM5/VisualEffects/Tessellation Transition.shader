// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

Shader "Alloy/Tessellation/Transition" {
Properties {
	// Settings
	_Mode ("'Rendering Mode' {RenderingMode:{Opaque:{_Cutoff}, Cutout:{}, Fade:{_Cutoff}, Transparent:{_Cutoff}}}", Float) = 0
	_SrcBlend ("__src", Float) = 0
	_DstBlend ("__dst", Float) = 0
	_ZWrite ("__zw", Float) = 1
	[LM_TransparencyCutOff] 
	_Cutoff ("'Alpha Cutoff' {Min:0, Max:1}", Float) = 0.5
	_Lightmapping ("'GI' {LightmapEmissionProperty:{}}", Float) = 1
	
	// Main Textures
	_MainTextures ("'Main Textures' {Section:{126, 41, 41}}", Float) = 0
	[LM_Albedo] [LM_Transparency] 
	_Color ("'Tint' {}", Color) = (1,1,1,1)	
	[LM_MasterTilingOffset] [LM_Albedo] 
	_MainTex ("'Base Color(RGB) Opacity(A)' {Visualize:{RGB, A}}", 2D) = "white" {}
	_MainTexVelocity ("Scroll", Vector) = (0,0,0,0) 
	_MainTexUV ("UV Set", Float) = 0
	[LM_Metallic]
 	_SpecTex ("'Metal(R) AO(G) Spec(B) Rough(A)' {Visualize:{R, G, B, A}, Parent:_MainTex}", 2D) = "white" {}
	[LM_NormalMap]
	_BumpMap ("'Normals' {Visualize:{NRM}, Parent:_MainTex}", 2D) = "bump" {}
	_BaseColorVertexTint ("'Vertex Color Tint' {Min:0, Max:1}", Float) = 0
	 
	// Main Physical Properties
	_MainPhysicalProperties ("'Main Physical Properties' {Section:{126, 66, 41}}", Float) = 0
	[LM_Metallic]
	_Metal ("'Metallic' {Min:0, Max:1}", Float) = 1
	_Specularity ("'Specularity' {Min:0, Max:1}", Float) = 1
	_Roughness ("'Roughness' {Min:0, Max:1}", Float) = 1
	_Occlusion ("'Occlusion Strength' {Min:0, Max:1}", Float) = 1
	_BumpScale ("'Normal Strength' {}", Float) = 1
	
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
	_DetailMask ("'Mask(A)' {Visualize:{A}, Parent:_MainTex}", 2D) = "white" {}
	_DetailWeight ("'Weight' {Min:0, Max:1}", Float) = 1
	_DetailAlbedoMap ("'Color' {Visualize:{RGB}}", 2D) = "white" {}
	_DetailAlbedoMapVelocity ("Scroll", Vector) = (0,0,0,0) 
	_DetailAlbedoMapUV ("UV Set", Float) = 0
	_DetailMaterialMap ("'AO(G) Variance(A)' {Visualize:{G, A}, Parent:_DetailAlbedoMap}", 2D) = "white" {}
	_DetailNormalMap ("'Normals' {Visualize:{NRM}, Parent:_DetailAlbedoMap}", 2D) = "bump" {}
	_DetailOcclusion ("'Occlusion Strength' {Min:0, Max:1}", Float) = 1
	_DetailNormalMapScale ("'Normal Strength' {}", Float) = 1
	
	// Team Color Properties
	[Toggle(_TEAMCOLOR_ON)] 
	_TeamColor ("'Team Color Properties' {Feature:{41, 126, 50}}", Float) = 0
	[Enum(RGB, 0, RGBA, 1)] 
	_TeamColorMode ("'Mode' {Dropdown:{RGB:{_TeamColor3}, RGBA:{}}}", Float) = 1	
	_TeamColor0 ("'Tint R' {}", Color) = (1,1,1)
	_TeamColor1 ("'Tint G' {}", Color) = (1,1,1)
	_TeamColor2 ("'Tint B' {}", Color) = (1,1,1)
	_TeamColor3 ("'Tint A' {}", Color) = (1,1,1)
	_TeamColorMaskMap ("'Masks' {Visualize:{R, G, B, A}, Parent:_MainTex}", 2D) = "white" {}
	
	// Decal Properties 
	[Toggle(_DECAL_ON)] 
	_Decal ("'Decal Properties' {Feature:{41, 126, 75}}", Float) = 0	
	_DecalColor ("'Tint' {}", Color) = (1,1,1,1)
	_DecalTex ("'Base Color(RGB) Opacity(A)' {Visualize:{RGB, A}}", 2D) = "black" {} 
	_DecalTexUV ("UV Set", Float) = 0
	_DecalWeight ("'Weight' {Min:0, Max:1}", Float) = 1
	_DecalSpecularity ("'Specularity' {Min:0, Max:1}", Float) = 0.5
	_DecalAlphaVertexTint ("'Vertex Alpha Tint' {Min:0, Max:1}", Float) = 0

	// Emission Properties 
	[Toggle(_EMISSION)] 
	_Emission ("'Emission Properties' {Feature:{41, 126, 101}}", Float) = 0
	[LM_Emission] 
	[HDR]
	_EmissionColor ("'Tint' {}", Color) = (1,1,1)
	[LM_Emission] 
	_EmissionMap ("'Color' {Visualize:{RGB}, Parent:_MainTex}", 2D) = "white" {}
	_IncandescenceMap ("'Effect' {Visualize:{RGB}}", 2D) = "white" {} 
	_IncandescenceMapVelocity ("Scroll", Vector) = (0,0,0,0) 
	_IncandescenceMapUV ("UV Set", Float) = 0
	[Gamma]
	_EmissionWeight ("'Weight' {Min:0, Max:1}", Float) = 1

	// Rim Emission Properties 
	[Toggle(_RIM_ON)] 
	_Rim ("'Rim Emission Properties' {Feature:{41, 125, 126}}", Float) = 0
	[HDR]
	_RimColor ("'Tint' {}", Color) = (1,1,1)
	_RimTex ("'Effect' {Visualize:{RGB}}", 2D) = "white" {}
	_RimTexVelocity ("Scroll", Vector) = (0,0,0,0) 
	_RimTexUV ("UV Set", Float) = 0
	[Gamma]
	_RimWeight ("'Weight' {Min:0, Max:1}", Float) = 1
	[Gamma]
	_RimBias ("'Fill' {Min:0, Max:1}", Float) = 0
	_RimPower ("'Falloff' {Min:0.01}", Float) = 4

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

	// Transition Properties 
	_TransitionProperties ("'Transition Properties' {Section:{41, 74, 126}}", Float) = 0
	[HDR]
	_TransitionGlowColor ("'Glow Tint' {}", Color) = (1,1,1,1)
	_TransitionTex ("'Glow Color(RGB) Trans(A)' {Visualize:{RGB, A}}", 2D) = "white" {} 
	_TransitionTexUV ("UV Set", Float) = 0
	_TransitionCutoff ("'Cutoff' {Min:0, Max:1}", Float) = 0
	[Gamma]
	_TransitionGlowWeight ("'Glow Weight' {Min:0, Max:1}", Float) = 1
	_TransitionEdgeWidth ("'Glow Width' {Min:0, Max:1}", Float) = 0.01
	
	// Secondary Textures 
	_SecondaryTextures ("'Secondary Textures' {Section:{41, 48, 126}}", Float) = 0
	_Color2 ("'Tint' {}", Color) = (1,1,1,1)	
	_MainTex2 ("'Base Color(RGB) Opacity(A)' {Visualize:{RGB, A}}", 2D) = "white" {}
	_MainTex2Velocity ("Scroll", Vector) = (0,0,0,0) 
	_MainTex2UV ("UV Set", Float) = 0
	_MaterialMap2 ("'Metal(R) AO(G) Spec(B) Rough(A)' {Visualize:{R, G, B, A}, Parent:_MainTex2}", 2D) = "white" {}
	_BumpMap2 ("'Normals' {Visualize:{NRM}, Parent:_MainTex2}", 2D) = "bump" {}
	_BaseColorVertexTint2 ("'Vertex Color Tint' {Min:0, Max:1}", Float) = 0
	
	// Secondary Physical Properties 
	_SecondaryPhysicalProperties ("'Secondary Physical Properties' {Section:{59, 41, 126}}", Float) = 0
	_Metallic2 ("'Metallic' {Min:0, Max:1}", Float) = 1
	_Specularity2 ("'Specularity' {Min:0, Max:1}", Float) = 1
	_Roughness2 ("'Roughness' {Min:0, Max:1}", Float) = 1
	_Occlusion2 ("'Occlusion Strength' {Min:0, Max:1}", Float) = 1
	_BumpScale2 ("'Normal Strength' {}", Float) = 1

	// Secondary Emission Properties 
	[Toggle(_EMISSION2_ON)] 
	_Emission2 ("'Secondary Emission Properties' {Feature:{85, 41, 126}}", Float) = 0
	[HDR]
	_Emission2Color ("'Tint' {}", Color) = (1,1,1)
	_EmissionMap2 ("'Color' {Visualize:{RGB}, Parent:_MainTex2}", 2D) = "white" {}
	_IncandescenceMap2 ("'Effect' {Visualize:{RGB}}", 2D) = "white" {} 
	_IncandescenceMap2Velocity ("Scroll", Vector) = (0,0,0,0) 
	_IncandescenceMap2UV ("UV Set", Float) = 0
	[Gamma]
	_Emission2Weight ("'Weight' {Min:0, Max:1}", Float) = 1
	
   	// Secondary Rim Emission Properties 
	[Toggle(_RIM2_ON)] 
	_Rim2 ("'Secondary Rim Emission' {Feature:{110, 41, 126}}", Float) = 0
	[HDR]
	_Rim2Color ("'Tint' {}", Color) = (1,1,1)
	_RimTex2 ("'Effect' {Visualize:{RGB}}", 2D) = "white" {}
	_RimTex2Velocity ("Scroll", Vector) = (0,0,0,0) 
	_RimTex2UV ("UV Set", Float) = 0
	[Gamma]
	_Rim2Weight ("'Weight' {Min:0, Max:1}", Float) = 1
	[Gamma]
	_Rim2Bias ("'Fill' {Min:0, Max:1}", Float) = 0
	_Rim2Power ("'Falloff' {Min:0}", Float) = 4
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
		#pragma shader_feature _DETAIL_ON
		#pragma shader_feature _TEAMCOLOR_ON
		#pragma shader_feature _DECAL_ON
		#pragma shader_feature _EMISSION
		#pragma shader_feature _RIM_ON
		#pragma shader_feature _DISSOLVE_ON
		#pragma shader_feature _EMISSION2_ON
		#pragma shader_feature _RIM2_ON
		
		#pragma multi_compile_fwdbase
		#pragma multi_compile_fog
			
		#pragma hull AlloyHullTessellation
		#pragma vertex AlloyVertexTessellation
		#pragma domain AlloyDomainForwardBase
		#pragma fragment AlloyFragmentForwardBase
		
		#define UNITY_PASS_FORWARDBASE
		
		#include "Assets/Alloy/Shaders/Definitions/Transition.cginc"
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
		#pragma shader_feature _DETAIL_ON
		#pragma shader_feature _TEAMCOLOR_ON
		#pragma shader_feature _DECAL_ON
		#pragma shader_feature _DISSOLVE_ON
		
		#pragma multi_compile_fwdadd_fullshadows
		#pragma multi_compile_fog
		
		#pragma hull AlloyHullTessellation
		#pragma vertex AlloyVertexTessellation
		#pragma domain AlloyDomainForwardAdd
		#pragma fragment AlloyFragmentForwardAdd

		#define UNITY_PASS_FORWARDADD

		#include "Assets/Alloy/Shaders/Definitions/Transition.cginc"
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
		#pragma shader_feature _DISSOLVE_ON
		
		#pragma multi_compile_shadowcaster

		#pragma hull AlloyHullTessellation
		#pragma vertex AlloyVertexTessellation
		#pragma domain AlloyDomainShadowCaster
		#pragma fragment AlloyFragmentShadowCaster
		
		#define UNITY_PASS_SHADOWCASTER
		
		#include "Assets/Alloy/Shaders/Definitions/Transition.cginc"
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
		#pragma shader_feature _DETAIL_ON
		#pragma shader_feature _TEAMCOLOR_ON
		#pragma shader_feature _DECAL_ON
		#pragma shader_feature _EMISSION
		#pragma shader_feature _RIM_ON
		#pragma shader_feature _DISSOLVE_ON
		#pragma shader_feature _EMISSION2_ON
		#pragma shader_feature _RIM2_ON
		
		#pragma multi_compile_prepassfinal
		
		#pragma hull AlloyHullTessellation
		#pragma vertex AlloyVertexTessellation
		#pragma domain AlloyDomainDeferred
		#pragma fragment AlloyFragmentDeferred
		
		#define UNITY_PASS_DEFERRED
		
		#include "Assets/Alloy/Shaders/Definitions/Transition.cginc"
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
		#pragma shader_feature _DETAIL_ON
		#pragma shader_feature _TEAMCOLOR_ON
		#pragma shader_feature _EMISSION
		#pragma shader_feature _RIM_ON
		#pragma shader_feature _DISSOLVE_ON
		#pragma shader_feature _EMISSION2_ON
		#pragma shader_feature _RIM2_ON
				
		#pragma hull AlloyHullTessellation
		#pragma vertex AlloyVertexTessellation
		#pragma domain AlloyDomainMeta
		#pragma fragment AlloyFragmentMeta
		
		#define UNITY_PASS_META
		
		#include "Assets/Alloy/Shaders/Definitions/Transition.cginc"
		#include "Assets/Alloy/Shaders/Passes/Meta.cginc"

		ENDCG
	}
}

FallBack "Alloy/Transition"
CustomEditor "AlloyFieldBasedEditor"
}
