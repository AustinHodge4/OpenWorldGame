Shader "Custom/PBS Terrain" {
	Properties {
						_Smoothness ("Override Smoothness", Range(0.0, 1.0)) = 0.0 
		[NoScaleOffset]	_NormalGlobal ("Normal Global", 2D) = "bump" {}
		
		// set by terrain engine
		[HideInInspector] _Control ("Control (RGBA)", 2D) = "red" {}
		[HideInInspector] _Splat3 ("Layer 3 (A)", 2D) = "white" {}
		[HideInInspector] _Splat2 ("Layer 2 (B)", 2D) = "white" {}
		[HideInInspector] _Splat1 ("Layer 1 (G)", 2D) = "white" {}
		[HideInInspector] _Splat0 ("Layer 0 (R)", 2D) = "white" {}
		[HideInInspector] _Normal3 ("Normal 3 (A)", 2D) = "bump" {}
		[HideInInspector] _Normal2 ("Normal 2 (B)", 2D) = "bump" {}
		[HideInInspector] _Normal1 ("Normal 1 (G)", 2D) = "bump" {}
		[HideInInspector] _Normal0 ("Normal 0 (R)", 2D) = "bump" {}
		[HideInInspector] [Gamma] _Metallic0 ("Metallic 0", Range(0.0, 1.0)) = 0.0	
		[HideInInspector] [Gamma] _Metallic1 ("Metallic 1", Range(0.0, 1.0)) = 0.0	
		[HideInInspector] [Gamma] _Metallic2 ("Metallic 2", Range(0.0, 1.0)) = 0.0	
		[HideInInspector] [Gamma] _Metallic3 ("Metallic 3", Range(0.0, 1.0)) = 0.0

		// used in fallback on old cards & base map
		[HideInInspector] _MainTex ("BaseMap (RGB)", 2D) = "white" {}
		[HideInInspector] _Color ("Main Color", Color) = (1,1,1,1)
	}

	SubShader {
		Tags {
			"SplatCount" = "4"
			"Queue" = "Geometry-100"
			"RenderType" = "Opaque"
		}

		CGPROGRAM
		// As we can't blend normals in g-buffer, this shader will not work in standard deferred path. 
		// So we use exclude_path:deferred to force it to only use the forward path.
		#pragma surface surf Standard vertex:SplatmapVert finalcolor:myfinal exclude_path:prepass exclude_path:deferred
		#pragma multi_compile_fog
		#pragma target 3.0
		// needs more than 8 texcoords
		#pragma exclude_renderers gles
		#include "UnityPBSLighting.cginc"

		#pragma multi_compile __ _TERRAIN_NORMAL_MAP
//		#pragma multi_compile __ _TERRAIN_OVERRIDE_SMOOTHNESS

		#include "TerrainSplatmapCommon.cginc"

//		#ifdef _TERRAIN_OVERRIDE_SMOOTHNESS
			half _Smoothness;
//		#endif

		half _Metallic0;
		half _Metallic1;
		half _Metallic2;
		half _Metallic3;
		sampler2D _NormalGlobal;
		
		void SplatmapMixed(Input IN, out half4 splat_control, out half weight, out fixed4 mixedDiffuse, inout fixed3 mixedNormal)
		{
			splat_control = tex2D(_Control, IN.tc_Control);
			weight = dot(splat_control, half4(1,1,1,1));

			#ifndef UNITY_PASS_DEFERRED
				// Normalize weights before lighting and restore weights in applyWeights function so that the overal
				// lighting result can be correctly weighted.
				// In G-Buffer pass we don't need to do it if Additive blending is enabled.
				// TODO: Normal blending in G-buffer pass...
				splat_control /= (weight + 1e-3f); // avoid NaNs in splat_control
			#endif

			#if !defined(SHADER_API_MOBILE) && defined(TERRAIN_SPLAT_ADDPASS)
				clip(weight - 0.0039 /*1/255*/);
			#endif

			mixedDiffuse = 0.0f;
			mixedDiffuse += splat_control.r * tex2D(_Splat0, IN.uv_Splat0);
			mixedDiffuse += splat_control.g * tex2D(_Splat1, IN.uv_Splat1);
			mixedDiffuse += splat_control.b * tex2D(_Splat2, IN.uv_Splat2);
			mixedDiffuse += splat_control.a * tex2D(_Splat3, IN.uv_Splat3);

			#ifdef _TERRAIN_NORMAL_MAP
				fixed4 nrm = 0.0f;
				nrm += splat_control.r * tex2D(_Normal0, IN.uv_Splat0);
				nrm += splat_control.g * tex2D(_Normal1, IN.uv_Splat1);
				nrm += splat_control.b * tex2D(_Normal2, IN.uv_Splat2);
				nrm += splat_control.a * tex2D(_Normal3, IN.uv_Splat3);
		//		mixedNormal = UnpackNormal(nrm);

			// Add global normal
			fixed4 global = ( tex2D (_NormalGlobal, IN.tc_Control) );
//			nrm.b = 0.0;
			// Sum of our four splat weights might not sum up to 1,
			// in case of more than 4 total splat maps. Need to lerp towards
			// "flat normal" in that case.
			fixed splatSum = dot(splat_control, (fixed4)1.0);
			fixed4 flatNormal = fixed4(0.5,0.5,1,0.5); // this is "flat normal" in both DXT5nm and xyz*2-1 cases
			nrm = lerp(flatNormal, nrm, splatSum);
			mixedNormal = UnpackNormal((global + nrm) * 0.5);
			#endif
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			half4 splat_control;
			half weight;
			fixed4 mixedDiffuse;
			SplatmapMixed(IN, splat_control, weight, mixedDiffuse, o.Normal);
			o.Albedo = mixedDiffuse.rgb;
			o.Alpha = weight;
//			#ifdef _TERRAIN_OVERRIDE_SMOOTHNESS
//				o.Smoothness = _Smoothness;
//			#else
				o.Smoothness = mixedDiffuse.a * _Smoothness;
//			#endif
			o.Metallic = dot(splat_control, half4(_Metallic0, _Metallic1, _Metallic2, _Metallic3));
		}

		void myfinal(Input IN, SurfaceOutputStandard o, inout fixed4 color)
		{
			SplatmapApplyWeight(color, o.Alpha);
			SplatmapApplyFog(color, IN);
		}

		ENDCG
	}

	Dependency "AddPassShader" = "Hidden/TerrainEngine/Splatmap/Standard-AddPass"
	Dependency "BaseMapShader" = "Hidden/TerrainEngine/Splatmap/Standard-Base"

	Fallback "Nature/Terrain/Diffuse"
}

