using UnityEngine;
using System.Collections;
using System.Collections.Generic;


[System.Serializable]
public class AxleInfo
{
    public WheelCollider leftWheel;
    public WheelCollider rightWheel;
    public bool motor;
    public bool steering;
}

public class SimpleCarController : MonoBehaviour
{
    public Transform driver;
    public Transform driverExit;

    public List<AxleInfo> axleInfos;
    public float maxMotorTorque;
    public float maxSteeringAngle;
    public float anitRoll = 1000;

    public Light[] brakeLights;
    public Material brakeMaterial;
    public Color brakeOn, brakeOff;

    // finds the corresponding visual wheel
    // correctly applies the transform
    public void ApplyLocalPositionToVisuals(WheelCollider collider)
    {
        if (collider.transform.childCount == 0)
        {
            return;
        }

        Transform visualWheel = collider.transform.GetChild(0);

        Vector3 position;
        Quaternion rotation;
        collider.GetWorldPose(out position, out rotation);

        visualWheel.transform.position = position;
        visualWheel.transform.rotation = rotation;
    }
    public void ApplyAntiRoll(WheelCollider wheelL, WheelCollider wheelR)
    {
        WheelHit hit;
        float travelL = 0.0f, travelR = 0.0f, antiRollForce = 0.0f;
        bool groundedL = wheelL.GetGroundHit(out hit);
        bool groundedR = wheelR.GetGroundHit(out hit);

        if (groundedL)
            travelL = (-wheelL.transform.InverseTransformPoint(hit.point).y - wheelL.radius) / wheelL.suspensionDistance;
        if (groundedR)
            travelR = (-wheelR.transform.InverseTransformPoint(hit.point).y - wheelR.radius) / wheelR.suspensionDistance;

        antiRollForce = (travelL - travelR) * anitRoll;

        if (groundedL)
            GetComponent<Rigidbody>().AddForceAtPosition(wheelL.transform.up * -antiRollForce, wheelL.transform.position);

        if (groundedR)
            GetComponent<Rigidbody>().AddForceAtPosition(wheelR.transform.up * antiRollForce, wheelR.transform.position);
    }

    public void Update()
    {
        if (CharacterInputController.inputType == ControlType.CAR)
        {
            if (CharacterInputController.Acceleration < 0 || CharacterInputController.Brake)
            {
                foreach (Light l in brakeLights)
                    l.enabled = true;
                brakeMaterial.SetColor("_EmissionColor", brakeOn * 10f);
            }
            else
            {
                foreach (Light l in brakeLights)
                    l.enabled = false;
                brakeMaterial.SetColor("_EmissionColor", brakeOff);

            }
            if (CharacterInputController.ExitCar)
            {
                driver.SetParent(null);
                CharacterInputController.animatorController.SetBool("InCar", false);
                driver.position = driverExit.position;
                driver.rotation = Quaternion.identity;
                driver.GetComponent<Rigidbody>().isKinematic = false;
                driver.GetComponent<Rigidbody>().constraints = RigidbodyConstraints.FreezeRotation;
                driver.GetComponent<RootMotion.FinalIK.FullBodyBipedIK>().enabled = true;
                driver.GetComponent<RootMotion.FinalIK.GrounderFBBIK>().enabled = true;
                driver.GetComponent<CapsuleCollider>().enabled = true;
                CharacterInputController.SwitchInputType(ControlType.HUMAN);
                driver = null;
            }
        }

    }
    public void FixedUpdate()
    {

        float motor = maxMotorTorque * CharacterInputController.Acceleration;
        float steering = maxSteeringAngle * CharacterInputController.Turn;
        float braking = maxMotorTorque;

        foreach (AxleInfo axleInfo in axleInfos)
        {
            if (axleInfo.steering)
            {
                axleInfo.leftWheel.steerAngle = steering;
                axleInfo.rightWheel.steerAngle = steering;
            }
            if (axleInfo.motor)
            {
                axleInfo.leftWheel.motorTorque = motor;
                axleInfo.rightWheel.motorTorque = motor;

                axleInfo.leftWheel.brakeTorque = CharacterInputController.Brake ? braking : 0;
                axleInfo.rightWheel.brakeTorque = CharacterInputController.Brake ? braking : 0;

            }

            ApplyLocalPositionToVisuals(axleInfo.leftWheel);
            ApplyLocalPositionToVisuals(axleInfo.rightWheel);
            ApplyAntiRoll(axleInfo.leftWheel, axleInfo.rightWheel);
        }
    }

}
