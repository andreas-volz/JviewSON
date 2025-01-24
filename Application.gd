extends Control

const ICON_ARRAY = preload("res://Assets/Icon_Array.svg")
const ICON_DICTIONARY = preload("res://Assets/Icon_Dictionary.svg")
const ICON_ARRAY_COLOR = Color.GREEN
const ICON_DICTIONARY_COLOR = Color.YELLOW

@onready var json_tree: Tree = %JSONTree
@onready var load_json_dialog: FileDialog = %LoadJSONDialog
@onready var auto_reload_check: CheckBox = %AutoReloadCheck
@onready var json_text: TextEdit = %JSONText

var tree_root: TreeItem
var modified_time: int
var current_loaded_file: String
var search_position: int = 0
var user_theme

func _ready() -> void:
	get_viewport().files_dropped.connect(_on_files_dropped)
		
	# TODO: this doesn't work. deactivate complete until solution is found
	# Load the UserTheme (if addon is available)
	#if is_addon_file_present("res://addons/UserTheme/available.txt"):
		#user_theme = UserTheme.new()
		#add_child(user_theme)
		#user_theme.loaded.connect(_on_user_theme_loaded)
		
	load_json_dialog.add_filter("*.json", "JSON")
	
	var param_file = get_file_parameter()
	if not param_file.is_empty():
		load_json_file(param_file)
	
	## TEST: this is only for local development - deactivate before release
	#current_loaded_file = "res://data/test1.json"
	#load_json_file(current_loaded_file)
	###################################################################
	
func is_addon_file_present(addon_file_path: String) -> bool:
	var addon_existing: bool = FileAccess.file_exists(addon_file_path)
	return addon_existing

	
func load_json_file(input_file: String, reload: bool = false):
	current_loaded_file = input_file
	json_tree.clear()
	
	var json_string = FileAccess.get_file_as_string(input_file)
	var json = JSON.new()
	var error = json.parse(json_string, true)
	if error != OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line(), " in file ", input_file)
		return

	json_text.set_unformated_text(json.get_parsed_text())

	modified_time = FileAccess.get_modified_time(input_file)

	var json_data: Variant = json.data

	tree_root = json_tree.create_item()
	var string_size = json_tree.get_theme_font_size("font_size") * 1.3
	tree_root.set_icon_max_width(0, string_size)

	if json_data is Dictionary:
		tree_root.set_icon(0, ICON_DICTIONARY)
		tree_root.set_icon_modulate(0, ICON_DICTIONARY_COLOR)
		tree_dict(json_data, tree_root)
	elif json_data is Array:
		tree_root.set_icon(0, ICON_ARRAY)
		tree_root.set_icon_modulate(0, ICON_ARRAY_COLOR)
		tree_array(json_data, tree_root)
	else:
		print("unknow JSON type")
		
	var window_name = ProjectSettings.get_setting("application/config/name") + " - " + input_file.get_file()
	DisplayServer.window_set_title(window_name)
	
	if not reload:
		# collapse everything and then open the root element
		json_tree.set_collapsed_recursive(true)
		tree_root.set_collapsed(false)
		
		json_tree.scroll_to_item(tree_root, 0)
		#json_text.scroll_to_line(0)
	
func tree_dict(json_data: Dictionary, tree_item: TreeItem):
	for element in json_data:
		if json_data[element] is Array:
			var tree_child = tree_item.create_child()
			var element_str: String = add_quotation(element)
			tree_child.set_icon(0, ICON_ARRAY)
			tree_child.set_icon_modulate(0, ICON_ARRAY_COLOR)
			tree_child.set_text(0, element_str)
			tree_array(json_data[element], tree_child)
		elif json_data[element] is Dictionary:
			var tree_child = tree_item.create_child()
			var element_str: String = add_quotation(element)
			tree_child.set_icon(0, ICON_DICTIONARY)
			tree_child.set_icon_modulate(0, ICON_DICTIONARY_COLOR)
			tree_child.set_text(0, element_str)
			tree_dict(json_data[element], tree_child)
		else:
			var key = add_quotation(element)
			var value = json_data[element]
			if value is String:
				value = add_quotation(value)
			var key_value: String = str(key) + " : " + str(value)
			var tree_child = tree_item.create_child()
			tree_child.set_text(0, key_value)
			
func tree_array(json_data: Array, tree_item: TreeItem):
	var i: int = 0
	for element in json_data:
		if element is Array:
			var tree_child = tree_item.create_child()
			var element_str: String = str(i)
			tree_child.set_icon(0, ICON_ARRAY)
			tree_child.set_icon_modulate(0, ICON_ARRAY_COLOR)
			tree_child.set_text(0, element_str)
			tree_array(element, tree_child)
		elif element is Dictionary:
			var tree_child = tree_item.create_child()
			var element_str: String = str(i)
			tree_child.set_icon(0, ICON_DICTIONARY)
			tree_child.set_icon_modulate(0, ICON_DICTIONARY_COLOR)
			tree_child.set_text(0, element_str)
			tree_dict(element, tree_child)
		else:
			var value = element
			if value is String:
				value = add_quotation(value)
			value = str(i) + " : " + str(value)
			var tree_child = tree_item.create_child()
			tree_child.set_text(0, value)
		
		i += 1

func add_quotation(input: String) -> String:
	return "\"" + str(input) + "\""

func get_file_parameter() -> String:
	var args = Array(OS.get_cmdline_args())
	var file_parameter: String = "" # default is none
	if args != null:
		if args.back() != null:
			var last_arg: String = args.back()
			if not last_arg.begins_with("res://") and not last_arg.begins_with("--"):
				file_parameter = last_arg
	return file_parameter

func _on_expand_all_button_pressed() -> void:
	json_tree.set_collapsed_recursive(false)


func _on_collapse_all_button_pressed() -> void:
	json_tree.set_collapsed_recursive(true)


func _on_load_json_button_pressed() -> void:
	load_json_dialog.visible = true


func _on_load_json_dialog_file_selected(path: String) -> void:
	load_json_file(path)


func _on_modified_check_timer_timeout() -> void:
	var last_modified_time = FileAccess.get_modified_time(current_loaded_file)
	if last_modified_time != modified_time:
		modified_time = last_modified_time
		if auto_reload_check.button_pressed:
			load_json_file(current_loaded_file, true)

func _on_reload_button_pressed() -> void:
	load_json_file(current_loaded_file)

func _on_check_box_toggled(toggled_on: bool) -> void:
	auto_reload_check.button_pressed = toggled_on
	if auto_reload_check.button_pressed:
		modified_time = 0
		$ModifiedCheckTimer.start()

func _on_files_dropped(files: PackedStringArray):
	var json_file = files[0]
	
	var reload: bool = false
	if json_file == current_loaded_file:
		reload = true
	load_json_file(json_file, reload)

func _on_user_theme_loaded(metatheme: Theme) -> void:
	theme = metatheme
