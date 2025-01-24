class_name TreeFinder
extends Tree

## this signal informs the TreeFinderControl that it has to thow all search results away
## the difficulty is that Tree has no change signal. So the Control user has to emit this after search relevant changes
## (e.g. add/remove/clear,change text...)
signal content_changed

var search_bg_color = Color.YELLOW
var search_text_color = Color.BLACK
var search_select_bg_color = Color.ORANGE
var search_select_text_color = Color.BLACK
var _found_items: Array[TreeItem] = []

func _init() -> void:
	content_changed.connect(_on_content_changed)
	
func set_collapsed_recursive(enable: bool, tree_item: TreeItem = null):
	if tree_item == null:
		tree_item = get_root()
		
	if tree_item != null:
		tree_item.set_collapsed_recursive(enable)

func find(search_text: String, ignore_case: bool, parent: TreeItem = null) -> int:
	if parent == null:
		parent = get_root()
		_found_items.clear()
	
	# if still null, then it's really empty
	if parent == null:
		return 0
	
	for child_item: TreeItem in parent.get_children():
		find(search_text, ignore_case, child_item)
	
	for i in columns:
		parent.clear_custom_color(i)
		parent.clear_custom_bg_color(i)
	
		var item_text := parent.get_text(i)
		if ignore_case:
			item_text = item_text.to_lower()
			search_text = search_text.to_lower()
		if item_text.contains(search_text):
			_found_items.push_back(parent)
		
	return _found_items.size()
	
func get_found_items_count() -> int:
	return _found_items.size()
	
func scroll_found_item(item_nr: int):
	if get_found_items_count() > 0:
		color_found_items()
		item_nr = min(item_nr, get_found_items_count())
		var select_item := _found_items[item_nr]
		scroll_to_item(select_item, 0)
		select_item.set_custom_bg_color(0, search_select_bg_color)
		select_item.set_custom_color(0, search_select_text_color)

func color_found_items():
	for found_item in _found_items:
		# this logic colors all found columns. If only the row cell should be colored it needs to be changed
		for i in columns:
			found_item.set_custom_bg_color(i, search_bg_color)
			found_item.set_custom_color(i, search_text_color)

func _on_content_changed():
	_found_items.clear()
