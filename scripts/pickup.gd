class_name SurvivalPickup
extends Node3D

var kind := "ammo"
var display_name := "HANDGUN AMMO"
var amount := 4
var collected := false


func _ready() -> void:
	var tint := Color("c3a26d")
	if kind == "heal":
		tint = Color("9ac5a1")
		display_name = "FIRST-AID KIT"
	elif kind == "key":
		tint = Color("d6b159")
		display_name = "BRASS EXIT KEY"
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 0.25
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.3, 0.15, 0.22) if kind != "key" else Vector3(0.1, 0.08, 0.34)
	var model := MeshInstance3D.new()
	model.mesh = mesh
	model.material_override = material
	add_child(model)
	var label := Label3D.new()
	label.text = "+" if kind == "heal" else ("KEY" if kind == "key" else "9mm")
	label.position = Vector3(0, 0.22, 0)
	label.font_size = 28
	label.pixel_size = 0.003
	label.modulate = tint
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 3
	add_child(label)


func collect() -> void:
	collected = true
	hide()


func reset() -> void:
	collected = false
	show()
