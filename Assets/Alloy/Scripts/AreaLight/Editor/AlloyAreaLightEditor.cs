// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(AlloyAreaLight))]
[CanEditMultipleObjects]
public class AlloyAreaLightEditor : Editor {
	
	public override void OnInspectorGUI() {
		
		serializedObject.Update();

		float minRange = float.MaxValue;

		foreach (AlloyAreaLight area in targets) {
			var light = area.GetComponent<Light>();
			minRange = Mathf.Min(light.range, minRange);
		}

		EditorGUILayout.Slider(serializedObject.FindProperty("m_size"), 0.0f, minRange);
		
		serializedObject.ApplyModifiedProperties();

		if (GUI.changed) {
			foreach (AlloyAreaLight area in targets) {
				area.UpdateBinding();
			}
		}
		
		bool wrongSetup = false;

		foreach (AlloyAreaLight area in targets) {
			var light = area.GetComponent<Light>();
			
			if (light.type != LightType.Point
			    && light.type != LightType.Spot) {
				wrongSetup = true;
			}
		}

		if (wrongSetup) {
			EditorGUILayout.HelpBox("Can only convert Point & Spot lights to area lights.", MessageType.Warning);
		}
	}

	private void OnSceneGUI() {
		var area = target as AlloyAreaLight;
		area.Size = Handles.RadiusHandle(Quaternion.identity, area.transform.position, area.Size);

		if (GUI.changed) {
			Undo.RecordObject(area, "Adjust area light");
		}
	}
}
