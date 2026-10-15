class_name CorridorZombie
extends CharacterBody3D

signal attacked(amount: int)
signal died

enum Mind { DORMANT, PURSUING, RETURNING, DEAD }
const SPEED := 1.05
const MAX_HEALTH := 100
const DETECTION_RANGE := 6.5
const GIVE_UP_RANGE := 10.0
const LEASH_RANGE := 10.0
const ATTACK_RANGE := 1.25
const ATTACK_DAMAGE := 28

var target: EscapePlayer
var active := false
var health := MAX_HEALTH
var mind := Mind.DORMANT
var home_position := Vector3.ZERO
var home_yaw := 0.0
var last_seen := Vector3.ZERO
var unseen_seconds := 0.0
var attack_remaining := -1.0
var attack_cooldown := 0.0
var stagger := 0.0
var model: ZombieModel
var collider: CollisionShape3D
var death_tween: Tween
var corridor: EscapeCorridor
var gait := 0.0
var groan_timer := 4.0
var voice: AudioStreamPlayer3D


func _ready() -> void:
	name = "TheSubject"
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.29
	capsule.height = 1.75
	collider = CollisionShape3D.new()
	collider.shape = capsule
	collider.position.y = 0.88
	add_child(collider)
	model = ZombieModel.new()
	add_child(model)
	voice = AudioStreamPlayer3D.new()
	voice.stream = load("res://assets/audio/groan.wav")
	voice.volume_db = -4.0
	voice.unit_size = 5.0
	voice.max_distance = 45.0
	voice.position.y = 1.5
	add_child(voice)


func _has_sight() -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.4, target.camera.global_position, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _physics_process(delta: float) -> void:
	if not active or health <= 0 or not is_instance_valid(target):
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	stagger = maxf(0.0, stagger - delta)
	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	var sight := distance < GIVE_UP_RANGE and _has_sight()
	if mind == Mind.DORMANT:
		if distance <= DETECTION_RANGE and sight:
			awaken()
	elif mind == Mind.PURSUING:
		unseen_seconds = 0.0 if sight else unseen_seconds + delta
		if sight:
			last_seen = target.global_position
		if distance > GIVE_UP_RANGE or global_position.distance_to(home_position) > LEASH_RANGE or unseen_seconds > 2.5:
			mind = Mind.RETURNING
			attack_remaining = -1.0
	if attack_remaining >= 0.0:
		attack_remaining -= delta
		if attack_remaining <= 0.0:
			attack_remaining = -1.0
			attack_cooldown = 1.7
			if distance <= ATTACK_RANGE + 0.25 and sight:
				attacked.emit(ATTACK_DAMAGE)
	elif mind == Mind.PURSUING and distance <= ATTACK_RANGE and sight and attack_cooldown <= 0.0 and stagger <= 0.0:
		attack_remaining = 0.6
		voice.pitch_scale = 1.12
		voice.play()
	var destination := global_position
	if mind == Mind.PURSUING:
		destination = last_seen
	elif mind == Mind.RETURNING:
		destination = home_position
		if global_position.distance_to(home_position) < 0.2:
			mind = Mind.DORMANT
			rotation.y = home_yaw
	if corridor:
		destination = corridor.pursuit_waypoint(global_position, destination)
	var direction := destination - global_position
	direction.y = 0.0
	var walking := direction.length() > 0.1 and attack_remaining < 0.0 and stagger <= 0.0
	if mind == Mind.PURSUING and distance < ATTACK_RANGE * 0.8:
		walking = false
	if walking:
		direction = direction.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 3.0)
		gait += delta * 4.3
	velocity.x = direction.x * SPEED if walking else 0.0
	velocity.z = direction.z * SPEED if walking else 0.0
	velocity.y = -0.4 if is_on_floor() else velocity.y - 20.0 * delta
	move_and_slide()
	model.animate(delta, walking, gait, attack_remaining >= 0.0, stagger)
	groan_timer -= delta
	if groan_timer <= 0.0 and mind == Mind.PURSUING:
		voice.pitch_scale = randf_range(0.82, 1.06)
		voice.play()
		groan_timer = randf_range(5.0, 8.0)


func awaken() -> void:
	if health <= 0:
		return
	mind = Mind.PURSUING
	last_seen = target.global_position
	unseen_seconds = 0.0
	voice.play()


func hear_shot(at: Vector3) -> void:
	if active and health > 0 and global_position.distance_to(at) < 9.0:
		awaken()


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(0, health - amount)
	stagger = 0.28
	attack_remaining = -1.0
	if health > 0:
		awaken()
		return
	mind = Mind.DEAD
	velocity = Vector3.ZERO
	voice.stop()
	collider.set_deferred("disabled", true)
	death_tween = create_tween().set_parallel(true)
	death_tween.tween_property(model, "rotation:x", -PI / 2.0, 0.4)
	death_tween.tween_property(model, "position:y", 0.24, 0.4)
	died.emit()


func reset_at(spawn: Vector3, yaw := 0.0) -> void:
	if death_tween and death_tween.is_valid():
		death_tween.kill()
	position = spawn
	home_position = spawn
	home_yaw = yaw
	rotation = Vector3(0, yaw, 0)
	model.position = Vector3.ZERO
	model.rotation = Vector3.ZERO
	model.reset_pose()
	active = false
	health = MAX_HEALTH
	mind = Mind.DORMANT
	attack_remaining = -1.0
	attack_cooldown = 0.0
	unseen_seconds = 0.0
	stagger = 0.0
	velocity = Vector3.ZERO
	groan_timer = 4.0
	collider.set_deferred("disabled", false)
	voice.stop()
