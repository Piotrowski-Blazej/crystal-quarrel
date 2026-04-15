extends Control

@onready var row_container: VBoxContainer = $AllRowContainer/ScrollContainer/RowContainer
@onready var column_names: HBoxContainer = $AllRowContainer/ColumnNames
@onready var boss: Label = $AllRowContainer/ColumnNames/Boss
@onready var difficulty: Label = $AllRowContainer/ColumnNames/Difficulty
@onready var temp_row_container: Node = $TempRowContainer

@onready var fadeout_rect: ColorRect = $FadeoutRect

var rows:Array[HBoxContainer] = []

const LEADERBOARD_LABEL = preload("uid://dvx43ajt3r266")
const LEADERBOARD_ROW = preload("uid://xh450jklgov2")


const SAVE_PATH = "user://scores.txt"
const HORIZONTAL_WIDTHS:PackedInt32Array = [460,240,240,180,144,152]#the widths of labels, in order


func _ready() -> void:
	#print(OS.get_user_data_dir())
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var read_line = file.get_line()
		
		var temp_row_array:Array[HBoxContainer]
		
		var line_index:int = 0
		while read_line:
			var values:PackedStringArray = read_line.split(";")
			
			var i_row = LEADERBOARD_ROW.instantiate()#instantiate a row container
			i_row.setup(values[1],values[2],float(values[3]),line_index)#set up it's values
			temp_row_array.append(i_row)#add it to the temp array
			temp_row_container.add_child(i_row)#add it as a child of the Temp container
			
			for i in range(values.size()):#create and setup the labels
				var i_label:Label = LEADERBOARD_LABEL.instantiate()
				i_row.add_child(i_label)
				i_label.text = values[i]
				i_label.custom_minimum_size.x = HORIZONTAL_WIDTHS[i]
			
			line_index += 1
			read_line = file.get_line()
		
		while temp_row_array.size() > 0:#sort the rows by time
			var smallest_value:float = 999999
			var smallest_index = 0
			for i in range(temp_row_array.size()):#find the next smallest time
				if temp_row_array[i].time < smallest_value:
					smallest_value = temp_row_array[i].time
					smallest_index = i
			
			rows.append(temp_row_array[smallest_index])#add it to the "permanent" array
			temp_row_array[smallest_index].reparent(row_container)#reparent it to the "permanent" container
			temp_row_array.pop_at(smallest_index)#remove it from the temp array


func remove_record(r_line_index:int) -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	
	var lines:PackedStringArray = []
	
	var read_line = file.get_line()
	
	var line_index:int = 0
	while read_line:
		if line_index != r_line_index:
			lines.append(read_line)
		if rows[line_index].line_index > r_line_index:
			rows[line_index].line_index -= 1
		line_index += 1
		read_line = file.get_line()
	
	file.close()
	file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	for line in lines:
		file.store_line(line)
	
	for i in range(rows.size()):
		if rows[i].line_index == r_line_index:
			rows.pop_at(i)
			break


func filter_rows() -> void:
	for row in rows:
		if !boss_option_pointer == 2 and !BOSS_OPTIONS[boss_option_pointer] == row.boss:
			row.hide()
			continue
		if !difficulty_option_pointer == 4 and !DIFFUCULTY_OPTIONS[difficulty_option_pointer] == row.difficulty:
			row.hide()
			continue
		row.show()


const BOSS_OPTIONS:PackedStringArray = ["Whirlwind","The Airship","All\nBosses"]
var boss_option_pointer:int = 2
func _on_boss_button_button_up() -> void:
	boss_option_pointer += 1
	if boss_option_pointer > BOSS_OPTIONS.size()-1: boss_option_pointer = 0
	boss.text = BOSS_OPTIONS[boss_option_pointer]
	filter_rows()

const DIFFUCULTY_OPTIONS:PackedStringArray = ["Very Easy","Easy","Medium","Hard","All\nDifficulties"]
var difficulty_option_pointer:int = 4
func _on_difficulty_button_button_up() -> void:
	difficulty_option_pointer -= 1
	if difficulty_option_pointer == -1: difficulty_option_pointer = 4
	difficulty.text = DIFFUCULTY_OPTIONS[difficulty_option_pointer]
	filter_rows()


func _on_back_button_button_up() -> void:
	fadeout_rect.fade_out(0.5)
