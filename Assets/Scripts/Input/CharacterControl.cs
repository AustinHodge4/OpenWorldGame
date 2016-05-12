using UnityEngine;
using UnityEngine.InputNew;

// GENERATED FILE - DO NOT EDIT MANUALLY
public class CharacterControl : ActionMapInput {
	public CharacterControl (ActionMap actionMap) : base (actionMap) { }
	
	public AxisInputControl @moveX { get { return (AxisInputControl)this[0]; } }
	public AxisInputControl @moveZ { get { return (AxisInputControl)this[1]; } }
	public Vector2InputControl @move { get { return (Vector2InputControl)this[2]; } }
	public ButtonInputControl @enterCar { get { return (ButtonInputControl)this[3]; } }
	public AxisInputControl @lookX { get { return (AxisInputControl)this[4]; } }
	public AxisInputControl @lookY { get { return (AxisInputControl)this[5]; } }
	public Vector2InputControl @look { get { return (Vector2InputControl)this[6]; } }
	public ButtonInputControl @run { get { return (ButtonInputControl)this[7]; } }
	public ButtonInputControl @jump { get { return (ButtonInputControl)this[8]; } }
	public ButtonInputControl @phone { get { return (ButtonInputControl)this[9]; } }
}
