using UnityEngine;
using UnityEngine.InputNew;

// GENERATED FILE - DO NOT EDIT MANUALLY
public class CarControl : ActionMapInput {
	public CarControl (ActionMap actionMap) : base (actionMap) { }
	
	public AxisInputControl @turn { get { return (AxisInputControl)this[0]; } }
	public AxisInputControl @accelerateReverse { get { return (AxisInputControl)this[1]; } }
	public ButtonInputControl @brake { get { return (ButtonInputControl)this[2]; } }
	public AxisInputControl @lookX { get { return (AxisInputControl)this[3]; } }
	public AxisInputControl @lookY { get { return (AxisInputControl)this[4]; } }
	public Vector2InputControl @drive { get { return (Vector2InputControl)this[5]; } }
	public Vector2InputControl @look { get { return (Vector2InputControl)this[6]; } }
	public ButtonInputControl @exitCar { get { return (ButtonInputControl)this[7]; } }
	public ButtonInputControl @phone { get { return (ButtonInputControl)this[8]; } }
}
