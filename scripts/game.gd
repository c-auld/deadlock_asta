class_name DeadlockGame
extends Control

enum State { TITLE, PLAYING, INVENTORY, PAUSED, WON, LOST }

var state := State.TITLE
var world_view: SubViewport
var corridor: EscapeCorridor
var player: EscapePlayer
var zombies: Array[CorridorZombie] = []
var supplies := SurvivalState.new()
var ui: EscapeInterface
var retro: ShaderMaterial
var ambience: AudioStreamPlayer
var effect: AudioStreamPlayer
var weapon_audio: AudioStreamPlayer
var heartbeat: AudioStreamPlayer
var run_seconds := 0.0
var elapsed := 0.0
var toast_seconds := 0.0
var beat_seconds := 0.0
var damage_flash := 0.0
var hit_flash := 0.0
var dry_fire_cooldown := 0.0
var muted := false
var shutting_down := false
var capture_path := ""
var capture_mode := "title"
var capture_elapsed := 0.0
var capture_started := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	_configure_input()
	_build_game()
	_build_audio()
	ui.start_requested.connect(start_run)
	ui.resume_requested.connect(resume_game)
	ui.title_requested.connect(show_title)
	ui.inventory_closed.connect(close_inventory)
	ui.heal_requested.connect(use_healing)
	ui.sensitivity_changed.connect(func(value: float) -> void: player.mouse_sensitivity = 0.0022 * value)
	ui.steady_light_changed.connect(func(enabled: bool) -> void: corridor.flicker_enabled = not enabled)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_path = argument.trim_prefix("--capture=")
		elif argument.begins_with("--view="):
			capture_mode = argument.trim_prefix("--view=")
	show_title()


func _configure_input() -> void:
	var bindings := {
		"move_forward": [KEY_W, KEY_Z], "move_back": [KEY_S],
		"move_left": [KEY_A, KEY_Q], "move_right": [KEY_D],
		"sprint": [KEY_SHIFT], "interact": [KEY_E],
		"look_left": [KEY_LEFT], "look_right": [KEY_RIGHT],
		"look_up": [KEY_UP], "look_down": [KEY_DOWN],
	}
	for action: String in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)


func _build_game() -> void:
	world_view = SubViewport.new()
	world_view.name = "LowResolutionWorld"
	world_view.size = Vector2i(480, 270)
	world_view.own_world_3d = true
	world_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	world_view.audio_listener_enable_3d = true
	add_child(world_view)
	corridor = EscapeCorridor.new()
	corridor.name = "Corridor"
	corridor.process_mode = Node.PROCESS_MODE_PAUSABLE
	world_view.add_child(corridor)
	player = EscapePlayer.new()
	corridor.add_child(player)
	for spawn: Vector3 in EscapeCorridor.ZOMBIE_SPAWNS:
		var zombie := CorridorZombie.new()
		corridor.add_child(zombie)
		zombie.target = player
		zombie.corridor = corridor
		zombie.reset_at(spawn, PI)
		zombie.attacked.connect(take_damage)
		zombies.append(zombie)
	var display := TextureRect.new()
	display.name = "RetroDisplay"
	display.texture = world_view.get_texture()
	display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.stretch_mode = TextureRect.STRETCH_SCALE
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(display)
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	retro = ShaderMaterial.new()
	retro.shader = load("res://shaders/retro.gdshader")
	display.material = retro
	ui = EscapeInterface.new()
	ui.name = "Interface"
	add_child(ui)


func _audio_player(volume: float) -> AudioStreamPlayer:
	var audio_player := AudioStreamPlayer.new()
	audio_player.volume_db = volume
	audio_player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(audio_player)
	return audio_player


func _build_audio() -> void:
	ambience = _audio_player(-19.0)
	ambience.stream = load("res://assets/audio/ambience.wav").duplicate()
	ambience.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	ambience.stream.loop_end = int(ambience.stream.get_length() * ambience.stream.mix_rate)
	ambience.play()
	effect = _audio_player(-10.0)
	weapon_audio = _audio_player(-9.0)
	heartbeat = _audio_player(-15.0)
	heartbeat.stream = load("res://assets/audio/heartbeat.wav")


func _sound(filename: String, volume := -10.0) -> void:
	effect.stream = load("res://assets/audio/" + filename + ".wav")
	effect.volume_db = volume
	effect.play()


func start_run() -> void:
	get_tree().paused = false
	state = State.PLAYING
	supplies.reset()
	run_seconds = 0.0
	damage_flash = 0.0
	hit_flash = 0.0
	beat_seconds = 1.0
	corridor.reset_door()
	corridor.reset_pickups()
	player.reset_at(EscapeCorridor.PLAYER_SPAWN)
	player.active = true
	player.handgun.show()
	for index in range(zombies.size()):
		zombies[index].reset_at(EscapeCorridor.ZOMBIE_SPAWNS[index], PI)
		zombies[index].active = true
	ui.show_game()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_notify("Search the side rooms. Six rounds won't clear the facility.", 6.0)
	_sync_ui()


func show_title() -> void:
	get_tree().paused = false
	state = State.TITLE
	player.active = false
	player.handgun.hide()
	player.reset_at(Vector3(-0.6, 0.05, -25.0))
	player.rotation.y = -0.11
	for index in range(zombies.size()):
		zombies[index].reset_at(EscapeCorridor.ZOMBIE_SPAWNS[index], PI)
	corridor.reset_door()
	corridor.reset_pickups()
	ui.show_title()
	retro.set_shader_parameter("danger", 0.0)
	retro.set_shader_parameter("damage", 0.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and state == State.PLAYING:
		player.look(event)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and state == State.PLAYING:
		shoot()
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	match code:
		KEY_F11:
			var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
		KEY_M:
			muted = not muted
			AudioServer.set_bus_mute(0, muted)
			ui.audio_label.text = "AUDIO OFF / M" if muted else "AUDIO ON  / M"
		KEY_ESCAPE:
			if state == State.INVENTORY:
				close_inventory()
			elif state == State.PAUSED:
				resume_game()
			elif state == State.PLAYING:
				pause_game()
		KEY_TAB, KEY_I:
			if state == State.INVENTORY:
				close_inventory()
			elif state == State.PLAYING:
				open_inventory()
		KEY_R:
			if state in [State.WON, State.LOST]:
				start_run()
			elif state == State.PLAYING:
				reload_weapon()
		KEY_H:
			use_healing()
		KEY_SPACE:
			shoot()
		KEY_E:
			interact()
		_:
			return
	get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if state != State.PLAYING:
		return
	supplies.tick(delta)
	dry_fire_cooldown = maxf(0.0, dry_fire_cooldown - delta)
	player.reload_progress = 1.0 - supplies.reload_remaining / SurvivalState.RELOAD_SECONDS if supplies.reload_remaining > 0.0 else -1.0
	if corridor.door_open and player.position.z < EscapeCorridor.EXIT_Z:
		_finish(true)


func _process(delta: float) -> void:
	if state not in [State.PAUSED, State.INVENTORY]:
		elapsed += delta
		retro.set_shader_parameter("elapsed", elapsed)
	if state == State.PLAYING:
		run_seconds += delta
		toast_seconds = maxf(0.0, toast_seconds - delta)
		damage_flash = maxf(0.0, damage_flash - delta * 1.7)
		hit_flash = maxf(0.0, hit_flash - delta)
		ui.toast.visible = toast_seconds > 0.0
		ui.reticle.text = "×" if hit_flash > 0.0 else "+"
		ui.reticle.add_theme_color_override("font_color", EscapeInterface.AMBER if hit_flash > 0.0 else EscapeInterface.INK)
		retro.set_shader_parameter("damage", damage_flash)
		retro.set_shader_parameter("danger", 1.0 - float(supplies.health) / SurvivalState.MAX_HEALTH)
		if supplies.health <= 35:
			beat_seconds -= delta
			if beat_seconds <= 0.0:
				heartbeat.play()
				beat_seconds = 1.1
		var pickup := nearby_pickup()
		ui.prompt.text = "[E]  TAKE " + pickup.display_name if pickup else ""
		if near_exit():
			ui.prompt.text = "[E]  USE BRASS KEY" if supplies.has_key else "[E]  EXIT LOCKED / BRASS KEY REQUIRED"
	_sync_ui()
	if not capture_path.is_empty():
		_capture_preview(delta)


func _sync_ui() -> void:
	ui.update_supplies(supplies)
	ui.objective.text = "Walk through the exit." if corridor.door_unlocked else ("Use the key at the exit." if supplies.has_key else "Find the key in Records.")


func shoot() -> void:
	if state != State.PLAYING:
		return
	if not supplies.fire_round():
		if supplies.magazine == 0 and supplies.reload_remaining <= 0.0 and dry_fire_cooldown <= 0.0:
			_sound("empty", -10.0)
			dry_fire_cooldown = 0.35
			_notify("Empty. Press R to reload." if supplies.reserve > 0 else "No ammunition. Make space and retreat.", 2.0)
		return
	player.shot_feedback()
	weapon_audio.stream = load("res://assets/audio/pistol.wav")
	weapon_audio.play()
	var origin := player.camera.global_position
	var query := PhysicsRayQueryParameters3D.create(origin, origin - player.camera.global_basis.z * 35.0, 1 | 4)
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider is CorridorZombie:
		var enemy := hit.collider as CorridorZombie
		enemy.take_damage(SurvivalState.BULLET_DAMAGE)
		hit_flash = 0.16
	for enemy in zombies:
		enemy.hear_shot(player.global_position)
	_sync_ui()


func reload_weapon() -> void:
	if state != State.PLAYING:
		return
	if supplies.start_reload():
		_sound("reload", -9.0)
	elif supplies.reserve <= 0:
		_notify("No spare rounds. Check the Supplies room.", 2.5)


func take_damage(amount: int) -> void:
	if state != State.PLAYING or not supplies.take_damage(amount):
		return
	damage_flash = 1.0
	_sound("caught", -12.0)
	if supplies.health <= 0:
		_finish(false)
	_sync_ui()


func use_healing() -> void:
	if state not in [State.PLAYING, State.INVENTORY]:
		return
	if supplies.heal():
		damage_flash = 0.0
		_notify("First-aid kit used. Recovered 50 health (up to 100).", 3.0)
		# Inventory pauses world audio too; feedback text remains available there.
		ui.inventory_message.text = "First-aid kit used. Health restored."
		_sound("connect", -15.0)
	else:
		ui.inventory_message.text = "Already at full health." if supplies.health == 100 else "No first-aid kit. Search the Supplies room."
		_notify(ui.inventory_message.text, 2.5)
	_sync_ui()


func can_reach(at: Vector3, distance_limit := 2.25) -> bool:
	var offset := at - player.camera.global_position
	if offset.length() > distance_limit or (-player.camera.global_basis.z).dot(offset.normalized()) < 0.4:
		return false
	var query := PhysicsRayQueryParameters3D.create(player.camera.global_position, at, 1)
	return player.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func nearby_pickup() -> SurvivalPickup:
	if state != State.PLAYING:
		return null
	var nearest: SurvivalPickup
	var closest := INF
	for pickup in corridor.pickups:
		var distance := player.camera.global_position.distance_to(pickup.global_position)
		if not pickup.collected and distance < closest and can_reach(pickup.global_position):
			nearest = pickup
			closest = distance
	return nearest


func near_exit() -> bool:
	return state == State.PLAYING and not corridor.door_unlocked and can_reach(Vector3(0, 1.5, EscapeCorridor.DOOR_Z + 0.3), 2.5)


func interact() -> void:
	if state != State.PLAYING:
		return
	var pickup := nearby_pickup()
	if pickup:
		match pickup.kind:
			"ammo": supplies.reserve += pickup.amount
			"heal": supplies.first_aid += pickup.amount
			"key": supplies.has_key = true
		pickup.collect()
		_notify("Collected %s%s." % [pickup.display_name, " × %d" % pickup.amount if pickup.kind == "ammo" else ""], 3.0)
		_sound("connect", -15.0)
	elif near_exit():
		if supplies.has_key:
			supplies.has_key = false
			supplies.key_used = true
			corridor.unlock_door()
			_sound("door", -9.0)
			_notify("Brass key used. The exit is opening.", 3.0)
		else:
			_notify("Locked. The brass exit key is kept in Records.", 4.0)
			_sound("denied", -16.0)
	_sync_ui()


func open_inventory() -> void:
	if state != State.PLAYING:
		return
	state = State.INVENTORY
	get_tree().paused = true
	ui.show_inventory()
	_sync_ui()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close_inventory() -> void:
	if state != State.INVENTORY:
		return
	get_tree().paused = false
	state = State.PLAYING
	ui.show_game()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func pause_game() -> void:
	if state != State.PLAYING:
		return
	state = State.PAUSED
	get_tree().paused = true
	ui.show_pause()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func resume_game() -> void:
	if state != State.PAUSED:
		return
	get_tree().paused = false
	state = State.PLAYING
	ui.show_game()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _finish(won: bool) -> void:
	get_tree().paused = false
	state = State.WON if won else State.LOST
	player.active = false
	player.velocity = Vector3.ZERO
	player.handgun.hide()
	for zombie in zombies:
		zombie.active = false
		zombie.voice.stop()
	heartbeat.stop()
	ui.show_result(won, run_seconds)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_sound("escape" if won else "caught", -11.0)


func _notify(message: String, duration: float) -> void:
	ui.toast.text = message
	ui.toast.visible = state == State.PLAYING
	toast_seconds = duration


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(ui) and capture_path.is_empty():
		pause_game()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(ui):
		_quit_cleanly()


func _quit_cleanly(exit_code := 0) -> void:
	if shutting_down:
		return
	shutting_down = true
	set_process(false)
	set_physics_process(false)
	get_tree().paused = false
	player.active = false
	for zombie in zombies:
		zombie.active = false
		zombie.voice.stop()
	for audio_player: Node in [ambience, effect, weapon_audio, heartbeat, player.footstep]:
		audio_player.stop()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit(exit_code)


func _capture_preview(delta: float) -> void:
	if not capture_started:
		capture_started = true
		if capture_mode != "title":
			start_run()
			player.reset_at(Vector3(0, 0.05, -14.0))
			if capture_mode.begins_with("zombie"):
				player.reset_at(Vector3(0, 0.05, -17.7))
				player.pitch = -0.22
				player.camera.rotation.x = player.pitch
				player.handgun.hide()
				zombies[1].reset_at(Vector3(0, 0.05, -20.0), PI)
				if capture_mode == "zombie_profile":
					zombies[1].rotation.y -= 0.75
					zombies[1].model.animate(0.5, true, 0.8, false, 0.0)
				elif capture_mode == "zombie_attack":
					zombies[1].model.animate(0.5, false, 0.0, true, 0.0)
				elif capture_mode == "zombie_dead":
					zombies[1].take_damage(100)
			elif capture_mode == "inventory":
				supplies.reserve = 4
				supplies.first_aid = 1
				supplies.health = 65
				open_inventory()
			elif capture_mode == "won":
				_finish(true)
			elif capture_mode == "lost":
				supplies.health = 0
				_finish(false)
			elif capture_mode == "pause":
				pause_game()
			player.active = false
			for zombie in zombies:
				zombie.active = false
	capture_elapsed += delta
	if capture_elapsed > 1.0:
		set_process(false)
		await RenderingServer.frame_post_draw
		var result := get_viewport().get_texture().get_image().save_png(capture_path)
		print("Preview saved: ", capture_path, " (", result, ")")
		_quit_cleanly(result)
