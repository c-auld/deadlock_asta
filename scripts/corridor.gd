class_name EscapeCorridor
extends Node3D

const PLAYER_SPAWN := Vector3(0.0, 0.05, 2.0)
const ZOMBIE_SPAWNS := [Vector3(-5.2, 0.05, -8.0), Vector3(1.0, 0.05, -20.0), Vector3(-0.9, 0.05, -34.5)]
const DOOR_Z := -39.0
const EXIT_Z := -42.0

var door: Node3D
var door_shape: CollisionShape3D
var door_light: OmniLight3D
var door_label: Label3D
var terminal_label: Label3D
var door_unlocked := false
var door_open := false
var door_tween: Tween
var ceiling_lights: Array[OmniLight3D] = []
var clock_time := 0.0
var flicker_enabled := true
var materials: Dictionary = {}
var pickups: Array[SurvivalPickup] = []


func _ready() -> void:
	_build_materials()
	_build_environment()
	_build_corridor()
	_build_terminal()
	_build_door()
	_build_rooms()


func _material(color: String, emission := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color)
	material.roughness = 0.95
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = Color(color)
		material.emission_energy_multiplier = emission
	return material


func _concrete(base: Color, seed_value: int, floor_surface := false) -> StandardMaterial3D:
	var texture_image := Image.create(64, 64, false, Image.FORMAT_RGB8)
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	for y in range(64):
		for x in range(64):
			var variation := random.randf_range(-0.055, 0.055)
			if x % 32 == 0 or y % 32 == 0:
				variation -= 0.055 if floor_surface else 0.025
			if x > 42 and x < 47:
				variation -= float(y) / 64.0 * 0.035
			texture_image.set_pixel(x, y, Color(clampf(base.r + variation, 0.0, 1.0), clampf(base.g + variation, 0.0, 1.0), clampf(base.b + variation, 0.0, 1.0)))
	var material := _material("ffffff")
	material.albedo_texture = ImageTexture.create_from_image(texture_image)
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * (0.9 if floor_surface else 0.6)
	return material


func _build_materials() -> void:
	materials.wall = _concrete(Color("666b61"), 7)
	materials.floor = _concrete(Color("414b49"), 31, true)
	materials.lower = _concrete(Color("334946"), 43)
	materials.ceiling = _concrete(Color("343c3b"), 59)
	materials.metal = _material("333e3d")
	materials.dark = _material("131b1c")
	materials.rust = _material("695244")
	materials.trim = _material("899083")
	materials.amber = _material("d3944d", 0.25)
	materials.lamp = _material("b9ceb0", 1.4)
	materials.red = _material("b45336", 0.6)
	materials.green = _material("79cba2", 0.9)
	materials.screen = _material("102a24", 0.35)
	materials.black = _material("080f10")


func _box(label: String, size: Vector3, at: Vector3, material: Material, solid := false, parent: Node3D = self) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		instance.add_child(body)
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
	return instance


func _pipe(at: Vector3, length: float, radius: float, material: Material, along_z := true) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 8
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	if along_z:
		instance.rotation.x = PI / 2.0
	add_child(instance)


func _label(text_value: String, at: Vector3, font_size: int, tint: Color, scale_value := 0.006) -> Label3D:
	var label := Label3D.new()
	label.text = text_value
	label.position = at
	label.font_size = font_size
	label.pixel_size = scale_value
	label.modulate = tint
	label.outline_size = 0
	label.no_depth_test = false
	label.shaded = false
	add_child(label)
	return label


func _light(at: Vector3, tint: Color, energy: float, radius: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = tint
	light.light_energy = energy
	light.omni_range = radius
	light.omni_attenuation = 1.3
	add_child(light)
	return light


func _build_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("0c1618")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("738d86")
	environment.ambient_light_energy = 0.22
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.fog_enabled = true
	environment.fog_light_color = Color("142322")
	environment.fog_light_energy = 0.3
	environment.fog_density = 0.021
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)


func _build_corridor() -> void:
	_box("Floor", Vector3(5.6, 0.3, 60.0), Vector3(0.0, -0.15, -18.0), materials.floor, true)
	_box("Ceiling", Vector3(5.6, 0.25, 60.0), Vector3(0.0, 3.4, -18.0), materials.ceiling, true)
	_build_side_wall(-1.0, -8.0)
	_build_side_wall(1.0, -24.0)
	_box("RearWall", Vector3(5.6, 3.5, 0.3), Vector3(0.0, 1.7, 11.7), materials.dark, true)
	_box("EndWall", Vector3(5.6, 3.5, 0.3), Vector3(0.0, 1.7, -47.5), materials.wall, true)
	for side: float in [-1.0, 1.0]:
		_pipe(Vector3(side * 2.2, 3.07, -17.0), 57.0, 0.085, materials.rust)
		_pipe(Vector3(side * 1.93, 3.15, -17.0), 57.0, 0.045, materials.metal)
	for z in range(6, -40, -5):
		_box("CeilingBeam", Vector3(5.0, 0.15, 0.16), Vector3(0.0, 3.17, z), materials.metal)
		_box("LampHousing", Vector3(1.35, 0.12, 0.36), Vector3(0.0, 3.12, z - 1.0), materials.dark)
		_box("Fluorescent", Vector3(1.16, 0.04, 0.22), Vector3(0.0, 3.05, z - 1.0), materials.lamp)
		var lamp := _light(Vector3(0.0, 2.9, z - 1.0), Color("9eb9a5"), 0.78, 5.6)
		ceiling_lights.append(lamp)
		for side: float in [-1.0, 1.0]:
			_box("PanelSeam", Vector3(0.012, 2.05, 0.035), Vector3(side * 2.48, 2.2, z), materials.metal)
	# Sealed side doors break up the straight route without adding rooms.
	for index in range(4):
		var side := -1.0 if index % 2 == 0 else 1.0
		var z := -29.5 if index == 3 else -3.5 - index * 7.0
		_box("SealedDoorFrame", Vector3(0.13, 2.55, 1.48), Vector3(side * 2.42, 1.28, z), materials.dark)
		_box("SealedDoor", Vector3(0.15, 2.37, 1.27), Vector3(side * 2.35, 1.2, z), materials.metal)
		_box("WiredGlass", Vector3(0.02, 0.4, 0.58), Vector3(side * 2.265, 1.82, z), materials.black)
		_box("DoorHandle", Vector3(0.12, 0.04, 0.19), Vector3(side * 2.22, 1.12, z + 0.4), materials.trim)
		var number := _label("0%d" % (index + 2), Vector3(side * 2.25, 2.16, z), 34, Color("a7b6a4"), 0.005)
		number.rotation.y = -side * PI / 2.0
		var sealed := _label("SEALED", Vector3(side * 2.25, 1.43, z), 20, Color("b58754"), 0.004)
		sealed.rotation.y = -side * PI / 2.0
	# Drain covers, warning paint, and a few flat scraps remain outside the walking path.
	for z in [-2.0, -16.0, -29.0]:
		_box("Drain", Vector3(0.6, 0.008, 0.8), Vector3(-1.65, 0.008, z), materials.dark)
		for bar in range(6):
			_box("DrainSlat", Vector3(0.57, 0.012, 0.025), Vector3(-1.65, 0.016, z - 0.31 + bar * 0.12), materials.metal)
	for z in [-8.0, -21.0, -35.7]:
		for side: float in [-1.0, 1.0]:
			_box("FloorGuide", Vector3(0.09, 0.007, 2.0), Vector3(side * 1.92, 0.005, z), materials.amber)
	for index in range(6):
		var paper := _box("Paper", Vector3(0.26, 0.004, 0.34), Vector3(-1.7 + (index % 3) * 0.3, 0.007, -11.0 - index * 0.27), materials.trim)
		paper.rotation.y = index * 0.7
	var sign_panel := _box("SectorSign", Vector3(0.035, 0.66, 1.65), Vector3(-2.46, 2.0, -9.3), materials.dark)
	var sector := _label("SECTOR 09\nACCESS CONTROL  →", sign_panel.position + Vector3(0.03, 0.0, 0.0), 29, Color("c3b894"), 0.004)
	sector.rotation.y = PI / 2.0
	_box("BreakerBox", Vector3(0.22, 0.76, 0.59), Vector3(2.35, 1.9, -17.0), materials.metal)
	_light(Vector3(2.12, 2.3, -17.0), Color("cc6d3b"), 1.2, 4.0)
	_box("WarningBulb", Vector3(0.1, 0.17, 0.13), Vector3(2.18, 2.4, -17.0), materials.red)
	_label("AUTHORIZED PERSONNEL ONLY", Vector3(0.0, 2.88, -37.5), 24, Color("a8b6a6"), 0.0035)


func _build_terminal() -> void:
	_box("TerminalFoot", Vector3(0.82, 0.15, 0.78), Vector3(1.65, 0.075, -34.0), materials.dark, true)
	_box("TerminalStand", Vector3(0.65, 0.94, 0.6), Vector3(1.65, 0.57, -34.0), materials.metal, true)
	_box("ConsoleHousing", Vector3(0.98, 0.68, 0.54), Vector3(1.65, 1.43, -34.0), materials.metal, true)
	_box("ScreenBezel", Vector3(0.87, 0.54, 0.055), Vector3(1.65, 1.47, -33.71), materials.black)
	_box("PhosphorScreen", Vector3(0.74, 0.4, 0.014), Vector3(1.65, 1.48, -33.674), materials.screen)
	terminal_label = _label("POWER OFFLINE\nUSE BRASS KEY\nAT EXIT", Vector3(1.65, 1.49, -33.66), 23, Color("7dd8a4"), 0.0027)
	_box("KeyboardTray", Vector3(0.94, 0.07, 0.43), Vector3(1.65, 1.08, -33.57), materials.dark, true)
	for row in range(3):
		for column in range(9):
			_box("Key", Vector3(0.06, 0.02, 0.055), Vector3(1.32 + column * 0.08, 1.128, -33.67 + row * 0.084), materials.trim)
	_light(Vector3(1.6, 1.7, -33.25), Color("71d3ac"), 1.15, 3.0)
	_label("09 / SECURITY", Vector3(1.65, 0.8, -33.686), 21, Color("9aa598"), 0.0024)
	var instruction := _label("MANUAL EXIT LOCK", Vector3(2.455, 2.28, -33.7), 24, Color("a6bfac"), 0.0035)
	instruction.rotation.y = -PI / 2.0


func _build_door() -> void:
	for side: float in [-1.0, 1.0]:
		_box("Bulkhead", Vector3(1.18, 3.4, 0.6), Vector3(side * 1.94, 1.7, DOOR_Z), materials.lower, true)
		_box("DoorJamb", Vector3(0.18, 3.0, 0.7), Vector3(side * 1.3, 1.5, DOOR_Z + 0.05), materials.metal, true)
	_box("DoorLintel", Vector3(2.7, 0.4, 0.7), Vector3(0.0, 3.12, DOOR_Z), materials.metal, true)
	door = Node3D.new()
	door.name = "EscapeDoor"
	door.position = Vector3(0.0, 0.0, DOOR_Z)
	add_child(door)
	_box("SlidingDoor", Vector3(2.45, 2.98, 0.2), Vector3(0.0, 1.49, 0.0), materials.metal, false, door)
	var body := StaticBody3D.new()
	door.add_child(body)
	door_shape = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.45, 2.98, 0.3)
	door_shape.shape = shape
	door_shape.position.y = 1.49
	body.add_child(door_shape)
	for x in [-0.96, 0.0, 0.96]:
		_box("DoorRib", Vector3(0.07, 2.83, 0.1), Vector3(x, 1.49, 0.15), materials.dark, false, door)
	_box("DoorWindow", Vector3(0.68, 0.35, 0.015), Vector3(0.0, 1.93, 0.16), materials.black, false, door)
	for index in range(10):
		_box("DoorWarning", Vector3(0.18, 0.12, 0.02), Vector3(-1.05 + index * 0.232, 0.2, 0.16), materials.amber if index % 2 == 0 else materials.dark, false, door)
	door_label = _label("LOCKED", Vector3(0.0, 2.42, DOOR_Z + 0.18), 34, Color("d39860"), 0.005)
	_label("EXIT", Vector3(0.0, 3.12, DOOR_Z + 0.37), 35, Color("a1c5ad"), 0.005)
	door_light = _light(Vector3(0.0, 2.6, DOOR_Z + 0.7), Color("d78a4a"), 0.95, 4.4)
	_light(Vector3(0.0, 2.5, -43.5), Color("a2d8bd"), 2.6, 6.0)
	_box("ExitGlow", Vector3(3.0, 2.5, 0.025), Vector3(0.0, 1.5, -47.3), materials.green)


func _process(delta: float) -> void:
	clock_time += delta
	if ceiling_lights.size() > 4:
		# A brief, occasional dying fluorescent, rather than full-screen strobing.
		var flickering := flicker_enabled and fmod(clock_time, 9.0) > 8.55
		ceiling_lights[3].light_energy = 0.18 if flickering and sin(clock_time * 38.0) > 0.1 else 0.78


func unlock_door() -> void:
	if door_unlocked:
		return
	door_unlocked = true
	terminal_label.text = "EXIT RELEASED"
	door_label.text = "OPEN"
	door_label.modulate = Color("88d0a6")
	door_light.light_color = Color("89d5af")
	door_shape.set_deferred("disabled", true)
	door_tween = create_tween()
	door_tween.tween_property(door, "position:y", 3.1, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	door_tween.tween_callback(func() -> void: door_open = true)


func reset_door() -> void:
	if door_tween and door_tween.is_valid():
		door_tween.kill()
	door.position.y = 0.0
	door_unlocked = false
	door_open = false
	door_shape.set_deferred("disabled", false)
	door_label.text = "LOCKED"
	door_label.modulate = Color("d39860")
	door_light.light_color = Color("d78a4a")
	terminal_label.text = "POWER OFFLINE\nUSE BRASS KEY\nAT EXIT"


func _build_side_wall(side: float, opening_z: float) -> void:
	for span: Vector2 in [Vector2(-48.0, opening_z - 1.1), Vector2(opening_z + 1.1, 12.0)]:
		var length_value := span.y - span.x
		var center := (span.x + span.y) * 0.5
		_box("CorridorWall", Vector3(0.3, 3.5, length_value), Vector3(side * 2.65, 1.7, center), materials.wall, true)
		_box("PaintedDado", Vector3(0.025, 1.15, length_value), Vector3(side * 2.49, 0.575, center), materials.lower)
		_box("WallRail", Vector3(0.08, 0.06, length_value), Vector3(side * 2.45, 1.17, center), materials.trim)
		_box("Skirting", Vector3(0.09, 0.17, length_value), Vector3(side * 2.45, 0.085, center), materials.dark)
	_box("RoomLintel", Vector3(0.45, 0.65, 2.2), Vector3(side * 2.65, 3.07, opening_z), materials.metal, true)


func _build_rooms() -> void:
	for side: float in [-1.0, 1.0]:
		var z := -8.0 if side < 0.0 else -24.0
		_box("RoomFloor", Vector3(4.5, 0.3, 5.6), Vector3(side * 4.75, -0.15, z), materials.floor, true)
		_box("RoomCeiling", Vector3(4.5, 0.25, 5.6), Vector3(side * 4.75, 3.4, z), materials.ceiling, true)
		_box("RoomEnd", Vector3(0.3, 3.5, 5.6), Vector3(side * 7.0, 1.7, z), materials.wall, true)
		for end in [-1.0, 1.0]:
			_box("RoomSide", Vector3(4.5, 3.5, 0.3), Vector3(side * 4.75, 1.7, z + end * 2.8), materials.lower, true)
		_light(Vector3(side * 5.0, 2.7, z), Color("a1bda4"), 1.1, 5.0)
		_box("RoomLamp", Vector3(1.0, 0.06, 0.24), Vector3(side * 5.0, 3.05, z), materials.lamp)
		var sign := _label("SUPPLIES" if side < 0.0 else "RECORDS / KEY STORAGE", Vector3(side * 2.38, 2.94, z), 25, Color("c3b894"), 0.004)
		sign.rotation.y = -side * PI / 2.0
		# Tables sit at the back, leaving room to skirt around a zombie.
		_box("SupplyTable", Vector3(2.6, 0.12, 0.75), Vector3(side * 4.95, 0.85, z - 2.0), materials.metal, true)
		for x in [-0.95, 0.95]:
			_box("TableLeg", Vector3(0.1, 0.8, 0.55), Vector3(side * 4.95 + x, 0.4, z - 2.0), materials.metal, true)
	_add_pickup("ammo", Vector3(-4.1, 1.03, -10.0), 4)
	_add_pickup("heal", Vector3(-5.75, 1.03, -10.0), 1)
	_add_pickup("key", Vector3(5.0, 1.03, -26.0), 1)
	_label("BRASS KEY / EXIT 09", Vector3(5.0, 1.8, -26.58), 24, Color("c3b894"), 0.005)
	_label("CHECK SIDE ROOMS\nCONSERVE AMMUNITION", Vector3(0.0, 2.8, -4.0), 22, Color("c3b894"), 0.0035)


func _add_pickup(kind: String, at: Vector3, amount: int) -> void:
	var pickup := SurvivalPickup.new()
	pickup.kind = kind
	pickup.amount = amount
	pickup.position = at
	add_child(pickup)
	pickups.append(pickup)


func reset_pickups() -> void:
	for pickup in pickups:
		pickup.reset()


func pursuit_waypoint(from: Vector3, destination: Vector3) -> Vector3:
	# Two authored doorways are sufficient for this small level. No runtime nav bake.
	for side: float in [-1.0, 1.0]:
		var z := -8.0 if side < 0.0 else -24.0
		var from_inside := from.x * side > 2.5
		var to_inside := destination.x * side > 2.5
		if from_inside and not to_inside:
			return Vector3(side * 1.8, 0.05, z)
		if to_inside and not from_inside and (absf(from.z - z) > 0.45 or from.x * side < 1.5):
			return Vector3(side * 1.8, 0.05, z)
	return destination
