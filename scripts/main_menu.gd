extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var main_menu_container: VBoxContainer = $MainMenuContainer

@onready var play: Label = $MainMenuContainer/Play
@onready var tutorial: Label = $MainMenuContainer/Tutorial
@onready var settings: Label = $MainMenuContainer/Settings
@onready var leaderboard: Label = $MainMenuContainer/Leaderboard
@onready var quit: Label = $MainMenuContainer/Quit


@onready var play_menu_container: VBoxContainer = $PlayMenuContainer

@onready var boss_1: Label = $PlayMenuContainer/Boss1
@onready var boss_2: Label = $PlayMenuContainer/Boss2
@onready var back: Label = $PlayMenuContainer/Back


@onready var difficulty_menu_container: VBoxContainer = $DifficultyMenuContainer

@onready var very_easy: Label = $DifficultyMenuContainer/VeryEasy
@onready var easy: Label = $DifficultyMenuContainer/Easy
@onready var medium: Label = $DifficultyMenuContainer/Medium
@onready var hard: Label = $DifficultyMenuContainer/Hard
@onready var back_2: Label = $DifficultyMenuContainer/Back2

var current_button:Control = null


const BOSS_1_FIGHT = preload("uid://d374n77822n4u")
const BOSS_2_FIGHT = preload("uid://bstiets5m38ya")
const TUTORIAL = "res://scenes/tutorial/new_tutorial.tscn"
const LEADERBOARD = "res://scenes/leaderboard/leaderboard.tscn"
const SETTINGS = "res://scenes/settings.tscn"

var selected_boss = BOSS_1_FIGHT

func _ready() -> void:
	GlobalValues.time_elapsed = 0.0
	GlobalValues.damage_taken = 0
	GlobalValues.hits_parried = 0
	animation_player.play("pulse")

func focus_button(on_off:bool):
	if on_off:
		current_button.self_modulate = Color(5,5,5)
	else:
		current_button.self_modulate = Color(1,1,1)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("shoot"):
		match current_button:
			tutorial:
				get_tree().change_scene_to_file(TUTORIAL)
			settings:
				get_tree().change_scene_to_file(SETTINGS)
			play:
				main_menu_container.hide()
				play_menu_container.show()
			leaderboard:
				get_tree().change_scene_to_file(LEADERBOARD)
			boss_1: 
				GlobalValues.selected_boss = 0
				selected_boss = BOSS_1_FIGHT
				play_menu_container.hide()
				difficulty_menu_container.show()
			boss_2:
				GlobalValues.selected_boss = 1
				selected_boss = BOSS_2_FIGHT
				play_menu_container.hide()
				difficulty_menu_container.show()
			back:
				main_menu_container.show()
				play_menu_container.hide()
			back_2:
				play_menu_container.show()
				difficulty_menu_container.hide()
			easy:
				GlobalValues.toggle_timer(true)
				GlobalValues.difficulty = 0
				get_tree().change_scene_to_packed(selected_boss)
			very_easy:
				GlobalValues.toggle_timer(true)
				GlobalValues.difficulty = 3
				get_tree().change_scene_to_packed(selected_boss)
			medium:
				GlobalValues.toggle_timer(true)
				GlobalValues.difficulty = 1
				get_tree().change_scene_to_packed(selected_boss)
			hard:
				GlobalValues.toggle_timer(true)
				GlobalValues.difficulty = 2
				get_tree().change_scene_to_packed(selected_boss)
			quit:
				get_tree().quit()

func _on_button_mouse_exited() -> void:
	focus_button(false)
	current_button = null

func _on_play_mouse_entered() -> void:
	current_button = play
	focus_button(true)

func _on_tutorial_mouse_entered() -> void:
	current_button = tutorial
	focus_button(true)

func _on_leaderboard_mouse_entered() -> void:
	current_button = leaderboard
	focus_button(true)

func _on_settings_mouse_entered() -> void:
	current_button = settings
	focus_button(true)

func _on_quit_mouse_entered() -> void:
	current_button = quit
	focus_button(true)

func _on_boss_1_mouse_entered() -> void:
	current_button = boss_1
	focus_button(true)

func _on_boss_2_mouse_entered() -> void:
	current_button = boss_2
	focus_button(true)

func _on_back_mouse_entered() -> void:
	current_button = back
	focus_button(true)

func _on_easy_mouse_entered() -> void:
	current_button = easy
	focus_button(true)

func _on_very_easy_mouse_entered() -> void:
	current_button = very_easy
	focus_button(true)

func _on_medium_mouse_entered() -> void:
	current_button = medium
	focus_button(true)

func _on_hard_mouse_entered() -> void:
	current_button = hard
	focus_button(true)

func _on_back_2_mouse_entered() -> void:
	current_button = back_2
	focus_button(true)
