extends SceneTree

var game: DeadlockGame
var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)


func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
	await process_frame


func key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
	Input.flush_buffered_events()


func fire() -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
	Input.flush_buffered_events()


func quiet_enemies() -> void:
	for enemy in game.zombies:
		enemy.active = false


func aim(at: Vector3) -> void:
	var direction := at - game.player.camera.global_position
	game.player.rotation.y = atan2(-direction.x, -direction.z)
	game.player.pitch = atan2(direction.y, Vector2(direction.x, direction.z).length())
	game.player.camera.rotation.x = game.player.pitch


func move_to(destination: Vector3, max_frames := 650) -> bool:
	game.player.use_movement_override = true
	for index in range(max_frames):
		if game.state != DeadlockGame.State.PLAYING:
			break
		var offset := destination - game.player.position
		offset.y = 0.0
		if offset.length() < 0.12:
			game.player.movement_override = Vector2.ZERO
			game.player.use_movement_override = false
			await frames(5)
			return true
		var local := game.player.basis.inverse() * offset.normalized() * minf(1.0, offset.length() * 3.0)
		game.player.movement_override = Vector2(local.x, local.z)
		await frames(1)
	game.player.movement_override = Vector2.ZERO
	game.player.use_movement_override = false
	print("Route stopped at ", game.player.position, " targeting ", destination, " health=", game.supplies.health, " state=", game.state)
	return false


func _run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	check(game.state == DeadlockGame.State.TITLE, "Title waits for input")
	key(KEY_ENTER)
	await frames(3)
	check(game.state == DeadlockGame.State.PLAYING, "Enter starts via the title button")
	check(game.supplies.magazine == 6 and game.supplies.reserve == 0 and game.supplies.health == 100, "New run starts with six rounds, no reserve, and full health")
	check(game.zombies.size() == 3 and game.corridor.pickups.size() == 3, "Three simple enemies and three exploration pickups exist")
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(100, 20)
	motion.screen_relative = motion.relative
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	await frames(2)
	check(is_equal_approx(game.player.rotation.y, -0.22) and is_equal_approx(game.player.pitch, -0.044), "Mouse look retains resolution-independent sensitivity")
	game.player.reset_at(EscapeCorridor.PLAYER_SPAWN)
	Input.action_press("move_forward")
	await frames(60)
	Input.action_release("move_forward")
	check(game.player.position.z < -1.0 and game.player.position.y > -0.05, "Movement and floor collision work")
	game.player.reset_at(Vector3(1.6, 0.03, -12.0))
	Input.action_press("move_right")
	await frames(60)
	Input.action_release("move_right")
	check(game.player.position.x < 2.24, "Walls block movement")
	check(game.nearby_pickup() == null, "Items cannot be collected remotely")

	# Isolate weapon mechanics from AI so failures identify the actual system.
	game.start_run()
	quiet_enemies()
	var enemy := game.zombies[0]
	enemy.reset_at(Vector3(0, 0.03, -4.0))
	game.player.reset_at(Vector3(0, 0.03, 0))
	aim(enemy.position + Vector3.UP * 1.25)
	await frames(2)
	fire()
	check(game.supplies.magazine == 5 and enemy.health == 75, "Mouse click consumes one bullet and raycast damages the zombie")
	check(game.player.flash_remaining > 0.0 and game.hit_flash > 0.0, "Shot creates muzzle flash, recoil, and hit feedback")
	fire()
	check(game.supplies.magazine == 5, "Fire cooldown prevents immediate duplicate shots")
	for index in range(3):
		await frames(25)
		fire()
	await frames(30)
	check(enemy.health == 0 and enemy.mind == CorridorZombie.Mind.DEAD, "Four hits kill a zombie")
	check(enemy.collider.disabled and absf(enemy.model.rotation.x) > 1.0, "Killed zombie falls and loses collision")
	game.player.rotation.y = PI
	for index in range(2):
		await frames(25)
		fire()
	await frames(25)
	fire()
	check(game.supplies.magazine == 0, "Empty trigger does not produce negative ammunition")
	key(KEY_R)
	check(game.supplies.reload_remaining == 0.0, "Reload refuses when there is no reserve")

	# Pickups, healing, and menu interactions use the real E/Tab/Enter input path.
	game.player.reset_at(Vector3(-2.2, 0.03, -10.0))
	aim(game.corridor.pickups[0].position)
	check(game.nearby_pickup() == null, "World geometry blocks collecting ammunition through a wall")
	game.player.reset_at(Vector3(-4.1, 0.03, -8.5))
	aim(game.corridor.pickups[0].position)
	key(KEY_E)
	check(game.supplies.reserve == 4 and game.corridor.pickups[0].collected, "E collects four spare rounds in Supplies")
	key(KEY_E)
	check(game.supplies.reserve == 4, "Collected ammo cannot be duplicated")
	game.player.reset_at(Vector3(-5.75, 0.03, -8.5))
	aim(game.corridor.pickups[1].position)
	key(KEY_E)
	check(game.supplies.first_aid == 1 and game.corridor.pickups[1].collected, "E collects the single first-aid kit")
	key(KEY_H)
	check(game.supplies.first_aid == 1, "Healing at full health does not waste the consumable")
	game.take_damage(28)
	check(game.supplies.health == 72 and game.damage_flash > 0.0, "Damage reduces health and starts visual feedback")
	game.take_damage(28)
	check(game.supplies.health == 72, "Brief damage immunity prevents stacked instant attacks")
	key(KEY_TAB)
	await frames(2)
	check(paused and game.state == DeadlockGame.State.INVENTORY, "Tab opens inventory and pauses the world")
	check(game.ui.inventory_ammo.text.contains("4") and game.ui.inventory_healing.text.contains("1") and game.ui.inventory_weapon.text.contains("HANDGUN"), "Inventory displays the weapon, ammunition, and healing item")
	var frozen_time := game.run_seconds
	var frozen_enemy := game.zombies[1].position
	fire()
	key(KEY_R)
	await frames(30)
	check(game.run_seconds == frozen_time and game.zombies[1].position.is_equal_approx(frozen_enemy), "Inventory freezes time and enemy motion")
	check(game.supplies.reload_remaining == 0.0, "Gameplay reload input is blocked in inventory")
	game.ui.heal_button.grab_focus()
	key(KEY_ENTER)
	await frames(2)
	check(game.supplies.health == 100 and game.supplies.first_aid == 0, "Inventory Use button heals and consumes exactly one kit")
	check(game.ui.heal_button.disabled, "Used healing item is disabled in inventory")
	key(KEY_ESCAPE)
	await frames(2)
	check(game.state == DeadlockGame.State.PLAYING and not paused, "Escape closes inventory and restores play")
	key(KEY_R)
	check(game.supplies.reload_remaining > 0.0, "R begins timed reload")
	fire()
	check(game.supplies.magazine == 0, "Shooting is blocked during reload")
	await frames(30)
	key(KEY_I)
	var frozen_reload := game.supplies.reload_remaining
	await frames(30)
	check(game.supplies.reload_remaining == frozen_reload, "Inventory pauses the reload timer")
	key(KEY_TAB)
	await frames(105)
	check(game.supplies.magazine == 4 and game.supplies.reserve == 0, "Reload transfers only available rounds")
	game.supplies.reserve = 1
	key(KEY_R)
	await frames(105)
	check(game.supplies.magazine == 5 and game.supplies.reserve == 0, "Partial reload retains rounds already in the magazine")

	# Walls stop bullets; no aim assist or damage through geometry.
	game.start_run()
	quiet_enemies()
	enemy.reset_at(Vector3(-5.0, 0.03, -10.0))
	game.player.reset_at(Vector3(0, 0.03, -10.0))
	aim(enemy.position + Vector3.UP * 1.3)
	await frames(3)
	fire()
	check(enemy.health == 100 and game.supplies.magazine == 5, "A wall blocks pistol damage while the shot still costs a round")

	# Real AI detection, attack timing, evasion, loss of interest, and death.
	game.start_run()
	quiet_enemies()
	game.player.reset_at(Vector3(-1.5, 0.03, -11.0))
	enemy.reset_at(Vector3(-5.5, 0.03, -9.5))
	enemy.active = true
	await frames(5)
	check(enemy.mind == CorridorZombie.Mind.DORMANT, "Walls prevent visual detection")
	game.player.reset_at(Vector3(0, 0.03, 0))
	enemy.reset_at(Vector3(0, 0.03, -1.0))
	enemy.active = true
	await frames(5)
	check(enemy.mind == CorridorZombie.Mind.PURSUING and game.supplies.health == 100, "Nearby visible player is detected; attack has a wind-up")
	await frames(40)
	check(game.supplies.health == 72, "Zombie attack deals 28 damage at close range")
	await frames(60)
	check(game.supplies.health == 72, "Attack recovery prevents continuous contact damage")
	game.start_run()
	quiet_enemies()
	game.player.reset_at(Vector3(0, 0.03, 0))
	enemy.reset_at(Vector3(0, 0.03, -1.0))
	enemy.active = true
	await frames(5)
	game.player.position.z = 3.0
	await frames(40)
	check(game.supplies.health == 100, "Backing out of attack range avoids the hit")
	var pursuing_z := enemy.position.z
	await frames(40)
	check(enemy.position.z > pursuing_z, "Detected zombie pursues at walking speed")
	game.player.position.z = 10.0
	await frames(180)
	check(enemy.mind != CorridorZombie.Mind.PURSUING, "Retreat breaks pursuit rather than causing a permanent chase")

	game.start_run()
	quiet_enemies()
	game.player.reset_at(Vector3(0, 0.03, 0))
	enemy.reset_at(Vector3(0, 0.03, -1.0))
	enemy.active = true
	enemy.health = 25
	await frames(5)
	aim(enemy.position + Vector3.UP * 1.3)
	fire()
	await frames(120)
	check(enemy.health == 0 and game.supplies.health == 100, "Killing a winding-up zombie cancels its attack")
	game.start_run()
	quiet_enemies()
	game.player.reset_at(Vector3(0, 0.03, 0))
	enemy.reset_at(Vector3(0, 0.03, -1.0))
	enemy.active = true
	await frames(520)
	check(game.supplies.health == 0 and game.state == DeadlockGame.State.LOST, "Repeated real zombie attacks cause defeat at zero health")
	fire()
	check(game.supplies.magazine == 6 and not game.player.active, "Death disables combat and movement")
	key(KEY_R)
	await frames(3)
	check(game.supplies.health == 100 and game.supplies.magazine == 6 and game.zombies[0].health == 100, "Retry resets health, ammunition, and zombies")
	check(not game.corridor.pickups[0].collected and not game.supplies.has_key, "Retry restores pickups and clears key state")

	# Locked progression: key collection alone cannot win or open the remote door.
	quiet_enemies()
	game.player.reset_at(Vector3(0, 0.03, -37.3))
	Input.action_press("move_forward")
	await frames(60)
	Input.action_release("move_forward")
	check(game.player.position.z > -38.7, "Locked exit blocks physical movement")
	key(KEY_E)
	check(not game.corridor.door_unlocked, "Exit refuses interaction without the brass key")
	game.player.reset_at(Vector3(5.0, 0.03, -24.5))
	aim(game.corridor.pickups[2].position)
	key(KEY_E)
	check(game.supplies.has_key and game.corridor.pickups[2].collected, "Records room contains a collectible brass key")
	key(KEY_I)
	check(game.ui.inventory_key.text == "BRASS EXIT KEY", "Key appears in inventory")
	key(KEY_I)
	key(KEY_E)
	check(not game.corridor.door_unlocked, "Collecting or using a key remotely does not unlock the exit")
	game.player.reset_at(Vector3(0, 0.03, -37.3))
	key(KEY_E)
	check(game.corridor.door_unlocked and game.supplies.key_used and not game.supplies.has_key, "E at exit uses the key and starts opening")
	key(KEY_ESCAPE)
	var door_y := game.corridor.door.position.y
	await frames(20)
	check(paused and game.corridor.door.position.y == door_y, "Pause freezes door motion")
	key(KEY_ESCAPE)
	await frames(120)
	check(game.corridor.door_open and game.corridor.door_shape.disabled, "Unlocked door finishes opening")
	check(game.state == DeadlockGame.State.PLAYING, "Unlocking alone does not win")
	Input.action_press("move_forward")
	await frames(100)
	Input.action_release("move_forward")
	check(game.state == DeadlockGame.State.WON, "Walking through the unlocked exit triggers victory")

	# Uninterrupted route with all enemies enabled and no teleports or extra supplies.
	game.start_run()
	check(await move_to(Vector3(1.8, 0, -6)), "Route: leave the starting area")
	check(await move_to(Vector3(1.8, 0, -24)), "Route: reach Records while avoiding combat")
	check(await move_to(Vector3(5.0, 0, -24.5)), "Route: enter Records through its doorway")
	aim(game.corridor.pickups[2].position)
	key(KEY_E)
	check(game.supplies.has_key, "Route: physically reach and collect the key")
	check(await move_to(Vector3(3.1, 0, -24)), "Route: leave the Records table")
	check(await move_to(Vector3(1.8, 0, -24)), "Route: return through the room doorway")
	check(await move_to(Vector3(0.65, 0, -30)), "Route: step around the old terminal")
	check(await move_to(Vector3(0.65, 0, -37)), "Route: pass the final enemy")
	check(await move_to(Vector3(0, 0, -37.2)), "Route: approach the locked exit")
	aim(Vector3(0, 1.5, EscapeCorridor.DOOR_Z + 0.3))
	key(KEY_E)
	await frames(115)
	game.player.rotation.y = 0.0
	game.player.pitch = 0.0
	Input.action_press("move_forward")
	await frames(100)
	Input.action_release("move_forward")
	check(game.state == DeadlockGame.State.WON and game.supplies.magazine == 6, "Full route can be won without firing or killing every enemy")
	game.show_title()
	check(game.state == DeadlockGame.State.TITLE and not paused, "Return to title resets menu state")
	print("\nSURVIVAL TEST: %d/%d passed" % [checks - failures, checks])
	game.queue_free()
	await process_frame
	OS.delay_msec(200)
	await process_frame
	quit(1 if failures > 0 else 0)
