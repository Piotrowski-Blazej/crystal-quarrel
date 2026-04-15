extends Control

@onready var boss: Label = $VBoxContainer/Boss
@onready var difficulty: Label = $VBoxContainer/Difficulty
@onready var time: Label = $VBoxContainer/Time
@onready var damage_taken: Label = $VBoxContainer/DamageTaken
@onready var hits_parried: Label = $VBoxContainer/HitsParried
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var fadeout_rect: ColorRect = $FadeoutRect

@onready var name_input: LineEdit = $VBoxContainer/AddScoreContainer/NameInput
@onready var name_label: Label = $VBoxContainer/AddScoreContainer/NameInput/NameLabel
@onready var save_button_label: Label = $VBoxContainer/AddScoreContainer/SaveButtonLabel


func _ready() -> void:
	GlobalValues.toggle_timer(false)
	
	boss.text = "Boss beaten: " + GlobalValues.boss_names[GlobalValues.selected_boss]
	difficulty.text = "Difficulty: " + GlobalValues.diff_names[GlobalValues.difficulty]
	time.text = "Time: " + str(snappedf(GlobalValues.time_elapsed,0.01)) + "s"
	damage_taken.text = "Damage Taken: " + str(GlobalValues.damage_taken)
	hits_parried.text = "Hits Parried: " + str(GlobalValues.hits_parried)
	
	animation_player.play("fade_in")

const SAVE_PATH = "user://scores.txt"
func save_run_data():
	if !FileAccess.file_exists(SAVE_PATH):
		FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ_WRITE)
	file.seek_end()
	var stored_line = name_label.text + ";" + str(GlobalValues.boss_names[GlobalValues.selected_boss]) + ";" + str(GlobalValues.diff_names[GlobalValues.difficulty]) + ";" + str(snappedf(GlobalValues.time_elapsed,0.01)) + "s" + ";" + str(GlobalValues.damage_taken) + ";" + str(GlobalValues.hits_parried)
	file.store_line(stored_line)
	file.close()


func _process(_delta: float) -> void:
	if !animation_player.is_playing():
		if Input.is_action_just_pressed("esc"):
			exit()
		elif Input.is_action_just_pressed("heal"):
			name_input.show()
			save_button_label.show()
			name_input.grab_focus()


func _on_nameinput_text_changed(new_text: String) -> void:
	name_label.text = new_text


func _on_name_input_editing_toggled(toggled_on: bool) -> void:
	if toggled_on: name_label.self_modulate.a = 0.5
	else: name_label.self_modulate.a = 0.25

var has_saved = false
func _on_save_button_pressed() -> void:
	if !has_saved:
		save_run_data()
		has_saved = true
	exit()


func exit():
	fadeout_rect.fade_out(0.5)
