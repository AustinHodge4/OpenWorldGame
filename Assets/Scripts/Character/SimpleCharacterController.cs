using UnityEngine;
using System.Collections;
using RootMotion.FinalIK;

public class SimpleCharacterController : MonoBehaviour
{

    public float walkSpeed = 2f;
    public float runSpeed = 6f;

    public bool grounded = true;
    public bool disableControl = false;
    private CapsuleCollider characterCollider;


    private float speed = 1;
    private float direction = 0;

    private int m_SpeedId = 0;
    private int m_AgularSpeedId = 0;
    private int m_DirectionId = 0;

    public float m_SpeedDampTime = 0.1f;
    public float m_AnguarSpeedDampTime = 0.25f;
    public float m_DirectionResponseTime = 0.2f;


    public bool usingPhone = false;
    private FullBodyBipedIK fullBodyIK;
    public Transform rightHand, leftHand;
    public RagdollUtility ragdollUtility;
    public Transform root;
    public Rigidbody pelvis;


    public void Start()
    {
        m_SpeedId = Animator.StringToHash("Speed");
        m_AgularSpeedId = Animator.StringToHash("AngularSpeed");
        m_DirectionId = Animator.StringToHash("Direction");

        characterCollider = GetComponent<CapsuleCollider>();

        fullBodyIK = GetComponent<FullBodyBipedIK>();

    }
    public void Update()
    {
        if (CharacterInputController.CharacterUsePhone || CharacterInputController.CarUsePhone)
        {
            AnimatorStateInfo state = CharacterInputController.animatorController.GetCurrentAnimatorStateInfo(1);
            bool inTransition = CharacterInputController.animatorController.IsInTransition(1);

            usingPhone = !usingPhone;
            CharacterInputController.animatorController.SetBool("UsePhone", usingPhone);

            if (usingPhone)
            {
                fullBodyIK.enabled = false;
                CharacterInputController.animatorController.SetLayerWeight(1, 1.0f);
                rightHand.FindChild("Phone").gameObject.SetActive(true);

            }
            else
            {
                fullBodyIK.enabled = true;
                CharacterInputController.animatorController.SetLayerWeight(1, 0.0f);
                rightHand.FindChild("Phone").gameObject.SetActive(false);
            }
        }

        if (CharacterInputController.inputType == ControlType.HUMAN && !disableControl)
        {
            if (CharacterInputController.CharacterJump && grounded)
            {
                CharacterInputController.animatorController.SetTrigger("Jump");
            }

            if (Input.GetKeyDown(KeyCode.R))
            {
                ragdollUtility.EnableRagdoll();
            }

            if (Input.GetKeyDown(KeyCode.P))
            {
                // Move the root of the character to where the pelvis is without moving the ragdoll
                CharacterInputController.animatorController.SetTrigger("ResetBody");
                Vector3 toPelvis = pelvis.position - root.position;
                root.position += toPelvis;
                pelvis.transform.position -= toPelvis;

                ragdollUtility.DisableRagdoll();
            }
            CalculateMovement();
            AnimatorMove();
        }
        if (disableControl)
        {
            CharacterInputController.animatorController.SetFloat(m_SpeedId, 0);
            CharacterInputController.animatorController.SetFloat(m_AgularSpeedId, 0);
        }
    }
    void CalculateStep()
    {
        float angle = -180f;
        Vector3 vector = Vector3.forward;

        for (float i = angle; i < 45; i++)
        {
            float refMag = Vector3.forward.sqrMagnitude;
            float z = Mathf.Rad2Deg * Mathf.Cos(i) * Mathf.Cos(i);
            float x = Mathf.Rad2Deg * Mathf.Sin(i);

            Vector3 point = new Vector3(x, 0, z);
            point.Normalize();
            Ray ray = new Ray(transform.position + Vector3.up, point);
            Debug.DrawRay(ray.origin, ray.direction, Color.red);
        }
    }
    void CalculateMovement()
    {
        Vector3 rootDirection = transform.forward;
        float horizontal = CharacterInputController.CharacterMoveX;
        float vertical = CharacterInputController.CharacterMoveZ;

        Vector3 stickDirection = new Vector3(horizontal, 0, vertical);

        // Get camera rotation.    

        Vector3 CameraDirection = Camera.main.transform.forward;
        CameraDirection.y = 0.0f; // kill Y
        Quaternion referentialShift = Quaternion.FromToRotation(Vector3.forward, CameraDirection);

        // Convert joystick input in Worldspace coordinates
        Vector3 moveDirection = referentialShift * stickDirection;

        Vector2 speedVec = new Vector2(horizontal, vertical);
        speed = Mathf.Clamp(speedVec.magnitude, 0, 1);

        if (speed > 0.01f) // dead zone
        {
            Vector3 axis = Vector3.Cross(rootDirection, moveDirection);
            direction = Vector3.Angle(rootDirection, moveDirection) / 180.0f * (axis.y < 0 ? -1 : 1);
        }
        else
        {
            direction = 0.0f;
        }

    }

    void AnimatorMove()
    {
        if (CharacterInputController.CharacterRun)
        {
            speed *= runSpeed;
        }
        else
            speed *= walkSpeed;

        direction *= 180;
        AnimatorStateInfo state = CharacterInputController.animatorController.GetCurrentAnimatorStateInfo(0);

        bool inTransition = CharacterInputController.animatorController.IsInTransition(0);
        bool inIdle = state.IsName("Locomotion.Idle");
        bool inTurn = state.IsName("Locomotion.TurnOnSpot") || state.IsName("Locomotion.PlantNTurnLeft") || state.IsName("Locomotion.PlantNTurnRight");
        bool inWalkRun = state.IsName("Locomotion.WalkRun");
        bool inJump = state.IsName("Jump");

        if (inJump)
        {
            if (!inTransition)
            {
                characterCollider.height = CharacterInputController.animatorController.GetFloat("ColliderHeight");

                Ray ray = new Ray(transform.position + Vector3.up, -Vector3.up);
                RaycastHit hitInfo = new RaycastHit();
                if (Physics.Raycast(ray, out hitInfo))
                {
                    if (hitInfo.distance > 1.5f)
                    {
                        CharacterInputController.animatorController.MatchTarget(hitInfo.point, Quaternion.identity, AvatarTarget.Root, new MatchTargetWeightMask(new Vector3(0, 1, 0), 0), 0.5f, 0.68f);
                    }
                }
            }
        }

        float speedDampTime = inIdle ? 0 : m_SpeedDampTime;
        float angularSpeedDampTime = inWalkRun || inTransition ? m_AnguarSpeedDampTime : 0;
        float directionDampTime = inTurn || inTransition ? 1000000 : 0;

        float angularSpeed = direction / m_DirectionResponseTime;

        CharacterInputController.animatorController.SetFloat(m_SpeedId, speed, speedDampTime, Time.deltaTime);
        CharacterInputController.animatorController.SetFloat(m_AgularSpeedId, angularSpeed, angularSpeedDampTime, Time.deltaTime);
        CharacterInputController.animatorController.SetFloat(m_DirectionId, direction, directionDampTime, Time.deltaTime);
    }

    void OnCollisionEnter(Collision collision)
    {
        if (!grounded)
            TrackGrounded(collision);
    }
    void OnCollisionStay(Collision collision)
    {
        TrackGrounded(collision);
    }
    void OnCollisionExit(Collision collision)
    {
        if (CharacterInputController.inputType == ControlType.HUMAN)
            grounded = false;
    }
    private void TrackGrounded(Collision collision)
    {
        if (CharacterInputController.inputType == ControlType.HUMAN)
        {
            float maxHeight = GetComponent<CapsuleCollider>().bounds.min.y + GetComponent<CapsuleCollider>().radius * .9f;
            foreach (ContactPoint contact in collision.contacts)
            {
                if (contact.point.y < maxHeight && Vector3.Angle(contact.normal, Vector3.up) < 80)
                {
                    grounded = true;
                    break;
                }
            }
        }
    }
    void OnTriggerStay(Collider col)
    {
        if (col.gameObject.tag == "CarDoor")
        {
            if (CharacterInputController.inputType == ControlType.HUMAN)
            {
                if (CharacterInputController.EnterCar)
                {
                    GetComponent<CapsuleCollider>().enabled = false;
                    transform.SetParent(col.gameObject.GetComponent<Seat>().seat);
                    CharacterInputController.animatorController.SetBool("InCar", true);
                    GetComponent<Rigidbody>().isKinematic = true;
                    fullBodyIK.enabled = false;
                    GetComponent<GrounderFBBIK>().enabled = false;
                    GetComponent<Rigidbody>().constraints = RigidbodyConstraints.FreezeAll;


                    col.gameObject.GetComponent<Seat>().car.driver = transform;
                    CharacterInputController.SwitchInputType(ControlType.CAR);
                }
            }
        }
    }
    IEnumerator Wait(float seconds)
    {
        yield return new WaitForSeconds(seconds);

    }
}
