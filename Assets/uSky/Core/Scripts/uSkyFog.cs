using UnityEngine;
using System.Collections;

namespace uSky
{
	[ExecuteInEditMode]
	[AddComponentMenu ("uSky/uSky Fog (Image Effects)")]
	public class uSkyFog : MonoBehaviour 
	{
		public enum FogModes
		{
			Linear = 1,
			Exponential = 2,
			Exponential_Squared = 3
		}
		public FogModes fogMode = FogModes.Exponential;

//		[Tooltip("Distance fog is based on radial distance from camera when checked")]
		public bool  useRadialDistance = false;

//		[Tooltip("Distance fog amount")]
		[Range(0.0001f,1f)]
		public float Density = 0.001f;
//		[Tooltip("Shifting the scattering color between horizon and zenith.")]
		[Range(0.06f,0.4f)]
		public float ColorDecay = 0.2f;
		[Range(0.0f,1f)]
		public float Scattering = 1f;
		[Range(0.0f,0.1f)]
		public float HorizonOffset = 0f;

//		[Tooltip("Push fog away from the camera by this amount")]
		public float StartDistance = 0.0f;
		public float EndDistance = 300.0f;

		public Material FogMaterial;

		uSkyManager _uSM;
		private uSkyManager uSM {
			get{
				if (_uSM == null) {
					_uSM = this.gameObject.GetComponent<uSkyManager>();
					#if UNITY_EDITOR
					if (_uSM == null)
						Debug.Log("Can't not find uSkyManager, please apply uSkyFog to uSkyManager gameobject");
					#endif
				}
				return _uSM;
			}
		}

		Material _skybox = null;
		private Material skybox{
			get{
				if (_skybox == null && uSM != null) {
					_skybox = this.gameObject.GetComponent<uSkyManager> ().SkyboxMaterial;
				}
				return _skybox;
			}
		}
		void Start () {
			updateFog (FogMaterial);
			skybox.SetFloat ("_HorizonOffset", HorizonOffset);
		}
		
		// Update is called once per frame
		void Update () {
		#if UNITY_EDITOR
			Density = Mathf.Max(0.0f, Density);
		#endif
			var sceneMode= fogMode;
			var sceneDensity= Density;
			var sceneStart= StartDistance;
			var sceneEnd= EndDistance;
			Vector4 sceneParams;
			bool  linear = (sceneMode == FogModes.Linear);
			float diff = linear ? sceneEnd - sceneStart : 0.0f;
			float invDiff = Mathf.Abs(diff) > 0.0001f ? 1.0f / diff : 0.0f;
			sceneParams.x = sceneDensity * 1.2011224087f; // density / sqrt(ln(2)), used by Exp2 fog mode
			sceneParams.y = sceneDensity * 1.4426950408f; // density / ln(2), used by Exp fog mode
			sceneParams.z = linear ? -invDiff : 0.0f;
			sceneParams.w = linear ? sceneEnd * invDiff : 0.0f;

			FogMaterial.SetVector ("_SceneFogParams", sceneParams);
			FogMaterial.SetVector ("_SceneFogMode", new Vector4((int)sceneMode, useRadialDistance ? 1 : 0, 0, 0));
			FogMaterial.SetVector ("_fParams", new Vector4 (fogMode == FogModes.Linear ? -Mathf.Max(StartDistance,0.0f): 0.0f, ColorDecay, Scattering,0f)); 

			updateFog (FogMaterial);
		}

		void updateFog (Material mat){
			if (uSM != null && mat != null) {
				if (uSM.SkyUpdate){ 
					uSM.InitMaterial (mat);
					skybox.SetFloat ("_HorizonOffset", HorizonOffset);
				}
			}
		}

		// for GUI function
		public void SetFogDensity(float value){
			Density = value;
		}
		public void SetFogColorDecay(float value){
			ColorDecay = value;
		}
	}
}