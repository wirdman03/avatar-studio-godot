class_name AvatarStudioEditor
extends Control

signal save_requested(choices: Dictionary)
signal appearance_changed(choices: Dictionary)
signal catalogue_loaded
signal catalogue_failed(error: Error)

@export_file("*.json") var catalogue_path: String
@export var title := "Crée ton avatar"
const INK := Color("#142328")
const PAPER := Color("#F5F3EA")
const ACCENT := Color("#d6e6a5")

var _avatar := AvatarStudioCharacter.new()
var _name: Label
var _viewport: SubViewport
var _camera: Camera3D
var _stage: SubViewportContainer
var _items: HBoxContainer
var _tabs: ButtonGroup
var _category: Dictionary
var _status: Label
var _turn := -0.16
var _zoom_face := false

func _ready() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = INK
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var column := VBoxContainer.new()
	add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 18
	column.offset_top = 16
	column.offset_right = -18
	column.offset_bottom = -16
	column.add_theme_constant_override("separation", 12)
	_add_header(column)
	_add_stage(column)
	_add_tray(column)

	var result := _avatar.configure(catalogue_path)
	if result != OK:
		show_status("Le catalogue n’a pas pu être chargé.")
		catalogue_failed.emit(result)
		return
	_name.text = _avatar.get_display_name()
	_add_categories()
	_set_camera()
	_apply_rotation()
	_avatar.appearance_changed.connect(func(choices: Dictionary) -> void:
		show_status("")
		appearance_changed.emit(choices)
	)
	catalogue_loaded.emit()

func get_character() -> AvatarStudioCharacter:
	return _avatar

func restore(choices: Dictionary) -> bool:
	if not _avatar.restore(choices):
		return false
	if not _category.is_empty():
		_show_options(_category)
	return true

func show_status(message: String) -> void:
	_status.text = message

func _save_appearance() -> void:
	if not _avatar.get_choices().is_empty():
		save_requested.emit(_avatar.get_choices())

func _add_header(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 2)
	row.add_child(titles)
	titles.add_child(_label("AVATAR STUDIO", 13, ACCENT))
	titles.add_child(_label(title, 28, PAPER))
	var done := Button.new()
	done.text = "Garder"
	done.custom_minimum_size = Vector2(81, 46)
	_style_button(done, true)
	done.pressed.connect(_save_appearance)
	row.add_child(done)

func _add_stage(parent: VBoxContainer) -> void:
	var stage := Panel.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.custom_minimum_size.y = 275
	stage.add_theme_stylebox_override("panel", _box(Color("#446c69"), Color("#678a86"), 18))
	parent.add_child(stage)

	var background := ColorRect.new()
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader_material := ShaderMaterial.new()
	shader_material.shader = preload("res://addons/avatar_studio/studio.gdshader")
	background.material = shader_material
	stage.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_stage = SubViewportContainer.new()
	_stage.stretch = true
	_stage.mouse_default_cursor_shape = Control.CURSOR_DRAG
	stage.add_child(_stage)
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.gui_input.connect(_turn_on_drag)
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.world_3d = World3D.new()
	_viewport.msaa_3d = Viewport.MSAA_2X
	_stage.add_child(_viewport)
	_viewport.add_child(_avatar)

	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("#ffe2db")
	environment.environment.ambient_light_energy = 0.54
	_viewport.add_child(environment)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.current = true
	_viewport.add_child(_camera)
	_stage.resized.connect(_set_camera)
	_set_camera()
	_add_light(Vector3(-38, -28, 0), Color("#ffe0d0"), 1.10)
	_add_light(Vector3(-15, 39, 0), Color("#ded6fb"), 0.36)
	_add_light(Vector3(-30, 160, 0), Color("#ffb0ac"), 0.7)

	_name = _label("", 16, PAPER)
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(_name)
	_name.position = Vector2(14, 12)

	var zoom := Button.new()
	zoom.name = "Zoom"
	zoom.text = "Zoom visage"
	_style_button(zoom)
	zoom.add_theme_font_size_override("font_size", 13)
	zoom.custom_minimum_size = Vector2(114, 39)
	stage.add_child(zoom)
	zoom.size = zoom.custom_minimum_size
	zoom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_KEEP_SIZE, 12)
	zoom.pressed.connect(func() -> void:
		_zoom_face = not _zoom_face
		zoom.text = "Plein pied" if _zoom_face else "Zoom visage"
		_set_camera()
	)
	var tip := _label("Glisse pour tourner", 13, PAPER)
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(tip)
	tip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_KEEP_SIZE, 14)

func _add_light(orientation: Vector3, color: Color, energy: float) -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = orientation
	light.light_color = color
	light.light_energy = energy
	_viewport.add_child(light)

func _set_camera() -> void:
	var bounds := _avatar.get_model_bounds()
	if bounds.size.y <= 0.001:
		bounds = AABB(Vector3(-0.35, 0, -0.25), Vector3(0.70, 2.0, 0.50))
	var center := bounds.get_center()
	var height := bounds.position.y + bounds.size.y * (0.83 if _zoom_face else 0.51)
	var aspect := maxf(0.05, _stage.size.x / maxf(1, _stage.size.y))
	var frame_height := bounds.size.y * (0.47 if _zoom_face else 1.16)
	var frame_width := bounds.size.x * (0.95 if _zoom_face else 1.14)
	_camera.position = Vector3(center.x, height + 0.065 * bounds.size.y, center.z + maxf(4.0, bounds.size.length() * 2))
	_camera.look_at(Vector3(center.x, height, center.z), Vector3.UP)
	_camera.size = maxf(frame_height, frame_width / aspect)

func _apply_rotation() -> void:
	_avatar.rotation.y = _turn

func _turn_on_drag(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_turn += event.relative.x * 0.012
		_apply_rotation()
		_stage.accept_event()
	elif event is InputEventScreenDrag:
		_turn += event.relative.x * 0.012
		_apply_rotation()
		_stage.accept_event()

func _add_tray(parent: VBoxContainer) -> void:
	var tabs := HFlowContainer.new()
	tabs.name = "Categories"
	tabs.add_theme_constant_override("h_separation", 6)
	tabs.add_theme_constant_override("v_separation", 6)
	parent.add_child(tabs)
	_tabs = ButtonGroup.new()
	_items = HBoxContainer.new()
	_items.add_theme_constant_override("separation", 9)
	parent.add_child(_items)
	_status = _label("", 13, ACCENT)
	_status.custom_minimum_size.y = 20
	parent.add_child(_status)

func _add_categories() -> void:
	for category: Dictionary in _avatar.get_categories():
		var button := Button.new()
		button.text = category["label"]
		button.toggle_mode = true
		button.button_group = _tabs
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 44
		_style_button(button, true)
		button.add_theme_font_size_override("font_size", 14)
		_items.get_parent().get_node("Categories").add_child(button)
		button.pressed.connect(_show_options.bind(category))
		if _category.is_empty():
			button.set_pressed_no_signal(true)
			_show_options(category)

func _show_options(category: Dictionary) -> void:
	_category = category
	for child in _items.get_children():
		_items.remove_child(child)
		child.queue_free()
	var selection := ButtonGroup.new()
	var current := _avatar.get_choices()
	for item: Dictionary in category["items"]:
		var button := Button.new()
		button.text = item["label"]
		if item.has("color"):
			button.icon = _colour_swatch(Color.html(item["color"]))
			button.add_theme_constant_override("icon_max_width", 22)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_group = selection
		button.set_pressed_no_signal(current.get(category["id"]) == item["id"])
		button.custom_minimum_size.y = 62
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(button)
		_items.add_child(button)
		button.pressed.connect(func() -> void:
			_avatar.choose(category["id"], item["id"])
		)

func _label(value: String, points: int, tone: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", points)
	label.add_theme_color_override("font_color", tone)
	return label

func _box(fill: Color, border: Color, corner: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(corner)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style

func _style_button(button: Button, accent := false) -> void:
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", PAPER)
	button.add_theme_color_override("font_hover_color", PAPER)
	button.add_theme_color_override("font_pressed_color", INK if accent else PAPER)
	button.add_theme_stylebox_override("normal", _box(Color("#243a3d"), Color("#4d6666"), 11))
	button.add_theme_stylebox_override("hover", _box(Color("#3d5354"), ACCENT, 11))
	button.add_theme_stylebox_override("pressed", _box(ACCENT if accent else Color("#4b6260"), ACCENT, 11))
	button.add_theme_stylebox_override("hover_pressed", _box(ACCENT if accent else Color("#536d65"), ACCENT, 11))
	var focus := _box(Color.TRANSPARENT, PAPER, 11)
	focus.draw_center = false
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _colour_swatch(colour: Color) -> Texture2D:
	var image := Image.create(22, 22, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in 22:
		for x in 22:
			if Vector2(x - 10.5, y - 10.5).length_squared() <= 100.0:
				image.set_pixel(x, y, colour)
	return ImageTexture.create_from_image(image)
