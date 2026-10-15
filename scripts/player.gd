class_name EscapePlayer
extends CharacterBody3D

const WALK_SPEED := 3.6
const RUN_SPEED := 5.1
const EYE_HEIGHT := 1.62

var active := false
var mouse_sensitivity := 0.0022
var camera: Camera3D
var flashlight: SpotLight3D
var footstep: AudioStreamPlayer
var pitch := 0.0
var bob_time := 0.0
var step_distance := 0.0
var movement_override := Vector2.ZERO
var use_movement_override := false
var handgun: Node3D
var muzzle: MeshInstance3D
var muzzle_light: OmniLight3D
var kick := 0.0
var flash_remaining := 0.0
var reload_progress := -1.0
const GUN_POSITION := Vector3(0.22, -0.20, -0.65)


func _ready() -> void:
	name = "Player"
	collision_layer = 2
	collision_mask = 1 | 4
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.27
	capsule.height = 1.75
	var body := CollisionShape3D.new()
	body.shape = capsule
	body.position.y = 0.88
	add_child(body)
	camera = Camera3D.new()
	camera.name = "Eyes"
	camera.position.y = EYE_HEIGHT
	camera.fov = 76.0
	camera.near = 0.05
	camera.far = 65.0
	camera.current = true
	add_child(camera)
	flashlight = SpotLight3D.new()
	flashlight.position = Vector3(0.12, -0.12, 0.03)
	flashlight.light_color = Color("b3c6ac")
	flashlight.light_energy = 1.35
	flashlight.spot_range = 15.0
	flashlight.spot_angle = 42.0
	flashlight.spot_angle_attenuation = 0.75
	flashlight.spot_attenuation = 1.3
	flashlight.shadow_enabled = true
	camera.add_child(flashlight)
	footstep = AudioStreamPlayer.new()
	footstep.stream = load("res://assets/audio/step.wav")
	footstep.volume_db = -14.0
	add_child(footstep)
	_build_handgun()


func _gun_part(size_value: Vector3, location: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	instance.material_override = material
	instance.position = location
	handgun.add_child(instance)
	return instance


func _build_handgun() -> void:
	handgun = Node3D.new()
	handgun.position = GUN_POSITION
	camera.add_child(handgun)
	_gun_part(Vector3(0.105, 0.09, 0.32), Vector3(0, 0, -0.03), Color("626861"))
	_gun_part(Vector3(0.09, 0.15, 0.11), Vector3(0, -0.1, 0.065), Color("292d2b"))
	_gun_part(Vector3(0.065, 0.07, 0.015), Vector3(0, 0, -0.197), Color("0b100f"))
	_gun_part(Vector3(0.024, 0.033, 0.025), Vector3(0, 0.056, -0.16), Color("919a85"))
	_gun_part(Vector3(0.12, 0.095, 0.15), Vector3(0.025, -0.14, 0.09), Color("8a8771"))
	muzzle = _gun_part(Vector3(0.14, 0.12, 0.13), Vector3(0, 0, -0.27), Color("ffd28c"))
	var flash_material := muzzle.material_override as StandardMaterial3D
	flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	muzzle.hide()
	muzzle_light = OmniLight3D.new()
	muzzle_light.position = Vector3(0, 0, -0.3)
	muzzle_light.light_color = Color("ffd69a")
	muzzle_light.light_energy = 2.0
	muzzle_light.omni_range = 4.0
	muzzle_light.hide()
	handgun.add_child(muzzle_light)


func shot_feedback() -> void:
	kick = 1.0
	flash_remaining = 0.065
	muzzle.show()
	muzzle_light.show()


func _process(delta: float) -> void:
	kick = move_toward(kick, 0.0, delta * 7.0)
	flash_remaining = maxf(0.0, flash_remaining - delta)
	muzzle.visible = flash_remaining > 0.0
	muzzle_light.visible = muzzle.visible
	var reload_dip := sin(reload_progress * PI) if reload_progress >= 0.0 else 0.0
	handgun.position = GUN_POSITION + Vector3(0.0, -0.23 * reload_dip, kick * 0.075)
	handgun.rotation = Vector3(kick * 0.13, 0.0, -0.75 * reload_dip)


func look(event: InputEventMouseMotion) -> void:
	if not active:
		return
	# Unscaled motion keeps sensitivity stable across window sizes and stretch modes.
	rotation.y -= event.screen_relative.x * mouse_sensitivity
	pitch = clampf(pitch - event.screen_relative.y * mouse_sensitivity, -1.25, 1.25)
	camera.rotation.x = pitch


func _physics_process(delta: float) -> void:
	if not active:
		velocity = Vector3.ZERO
		return
	var movement := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if use_movement_override:
		movement = movement_override
	var running := Input.is_action_pressed("sprint")
	var speed := RUN_SPEED if running else WALK_SPEED
	var direction := transform.basis * Vector3(movement.x, 0.0, movement.y)
	velocity.x = move_toward(velocity.x, direction.x * speed, 24.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, 24.0 * delta)
	velocity.y = -0.4 if is_on_floor() else velocity.y - 20.0 * delta
	move_and_slide()
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.1 and is_on_floor():
		bob_time += delta * (11.0 if running else 8.0)
		step_distance += horizontal_speed * delta
		if step_distance > 1.6:
			step_distance = 0.0
			footstep.pitch_scale = randf_range(0.88, 1.12)
			footstep.play()
		camera.position.y = EYE_HEIGHT + sin(bob_time) * 0.025
	else:
		camera.position.y = lerpf(camera.position.y, EYE_HEIGHT, delta * 8.0)
	rotation.y += Input.get_axis("look_right", "look_left") * delta * 1.8
	pitch = clampf(pitch + Input.get_axis("look_down", "look_up") * delta * 1.4, -1.25, 1.25)
	camera.rotation.x = pitch
	camera.fov = lerpf(camera.fov, 81.0 if running and horizontal_speed > 1.0 else 76.0, delta * 4.0)


func reset_at(spawn: Vector3) -> void:
	position = spawn
	rotation = Vector3.ZERO
	pitch = 0.0
	camera.rotation = Vector3.ZERO
	camera.position.y = EYE_HEIGHT
	velocity = Vector3.ZERO
	step_distance = 0.0
	bob_time = 0.0
	kick = 0.0
	flash_remaining = 0.0
	reload_progress = -1.0
