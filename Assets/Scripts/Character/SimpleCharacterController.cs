using UnityEngine;
using System.Collections;

public class SimpleCharacterController : MonoBehaviour {

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

    public bool ikActive = false;
    public Transform rightHand;
    public Transform rightHandObj = null;
    public Transform lookObj = null;

    public bool usingPhone = false;

    public void Start()
    {
        m_SpeedId = Animator.StringToHash("Speed");
        m_AgularSpeedId = Animator.StringToHash("AngularSpeed");
        m_DirectionId = Animator.StringToHash("Direction");

        characterCollider = GetComponent<CapsuleCollider>();
        
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
                CharacterInputController.animatorController.SetLayerWeight(1, 1.0f);
            else
                CharacterInputController.animatorController.SetLayerWeight(1, 0.0f);
        }
       
        if (CharacterInputController.inputType == ControlType.HUMAN && !disableControl)
        {
            if (CharacterInputController.CharacterJump)
            {
                CharacterInputController.animatorController.SetTrigger("Jump");
            }
            
            CalculateMovement();
            AnimatorMove();
        }
    }
    void CalculateStep()
    {
        float angle = -180f;
        Vector3 vector = Vector3.forward;

        for(float i = angle; i < 45; i++)
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
            }
            Ray ray = new Ray(transform.position + Vector3.up, -Vector3.up);
            RaycastHit hitInfo = new RaycastHit();
            if(Physics.Raycast(ray, out hitInfo))
            {
                if(hitInfo.distance > 1.75f)
                {
                    CharacterInputController.animatorController.MatchTarget(hitInfo.point, Quaternion.identity, AvatarTarget.Root, new MatchTargetWeightMask(new Vector3(0, 1, 0), 0), 0.5f, 0.68f);
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
    void OnAnimatorIK()
    {
        if (CharacterInputController.animatorController)
        {

            //if the IK is active, set the position and rotation directly to the goal. 
            if (ikActive)
            {

                // Set the look target position, if one has been assigned
                if (lookObj != null)
                {
                    CharacterInputController.animatorController.SetLookAtWeight(1);
                    CharacterInputController.animatorController.SetLookAtPosition(lookObj.position);
                }

                // Set the right hand target position and rotation, if one has been assigned
                if (rightHandObj != null)
                {
                    rightHandObj.SetParent(rightHand);
                    rightHandObj.localPosition = Vector3.zero;
                    //CharacterInputController.animatorController.SetIKPositionWeight(AvatarIKGoal.RightHand, 1);
                    //CharacterInputController.animatorController.SetIKRotationWeight(AvatarIKGoal.RightHand, 1);
                    //CharacterInputController.animatorController.SetIKPosition(AvatarIKGoal.RightHand, rightHandObj.position);
                    //CharacterInputController.animatorController.SetIKRotation(AvatarIKGoal.RightHand, rightHandObj.rotation);
                }

            }

            //if the IK is not active, set the position and rotation of the hand and head back to the original position
            else
            {
                rightHandObj.SetParent(null);
                CharacterInputController.animatorController.SetIKPositionWeight(AvatarIKGoal.RightHand, 0);
                CharacterInputController.animatorController.SetIKRotationWeight(AvatarIKGoal.RightHand, 0);
                CharacterInputController.animatorController.SetLookAtWeight(0);
            }
        }
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
