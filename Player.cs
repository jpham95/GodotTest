using Godot;
using System;
using System.Collections.Generic;

public partial class Player : CharacterBody3D
{
	// PARTS
	public Node3D Head;
	public Node3D Neck;
	public Camera3D Camera;

	// ATTRIBUTES
	public float Speed = 5.0f;
	public float JumpVelocity = 4.5f;
	public float walkSpeed = 5.0f;
	public float sprintSpeed = 8.0f;
	public float crouchSpeed = 3.0f;

	// STATES
	public bool isWalking = false;
	public bool isSprinting = false;
	public bool isCrouching = false;
	public bool freeLook = false;
	public bool isSliding = false;

	// SLIDE VARIABLES
	private float slideSpeed = 10.0f;
	private float slideTime = 0.0f;
	private float slideTimeMax = 1.0f;
	private Vector2 slideDir = Vector2.Zero;

	// HEAD BOB VARIABLES
	private float sprintBobSpeed = 22.0f;
	private float walkBobSpeed = 14.0f;
	private float crouchBobSpeed = 10.0f;
	private float sprintBobIntensity = 0.5f;
	private float walkBobIntensity = 0.25f;
	private float crouchBobIntensity = 0.1f;

	private Vector2 bobbingVector = Vector2.Zero;
	private float bobbingIndex = 0.0f;
	private float bobbingSpeed = 0.0f;
	private float bobbingIntensity = 0.0f;

	// MISC VARIABLES
	[Export]public float mouseSensitivity = 0.003f;
	private float freeLookTilt = 0.1f;
	private float currentSpeed = 0.0f;
	private float lerpSpeed = 8.0f;
	private Vector3 direction = Vector3.Zero;
	private float _rotationX = 0.0f;
	private float _rotationY = 0.0f;
	private float headAngle = 0.0f;

	// Get the gravity from the project settings to be synced with RigidBody nodes.
	public float gravity = ProjectSettings.GetSetting("physics/3d/default_gravity").AsSingle();

	public override void _Ready()
	{
		// Get the parts.
		Head = GetNode<Node3D>("Head");
		Neck = GetNode<Node3D>("Neck");
		Camera = GetNode<Camera3D>("Eyes");
		// Hide the mouse cursor.
		Input.MouseMode = Input.MouseModeEnum.Captured;
	}

    public override void _Input(InputEvent e)
    {
        if (e is InputEventMouseMotion) 
		{
			var mouseMotion = e as InputEventMouseMotion;
			Vector2 motion = -mouseMotion.Relative * mouseSensitivity;
			// _rotationX = mouseMotion.Relative.X * mouseSensitivity;
        	// _rotationY = mouseMotion.Relative.Y * mouseSensitivity;
			if (freeLook)
			{
				Neck.RotateY(motion.X);
				var NeckRotation = Neck.RotationDegrees;
				NeckRotation.X = Mathf.Clamp(NeckRotation.X, -70, 70);
				Neck.RotationDegrees = NeckRotation;
			}
			else
			{
				RotateY(motion.X);
			}
			
			Camera.RotateX(motion.Y);
			var CameraRotation = Camera.RotationDegrees;
			CameraRotation.X = Mathf.Clamp(CameraRotation.X, -89, 89);
			Camera.RotationDegrees = CameraRotation;
		}
    }
    public override void _PhysicsProcess(double delta)
	{
		Vector3 velocity = Velocity;

		// Add the gravity.
		if (!IsOnFloor())
			velocity.Y -= gravity * (float)delta;

		// Handle Jump.
		if (Input.IsActionJustPressed("ui_accept") && IsOnFloor())
			velocity.Y = JumpVelocity;

		// Get the input direction and handle the movement/deceleration.
		// As good practice, you should replace UI actions with custom gameplay actions.
		Vector2 inputDir = Input.GetVector("left", "right", "forward", "backward");
		Vector3 direction = (Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();
		if (direction != Vector3.Zero)
		{
			velocity.X = direction.X * Speed;
			velocity.Z = direction.Z * Speed;
		}
		else
		{
			velocity.X = Mathf.MoveToward(Velocity.X, 0, Speed);
			velocity.Z = Mathf.MoveToward(Velocity.Z, 0, Speed);
		}

		Velocity = velocity;
		MoveAndSlide();
	}
}
