// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

using UnityEngine;

[RequireComponent(typeof(Light))]
[ExecuteInEditMode]
[AddComponentMenu("Alloy/Area Light")]
public class AlloyAreaLight : MonoBehaviour {
	[SerializeField] 
	private Color m_color = new Color(1.0f, 1.0f, 1.0f, 0.0f);

	[SerializeField] 
	private float m_intensity = 1.0f;

	[SerializeField] 
	private float m_size = 0.0f;

	private Light m_light;
	private float m_lastRange;

	private Light Light
	{
		get
		{
			// Ensures that we have the light component, even if light is disabled.
			if (m_light == null)
				m_light = GetComponent<Light>();

			return m_light;
		}
	}

	public float Size {
		get { return m_size; }
		set {
			if (m_size != value) {
				m_size = value;

				UpdateBinding();
			}
		}
	}

	public float Intensity {
		get { return m_intensity; }
		set {
			if (m_intensity != value) {
				m_intensity = value;
				
				UpdateBinding();
			}
		}
	}
	
	public Color Color {
		get { return m_color; }
		set {
			if (m_color != value) {
				m_color = value;
				
				UpdateBinding();
			}
		}
	}
	
	public void UpdateBinding() {
		var light = Light;

		m_size = Mathf.Clamp(m_size, 0.0f, light.range);
		m_intensity = Mathf.Max(m_intensity, 0.0f);

		// Multiply intensity into color to get uncapped values. Unity's
		// light.intensity is implicitly capped to 8, so it is unusable.
		var col = light.color;
		col.r = m_color.r;
		col.g = m_color.g;
		col.b = m_color.b;
		col *= m_intensity; // Color is in gamma space, so mul directly.

		// Store size as a normalized weight, and recover in shader.
		col.a = m_size / light.range;
		light.color = col; 

		// Unity implicitly multiplies color by intensity when uploading
		// it to the shader. So we need it to be one to avoid messing up
		// size stored in alpha.
		light.intensity = 1.0f; 

		m_lastRange = light.range;
	}
	
	private void Reset() {
		var l = GetComponent<Light>();
		
		if (l != null) {
			m_color.r = l.color.r;
			m_color.g = l.color.g;
			m_color.b = l.color.b;
			m_intensity = l.intensity;
			m_size = 0.0f;
		} else {
			m_color.r = 1.0f;
			m_color.g = 1.0f;
			m_color.b = 1.0f;
			m_intensity = 1.0f;
			m_size = 0.0f;
		}

		UpdateBinding ();
	}

	private void Update() {
		if (Light.range != m_lastRange) {
			UpdateBinding();
		}
	}
}
