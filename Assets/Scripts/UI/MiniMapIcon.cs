using UnityEngine;
using UnityEngine.UI;
using System.Collections;

public class MiniMapIcon : MonoBehaviour {
    public GameObject obj;
    public Image icon;
	// Use this for initialization
	void Start () {
        
        MiniMapController.RegisterGameIcon(icon, obj);
	}
    void OnDestroy()
    {
        MiniMapController.UnRegisterGameIcon(obj);
    }
	
}
