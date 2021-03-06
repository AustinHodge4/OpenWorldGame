﻿// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

Shader "Hidden/AlloyNormalBlit" {
	Properties {
		_MainTex ("Render Input", 2D) = "white" {}
	}
	SubShader {
		ZTest Always Cull Off ZWrite Off Fog { Mode Off }
		Pass {
			CGPROGRAM
				#pragma vertex vert_img
				#pragma fragment frag
				#include "UnityCG.cginc"
			
				sampler2D _MainTex;
				float _EditorIsLinear;
			
				float4 frag(v2f_img IN) : COLOR {
					half3 n = UnpackNormal(tex2D (_MainTex, IN.uv));
					half4 col =  half4((n.x + 1.0f) / 2.0f, (n.y + 1.0f) / 2.0f, (n.z + 1.0f) / 2.0f, 1.0f);


					//TODO: Whyyyyy was this in there? what did it do?
					//if (_EditorIsLinear > 0)
					//{
						//col = pow(col, 2.2f);
					//}

					return col;
				}
			ENDCG
		}
	}
}