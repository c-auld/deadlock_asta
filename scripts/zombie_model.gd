class_name ZombieModel
extends Node3D

# A small faceted character assembled around human joints. The enemy's capsule,
# damage, and AI live in zombie.gd; this node only owns appearance and animation.
var torso: Node3D
var head: Node3D
var jaw: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_knee: Node3D
var right_knee: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_elbow: Node3D
var right_elbow: Node3D
var visual_time := 0.0
var skin: StandardMaterial3D
var bone: StandardMaterial3D
var shadow: StandardMaterial3D
var cloth: StandardMaterial3D
var trousers: StandardMaterial3D
var leather: StandardMaterial3D
var grime: StandardMaterial3D


func _ready() -> void:
	skin = _material("96968a")
	bone = _material("b0ac98")
	shadow = _material("282b29")
	cloth = _material("696b60")
	trousers = _material("3c4440")
	leather = _material("272b28")
	grime = _material("45413a")
	_build_body()
	_build_head()
	left_leg = _build_leg(-1.0)
	right_leg = _build_leg(1.0)
	left_arm = _build_arm(-1.0)
	right_arm = _build_arm(1.0)
	reset_pose()


func _material(color: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color)
	material.roughness = 1.0
	# Torn cuffs and small facial planes should read from both sides.
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _pivot(parent: Node3D, at: Vector3) -> Node3D:
	var joint := Node3D.new()
	joint.position = at
	parent.add_child(joint)
	return joint


func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (b - a).cross(c - a).normalized()
	for vertex: Vector3 in [a, b, c]:
		surface.set_normal(normal)
		surface.add_vertex(vertex)


func _rings(parent: Node3D, at: Vector3, profiles: Array[Vector4], material: Material, sides := 8, ragged := false) -> MeshInstance3D:
	# Profiles contain height, horizontal radius, depth radius, and depth offset.
	# Independent triangle normals retain the original low-poly lighting.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for row in range(profiles.size()):
		var profile := profiles[row]
		var ring := PackedVector3Array()
		for column in range(sides):
			var angle := TAU * float(column) / sides
			var hem := 0.018 * float(column % 3 - 1) if ragged and row == 0 else 0.0
			ring.append(Vector3(cos(angle) * profile.y, profile.x + hem, sin(angle) * profile.z + profile.w))
		rings.append(ring)
	for row in range(rings.size() - 1):
		for column in range(sides):
			var next := (column + 1) % sides
			_triangle(surface, rings[row][column], rings[row + 1][column], rings[row + 1][next])
			_triangle(surface, rings[row][column], rings[row + 1][next], rings[row][next])
	for column in range(sides):
		var next := (column + 1) % sides
		_triangle(surface, Vector3(0, profiles[0].x, profiles[0].w), rings[0][column], rings[0][next])
		_triangle(surface, Vector3(0, profiles[-1].x, profiles[-1].w), rings[-1][next], rings[-1][column])
	var instance := MeshInstance3D.new()
	instance.mesh = surface.commit()
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance


func _ellipsoid(parent: Node3D, at: Vector3, radius: Vector3, material: Material, sides := 8) -> MeshInstance3D:
	return _rings(parent, at, [
		Vector4(-radius.y, radius.x * 0.18, radius.z * 0.18, 0),
		Vector4(-radius.y * 0.5, radius.x * 0.86, radius.z * 0.86, 0),
		Vector4(radius.y * 0.25, radius.x, radius.z, 0),
		Vector4(radius.y * 0.8, radius.x * 0.65, radius.z * 0.65, 0),
		Vector4(radius.y, radius.x * 0.18, radius.z * 0.18, 0),
	], material, sides)


func _limb(parent: Node3D, from: Vector3, to: Vector3, start_radius: Vector2, end_radius: Vector2, material: Material, sides := 7) -> MeshInstance3D:
	var length_value := from.distance_to(to)
	var limb := _rings(parent, (from + to) * 0.5, [
		Vector4(-length_value * 0.5, end_radius.x, end_radius.y, 0),
		Vector4(-length_value * 0.1, lerpf(end_radius.x, start_radius.x, 0.65), lerpf(end_radius.y, start_radius.y, 0.65), 0),
		Vector4(length_value * 0.5, start_radius.x, start_radius.y, 0),
	], material, sides)
	limb.quaternion = Quaternion(Vector3.UP, (from - to).normalized())
	return limb


func _patch(parent: Node3D, vertices: PackedVector3Array, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(1, vertices.size() - 1):
		_triangle(surface, vertices[0], vertices[index], vertices[index + 1])
	var instance := MeshInstance3D.new()
	instance.mesh = surface.commit()
	instance.material_override = material
	parent.add_child(instance)


func _build_body() -> void:
	_rings(self, Vector3(0, 0.89, 0.025), [
		Vector4(-0.1, 0.13, 0.09, 0), Vector4(0.04, 0.165, 0.11, 0), Vector4(0.12, 0.135, 0.09, 0),
	], trousers)
	torso = _pivot(self, Vector3(0, 1.12, 0))
	_rings(torso, Vector3.ZERO, [
		Vector4(-0.23, 0.165, 0.105, 0.015),
		Vector4(-0.05, 0.16, 0.09, 0.005),
		Vector4(0.15, 0.225, 0.125, 0.025),
		Vector4(0.25, 0.215, 0.105, 0.025),
		Vector4(0.31, 0.125, 0.08, 0.025),
	], cloth, 10, true)
	# An irregular, open collar exposes a thin neck and prominent tendons.
	_ellipsoid(torso, Vector3(0, 0.3, -0.015), Vector3(0.09, 0.025, 0.075), shadow)
	_limb(torso, Vector3(0, 0.29, 0.01), Vector3(0.005, 0.44, -0.035), Vector2(0.057, 0.05), Vector2(0.045, 0.045), skin)
	for side: float in [-1.0, 1.0]:
		_limb(torso, Vector3(side * 0.045, 0.31, -0.032), Vector3(side * 0.023, 0.44, -0.065), Vector2(0.008, 0.008), Vector2(0.006, 0.006), bone, 5)
		_patch(torso, PackedVector3Array([
			Vector3(side * 0.027, 0.29, -0.058), Vector3(side * 0.125, 0.275, -0.04),
			Vector3(side * 0.095, 0.175, -0.09), Vector3(side * 0.015, 0.23, -0.093),
		]), grime)
	# Dried stains and a ragged tear follow the chest's surface, not square decals.
	_patch(torso, PackedVector3Array([
		Vector3(-0.14, 0.14, -0.075), Vector3(-0.055, 0.18, -0.103),
		Vector3(-0.025, 0.02, -0.094), Vector3(-0.07, -0.13, -0.09),
		Vector3(-0.13, -0.1, -0.07), Vector3(-0.1, 0.025, -0.09),
	]), _material("4b3932"))
	_patch(torso, PackedVector3Array([
		Vector3(0.045, -0.14, -0.099), Vector3(0.11, -0.16, -0.084),
		Vector3(0.09, -0.245, -0.081), Vector3(0.035, -0.225, -0.101),
	]), skin)
	for y in [-0.12, -0.01, 0.1]:
		_ellipsoid(torso, Vector3(0.005, y, -0.1), Vector3(0.007, 0.007, 0.004), shadow, 5)


func _build_head() -> void:
	head = _pivot(torso, Vector3(0.012, 0.49, -0.055))
	_rings(head, Vector3.ZERO, [
		Vector4(-0.065, 0.052, 0.065, -0.005),
		Vector4(-0.025, 0.077, 0.085, 0.0),
		Vector4(0.04, 0.094, 0.102, 0.006),
		Vector4(0.105, 0.081, 0.094, 0.012),
		Vector4(0.15, 0.046, 0.065, 0.012),
		Vector4(0.165, 0.018, 0.03, 0.012),
	], skin, 10)
	_rings(head, Vector3.ZERO, [
		Vector4(0.105, 0.083, 0.096, 0.015),
		Vector4(0.15, 0.048, 0.067, 0.014),
		Vector4(0.168, 0.017, 0.028, 0.014),
	], _material("373a34"), 9, true)
	for side: float in [-1.0, 1.0]:
		_ellipsoid(head, Vector3(side * 0.095, 0.005, 0.0), Vector3(0.018, 0.032, 0.021), skin, 6)
		# Deep eye sockets and tiny opaque eyes, without the old glowing square eyes.
		_ellipsoid(head, Vector3(side * 0.041, 0.027, -0.094), Vector3(0.032, 0.023, 0.018), shadow, 6)
		_ellipsoid(head, Vector3(side * 0.041, 0.025, -0.111), Vector3(0.01, 0.007, 0.005), _material("b4b09c"), 6)
		_limb(head, Vector3(side * 0.013, 0.054, -0.103), Vector3(side * 0.075, 0.042, -0.077), Vector2(0.013, 0.013), Vector2(0.01, 0.011), bone, 5)
		_limb(head, Vector3(side * 0.08, -0.005, -0.068), Vector3(side * 0.05, -0.037, -0.085), Vector2(0.016, 0.013), Vector2(0.008, 0.009), bone, 5)
	_patch(head, PackedVector3Array([
		Vector3(0, 0.045, -0.103), Vector3(-0.016, -0.016, -0.11),
		Vector3(0.002, -0.022, -0.147), Vector3(0.016, -0.013, -0.11),
	]), bone)
	_ellipsoid(head, Vector3(0.007, -0.069, -0.09), Vector3(0.041, 0.028, 0.021), _material("211e1b"), 7)
	jaw = _pivot(head, Vector3(0, -0.046, 0.015))
	_rings(jaw, Vector3.ZERO, [
		Vector4(-0.078, 0.034, 0.036, -0.054),
		Vector4(-0.047, 0.054, 0.052, -0.036),
		Vector4(-0.009, 0.057, 0.038, -0.015),
	], skin, 7)
	for index in range(4):
		var x := -0.02 + index * 0.013
		_limb(head, Vector3(x, -0.049, -0.111), Vector3(x, -0.062 - (index % 2) * 0.004, -0.112), Vector2(0.0045, 0.004), Vector2(0.003, 0.003), bone, 4)
	# A sunken cheek gives the two sides different silhouettes.
	_patch(head, PackedVector3Array([
		Vector3(-0.066, -0.014, -0.079), Vector3(-0.025, -0.024, -0.087),
		Vector3(-0.035, -0.054, -0.08), Vector3(-0.058, -0.046, -0.065),
	]), _material("656358"))


func _build_leg(side: float) -> Node3D:
	var hip := _pivot(self, Vector3(side * 0.105, 0.91, 0.02))
	var knee_at := Vector3(side * 0.012, -0.39, 0.015)
	_limb(hip, Vector3.ZERO, knee_at, Vector2(0.081, 0.089), Vector2(0.059, 0.062), trousers)
	var knee := _pivot(hip, knee_at)
	_ellipsoid(knee, Vector3.ZERO, Vector3(0.061, 0.06, 0.061), grime)
	_limb(knee, Vector3.ZERO, Vector3(0, -0.39, 0), Vector2(0.06, 0.063), Vector2(0.039, 0.043), trousers)
	_rings(knee, Vector3(0, -0.51, 0), [
		Vector4(0, 0.063, 0.12, -0.048), Vector4(0.055, 0.066, 0.126, -0.048),
		Vector4(0.105, 0.052, 0.075, -0.005), Vector4(0.135, 0.041, 0.05, 0.01),
	], leather, 7)
	if side < 0:
		left_knee = knee
	else:
		right_knee = knee
	return hip


func _build_arm(side: float) -> Node3D:
	var shoulder := _pivot(torso, Vector3(side * 0.22, 0.215, 0.005))
	_ellipsoid(shoulder, Vector3(side * 0.014, -0.025, 0), Vector3(0.074, 0.085, 0.081), cloth)
	var elbow_at := Vector3(side * 0.03, -0.275, 0)
	_limb(shoulder, Vector3.ZERO, elbow_at, Vector2(0.061, 0.066), Vector2(0.04, 0.043), skin)
	var sleeve_length := 0.22 if side < 0 else 0.15
	_rings(shoulder, Vector3.ZERO, [
		Vector4(-sleeve_length, 0.048, 0.054, 0), Vector4(-0.07, 0.073, 0.075, 0), Vector4(0.02, 0.055, 0.061, 0),
	], cloth, 7, true)
	var elbow := _pivot(shoulder, elbow_at)
	_ellipsoid(elbow, Vector3.ZERO, Vector3(0.041, 0.047, 0.042), bone, 7)
	_limb(elbow, Vector3.ZERO, Vector3(0, -0.255, -0.005), Vector2(0.047, 0.046), Vector2(0.027, 0.027), skin)
	var hand := _pivot(elbow, Vector3(0, -0.26, -0.005))
	hand.rotation = Vector3(0.15, side * 0.2, side * 0.12)
	_rings(hand, Vector3.ZERO, [
		Vector4(-0.085, 0.032, 0.017, -0.005), Vector4(-0.025, 0.038, 0.02, 0), Vector4(0, 0.026, 0.026, 0),
	], skin, 6)
	for finger in range(4):
		var x := (float(finger) - 1.5) * 0.017
		var length_value := 0.056 if finger in [1, 2] else 0.043
		var knuckle := Vector3(x, -0.08, -0.004)
		var bend := knuckle + Vector3(side * 0.004, -length_value, -0.008)
		_limb(hand, knuckle, bend, Vector2(0.009, 0.009), Vector2(0.006, 0.007), skin, 5)
		_limb(hand, bend, bend + Vector3(0, -0.017, -0.017), Vector2(0.006, 0.007), Vector2(0.004, 0.004), bone, 4)
	_limb(hand, Vector3(-side * 0.028, -0.025, 0), Vector3(-side * 0.065, -0.065, -0.018), Vector2(0.011, 0.011), Vector2(0.007, 0.008), skin, 5)
	if side < 0:
		left_elbow = elbow
	else:
		right_elbow = elbow
	return shoulder


func animate(delta: float, walking: bool, gait: float, attacking: bool, stagger: float) -> void:
	visual_time += delta
	var stride := sin(gait) if walking else 0.0
	left_leg.rotation.x = stride * 0.38
	right_leg.rotation.x = -stride * 0.28
	left_knee.rotation.x = -0.08 - maxf(0, -stride) * 0.36
	right_knee.rotation.x = -0.14 - maxf(0, stride) * 0.24
	torso.position.y = 1.12 + (absf(stride) * 0.012 if walking else sin(visual_time * 1.7) * 0.003)
	torso.rotation = Vector3(-0.19 + stagger * 1.1, sin(gait * 0.5) * 0.025, -0.025 + stride * 0.035)
	head.rotation = Vector3(0.04, sin(visual_time * 0.6) * 0.04, -0.14 + sin(visual_time * 1.2) * 0.025)
	jaw.rotation = Vector3(0.12 + sin(visual_time * 1.4) * 0.025, 0.02, 0.07)
	left_arm.rotation = Vector3(1.25 if attacking else 0.32 - stride * 0.1, -0.08, -0.08)
	right_arm.rotation = Vector3(1.05 if attacking else 0.08 + stride * 0.08, 0.13, 0.055)
	left_elbow.rotation.x = 0.45 if attacking else 0.38
	right_elbow.rotation.x = 0.7 if attacking else 0.19


func reset_pose() -> void:
	visual_time = 0.0
	animate(0.0, false, 0.0, false, 0.0)
