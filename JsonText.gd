extends TextEdit

func _ready() -> void:
	# minimal syntax highlighting
	syntax_highlighter = CodeHighlighter.new()
	syntax_highlighter.add_color_region('"', '"', Color.YELLOW_GREEN)
	

func set_unformated_text(unformated_text: String):
	text = unformated_text

# TODO: implement Ctrl-C
func _copy(caret_index: int) -> void:
	var selected_text : String = get_selected_text()
	DisplayServer.clipboard_set(selected_text)
