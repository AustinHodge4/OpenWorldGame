using UnityEngine;
using System.Collections;

public class Seat : MonoBehaviour {

    public Transform seat;
    public SimpleCarController car;

    public void Update()
    {
        if (car.driver)
        {
            car.driver.localPosition = Vector3.zero;
            car.driver.localRotation = Quaternion.identity;
        }
    }
}
