using UnityEngine;
using System.Collections;
using UnityEngine.InputNew;

public enum ControlType
{
    CAR, HUMAN, MENU
}
public static class CharacterInputController  {
    public static Animator animatorController;
    public static RootMotion.FinalIK.InteractionSystem interactionSystem;
    private static PlayerInput playerInput;
    public static ControlType inputType;
    
    private static CarControl carControls;
    private static CharacterControl characterControls;

    // Use this for initialization
    static CharacterInputController() {
        animatorController = GameObject.FindGameObjectWithTag("Character").GetComponent<Animator>();
        interactionSystem = GameObject.FindGameObjectWithTag("Character").GetComponent<RootMotion.FinalIK.InteractionSystem>();
        playerInput = GameObject.Find("Input").GetComponent<PlayerInput>();
        carControls = playerInput.GetActions<CarControl>();
        characterControls = playerInput.GetActions<CharacterControl>();
        inputType = ControlType.HUMAN;
        ApplyControlType();
    }
    public static void SwitchInputType(ControlType type) { inputType = type; ApplyControlType(); }
    private static void ApplyControlType()
    {
        switch (inputType)
        {
            case ControlType.CAR:
                characterControls.active = false;
                carControls.active = true;
                break;
            case ControlType.HUMAN:
                carControls.active = false;
                characterControls.active = true;
                break;
            case ControlType.MENU:
                characterControls.active = false;
                carControls.active = false;
                break;
        }
    }
    public static float Acceleration { get { return carControls.drive.vector2.y; } }
    public static bool Brake { get { return carControls.brake.isHeld; } }
    public static float Turn { get { return carControls.drive.vector2.x; } }
    public static float CarLookX { get{ return carControls.look.vector2.x; } }
    public static float CarLookY { get { return carControls.look.vector2.y; } }
    public static bool CarUsePhone { get { return carControls.phone.wasJustPressed; } }
    public static bool ExitCar { get { return carControls.exitCar.wasJustPressed; } }

    public static float CharacterMoveX { get { return characterControls.move.vector2.x; } }
    public static float CharacterMoveZ { get { return characterControls.move.vector2.y; } }
    public static float CharacterLookX { get { return characterControls.look.vector2.x; } }
    public static float CharacterLookY { get { return characterControls.look.vector2.y; } }
    public static bool CharacterRun { get { return characterControls.run.isHeld; } }
    public static bool CharacterJump { get { return characterControls.jump.wasJustPressed; } }
    public static bool CharacterUsePhone { get { return characterControls.phone.wasJustPressed; } }
    public static bool EnterCar { get { return characterControls.enterCar.wasJustPressed; } }




}
