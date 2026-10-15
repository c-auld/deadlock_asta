class_name EscapeInterface
extends Control

signal start_requested
signal resume_requested
signal title_requested
signal heal_requested
signal inventory_closed
signal sensitivity_changed(value: float)
signal steady_light_changed(enabled: bool)

const INK := Color("d3d8c5")
const MUTED := Color("8c9e96")
const AMBER := Color("d4a365")
const GREEN := Color("9ed4ae")
const RED := Color("dd9274")

var title_screen: Control
var hud: Control
var inventory_screen: Control
var pause_screen: Control
var end_screen: Control
var objective: Label
var status: Label
var prompt: Label
var toast: Label
var reticle: Label
var audio_label: Label
var inventory_health: Label
var inventory_ammo: Label
var inventory_weapon: Label
var inventory_healing: Label
var inventory_key: Label
var inventory_message: Label
var heal_button: Button
var inventory_close_button: Button
var ammo_label: Label
var end_heading: Label
var end_copy: Label
var end_code: Label
var end_button: Button
var start_button: Button
var resume_button: Button
var mono: SystemFont
var heavy: SystemFont


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	mono = SystemFont.new()
	mono.font_names = PackedStringArray(["Menlo", "Consolas", "DejaVu Sans Mono", "monospace"])
	heavy = SystemFont.new()
	heavy.font_names = mono.font_names
	heavy.font_weight = 700
	_build_title()
	_build_hud()
	_build_inventory()
	_build_pause()
	_build_end()
	show_title()


func _screen() -> Control:
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen)
	return screen


func _rect(parent: Control, at: Vector2, size_value: Vector2, tint: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = at
	rect.size = size_value
	rect.color = tint
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect


func _shade(parent: Control, tint: Color) -> void:
	var rect := _rect(parent, Vector2.ZERO, Vector2.ZERO, tint)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _text(parent: Control, value: String, at: Vector2, font_size: int, tint := INK, width := 0.0) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.add_theme_font_override("font", mono)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if width > 0.0:
		label.size.x = width
	parent.add_child(label)
	return label


func _style(background: Color, border: Color, border_width := 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style


func _button(parent: Control, value: String, at: Vector2, size_value: Vector2, callback: Callable, primary := false) -> Button:
	var button := Button.new()
	button.text = value
	button.position = at
	button.size = size_value
	button.add_theme_font_override("font", mono)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("101b19") if primary else INK)
	button.add_theme_color_override("font_focus_color", Color("101b19") if primary else INK)
	button.add_theme_color_override("font_hover_color", Color("0c1814") if primary else GREEN)
	button.add_theme_color_override("font_pressed_color", Color("0c1814"))
	button.add_theme_stylebox_override("normal", _style(AMBER if primary else Color("142020"), AMBER if primary else Color("46564e")))
	button.add_theme_stylebox_override("hover", _style(INK if primary else Color("21352d"), INK))
	button.add_theme_stylebox_override("pressed", _style(GREEN, GREEN))
	button.add_theme_stylebox_override("focus", _style(Color(0, 0, 0, 0), INK, 2))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _rule(parent: Control, at: Vector2, width: float, tint := Color("43534b")) -> void:
	_rect(parent, at, Vector2(width, 1.0), tint)


func _right_panel(parent: Control, width: float, top: float, height: float) -> Control:
	var panel := Control.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -width - 44.0
	panel.offset_right = -44.0
	panel.offset_top = top
	panel.offset_bottom = top + height
	parent.add_child(panel)
	return panel


func _center_panel(parent: Control, dimensions: Vector2) -> Control:
	var panel := Control.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -dimensions.x / 2.0
	panel.offset_right = dimensions.x / 2.0
	panel.offset_top = -dimensions.y / 2.0
	panel.offset_bottom = dimensions.y / 2.0
	parent.add_child(panel)
	return panel


func _build_title() -> void:
	title_screen = _screen()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.025, 0.045, 0.048, 0.98))
	gradient.set_color(1, Color(0.025, 0.045, 0.048, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.25, 0.0)
	texture.fill_to = Vector2(1.0, 0.0)
	var fade := TextureRect.new()
	fade.texture = texture
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_screen.add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect(title_screen, Vector2(65, 66), Vector2(8, 8), AMBER)
	_text(title_screen, "FIRST-PERSON SURVIVAL HORROR", Vector2(88, 59), 14, AMBER)
	_rule(title_screen, Vector2(65, 96), 438)
	var wordmark := _text(title_screen, "DEADLOCK\n_ASTA", Vector2(58, 127), 80)
	wordmark.add_theme_font_override("font", heavy)
	wordmark.add_theme_constant_override("line_spacing", -22)
	_text(title_screen, "SECTOR 09  /  CONTAINMENT FAILURE", Vector2(66, 387), 13, AMBER)
	_text(title_screen, "A locked exit. Six rounds.\nChoose your encounters.", Vector2(65, 423), 20, INK)
	start_button = _button(title_screen, "ENTER THE CORRIDOR     [ENTER]", Vector2(65, 512), Vector2(440, 57), func() -> void: start_requested.emit(), true)
	_text(title_screen, "Explore. Conserve ammunition. Find the brass key.", Vector2(65, 590), 13, MUTED)
	var footer := _text(title_screen, "WASD  MOVE     MOUSE  LOOK     SHIFT  RUN     E  INTERACT", Vector2(65, -51), 12, MUTED)
	footer.anchor_top = 1.0
	footer.anchor_bottom = 1.0
	var stamp := _right_panel(title_screen, 237, 62, 85)
	_text(stamp, "FACILITY // 09", Vector2.ZERO, 17, INK)
	_text(stamp, "SIGNAL LOST\n03:17:09  —  NIGHT SHIFT", Vector2(0, 31), 12, MUTED)
	var version := _text(title_screen, "EVERY ROUND COUNTS.", Vector2(-292, -50), 12, AMBER)
	version.anchor_left = 1.0
	version.anchor_right = 1.0
	version.anchor_top = 1.0
	version.anchor_bottom = 1.0


func _build_hud() -> void:
	hud = _screen()
	_text(hud, "09", Vector2(35, 25), 36, INK)
	_rect(hud, Vector2(101, 34), Vector2(1, 38), Color("617167"))
	_text(hud, "SERVICE CORRIDOR", Vector2(116, 33), 13, INK)
	audio_label = _text(hud, "AUDIO ON  /  M", Vector2(117, 55), 11, MUTED)
	var objective_panel := _right_panel(hud, 360, 31, 60)
	_text(objective_panel, "CURRENT OBJECTIVE", Vector2.ZERO, 11, AMBER)
	objective = _text(objective_panel, "Find the key in Records.", Vector2(0, 24), 16, INK)
	status = _text(hud, "HEALTH 100 / FINE", Vector2(38, -75), 12, MUTED)
	status.anchor_top = 1.0
	status.anchor_bottom = 1.0
	var controls := _text(hud, "WASD  MOVE   SHIFT  RUN   E  TAKE / USE", Vector2(38, -48), 11, MUTED)
	controls.anchor_top = 1.0
	controls.anchor_bottom = 1.0
	ammo_label = _text(hud, "PISTOL  06 / 00", Vector2(-340, -85), 22, INK)
	ammo_label.anchor_left = 1.0
	ammo_label.anchor_right = 1.0
	ammo_label.anchor_top = 1.0
	ammo_label.anchor_bottom = 1.0
	var firing_help := _text(hud, "LMB  FIRE    R  RELOAD", Vector2(-340, -113), 11, MUTED)
	firing_help.anchor_left = 1.0
	firing_help.anchor_top = 1.0
	var pause_help := _text(hud, "TAB  INVENTORY    ESC  PAUSE", Vector2(-292, -48), 11, MUTED)
	pause_help.anchor_left = 1.0
	pause_help.anchor_right = 1.0
	pause_help.anchor_top = 1.0
	pause_help.anchor_bottom = 1.0
	reticle = _text(hud, "+", Vector2(-7, -14), 18, Color(0.8, 0.87, 0.77, 0.62))
	reticle.anchor_left = 0.5
	reticle.anchor_top = 0.5
	prompt = _text(hud, "", Vector2(-300, 49), 17, GREEN, 600.0)
	prompt.anchor_left = 0.5
	prompt.anchor_top = 0.5
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast = _text(hud, "", Vector2(-420, -140), 17, AMBER, 840.0)
	toast.anchor_left = 0.5
	toast.anchor_top = 1.0
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _build_inventory() -> void:
	inventory_screen = _screen()
	_shade(inventory_screen, Color(0.02, 0.04, 0.035, 0.94))
	var panel := _center_panel(inventory_screen, Vector2(740, 550))
	_text(panel, "PERSONAL EFFECTS / 09", Vector2.ZERO, 13, AMBER)
	_text(panel, "INVENTORY", Vector2(-3, 29), 46, INK)
	inventory_health = _text(panel, "", Vector2(465, 47), 20, GREEN)
	_text(panel, "TIME IS PAUSED. Take a moment to plan.", Vector2(0, 100), 13, MUTED)
	_rule(panel, Vector2(0, 134), 740)
	for position_value: Vector2 in [Vector2(0, 156), Vector2(382, 156), Vector2(0, 292), Vector2(382, 292)]:
		_rect(panel, position_value, Vector2(358, 116), Color("16231f"))
	_text(panel, "01 / WEAPON", Vector2(18, 170), 12, AMBER)
	inventory_weapon = _text(panel, "", Vector2(18, 198), 18, INK)
	_text(panel, "Equipped · six-round magazine", Vector2(18, 239), 12, MUTED)
	_text(panel, "02 / AMMUNITION", Vector2(400, 170), 12, AMBER)
	inventory_ammo = _text(panel, "", Vector2(400, 198), 18, INK)
	_text(panel, "Reload with R after closing inventory.", Vector2(400, 239), 11, MUTED)
	_text(panel, "03 / RECOVERY", Vector2(18, 306), 12, AMBER)
	inventory_healing = _text(panel, "", Vector2(18, 334), 18, INK)
	_text(panel, "One use · restores up to 50 health", Vector2(18, 375), 12, MUTED)
	_text(panel, "04 / KEY ITEM", Vector2(400, 306), 12, AMBER)
	inventory_key = _text(panel, "", Vector2(400, 334), 18, INK)
	_text(panel, "Use at the far exit with E.", Vector2(400, 375), 12, MUTED)
	inventory_message = _text(panel, "", Vector2(0, 426), 13, GREEN)
	heal_button = _button(panel, "USE FIRST AID  [H]", Vector2(0, 468), Vector2(358, 53), func() -> void: heal_requested.emit(), true)
	inventory_close_button = _button(panel, "CLOSE  [TAB / ESC]", Vector2(382, 468), Vector2(358, 53), func() -> void: inventory_closed.emit())


func update_supplies(supplies: SurvivalState) -> void:
	var condition := "FINE" if supplies.health > 65 else ("CAUTION" if supplies.health > 35 else "DANGER")
	var tint := GREEN if supplies.health > 65 else (AMBER if supplies.health > 35 else RED)
	status.text = "HEALTH %03d / %s" % [supplies.health, condition]
	status.add_theme_color_override("font_color", tint)
	ammo_label.text = "RELOADING..." if supplies.reload_remaining > 0.0 else "PISTOL  %02d / %02d" % [supplies.magazine, supplies.reserve]
	inventory_health.text = "%03d / %s" % [supplies.health, condition]
	inventory_health.add_theme_color_override("font_color", tint)
	inventory_weapon.text = "HANDGUN    %d / 6" % supplies.magazine
	inventory_ammo.text = "9mm ROUNDS    × %d" % supplies.reserve
	inventory_healing.text = "FIRST-AID KIT × %d" % supplies.first_aid
	inventory_key.text = "BRASS KEY / USED" if supplies.key_used else ("BRASS EXIT KEY" if supplies.has_key else "EMPTY")
	heal_button.disabled = supplies.first_aid <= 0 or supplies.health >= 100 or supplies.health <= 0


func _build_pause() -> void:
	pause_screen = _screen()
	_shade(pause_screen, Color(0.02, 0.04, 0.035, 0.94))
	var panel := _center_panel(pause_screen, Vector2(460, 476))
	_text(panel, "PROCESS SUSPENDED", Vector2(0, 0), 12, AMBER)
	_text(panel, "PAUSED", Vector2(-4, 24), 55, INK)
	_text(panel, "You can breathe here.", Vector2(0, 101), 15, MUTED)
	resume_button = _button(panel, "RESUME  [ESC]", Vector2(0, 150), Vector2(460, 52), func() -> void: resume_requested.emit(), true)
	_button(panel, "RESTART", Vector2(0, 215), Vector2(222, 47), func() -> void: start_requested.emit())
	_button(panel, "TITLE SCREEN", Vector2(238, 215), Vector2(222, 47), func() -> void: title_requested.emit())
	_text(panel, "MOUSE SENSITIVITY", Vector2(0, 291), 12, MUTED)
	var slider := HSlider.new()
	slider.position = Vector2(228, 287)
	slider.size = Vector2(232, 24)
	slider.min_value = 0.5
	slider.max_value = 2.0
	slider.step = 0.05
	slider.value = 1.0
	slider.value_changed.connect(func(value: float) -> void: sensitivity_changed.emit(value))
	panel.add_child(slider)
	var steady := CheckButton.new()
	steady.position = Vector2(0, 334)
	steady.size = Vector2(460, 38)
	steady.text = "STEADY FLUORESCENT LIGHT"
	steady.add_theme_font_override("font", mono)
	steady.add_theme_font_size_override("font_size", 12)
	steady.toggled.connect(func(enabled: bool) -> void: steady_light_changed.emit(enabled))
	panel.add_child(steady)
	_rule(panel, Vector2(0, 402), 460)
	_text(panel, "WASD  MOVE   MOUSE / ARROWS  LOOK\nLMB / SPACE  FIRE   R  RELOAD   E  USE\nTAB / I  INVENTORY   H  HEAL   SHIFT  RUN", Vector2(0, 420), 12, MUTED)


func _build_end() -> void:
	end_screen = _screen()
	_shade(end_screen, Color(0.018, 0.035, 0.031, 0.95))
	var panel := _center_panel(end_screen, Vector2(670, 420))
	end_code = _text(panel, "", Vector2(0, 0), 13, AMBER)
	_rule(panel, Vector2(0, 36), 670)
	end_heading = _text(panel, "", Vector2(-5, 66), 67, INK)
	end_heading.add_theme_font_override("font", heavy)
	end_copy = _text(panel, "", Vector2(0, 168), 18, MUTED)
	end_button = _button(panel, "TRY AGAIN  [R]", Vector2(0, 284), Vector2(325, 56), func() -> void: start_requested.emit(), true)
	_button(panel, "TITLE SCREEN", Vector2(345, 284), Vector2(325, 56), func() -> void: title_requested.emit())
	_text(panel, "DEADLOCK_ASTA  /  END OF TRANSMISSION", Vector2(0, 386), 12, MUTED)


func show_title() -> void:
	title_screen.show()
	hud.hide()
	inventory_screen.hide()
	pause_screen.hide()
	end_screen.hide()
	start_button.grab_focus()


func show_game() -> void:
	title_screen.hide()
	hud.show()
	inventory_screen.hide()
	pause_screen.hide()
	end_screen.hide()
	reticle.show()


func show_inventory() -> void:
	inventory_screen.show()
	reticle.hide()
	toast.hide()
	prompt.text = ""
	inventory_message.text = "Supplies are limited. You do not need to kill everything."
	inventory_close_button.grab_focus()


func show_pause() -> void:
	pause_screen.show()
	resume_button.grab_focus()


func show_result(won: bool, seconds: float) -> void:
	show_game()
	hud.hide()
	end_screen.show()
	end_code.text = "PROCESS COMPLETE  /  ACCESS GRANTED" if won else "CONNECTION LOST  /  SUBJECT 09"
	end_code.add_theme_color_override("font_color", GREEN if won else RED)
	end_heading.text = "YOU GOT OUT." if won else "DEAD END."
	end_copy.text = "The lock released. You didn't look back.\nEscaped in %02d:%02d." % [int(seconds) / 60, int(seconds) % 60] if won else "Your wounds caught up with you.\nRetreat, conserve ammunition, and use first aid."
	end_button.text = "PLAY AGAIN  [R]" if won else "TRY AGAIN  [R]"
	end_button.grab_focus()
