class_name SurvivalState
extends RefCounted

const MAX_HEALTH := 100
const MAGAZINE_SIZE := 6
const BULLET_DAMAGE := 25
const RELOAD_SECONDS := 1.65
const SHOT_INTERVAL := 0.38

var health := MAX_HEALTH
var magazine := MAGAZINE_SIZE
var reserve := 0
var first_aid := 0
var has_key := false
var key_used := false
var reload_remaining := 0.0
var shot_cooldown := 0.0
var invulnerability := 0.0


func reset() -> void:
	health = MAX_HEALTH
	magazine = MAGAZINE_SIZE
	reserve = 0
	first_aid = 0
	has_key = false
	key_used = false
	reload_remaining = 0.0
	shot_cooldown = 0.0
	invulnerability = 0.0


func tick(delta: float) -> void:
	shot_cooldown = maxf(0.0, shot_cooldown - delta)
	invulnerability = maxf(0.0, invulnerability - delta)
	if reload_remaining > 0.0:
		reload_remaining = maxf(0.0, reload_remaining - delta)
		if reload_remaining == 0.0:
			var rounds := mini(MAGAZINE_SIZE - magazine, reserve)
			magazine += rounds
			reserve -= rounds


func fire_round() -> bool:
	if health <= 0 or reload_remaining > 0.0 or shot_cooldown > 0.0 or magazine <= 0:
		return false
	magazine -= 1
	shot_cooldown = SHOT_INTERVAL
	return true


func start_reload() -> bool:
	if health <= 0 or reload_remaining > 0.0 or magazine == MAGAZINE_SIZE or reserve <= 0:
		return false
	reload_remaining = RELOAD_SECONDS
	return true


func take_damage(amount: int) -> bool:
	if health <= 0 or invulnerability > 0.0:
		return false
	health = maxi(0, health - amount)
	invulnerability = 0.9
	return true


func heal() -> bool:
	if first_aid <= 0 or health <= 0 or health == MAX_HEALTH:
		return false
	first_aid -= 1
	health = mini(MAX_HEALTH, health + 50)
	return true
