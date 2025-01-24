@tool
class_name TreeFinderControl
extends HBoxContainer

@export var tree_finder: TreeFinder
@export var ignore_case: bool = false : set=set_ignore_case
@export var show_ignore_case: bool = false : set=set_show_ignore_case

var search_position: int = 0

func _ready() -> void:
	$SearchInput.text_changed.connect(_on_search_input_text_changed)
	$IgnoreCase.toggled.connect(_on_ignore_case_toggled)
	$SearchPrev.pressed.connect(_on_search_prev_pressed)
	$SearchNext.pressed.connect(_on_search_next_pressed)
	tree_finder.content_changed.connect(_on_tree_content_changed)
	
func update_found_label(select: int, complete: int):
	if complete > 0:
		$FoundItems.text = str(select) + " / " + str(complete)
	else:
		$FoundItems.text = ""

func set_ignore_case(value: bool):
	ignore_case = value
	$IgnoreCase.button_pressed = value

		
func set_show_ignore_case(value: bool):
	show_ignore_case = value
	$IgnoreCase.visible = value
	
func _on_search_input_text_changed(new_text: String) -> void:
	var found = tree_finder.find(new_text, $IgnoreCase.button_pressed)
	update_found_label(1, tree_finder.get_found_items_count())
	if found:
		tree_finder.set_collapsed_recursive(false)
		tree_finder.color_found_items()
		tree_finder.scroll_found_item(0)

func _on_ignore_case_toggled(toggled_on: bool) -> void:
	_on_search_input_text_changed($SearchInput.text)

func _on_search_prev_pressed() -> void:
	search_position = wrapi(search_position - 1, 0, tree_finder.get_found_items_count())
	tree_finder.scroll_found_item(search_position)
	update_found_label(search_position + 1, tree_finder.get_found_items_count())


func _on_search_next_pressed() -> void:
	search_position = wrapi(search_position + 1, 0, tree_finder.get_found_items_count())
	tree_finder.scroll_found_item(search_position)
	update_found_label(search_position + 1, tree_finder.get_found_items_count())

func _on_tree_content_changed():
	$SearchInput.text = ""
	update_found_label(0, 0)
	search_position = 0
