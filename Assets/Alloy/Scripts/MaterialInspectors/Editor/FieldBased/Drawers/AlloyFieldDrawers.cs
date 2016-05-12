// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class AlloyDefaultDrawer : AlloyFieldDrawer
{
	public override void Draw(AlloyFieldDrawerArgs args) {
		PropField(DisplayName);
	}

	public AlloyDefaultDrawer(AlloyInspectorBase editor, MaterialProperty property) : base(editor, property) {
	}
}


public class AlloyLightmapEmissionDrawer : AlloyFieldDrawer {
	
	public override void Draw(AlloyFieldDrawerArgs args) {
		args.Editor.MatEditor.LightmapEmissionProperty();
		
		foreach (var material in args.Materials) {
			// Setup lightmap emissive flags
			MaterialGlobalIlluminationFlags flags = material.globalIlluminationFlags;
			if ((flags & (MaterialGlobalIlluminationFlags.BakedEmissive | MaterialGlobalIlluminationFlags.RealtimeEmissive)) != 0) {
				flags &= ~MaterialGlobalIlluminationFlags.EmissiveIsBlack;
				
			
				material.globalIlluminationFlags = flags;
			}
		}
	}

	public AlloyLightmapEmissionDrawer(AlloyInspectorBase editor, MaterialProperty property) : base(editor, property) {
	}

}

public class AlloyRenderingModeDrawer : AlloyDropdownDrawer
{
	public string RenderQueueOrderField;
	
	private enum RenderingMode
	{
		Opaque,
		Cutout,
		Fade,
		Transparent
	}
	
	protected override bool OnSetOption(int newOption, AlloyFieldDrawerArgs args) {
		base.OnSetOption(newOption, args);
		var newMode = (RenderingMode) newOption;
		bool setVal = true;
		
		
		if (!string.IsNullOrEmpty(RenderQueueOrderField)) {
			var custom = args.Editor.GetProperty(MaterialProperty.PropType.Float, RenderQueueOrderField);
			
			if (custom.floatValue > 0.5f) {
				setVal = false;
			}
		}
		
		foreach (var material in args.Materials) {
			switch (newMode) {
			case RenderingMode.Opaque:
				material.SetInt("_SrcBlend", (int) BlendMode.One);
				material.SetInt("_DstBlend", (int) BlendMode.Zero);
				material.SetInt("_ZWrite", 1);
				
				material.DisableKeyword("_ALPHATEST_ON");
				material.DisableKeyword("_ALPHABLEND_ON");
				material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
				
				if (setVal) {
					material.renderQueue = -1;
				}
				break;
			case RenderingMode.Cutout:
				material.SetInt("_SrcBlend", (int) BlendMode.One);
				material.SetInt("_DstBlend", (int) BlendMode.Zero);
				material.SetInt("_ZWrite", 1);
				
				material.DisableKeyword("_ALPHABLEND_ON");
				material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
				material.EnableKeyword("_ALPHATEST_ON");
				
				if (setVal) {
					material.renderQueue = 2450;
				}
				break;
			case RenderingMode.Fade:
				material.SetInt("_SrcBlend", (int) BlendMode.SrcAlpha);
				material.SetInt("_DstBlend", (int) BlendMode.OneMinusSrcAlpha);
				material.SetInt("_ZWrite", 0);
				
				material.DisableKeyword("_ALPHATEST_ON");
				material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
				material.EnableKeyword("_ALPHABLEND_ON");
				
				if (setVal) {
					material.renderQueue = 3000;
				}
				break;
			case RenderingMode.Transparent:
				material.SetInt("_SrcBlend", (int) BlendMode.One);
				material.SetInt("_DstBlend", (int) BlendMode.OneMinusSrcAlpha);
				material.SetInt("_ZWrite", 0);
				
				material.DisableKeyword("_ALPHATEST_ON");
				material.DisableKeyword("_ALPHABLEND_ON");
				material.EnableKeyword("_ALPHAPREMULTIPLY_ON");
				
				if (setVal) {
					material.renderQueue = 3000;
				}
				break;
			}
			
			material.SetInt("_Mode", (int)newMode);
			EditorUtility.SetDirty(material);
		}
		
		Undo.RecordObjects(args.Materials, "Set blend mode");
		return true;
	}

	public AlloyRenderingModeDrawer(AlloyInspectorBase editor, MaterialProperty property) : base(editor, property) {
	}
}

public class AlloyColorParser : AlloyFieldParser{
	protected override AlloyFieldDrawer GenerateDrawer(AlloyInspectorBase editor) {
		var ret = new AlloyColorDrawer(editor, MaterialProperty);
		return ret;
	}
	
	public AlloyColorParser(MaterialProperty field) : base(field) {
	}
}

public class AlloyColorDrawer : AlloyFieldDrawer {
	public override void Draw(AlloyFieldDrawerArgs args) {
		MaterialPropField(DisplayName, args);
	}

	public AlloyColorDrawer(AlloyInspectorBase editor, MaterialProperty property) : base(editor, property) {
	}
}
