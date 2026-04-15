extends Node2D

signal move_tutorial
var stage:int = 0
enum STAGES {MOVEMENT = 0, TUNNEL = 1, DASHING = 2, DODGING = 3, PARRYING = 4}

@onready var tutorial_label: Label = $TutorialUI/TutorialLabel
@onready var player = $TutorialPlayer
@onready var tutorial_anim_player: AnimationPlayer = $TutorialAnimPlayer
@onready var fadeout_rect: ColorRect = $TutorialUI/FadeoutRect
@onready var bullet_holder: Node2D = $BulletHolder

@onready var area_1: Node2D = $Area1
@onready var area_2: Node2D = $Area2

var input_map:Dictionary[String, String]

const MAIN_MENU = preload("uid://bbaywroopna3x")

func _ready() -> void:
	input_map.set("up", InputMap.action_get_events("move_up")[0].as_text().replace(" (Physical)", ""))
	input_map.set("left", InputMap.action_get_events("move_left")[0].as_text().replace(" (Physical)", ""))
	input_map.set("down", InputMap.action_get_events("move_down")[0].as_text().replace(" (Physical)", ""))
	input_map.set("right", InputMap.action_get_events("move_right")[0].as_text().replace(" (Physical)", ""))
	
	input_map.set("shoot", InputMap.action_get_events("shoot")[0].as_text().replace(" (Physical)", ""))
	input_map.set("parry", InputMap.action_get_events("parry")[0].as_text().replace(" (Physical)", ""))
	input_map.set("dash", InputMap.action_get_events("dash")[0].as_text().replace(" (Physical)", ""))
	input_map.set("heal", InputMap.action_get_events("heal")[0].as_text().replace(" (Physical)", ""))
	input_map.set("superdash", InputMap.action_get_events("superdash")[0].as_text().replace(" (Physical)", ""))
	input_map.set("fire_laser", InputMap.action_get_events("fire_laser")[0].as_text().replace(" (Physical)", ""))
	
	stage_0_movement()

signal misc_check_signal
var has_function_been_restarted = false#if a function has been restarted due to a player failure
var ready_for_check:bool = false
var misc_variable:float = 0
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("move_tutorial"):
		move_tutorial.emit()
	if Input.is_action_just_pressed("esc"):
		get_tree().change_scene_to_packed(MAIN_MENU)
	
	if ready_for_check:
		if stage == STAGES.MOVEMENT:
			misc_variable += player.linear_velocity.length()
			if misc_variable > 200000: stage_1_tunnel()
		if stage == STAGES.DASHING:
			if player.linear_velocity.length() > 0: misc_check_signal.emit()

func misc_event(_irrelevant = null):
	if ready_for_check and stage == STAGES.TUNNEL:
		player.teleporting_player = true
		player.teleport_destination = Vector2.ZERO
	if stage == STAGES.DASHING:
		tutorial_anim_player.play("RESET")
		player.teleporting_player = true
		player.teleport_destination = Vector2.ZERO
		has_function_been_restarted = true
		stage_2_dash()
		tutorial_label.change_text("try again")
	if stage == STAGES.PARRYING:
		misc_variable += 1


func stage_0_movement():
	tutorial_label.change_text("Welcome to the tutorial!\nTo move the tutorial, press Tab or Enter")
	await move_tutorial
	tutorial_label.change_text("To move, use " + input_map["up"] + " " + input_map["left"] + " " + input_map["down"] + " " + input_map["right"])
	await move_tutorial
	tutorial_label.change_text("Move around a bit")
	ready_for_check = true

func stage_1_tunnel():
	stage = 1
	ready_for_check = false
	tutorial_label.change_text("As you can see, movement is physics-based.\nThis means you have to move carefully")
	await move_tutorial
	$Area1/WallTunnelEntrance.queue_free()
	tutorial_label.change_text("Now make your way through the tunnel, without touching the edges")
	ready_for_check = true
	await $Area1/AreaBullet.body_entered
	$Area1/Border.contact_monitor = false
	stage_2_dash(true)

func stage_2_dash(first_time = false):
	stage = 2
	player.can_move = true
	player.can_dash = false
	ready_for_check = false
	
	if !first_time: await $Area1/AreaBullet.body_entered
	tutorial_anim_player.play("move_bullet(dash)")
	await tutorial_anim_player.animation_finished
	
	if get_node_or_null("Area1/WallBulletOpening"): $Area1/WallBulletOpening.queue_free()
	tutorial_label.change_text("To change direction qucikly or just move faster\npress "+input_map["dash"]+" to dash towards your mouse")
	
	player.linear_velocity = Vector2.ZERO
	player.can_move = false
	await move_tutorial
	
	tutorial_label.change_text("Dash upwards (" + input_map["dash"] + ")")
	player.can_dash = true
	ready_for_check = true
	
	await misc_check_signal
	ready_for_check = false
	tutorial_anim_player.play("move_bullet_slow(dash)")
	if !has_function_been_restarted:
		await $Area1/AreaBullet2.body_entered
		player.can_dash = false
		
		fadeout_rect.fade_out()
		await fadeout_rect.has_faded
		area_1.queue_free()
		area_2.show()
		area_2.process_mode = Node.PROCESS_MODE_INHERIT
		player.teleporting_player = true
		
		fadeout_rect.fade_in()
		await fadeout_rect.has_faded
		
		player.can_move = true
		player.can_dash = true
		tutorial_label.change_text("Dashing has a very low cooldown")
		await tutorial_label.finished_text
		await move_tutorial
		tutorial_label.change_text("Now try dodging using movement\nand dashes when necessary")
		await move_tutorial
		
		stage_3_dodge()
	else: has_function_been_restarted = false

@onready var bullet_spawners: Node2D = $Area2/BulletSpawners
func stage_3_dodge():
	stage = 3
	for j in range(2):
		await get_tree().create_timer(1.5).timeout
		for i in range(bullet_spawners.get_child_count()):
			if i%2==0: bullet_spawners.get_child(i).shoot()
		await get_tree().create_timer(1.5).timeout
		for i in range(bullet_spawners.get_child_count()):
			if i%2==1: bullet_spawners.get_child(i).shoot()
		await get_tree().create_timer(1.5).timeout
		for i in range(bullet_spawners.get_child_count()):
			if i>2: bullet_spawners.get_child(i).shoot()
		await get_tree().create_timer(1).timeout
		for i in range(bullet_spawners.get_child_count()):
			if i<bullet_spawners.get_child_count()-3: bullet_spawners.get_child(i).shoot()
	await get_tree().create_timer(4).timeout
	if player.health != player.max_health:
		tutorial_label.change_text("Try again")
		await get_tree().create_timer(0.5).timeout
		
		fadeout_rect.fade_out(0.25)
		await fadeout_rect.has_faded
		player.health = player.max_health
		fadeout_rect.fade_in(0.25)
		await fadeout_rect.has_faded
		
		stage_3_dodge()
	else:
		tutorial_label.change_text("You need to avoid all red bullets,\nbut there are some bullets you can parry")
		await move_tutorial
		tutorial_label.change_text("To parry, press "+input_map["parry"]+"\nright before getting hit by a pink bullet")
		await move_tutorial
		stage_4_parry()

func stage_4_parry():
	stage = 4
	player.can_parry = true
	misc_variable = -1
	player.player_parried.connect(misc_event)
	
	while misc_variable == -1:
		for i in range(bullet_spawners.get_child_count()):
			if i%2==0: bullet_spawners.get_child(i).shoot(randi_range(0,1))
		await get_tree().create_timer(4).timeout
	
	tutorial_label.change_text("If you try to parry a red bullet,\nyou will take double damage")
	await move_tutorial
	tutorial_label.change_text("On a successful parry,\nyour dash and parry cooldowns are reset.")
	await move_tutorial
	tutorial_label.change_text("Try parrying multiple bullets,\nby parrying one, then dashing into and parrying another")
	await move_tutorial
	misc_variable = 0
	
	while misc_variable < 2:
		misc_variable = 0
		for i in range(bullet_spawners.get_child_count()):
			if i%4==0: bullet_spawners.get_child(i).shoot(1)
		await get_tree().create_timer(4).timeout
	
	player.player_parried.disconnect(misc_event)
	player.health = player.max_health*0.9
	player.can_heal = true
	
	tutorial_label.change_text("On a successful parry, you gain 1 charge,\nwith a max of 10.\ncharges can be used for 3 things")
	await move_tutorial
	tutorial_label.change_text("The first is healing, press "+input_map["heal"]+" to heal.\nyou heal 5% of your max health per charge,\nhealing uses all charges, unless you have more than you need")
	while player.health != player.max_health: await get_tree().process_frame
	tutorial_label.change_text("Parrying when at full charge, will heal you instead")
	await move_tutorial
	tutorial_label.change_text("The other uses will be explained later")
	await move_tutorial
	stage_5_shooting()

const TUTORIAL_ENEMY_TURRET = preload("uid://c3wi01trpycnt")
func stage_5_shooting():
	stage = 5
	player.can_fire = true
	tutorial_label.change_text("Shoot by holding "+input_map["shoot"])
	await move_tutorial
	
	fadeout_rect.fade_out()
	await fadeout_rect.has_faded
	
	player.teleporting_player = true
	player.teleport_destination = Vector2(-768,0)
	bullet_spawners.queue_free()
	
	var i_turret = TUTORIAL_ENEMY_TURRET.instantiate()
	GlobalValues.world_center.add_child(i_turret)
	i_turret.global_position = Vector2(768,0)
	
	fadeout_rect.fade_in()
	await fadeout_rect.has_faded
	tutorial_label.change_text("Fire at the turret")
	
	while  i_turret.health > 0: await get_tree().process_frame
	player.process_mode = Node.PROCESS_MODE_DISABLED
	area_2.process_mode = Node.PROCESS_MODE_DISABLED
	bullet_holder.process_mode = Node.PROCESS_MODE_DISABLED
	i_turret.shooting_c.stop()
	
	tutorial_label.change_text('When a target reaches 0 hp,\nit will need a "strong" attack to be destroyed.')
	await move_tutorial
	tutorial_label.change_text("You know a target is at 0hp,\nwhen its cracks reach the 4th stage\nand when it starts constantly spawning particles")
	await move_tutorial
	tutorial_label.change_text("The first strong attack, is the superdash\npress "+input_map["superdash"]+" to very quickly dash to your mouse...")
	await move_tutorial
	tutorial_label.change_text("When superdashing, you will be invincible (to bullets and contact damage) for 0.5s,\nAnd for 1s you will, on contact, deal 80 damage (8 normal shots) (one time).\nsuperdashing takes 1 charge")
	await move_tutorial
	tutorial_label.change_text("Superdash into the enemy\n("+input_map["superdash"]+")")
	await move_tutorial
	player.process_mode = Node.PROCESS_MODE_INHERIT
	area_2.process_mode = Node.PROCESS_MODE_INHERIT
	bullet_holder.process_mode = Node.PROCESS_MODE_INHERIT
	i_turret.shooting_c.start()
	player.can_superdash = true
	
	while is_instance_valid(i_turret): await get_tree().process_frame
	tutorial_label.change_text("Also, if an enemy is dashing at you,\nand you superdash into it\nyou will not take damage, and it will take 120 damage (1.5x)")
	await move_tutorial
	stage_6_laser()

func stage_6_laser():
	stage = 6
	tutorial_label.change_text("The last attack you have, is the laser.\nYou need at least 5 charges,\nand it will use all of your charges")
	await move_tutorial
	tutorial_label.change_text('The laser lasts 0.1 seconds per charge used\nand deals 120 damage per charge\nit is also a "strong" attack')
	await move_tutorial
	tutorial_label.change_text("To fire the laser, hold "+input_map["fire_laser"]+" for 1 second\n(it fires at, and follows your mouse)")
	await move_tutorial
	
	fadeout_rect.fade_out()
	await fadeout_rect.has_faded
	
	player.parry_charges = 0
	player.can_fire = false
	player.can_superdash = false
	player.can_laser = true
	
	player.teleporting_player = true
	player.teleport_destination = Vector2(-768,0)
	
	var i_turret = TUTORIAL_ENEMY_TURRET.instantiate()
	GlobalValues.world_center.add_child(i_turret)
	i_turret.global_position = Vector2(768,0)
	i_turret.parriable_chance = 100
	i_turret.shooting_c.wait_time = 0.5
	
	fadeout_rect.fade_in()
	await fadeout_rect.has_faded
	tutorial_label.change_text("Fire a laser at the turret\n("+input_map["fire_laser"]+")")
	while is_instance_valid(i_turret): await get_tree().process_frame
	tutorial_label.change_text("That's it, press escape to exit the tutorial")
