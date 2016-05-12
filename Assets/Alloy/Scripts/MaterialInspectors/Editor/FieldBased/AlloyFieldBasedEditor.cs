// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

using UnityEngine;

using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEditor.AnimatedValues;


[CanEditMultipleObjects]
public class AlloyFieldBasedEditor : AlloyInspectorBase
{
	private Dictionary<string, AnimBool> m_openCloseAnim;
	private Dictionary<MaterialProperty, AlloyFieldDrawer> m_propInfo;

	private GenericMenu m_menu;
	private string[] m_allTabs;


	private void CloseTabNow(string toggleName) {
		GetProperty(MaterialProperty.PropType.Float, toggleName).floatValue = 0.0f;
		SerializedObject.ApplyModifiedProperties();
		MaterialEditor.ApplyMaterialPropertyDrawers(Targets);

		SceneView.lastActiveSceneView.Repaint();
	}

	public bool TabIsEnabled(string toggleName) {
		var prop = GetProperty(MaterialProperty.PropType.Float, toggleName);

		if (prop == null) {
			Debug.LogError("Can't find tab: " + toggleName);
			return false;
		}

		return !prop.hasMultipleDifferentValues && prop.floatValue > 0.5f;
	}

	public void EnableTab(string tab, string toggleName, int matInst) {
		m_openCloseAnim[toggleName].value = false;
		TabGroup.SetOpen(tab + matInst, true);

		GetProperty(MaterialProperty.PropType.Float, toggleName).floatValue = 1.0f;
		SerializedObject.ApplyModifiedProperties();
		MaterialEditor.ApplyMaterialPropertyDrawers(Targets);

		SceneView.lastActiveSceneView.Repaint();
	}
	
	public void DisableTab(string tab, string toggleName, int matInst) {
		if (TabGroup.IsOpen(tab + matInst)) {
			EditorApplication.delayCall += () => CloseTabNow(toggleName);
		}
		else {
			CloseTabNow(toggleName);
		}

		m_openCloseAnim[toggleName].target = false;
		TabGroup.SetOpen(tab + matInst, false);
	}

	protected override void OnAlloyShaderEnable() {
		m_openCloseAnim = new Dictionary<string, AnimBool>();
		m_propInfo = new Dictionary<MaterialProperty, AlloyFieldDrawer>();
		
		
		
		foreach (var property in MaterialProperties) {
			var drawer = AlloyFieldDrawerFactory.GetFieldDrawer(this, property);



			m_propInfo.Add(property, drawer);
		}

		var allTabs = new List<string>();

		foreach (var drawerProp in m_propInfo) {
			var drawer = drawerProp.Value;

			if (drawer is AlloyTabDrawer) {

				bool isOpenCur = TabGroup.IsOpen(drawer.DisplayName + MatInst);
				
				var anim = new AnimBool(isOpenCur) {speed = 6.0f, value = isOpenCur};
				m_openCloseAnim.Add(drawerProp.Key.name, anim);

				allTabs.Add(drawer.DisplayName);
			}


		}

		

		m_allTabs = allTabs.ToArray();
		m_menu = new GenericMenu();
		Undo.undoRedoPerformed += OnUndo;
	}



	public override void OnAlloyShaderDisable() {
		base.OnAlloyShaderDisable();

		if (m_propInfo != null) {
			foreach (var drawer in m_propInfo) {
				if (drawer.Value != null) {
					drawer.Value.OnDisable();
				}
			}

			m_propInfo.Clear();
		}
	}

	private void OnUndo() {
		OnAlloyShaderDisable();
	}


	protected override void OnAlloyShaderGUI() {
		var args = new AlloyFieldDrawerArgs
		           {
			           Editor = this,
			           Materials = Targets.Cast<Material>().ToArray(),
			           PropertiesSkip = new List<string>(),
			           MatInst = MatInst,
			           TabGroup = TabGroup,
			           AllTabNames = m_allTabs,
					   OpenCloseAnim = m_openCloseAnim
		           };



		foreach (var animBool in m_openCloseAnim) {
			if (animBool.Value.isAnimating) {
				MatEditor.Repaint();
			}
		}



		foreach (var kv in m_propInfo) {

			if (kv.Value == null) {
				continue;
			}

			var drawer = kv.Value;



			if (drawer.ShouldDraw(args)) {
				drawer.Draw(args);
			}
		}


		if (!string.IsNullOrEmpty(args.CurrentTab)) {
			EditorGUILayout.EndFadeGroup();
		}
		

		GUILayout.Space(10.0f);

		DrawAddTabGUI(args.TabsToAdd);
	}


	protected void DrawAddTabGUI(List<AlloyTabAdd> tabsToAdd) {
		if (tabsToAdd.Count <= 0) {
			return;
		}

		GUI.color = new Color(0.8f, 0.8f, 0.8f, 0.8f);
		GUILayout.Label("");
		var rect = GUILayoutUtility.GetLastRect();

		rect.x -= 35.0f;
		rect.width += 10.0f;

		GUI.color = Color.clear;
		bool add = GUI.Button(rect, new GUIContent(""), "Box");
		GUI.color = new Color(0.8f, 0.8f, 0.8f, 0.8f);
		Rect subRect = rect;

		foreach (var tab in tabsToAdd) {
			GUI.color = tab.Color;
			GUI.Box(subRect, "", "ShurikenModuleTitle");

			subRect.x += rect.width / tabsToAdd.Count;
			subRect.width -= rect.width / tabsToAdd.Count;
		}

		GUI.color = new Color(0.8f, 0.8f, 0.8f, 0.8f);

		var delRect = rect;
		delRect.xMin = rect.xMax;
		delRect.xMax += 40.0f;

		if (GUI.Button(delRect, "", "ShurikenModuleTitle") || add) {
			m_menu = new GenericMenu();

			foreach (var tab in tabsToAdd) {
				m_menu.AddItem(new GUIContent(tab.Name), false, tab.Enable);
			}

			m_menu.ShowAsContext();
		}

		delRect.x += 10.0f;

		GUI.Label(delRect, "+");
		rect.x += EditorGUIUtility.currentViewWidth / 2.0f - 30.0f;

		// Ensures tab text is always white, even when using light skin in pro.
		GUI.color = EditorGUIUtility.isProSkin ? new Color(0.7f, 0.7f, 0.7f) : new Color(0.9f, 0.9f, 0.9f);
		GUI.Label(rect, "Add tab", EditorStyles.whiteLabel);
		GUI.color = Color.white;
	}

	public override void OnAlloySceneGUI(SceneView sceneView) {
		foreach (var drawer in m_propInfo) {
			if (drawer.Value == null) {
				continue;
			}

			drawer.Value.Serialized = GetProperty(drawer.Key.type, drawer.Key.name);
			drawer.Value.OnSceneGUI(Targets.Cast<Material>().ToArray());
		}
	}
}