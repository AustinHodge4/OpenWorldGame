using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;

public struct MapIcon
{
    public Image icon;
    public GameObject obj;
}
public class MiniMapController : MonoBehaviour {

    public Camera miniMapCamera;
    public float yPos;
    private Transform targetPosition;
    private Vector3 pos;
    private Quaternion rotation;
    private float x = 0.0f;
    public static List<MapIcon> mapIcons = new List<MapIcon>();
    public void Awake()
    {
        targetPosition = GameObject.FindGameObjectWithTag("Character").transform;
        rotation = miniMapCamera.transform.rotation;
        yPos = miniMapCamera.transform.position.y;

        Vector3 angles = miniMapCamera.transform.eulerAngles;
        x = angles.y;
    }
    public static void RegisterGameIcon(Image i, GameObject o)
    {
        Image ic = Instantiate<Image>(i);
        mapIcons.Add(new MapIcon() { icon = ic, obj = o });
    }

    public static void UnRegisterGameIcon(GameObject o)
    {
        List<MapIcon> newMapIcons = new List<MapIcon>(mapIcons);

        foreach (MapIcon mi in newMapIcons)
        {
            if (mi.obj.Equals(o))
            {
                Destroy(mi.obj);
                mapIcons.Remove(mi);
            }
        }
        mapIcons.RemoveRange(0, mapIcons.Count);
        mapIcons.AddRange(newMapIcons);
    }
    public void Update()
    {
        pos = targetPosition.position;
        pos.y = yPos;

        x += CharacterInputController.CharacterLookX * 8 * 2.5f * 0.02f;
        rotation = Quaternion.Euler(rotation.eulerAngles.x, x, rotation.eulerAngles.z);

        miniMapCamera.transform.rotation = rotation;
        miniMapCamera.transform.position = pos;
        foreach(MapIcon mi in mapIcons)
        {
            Vector3 screenPos = miniMapCamera.WorldToViewportPoint(mi.obj.transform.position);
            mi.icon.transform.SetParent(this.gameObject.transform);
            RectTransform rectTrans = this.GetComponent<RectTransform>();
            Vector3[] corners = new Vector3[4];
            rectTrans.GetWorldCorners(corners);

            screenPos.x = Mathf.Clamp(screenPos.x * rectTrans.rect.width + corners[0].x, corners[0].x, corners[2].x);
            screenPos.y = Mathf.Clamp(screenPos.y * rectTrans.rect.height + corners[0].y, corners[0].y, corners[1].y);

            screenPos.z = 0;

            mi.icon.transform.position = screenPos;
        }
    }
}
