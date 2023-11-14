extends CharacterBody3D
class_name Player
# EXPORTED VARIABLES
@export var walk_speed = 5.0
@export var sprint_speed = 8.0
@export var crouch_speed = 3.0
@export var JUMP_VELOCITY = 4.5
# NODES
@onready var neck = $Neck
@onready var head = $Neck/Head
@onready var eyes = $Neck/Head/Eyes
@onready var camera_3d = $Neck/Head/Eyes/Camera3D
@onready var crouch_collider = $crouch_collider
@onready var stand_collider = $stand_collider
@onready var ray_cast_3d = $RayCastUncrouch
@onready var animation_player = $Neck/Head/Eyes/AnimationPlayer
@onready var ray_cast_look_at = $Neck/Head/Eyes/RayCastLookAt

# STATES
var walking = false
var sprinting = false
var crouching = false
var freelooking = false
var sliding = false
var aiming = false
var climbing = false
var zooming = false

# VARIABLES
const mouse_sens = 0.4

var freelook_tilt = 0.1

var curr_speed = 5.0

var crouching_depth = -0.5

var lerp_speed = 8.0

var direction = Vector3.ZERO

# SLIDE
var slide_timer = 0.0
var slide_vector = Vector2.ZERO
@export var slide_speed = 10.0
@export var slide_timer_max = 1.0

# HEADBOBBING
## SPEED
const bob_sprint_speed = 22.0
const bob_walk_speed = 14.0
const bob_crouch_speed = 10.0
## INTENSITY
const bob_sprint_intensity = 0.5
const bob_walk_intensity = 0.2
const bob_crouch_intensity = 0.1
## VARIABLES
var bobbing_vector = Vector2.ZERO
var bobbing_index = 0.0
var bobbing_intensity = 0.0
var bobbing_speed = 0.0


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		if freelooking:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-70), deg_to_rad(70))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

		
func _physics_process(delta):
	# Get movement input
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	# STATE CHECKING
	if Input.is_action_just_pressed("zoom"):
		zooming = true
	elif Input.is_action_just_released("zoom"):
		zooming = false
	
	if Input.is_action_just_pressed("aim"):
		aiming = true
	elif Input.is_action_just_released("aim"):
		aiming = false
	
	if Input.is_action_just_pressed("crouch"):
		crouching = true
	elif Input.is_action_just_released("crouch") && not ray_cast_3d.is_colliding():
		crouching = false
	
	if Input.is_action_just_pressed("sprint"):
		walking = false
		sprinting = true
		crouching = false
	elif Input.is_action_just_released("sprint"):
		walking = true
		sprinting = false
	
	if Input.is_action_just_pressed("freelook"):
		freelooking = true
	elif Input.is_action_just_released("freelook"):
		freelooking = false
			
	if climbing:
		#input_dir.y
		## up = -1
		## down = 1
		## none = 0
		velocity.z = 0
		velocity.x = 0
		if sprinting:
			velocity.y = -input_dir.y*2
		else:
			velocity.y = -input_dir.y
		
		if Input.is_action_just_pressed("jump") || Input.is_action_just_pressed("interact"):
			climbing = false
	else:
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= gravity * delta
			# Reset position if falling below stage
			if position.y < -5.0:
				position.x = 0.0
				position.y = 0.0
				position.z = 0.0
		
		# Handle interact
		if Input.is_action_pressed("interact"):
			if ray_cast_look_at.is_colliding():
				var object = ray_cast_look_at.get_collider()
				playerInteract(object)
				
		# Handle Jump.
		if Input.is_action_pressed("jump"):
			playerJump()
				
		# Handle Crouch
		if crouching:
			playerCrouch(delta, input_dir)
			
		elif not ray_cast_3d.is_colliding():
			if sliding:
				# end slide
				slide_timer = 0.0
			if crouching:
				#change back to stand collider
				stand_collider.disabled = false
				crouch_collider.disabled = true
				# reset head position
				head.position.y = lerp(head.position.y, 0.0, delta*lerp_speed)
			
			# Handle Sprint/Walk.
			if sprinting:
				#Sprint
				curr_speed = lerp(curr_speed, sprint_speed, delta*lerp_speed)

			else:
				#Walk
				curr_speed = lerp(curr_speed, walk_speed, delta*lerp_speed)
				
		# Handle Freelook
		if Input.is_action_pressed("freelook"):
			freelooking = true
			
			if sliding:
				eyes.rotation.z = lerp(eyes.rotation.z, -deg_to_rad(7.0), delta*lerp_speed)
			
			if rad_to_deg(neck.rotation.y) > 45 or rad_to_deg(neck.rotation.y) < -45:
				eyes.rotation.z = lerp(eyes.rotation.z, -neck.rotation.y*freelook_tilt, delta*lerp_speed)
			else:
				eyes.rotation.z = lerp(eyes.rotation.z, 0.0, delta*(lerp_speed/2))
		else:
			freelooking = false
			neck.rotation.y = lerp(neck.rotation.y, 0.0, delta*lerp_speed)
			eyes.rotation.z = lerp(eyes.rotation.z, 0.0, delta*(lerp_speed/2))
		
		# Handle sliding
		if sliding:
			slide_timer -= delta
			if slide_timer <= 0:
				sliding = false
				freelooking = false
		
		# Handle bobbing
		if sprinting:
			bobbing_intensity = bob_sprint_intensity
			bobbing_index += bob_sprint_speed*delta
		elif crouching:
			bobbing_intensity = bob_crouch_intensity
			bobbing_index += bob_crouch_speed*delta
		else:
			bobbing_intensity = bob_walk_intensity
			bobbing_index += bob_walk_speed*delta
			
		if is_on_floor() && not sliding && input_dir != Vector2.ZERO:
			bobbing_vector.y = sin(bobbing_index)
			bobbing_vector.x = sin((bobbing_index/2)+0.5)
			
			eyes.position.y = lerp(eyes.position.y, bobbing_vector.y*(bobbing_intensity/2.0), delta*lerp_speed)
			eyes.position.x = lerp(eyes.position.x, bobbing_vector.x*bobbing_intensity, delta*lerp_speed)
		else:
			eyes.position.y = lerp(eyes.position.y, 0.0, delta*lerp_speed)
			eyes.position.x = lerp(eyes.position.x, 0.0, delta*lerp_speed)
			

		if is_on_floor():
			direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*lerp_speed)
			
		if sliding:
			direction = transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)
			curr_speed = (slide_timer+0.3) * slide_speed
			
		if direction:
			velocity.x = direction.x * curr_speed
			velocity.z = direction.z * curr_speed
			
		else:
			velocity.x = move_toward(velocity.x, 0, curr_speed)
			velocity.z = move_toward(velocity.z, 0, curr_speed)
	
	# Handle Zoom
	if aiming:
		print(zooming)
		if zooming:
			camera_3d.fov = lerp(camera_3d.fov, 20.0, delta*lerp_speed)			
		else:
			camera_3d.fov = lerp(camera_3d.fov, 50.0, delta*lerp_speed)
	else:
		zooming = false
		camera_3d.fov = lerp(camera_3d.fov, 75.0, delta*lerp_speed)

	move_and_slide()

func playerInteract(object):
	print(object.get_class())
	if object is ClimbingWall:
		climbing = true
	else:
		pass
	
func playerJump():
	if is_on_floor():
		if sliding:
			sliding = false
		animation_player.play("jump")
		velocity.y += JUMP_VELOCITY
	else:
		# double jump with lower strength
		velocity.y = JUMP_VELOCITY/2

func playerCrouch(delta, input_dir):
	curr_speed = lerp(curr_speed, crouch_speed, delta*lerp_speed)
	head.position.y = lerp(head.position.y, crouching_depth, delta*lerp_speed)

	stand_collider.disabled = true
	crouch_collider.disabled = false

	if sprinting: #&& input_dir != Vector2.ZERO:
		playerSlide(input_dir)
	else:
		crouching = true
	
	walking = false
	sprinting = false
	# crouching = true

func playerSlide(input_dir):
	sliding = true
	slide_timer = slide_timer_max
	slide_vector = input_dir
	freelooking = true
