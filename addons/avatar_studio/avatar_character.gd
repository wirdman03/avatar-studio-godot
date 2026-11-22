class_name AvatarStudioCharacter
extends Node3D
## Loads a local catalogue and applies independent appearance choices to a 3D model.

signal appearance_changed(choices: Dictionary)

var _catalogue: Dictionary = {}
var _choices: Dictionary = {}
var _model: Node3D
var _groups: Dictionary = {}
var _morphs: Dictionary = {}
var _materials: Dictionary = {}
var _items: Dictionary = {}
var _defaults: Dictionary = {}
var _bounds := AABB()

func configure(catalogue_path: String) -> Error:
	if _model != null:
		return ERR_ALREADY_IN_USE
	if not catalogue_path.begins_with("res://") or not FileAccess.file_exists(catalogue_path):
		return ERR_FILE_NOT_FOUND
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(catalogue_path)) != OK:
		return ERR_PARSE_ERROR
	var document: Variant = json.data
	if not document is Dictionary:
		return ERR_INVALID_DATA
	if not document.get("model") is String or not document.get("categories") is Array or not document.get("default") is Dictionary:
		return ERR_INVALID_DATA
	var model_path: String = document["model"]
	if not model_path.begins_with("res://"):
		model_path = catalogue_path.get_base_dir().path_join(model_path).simplify_path()
	if not model_path.begins_with("res://") or not ResourceLoader.exists(model_path, "PackedScene"):
		return ERR_FILE_NOT_FOUND
	var packed := load(model_path) as PackedScene
	if packed == null:
		return ERR_INVALID_DATA
	var instance := packed.instantiate()
	_model = instance as Node3D
	if _model == null:
		instance.free()
		return ERR_INVALID_DATA
	_catalogue = document
	_index_model(_model)
	if not _validate_catalogue():
		_model.free()
		_model = null
		_catalogue.clear()
		_groups.clear()
		_morphs.clear()
		_materials.clear()
		_items.clear()
		return ERR_INVALID_DATA
	_defaults = document["default"].duplicate()
	_choices = _defaults.duplicate()
	_apply()
	add_child(_model)
	_cache_bounds()
	return OK

func _cache_bounds() -> void:
	var has_bounds := false
	for node in _model.find_children("*", "MeshInstance3D", true, false):
		if node.mesh == null:
			continue
		var local_transform: Transform3D = node.transform
		var parent := node.get_parent() as Node3D
		while parent != null and parent != self:
			local_transform = parent.transform * local_transform
			parent = parent.get_parent() as Node3D
		var local_bounds: AABB = local_transform * node.get_aabb()
		_bounds = _bounds.merge(local_bounds) if has_bounds else local_bounds
		has_bounds = true

func get_model_bounds() -> AABB:
	return _bounds

func _index_model(node: Node) -> void:
	if node is Node3D:
		var key := String(node.name)
		if not _groups.has(key):
			_groups[key] = node
		else:
			_groups[key] = null
	if node is MeshInstance3D and node.mesh != null:
		var vertex_paint: Variant = _catalogue.get("vertexColorMaterials", [])
		for surface in node.mesh.get_surface_count():
			var material := node.mesh.surface_get_material(surface) as StandardMaterial3D
			if material == null:
				continue
			var key := material.resource_name
			if not _materials.has(key):
				_materials[key] = []
			var override := material.duplicate() as StandardMaterial3D
			if vertex_paint is Array and vertex_paint.has(key):
				override.vertex_color_use_as_albedo = true
			_materials[key].append([override, material.albedo_color])
			node.set_surface_override_material(surface, override)
		for index in node.get_blend_shape_count():
			var key := String(node.mesh.get_blend_shape_name(index))
			if not _morphs.has(key):
				_morphs[key] = []
			_morphs[key].append([node, index])
	for child in node.get_children():
		_index_model(child)

func _validate_catalogue() -> bool:
	var targets: Dictionary = {}
	var defaults: Dictionary = _catalogue["default"]
	for category in _catalogue["categories"]:
		if not category is Dictionary or not category.get("id") is String or not category.get("label") is String or not category.get("items") is Array:
			return false
		for key_name in ["section", "sectionLabel", "railGroup", "railGroupLabel", "railLabel", "framing", "heading", "thumbnailFraming", "paletteFor", "palettePlacement"]:
			if category.has(key_name) and not category[key_name] is String:
				return false
		var key: String = category["id"]
		if key.is_empty() or _items.has(key):
			return false
		var options: Dictionary = {}
		for item in category["items"]:
			if not item is Dictionary or not item.get("id") is String or not item.get("label") is String or not item.get("hint", "") is String:
				return false
			var item_id: String = item["id"]
			if item_id.is_empty() or options.has(item_id):
				return false
			if not _validate_option(item, key, targets):
				return false
			options[item_id] = item
		if not options.has(defaults.get(key)):
			return false
		_items[key] = options
	return not _items.is_empty() and _items.size() == defaults.size() and _validate_palette_links()

func _validate_palette_links() -> bool:
	var targets: Dictionary = {}
	for category: Dictionary in _catalogue["categories"]:
		var target: String = category.get("paletteFor", "")
		if not target.is_empty():
			if target == category["id"] or not _items.has(target) or targets.has(target):
				return false
			targets[target] = category["id"]
			var choices: Variant = category.get("paletteItems", [])
			if not choices is Array:
				return false
			for choice in choices:
				if not choice is String or not _items[target].has(choice):
					return false
		if not target.is_empty() or category.get("palettePlacement") == "preview":
			for item: Dictionary in category["items"]:
				if not _valid_color(item.get("color")):
					return false
	for palette_id in targets.values():
		if targets.has(palette_id):
			return false
	return true

func _validate_option(item: Dictionary, category: String, targets: Dictionary) -> bool:
	var actions := ["group", "morph", "material", "clear"]
	var used := actions.filter(func(key: String) -> bool: return item.has(key))
	if used.size() != 1:
		return false
	var kind: String = used[0]
	if kind == "clear":
		return item["clear"] == true
	if not item[kind] is String:
		return false
	var name: String = item[kind]
	if not _claim_target(kind, name, category, targets):
		return false
	match kind:
		"group":
			return _groups.get(name) != null and _groups[name] != _model
		"morph":
			var value: Variant = item.get("weight")
			return _morphs.has(name) and (value is float or value is int) and is_finite(float(value)) and float(value) >= 0.0 and float(value) <= 1.0
		"material":
			if not _materials.has(name) or not _valid_color(item.get("color")):
				return false
			var extra: Variant = item.get("tints", {})
			if not extra is Dictionary or extra.has(name):
				return false
			for material in extra:
				if not _materials.has(material) or not _valid_color(extra[material]) or not _claim_target(kind, material, category, targets):
					return false
			return true
	return false

func _claim_target(kind: String, name: String, category: String, targets: Dictionary) -> bool:
	var target := kind + ":" + name
	if targets.has(target) and targets[target] != category:
		return false
	targets[target] = category
	return true

func _valid_color(value: Variant) -> bool:
	return value is String and Color.html_is_valid(value)

func get_display_name() -> String:
	return str(_catalogue.get("name", "Avatar"))

func get_categories() -> Array:
	var categories: Array = _catalogue.get("categories", [])
	return categories.duplicate(true)

func get_choices() -> Dictionary:
	return _choices.duplicate()

func choose(category: String, option: String) -> bool:
	if not _items.has(category) or not _items[category].has(option):
		return false
	var next := _choices.duplicate()
	next[category] = option
	return restore(next)

func restore(choices: Dictionary) -> bool:
	if _model == null or _choices.size() != choices.size():
		return false
	for category in _items:
		if not _items[category].has(choices.get(category)):
			return false
	if choices != _choices:
		_choices = choices.duplicate()
		_apply()
		appearance_changed.emit(get_choices())
	return true

func reset() -> void:
	restore(_defaults)

func _apply() -> void:
	for category in _items:
		for item in _items[category].values():
			if item.has("group"):
				_groups[item["group"]].visible = false
	for entries in _morphs.values():
		for entry in entries:
			entry[0].set_blend_shape_value(entry[1], 0.0)
	for entries in _materials.values():
		for entry in entries:
			entry[0].albedo_color = entry[1]
	for category in _items:
		var item: Dictionary = _items[category][_choices[category]]
		if item.has("group"):
			_groups[item["group"]].visible = true
		elif item.has("morph"):
			for entry in _morphs[item["morph"]]:
				entry[0].set_blend_shape_value(entry[1], item["weight"])
		elif item.has("material"):
			_tint(item["material"], item["color"])
			var extra: Dictionary = item.get("tints", {})
			for material in extra:
				_tint(material, extra[material])

func _tint(material: String, color: String) -> void:
	for entry in _materials[material]:
		entry[0].albedo_color = Color.html(color)
