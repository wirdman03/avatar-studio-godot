class_name AvatarStudioEditor
extends Control

signal save_requested(choices: Dictionary)
signal close_requested
signal appearance_changed(choices: Dictionary)
signal catalogue_loaded
signal catalogue_failed(error: Error)

@export_file("*.json") var catalogue_path: String
@export var title := "Mon avatar"
@export var show_close_button := false
const INK := Color("#111718")
const PAPER := Color("#F3F8F6")
const ACCENT := Color("#69DDF5")
const MUTED := Color("#AEBFBC")
const TRAY := Color("#182121")
const RAIL := Color("#293535")
const EDGE := Color("#405454")
const TARGET := 54.0
const PORTRAIT_TILE_HEIGHT := 94.0
const PORTRAIT_SWATCH_HEIGHT := 65.0
const GRID_GAP := 7
const CATEGORY_ICONS := preload("res://addons/avatar_studio/category_icons.gd")

var _avatar := AvatarStudioCharacter.new()
var _emphasis := SystemFont.new()
var _column: VBoxContainer
var _header: HBoxContainer
var _header_title: Label
var _current_choice: Label
var _name: Label
var _viewport: SubViewport
var _camera: Camera3D
var _stage: SubViewportContainer
var _workspace: BoxContainer
var _stage_panel: Panel
var _history: HBoxContainer
var _tip: Label
var _tray_content: VBoxContainer
var _category_rail: ScrollContainer
var _category_row: HBoxContainer
var _category_title: Label
var _visible_categories: Array = []
var _all_categories: Array = []
var _tray: PanelContainer
var _undo_button: Button
var _redo_button: Button
var _undo: Array[Dictionary] = []
var _redo: Array[Dictionary] = []
var _wide := false
var _layout_ready := false
var _items: GridContainer
var _choice_scroll: ScrollContainer
var _family_subbar: HBoxContainer
var _section_bar: HBoxContainer
var _section_dock: PanelContainer
var _section_groups: Dictionary = {}
var _section_categories: Dictionary = {}
var _thumbnail_tiles: Dictionary = {}
var _category_families: Dictionary = {}
var _family_buttons: Dictionary = {}
var _family_tabs: Dictionary = {}
var _shown_family := ""
var _garment_palettes: Dictionary = {}
var _palette: PanelContainer
var _palette_list: VBoxContainer
var _framing_button: Button
var _thumb_renderer: SubViewport
var _move: Tween
var _category: Dictionary
var _status: Label
var _turn := -0.16
var _mouse_drag := false
var _touch_drag := -1
var _framing := "face"

func _ready() -> void:
	_emphasis.font_names = PackedStringArray(["Inter", "SF Pro Text", "Roboto", "Noto Sans", "Arial"])
	_emphasis.font_weight = 700
	var backdrop := ColorRect.new()
	backdrop.color = INK
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var column := VBoxContainer.new()
	_column = column
	add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 10
	column.offset_top = 9
	column.offset_right = -10
	column.offset_bottom = -8
	column.add_theme_constant_override("separation", 8)
	_add_header(column)
	_workspace = BoxContainer.new()
	_workspace.vertical = true
	_workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_workspace.add_theme_constant_override("separation", 7)
	column.add_child(_workspace)
	_add_stage(_workspace)
	_add_tray(_workspace)
	resized.connect(_layout_editor)
	_layout_editor()

	var result := _avatar.configure(catalogue_path)
	if result != OK:
		show_status("Le catalogue n’a pas pu être chargé.")
		catalogue_failed.emit(result)
		return
	_name.text = _avatar.get_display_name()
	_thumb_renderer = preload("res://addons/avatar_studio/thumbnail_renderer.gd").new()
	add_child(_thumb_renderer)
	_thumb_renderer.setup(catalogue_path)
	_add_categories()
	_set_camera()
	_apply_rotation()
	_avatar.appearance_changed.connect(func(choices: Dictionary) -> void:
		show_status("")
		_preview_changed()
		appearance_changed.emit(choices)
	)
	catalogue_loaded.emit()

func get_character() -> AvatarStudioCharacter:
	return _avatar

func restore(choices: Dictionary) -> bool:
	if not _avatar.restore(choices):
		return false
	_undo.clear()
	_redo.clear()
	_update_history_buttons()
	if not _category.is_empty():
		_show_options(_category)
	return true

func show_status(message: String) -> void:
	_status.text = message
	_status.visible = not message.is_empty()

func _save_appearance() -> void:
	if not _avatar.get_choices().is_empty():
		save_requested.emit(_avatar.get_choices())

func _add_header(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	_header = row
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	if show_close_button:
		var close := _icon_button("close", "Fermer")
		close.add_theme_constant_override("icon_max_width", 34)
		close.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		close.pressed.connect(func() -> void: close_requested.emit())
		row.add_child(close)
	_header_title = _label(title, 27, PAPER)
	_header_title.add_theme_font_override("font", _emphasis)
	_header_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_header_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(_header_title)
	var done := Button.new()
	done.text = "Enregistrer"
	done.custom_minimum_size = Vector2(122, TARGET)
	_style_button(done, true)
	done.add_theme_font_override("font", _emphasis)
	done.add_theme_font_size_override("font_size", 18)
	var save_box := _box(ACCENT, ACCENT, 12)
	save_box.expand_margin_top = -5
	save_box.expand_margin_bottom = -5
	var save_hover := save_box.duplicate() as StyleBoxFlat
	save_hover.bg_color = Color("#A4EEFC")
	done.add_theme_stylebox_override("normal", save_box)
	done.add_theme_stylebox_override("pressed", save_box)
	done.add_theme_stylebox_override("hover", save_hover)
	done.add_theme_color_override("font_color", INK)
	done.add_theme_color_override("font_hover_color", INK)
	done.add_theme_color_override("font_focus_color", INK)
	done.pressed.connect(_save_appearance)
	row.add_child(done)

func _add_stage(parent: BoxContainer) -> void:
	var stage := Panel.new()
	_stage_panel = stage
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.custom_minimum_size.y = 226
	stage.clip_contents = true
	stage.add_theme_stylebox_override("panel", _box(Color("#102B25"), EDGE, 18))
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
	environment.environment.ambient_light_color = Color("#eef6f2")
	environment.environment.ambient_light_energy = 0.53
	_viewport.add_child(environment)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.current = true
	_viewport.add_child(_camera)
	_stage.resized.connect(_set_camera)
	_set_camera()
	_add_light(Vector3(-38, -28, 0), Color("#fff3e4"), 0.94)
	_add_light(Vector3(-15, 39, 0), Color("#dae9f7"), 0.40)
	_add_light(Vector3(-30, 160, 0), Color("#a6f8d8"), 0.58)

	_name = _label("", 14, PAPER)
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(_name)
	_name.position = Vector2(14, 12)

	var zoom := _icon_button("full", "Plein pied")
	_framing_button = zoom
	zoom.name = "Zoom"
	stage.add_child(zoom)
	zoom.size = zoom.custom_minimum_size
	zoom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_KEEP_SIZE, 12)
	zoom.pressed.connect(func() -> void:
		_focus("face" if _framing == "full" else "full")
	)
	var history := HBoxContainer.new()
	_history = history
	history.add_theme_constant_override("separation", 5)
	stage.add_child(history)
	history.position = Vector2(13, 37)
	_undo_button = _history_button("undo", "Annuler", history, _undo_change)
	_redo_button = _history_button("redo", "Rétablir", history, _redo_change)
	_update_history_buttons()
	var tip := _label("Glisse pour tourner", 13, PAPER)
	_tip = tip
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(tip)
	tip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_KEEP_SIZE, 14)
	_add_garment_palette(stage)

func _add_garment_palette(stage: Panel) -> void:
	_palette = PanelContainer.new()
	_palette.name = "GarmentPalette"
	_palette.accessibility_name = "Couleurs du vêtement"
	_palette.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	stage.add_child(_palette)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.follow_focus = true
	_palette.add_child(scroll)
	_palette_list = VBoxContainer.new()
	_palette_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_palette_list)
	_palette.hide()
	stage.resized.connect(_position_palette)

func _position_palette() -> void:
	if not _palette.visible:
		return
	var height := minf(_palette_list.get_combined_minimum_size().y, maxf(TARGET, _stage_panel.size.y - 134))
	_palette.size = Vector2(TARGET, height)
	_palette.position = Vector2(_stage_panel.size.x - _palette.size.x - 13, (_stage_panel.size.y - height) * 0.5)

func _history_button(icon: String, label: String, parent: HBoxContainer, action: Callable) -> Button:
	var button := _icon_button(icon, label)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _icon_button(icon: String, label: String) -> Button:
	var button := Button.new()
	button.icon = CATEGORY_ICONS.get_icon(icon)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", 27)
	button.tooltip_text = label
	button.accessibility_name = label
	button.custom_minimum_size = Vector2(TARGET, TARGET)
	_style_button(button)
	var box := _box(Color("#233131"), EDGE, 12)
	box.expand_margin_top = -4
	box.expand_margin_bottom = -4
	button.add_theme_stylebox_override("normal", box)
	button.add_theme_stylebox_override("disabled", box)
	button.add_theme_color_override("icon_normal_color", PAPER)
	button.add_theme_color_override("icon_disabled_color", Color(MUTED, 0.46))
	return button

func _layout_editor() -> void:
	var large := size.x >= 740
	var changed := not _layout_ready or _wide != large
	_wide = large
	_layout_ready = true
	_workspace.vertical = not _wide
	_workspace.add_theme_constant_override("separation", 7 if _wide else 0)
	_column.offset_left = 10 if _wide else 0
	_column.offset_right = -10 if _wide else 0
	_column.offset_top = 9 if _wide else 0
	_column.offset_bottom = -8 if _wide else 0
	_stage_panel.custom_minimum_size.y = 226 if _wide else maxf(196, roundf(size.y * 0.425))
	_stage_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL if _wide else Control.SIZE_FILL
	_tray.custom_minimum_size.x = clampf(size.x * 0.39, 310, 490) if _wide else 0
	_tray.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_section_dock.visible = _section_groups.size() > 1
	_tray_content.move_child(_section_dock, 0 if _wide else _tray_content.get_child_count() - 1)
	var panel := _box(TRAY, EDGE, 18)
	if not _wide:
		panel.border_width_left = 0
		panel.border_width_right = 0
		panel.border_width_bottom = 0
		panel.corner_radius_bottom_left = 0
		panel.corner_radius_bottom_right = 0
	_tray.add_theme_stylebox_override("panel", panel)
	_place_header()
	_name.visible = _wide
	_tip.visible = _wide
	if _wide:
		_history.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_KEEP_SIZE)
		_history.position = Vector2(13,37)
		_tip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_KEEP_SIZE, 14)
	else:
		_history.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_KEEP_SIZE, 12)
		_tip.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_KEEP_SIZE)
		_tip.position = Vector2(14,33)
	if changed and not _all_categories.is_empty():
		_refresh_categories(str(_category.get("section","appearance")), str(_category.get("id","")))
	_fit_grid()

func _place_header() -> void:
	if _wide:
		if _header.get_parent() != _column:
			_header.reparent(_column, false)
			_column.move_child(_header, 0)
		_header_title.add_theme_font_size_override("font_size", 27)
	else:
		if _header.get_parent() != _stage_panel:
			_header.reparent(_stage_panel, false)
		_header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		_header.offset_left = 14
		_header.offset_right = -14
		_header.offset_top = 12
		_header.offset_bottom = 56
		_header_title.add_theme_font_size_override("font_size", 26)

func _select_option(category: String, item: String) -> void:
	var previous := _avatar.get_choices()
	if previous.get(category) == item or not _avatar.choose(category, item):
		return
	_update_choice_caption()
	if _garment_palettes.has(category):
		_show_garment_palette()
	elif category == _category.get("id") and _category.get("palettePlacement") == "preview":
		_show_options(_category, false)
	elif _garment_palettes.get(_category.get("id"), {}).get("id") == category:
		_request_thumbnails()
	_undo.append(previous)
	if _undo.size() > 40:
		_undo.pop_front()
	_redo.clear()
	_update_history_buttons()

func _undo_change() -> void:
	if _undo.is_empty():
		return
	var previous: Dictionary = _undo.pop_back()
	_redo.append(_avatar.get_choices())
	_avatar.restore(previous)
	_show_options(_category, false)
	_update_history_buttons()

func _redo_change() -> void:
	if _redo.is_empty():
		return
	var next: Dictionary = _redo.pop_back()
	_undo.append(_avatar.get_choices())
	_avatar.restore(next)
	_show_options(_category, false)
	_update_history_buttons()

func _update_history_buttons() -> void:
	_undo_button.disabled = _undo.is_empty()
	_redo_button.disabled = _redo.is_empty()

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
	var height_ratio := (0.815 if _wide else 0.763) if _framing == "face" else 0.51
	if _framing == "upper":
		height_ratio = 0.68
	var height := bounds.position.y + bounds.size.y * height_ratio
	var aspect := maxf(0.05, _stage.size.x / maxf(1, _stage.size.y))
	var frame_height := bounds.size.y * (0.51 if _framing == "face" else 1.20)
	if _framing == "upper":
		frame_height = bounds.size.y * 0.67
	var frame_width := bounds.size.x * 1.18
	_camera.position = Vector3(center.x, height + 0.065 * bounds.size.y, center.z + maxf(4.0, bounds.size.length() * 2))
	_camera.look_at(Vector3(center.x, height, center.z), Vector3.UP)
	_camera.size = maxf(frame_height, frame_width / aspect)
	_camera.h_offset = _camera.size * 0.07 if is_instance_valid(_palette) and _palette.visible else 0.0

func _apply_rotation() -> void:
	_avatar.rotation.y = _turn

func _turn_on_drag(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_drag = event.pressed
		_stage.accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed and _touch_drag < 0:
			_touch_drag = event.index
		elif not event.pressed and _touch_drag == event.index:
			_touch_drag = -1
		_stage.accept_event()
	elif event is InputEventMouseMotion and _mouse_drag and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_turn += event.relative.x * 0.012
		_apply_rotation()
		_stage.accept_event()
	elif event is InputEventScreenDrag and _touch_drag == event.index:
		_turn += event.relative.x * 0.012
		_apply_rotation()
		_stage.accept_event()

func _focus(mode: String) -> void:
	_framing = mode if mode in ["face", "upper", "full"] else "full"
	var label := "Zoom visage" if _framing == "full" else "Plein pied"
	_framing_button.icon = CATEGORY_ICONS.get_icon("portrait" if _framing == "full" else "full")
	_framing_button.tooltip_text = label
	_framing_button.accessibility_name = label
	_set_camera()

func _preview_changed() -> void:
	if _move != null:
		_move.kill()
	_avatar.position.y = 0
	_move = create_tween()
	_move.tween_property(_avatar, "position:y", 0.016, 0.09).set_trans(Tween.TRANS_SINE)
	_move.tween_property(_avatar, "position:y", 0.0, 0.14).set_trans(Tween.TRANS_SINE)

func _add_tray(parent: BoxContainer) -> void:
	_tray = PanelContainer.new()
	_tray.add_theme_stylebox_override("panel", _box(TRAY, Color("#4A3445"), 18))
	parent.add_child(_tray)

	var content := VBoxContainer.new()
	_tray_content = content
	content.add_theme_constant_override("separation", 6)
	_tray.add_child(content)

	var category_header := PanelContainer.new()
	var category_surface := _box(Color("#2B3839"), Color("#3B4A4A"), 13)
	category_surface.set_content_margin_all(3)
	category_surface.content_margin_left = 13
	category_header.add_theme_stylebox_override("panel", category_surface)
	content.add_child(category_header)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 6)
	category_header.add_child(header_row)
	_category_title = _label("", 24, PAPER)
	_category_title.add_theme_font_override("font", _emphasis)
	_category_title.custom_minimum_size.x = 102
	_category_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_category_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_row.add_child(_category_title)
	_category_rail = ScrollContainer.new()
	_category_rail.name = "CategoryRail"
	_category_rail.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_category_rail.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_category_rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_category_rail.follow_focus = true
	_category_rail.gui_input.connect(_scroll_categories_with_wheel)
	header_row.add_child(_category_rail)
	_category_row = HBoxContainer.new()
	_category_row.add_theme_constant_override("separation", 2)
	_category_row.alignment = BoxContainer.ALIGNMENT_END
	_category_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_category_rail.add_child(_category_row)

	var details := PanelContainer.new()
	details.custom_minimum_size.y = TARGET
	var detail_style := _box(Color.TRANSPARENT, Color.TRANSPARENT, 0)
	detail_style.set_border_width_all(0)
	detail_style.set_content_margin_all(0)
	details.add_theme_stylebox_override("panel", detail_style)
	content.add_child(details)
	_family_subbar = HBoxContainer.new()
	_family_subbar.name = "FamilySubtabs"
	_family_subbar.add_theme_constant_override("separation", 7)
	details.add_child(_family_subbar)
	_family_subbar.hide()

	_current_choice = _label("", 14, MUTED)
	_current_choice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_current_choice.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	details.add_child(_current_choice)

	_choice_scroll = ScrollContainer.new()
	_choice_scroll.name = "OptionGallery"
	_choice_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_choice_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_choice_scroll.follow_focus = true
	_choice_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_choice_scroll.custom_minimum_size.y = 90
	var scroll_indicator := _choice_scroll.get_v_scroll_bar()
	var thumb := _box(Color("#667E7D"), Color.TRANSPARENT, 3)
	thumb.set_border_width_all(0)
	thumb.content_margin_left = 2
	thumb.content_margin_right = 2
	scroll_indicator.add_theme_stylebox_override("scroll", StyleBoxEmpty.new())
	scroll_indicator.add_theme_stylebox_override("grabber", thumb)
	scroll_indicator.add_theme_stylebox_override("grabber_highlight", thumb)
	scroll_indicator.add_theme_stylebox_override("grabber_pressed", thumb)
	_choice_scroll.resized.connect(_fit_grid)
	content.add_child(_choice_scroll)
	var grid_row := HBoxContainer.new()
	grid_row.alignment = BoxContainer.ALIGNMENT_CENTER
	grid_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_choice_scroll.add_child(grid_row)
	_items = GridContainer.new()
	_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items.add_theme_constant_override("h_separation", GRID_GAP)
	_items.add_theme_constant_override("v_separation", GRID_GAP)
	grid_row.add_child(_items)

	_status = _label("", 13, MUTED)
	_status.custom_minimum_size.y = 17
	content.add_child(_status)
	_status.hide()
	_add_section_dock(content)

func _add_categories() -> void:
	for category: Dictionary in _avatar.get_categories():
		var garment: String = category.get("paletteFor", "")
		if not garment.is_empty():
			_garment_palettes[garment] = category
			continue
		_all_categories.append(category)
		var section: String = category.get("section", "appearance")
		if not _section_groups.has(section):
			_section_groups[section] = []
		_section_groups[section].append(category)

	var section_buttons := ButtonGroup.new()
	for section: String in _section_groups:
		var label := "Tenue" if section == "wardrobe" else str(_section_groups[section][0].get("sectionLabel", "Avatar"))
		var button := _section_button(label, "outfit" if section == "wardrobe" else "face")
		button.button_group = section_buttons
		_section_bar.add_child(button)
		button.pressed.connect(_refresh_categories.bind(section))
	_section_dock.visible = _section_groups.size() > 1
	_refresh_categories(_section_groups.keys()[0])

func _add_section_dock(parent: VBoxContainer) -> void:
	_section_dock = PanelContainer.new()
	var surface := _box(Color("#202A2A"), EDGE, 18)
	surface.set_content_margin_all(5)
	_section_dock.add_theme_stylebox_override("panel", surface)
	parent.add_child(_section_dock)
	_section_bar = HBoxContainer.new()
	_section_bar.name = "EditorSections"
	_section_bar.add_theme_constant_override("separation", 6)
	_section_dock.add_child(_section_bar)

func _section_button(label: String, icon: String) -> Button:
	var button := Button.new()
	button.tooltip_text = label
	button.accessibility_name = label
	button.toggle_mode = true
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, TARGET + 4)
	_style_section(button)
	_add_button_content(button, label, icon, 18)
	button.get_node("Content/Icon").custom_minimum_size = Vector2(29, 29)
	return button

func _add_button_content(button: Button, label: String, icon: String, font_size: int) -> void:
	var row := HBoxContainer.new()
	row.name = "Content"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 9)
	button.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mark := TextureRect.new()
	mark.name = "Icon"
	mark.texture = CATEGORY_ICONS.get_icon(icon)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.custom_minimum_size = Vector2(23, 23)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(mark)
	var caption := _label(label, font_size, PAPER)
	caption.name = "Caption"
	caption.add_theme_font_override("font", _emphasis)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(caption)

func _refresh_categories(section: String, focus_id := "") -> void:
	if focus_id.is_empty():
		focus_id = _section_categories.get(section, "")
	var section_index := _section_groups.keys().find(section)
	for index in _section_bar.get_child_count():
		var button := _section_bar.get_child(index) as Button
		button.set_pressed_no_signal(index == section_index)
		button.get_node("Content/Icon").modulate = ACCENT if index == section_index else PAPER
	_visible_categories = _section_groups.get(section, _all_categories)
	_clear_controls(_category_row)
	_category_families.clear()
	_family_buttons.clear()
	_shown_family = ""
	var selected: Dictionary = {}
	for category: Dictionary in _visible_categories:
		var family: String = category.get("railGroup", category["id"])
		if not _category_families.has(family):
			_category_families[family] = []
		_category_families[family].append(category)
		if selected.is_empty() or category["id"] == focus_id:
			selected = category
	var group := ButtonGroup.new()
	for family: String in _category_families:
		var first: Dictionary = _category_families[family][0]
		var label: String = first.get("railGroupLabel", first["label"])
		var button := _category_button(first["id"], label, true)
		button.button_group = group
		button.pressed.connect(_show_options.bind(first))
		_category_row.add_child(button)
		_family_buttons[family] = button
	_category_rail.scroll_horizontal = 0
	if not selected.is_empty():
		_show_options(selected)

func _category_button(id: String, label: String, stacked: bool) -> Button:
	var button := Button.new()
	button.text = label
	button.tooltip_text = label
	button.accessibility_name = label
	if stacked:
		button.text = ""
		button.icon = CATEGORY_ICONS.get_icon(id)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width", 25)
	else:
		button.text = ""
		_add_button_content(button, label, id, 17)
		button.get_node("Content/Icon").hide()
	button.toggle_mode = true
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(48 if stacked else 62, TARGET)
	_style_tab(button, stacked)
	return button

func _show_family(category: Dictionary) -> void:
	var family: String = category.get("railGroup", category["id"])
	var family_button: Button = _family_buttons.get(family)
	if family_button != null:
		family_button.set_pressed_no_signal(true)
		_scroll_to_family.call_deferred()

	var members: Array = _category_families.get(family, [])
	var title_category: Dictionary = members[0] if members.size() > 1 and category.get("section") != "wardrobe" else category
	_category_title.text = title_category.get("railGroupLabel", title_category["label"])
	_category_title.tooltip_text = _category_title.text
	if family != _shown_family:
		_shown_family = family
		_clear_controls(_family_subbar)
		_family_tabs.clear()
		if members.size() > 1:
			var group := ButtonGroup.new()
			for member: Dictionary in members:
				var label: String = member.get("railLabel", member["label"])
				var tab := _category_button(member["id"], label, false)
				tab.tooltip_text = member.get("heading", member["label"]) if label == "Couleur" else label
				tab.accessibility_name = member.get("heading", member["label"])
				tab.button_group = group
				tab.pressed.connect(_show_options.bind(member))
				_family_tabs[member["id"]] = tab
				_family_subbar.add_child(tab)
	_family_subbar.visible = members.size() > 1
	_current_choice.visible = not _family_subbar.visible
	for id: String in _family_tabs:
		var tab: Button = _family_tabs[id]
		var active: bool = id == category["id"]
		tab.set_pressed_no_signal(active)
		tab.get_node("Content/Icon").modulate = INK if active else MUTED
		tab.get_node("Content/Caption").add_theme_color_override("font_color", INK if active else PAPER)

func _scroll_to_family() -> void:
	var button: Button = _family_buttons.get(_shown_family)
	if is_instance_valid(button) and _category_rail.is_ancestor_of(button):
		_category_rail.ensure_control_visible(button)

func _clear_controls(parent: Control) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func _scroll_categories_with_wheel(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var direction := 1 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1
		_category_rail.scroll_horizontal += direction * 62
		_category_rail.accept_event()

func _fit_grid() -> void:
	if _items == null:
		return
	var width := _choice_scroll.size.x
	var count := _items.get_child_count()
	var compact_colors: bool = not _wide and _category.get("swatches", false)
	var column_width := 76.0 if compact_colors else 98.0
	var columns := int((width + GRID_GAP) / column_width)
	if not _wide and _category.get("section") == "wardrobe":
		columns = mini(3, columns)
	_items.columns = clampi(columns, 1, maxi(1, count))

func _show_options(category: Dictionary, auto_frame := true) -> void:
	_category = category
	_section_categories[category.get("section", "appearance")] = category["id"]
	_show_family(category)
	if auto_frame:
		_focus(category.get("framing", "face"))
	_show_garment_palette()
	_choice_scroll.scroll_vertical = 0
	for child in _items.get_children():
		_items.remove_child(child)
		child.queue_free()
	var selection := ButtonGroup.new()
	var current := _avatar.get_choices()
	_update_choice_caption()
	_thumbnail_tiles.clear()
	var compact_colors: bool = not _wide and category.get("swatches", false)
	_items.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if compact_colors else Control.SIZE_EXPAND_FILL
	for item: Dictionary in category["items"]:
		if category.get("palettePlacement") == "preview" and current.get(category["id"]) != item["id"]:
			continue
		var button := Button.new()
		button.text = item["label"] if _wide else ""
		button.tooltip_text = item["label"]
		button.accessibility_name = item["label"]
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP if _wide else VERTICAL_ALIGNMENT_CENTER
		button.expand_icon = true
		button.toggle_mode = true
		button.button_group = selection
		button.set_pressed_no_signal(current.get(category["id"]) == item["id"])
		var tile_height := PORTRAIT_TILE_HEIGHT
		if _wide:
			tile_height = 126
		elif category.get("section") == "wardrobe":
			tile_height = 106
		button.custom_minimum_size = Vector2(83, tile_height)
		if compact_colors:
			button.custom_minimum_size = Vector2(66, PORTRAIT_SWATCH_HEIGHT)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(button, false, not _wide)
		button.add_theme_constant_override("icon_max_width", 152)
		button.add_theme_constant_override("h_separation", 4)
		_items.add_child(button)
		if category.get("swatches", false) and item.has("color"):
			_style_color_option(button, Color(item["color"]))
		else:
			_thumbnail_tiles[item["id"]] = button
		if not _wide:
			_add_selection_mark(button)
		button.pressed.connect(func() -> void:
			_select_option(category["id"], item["id"])
		)
	_fit_grid()
	_request_thumbnails()

func _request_thumbnails() -> void:
	if _thumb_renderer != null:
		_thumb_renderer.show_options(_category, _avatar.get_choices(), _thumbnail_tiles)

func _show_garment_palette() -> void:
	for child in _palette_list.get_children():
		_palette_list.remove_child(child)
		child.queue_free()
	var choices := _avatar.get_choices()
	var palette: Dictionary = _garment_palettes.get(_category.get("id"), {})
	if _category.get("palettePlacement") == "preview":
		palette = _category
	var allowed: Array = palette.get("paletteItems", [])
	var visible_palette: bool = not palette.is_empty() and (allowed.is_empty() or choices.get(_category["id"]) in allowed)
	_palette.visible = visible_palette
	if visible_palette:
		var buttons := ButtonGroup.new()
		for item: Dictionary in palette["items"]:
			var color := Button.new()
			color.custom_minimum_size = Vector2(TARGET, TARGET)
			color.tooltip_text = item["label"]
			color.accessibility_name = item["label"]
			color.toggle_mode = true
			color.button_group = buttons
			color.set_pressed_no_signal(choices.get(palette["id"]) == item["id"])
			_style_button(color)
			_style_color_option(color, Color(item["color"]))
			_palette_list.add_child(color)
			_add_selection_mark(color)
			color.pressed.connect(_select_option.bind(palette["id"], item["id"]))
		_position_palette()
	_set_camera()

func _update_choice_caption() -> void:
	var selected: Variant = _avatar.get_choices().get(_category.get("id"))
	_current_choice.text = ""
	for item in _category.get("items", []):
		if item["id"] == selected:
			_current_choice.text = str(item["label"])
			return

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

func _style_tab(button: Button, icon_only: bool) -> void:
	_style_button(button)
	var resting := _box(Color.TRANSPARENT if icon_only else RAIL, Color.TRANSPARENT, 12)
	resting.set_border_width_all(0)
	var hover := _box(Color("#314343"), EDGE, 12)
	var selected := _box(Color("#243E46") if icon_only else ACCENT, Color("#64A9BD") if icon_only else ACCENT, 12)
	for style in [resting, hover, selected]:
		style.content_margin_left = 4 if icon_only else 10
		style.content_margin_right = 4 if icon_only else 10
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		style.expand_margin_top = -4
		style.expand_margin_bottom = -4
	button.add_theme_stylebox_override("normal", resting)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", selected)
	button.add_theme_stylebox_override("hover_pressed", selected)
	button.add_theme_color_override("font_color", PAPER)
	button.add_theme_color_override("font_pressed_color", ACCENT if icon_only else INK)
	button.add_theme_color_override("font_hover_pressed_color", ACCENT if icon_only else INK)
	button.add_theme_color_override("font_focus_color", PAPER)
	button.add_theme_color_override("icon_normal_color", MUTED)
	button.add_theme_color_override("icon_pressed_color", ACCENT if icon_only else INK)
	button.add_theme_color_override("icon_hover_pressed_color", ACCENT if icon_only else INK)

func _style_section(button: Button) -> void:
	_style_button(button)
	var active := _box(Color("#244550"), Color("#446C78"), 14)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", active)
	button.add_theme_stylebox_override("hover_pressed", active)

func _style_color_option(button: Button, color: Color) -> void:
	var normal := _box(color, color.lightened(0.24), 13)
	var hover := _box(color, PAPER, 12)
	var selected := _box(color, ACCENT, 13)
	selected.set_border_width_all(3)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", selected)
	button.add_theme_stylebox_override("hover_pressed", selected)
	var ink := Color.BLACK if color.srgb_to_linear().get_luminance() > 0.18 else Color.WHITE
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, ink)

func _add_selection_mark(button: Button) -> void:
	var mark := Panel.new()
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.add_theme_stylebox_override("panel", _box(ACCENT, ACCENT, 11))
	button.add_child(mark)
	mark.size = Vector2(22, 22)
	mark.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_KEEP_SIZE, 6)
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = CATEGORY_ICONS.get_icon("check")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = INK
	mark.add_child(icon)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 2)
	mark.visible = button.button_pressed
	button.toggled.connect(func(active: bool) -> void: mark.visible = active)

func _style_button(button: Button, accent := false, gallery := false) -> void:
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", PAPER)
	button.add_theme_color_override("font_hover_color", PAPER)
	button.add_theme_color_override("font_pressed_color", INK if accent else PAPER)
	button.add_theme_color_override("font_hover_pressed_color", INK if accent else PAPER)
	button.add_theme_color_override("font_focus_color", PAPER)
	var normal := _box(Color("#243030") if gallery else RAIL, EDGE, 15)
	var hover := _box(Color("#344747"), Color("#62817F"), 15)
	var active := _box(ACCENT if accent else Color("#233D44"), ACCENT, 15)
	active.set_border_width_all(2)
	if gallery:
		normal.set_border_width_all(0)
		for style in [normal, active, hover]:
			style.content_margin_left = 4
			style.content_margin_right = 4
			style.content_margin_top = 4
			style.content_margin_bottom = 4
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", active)
	button.add_theme_stylebox_override("hover_pressed", active)
	button.add_theme_color_override("font_disabled_color", MUTED)
	button.add_theme_stylebox_override("disabled", _box(Color("#202B2B"), EDGE, 12))
	var focus := _box(Color.TRANSPARENT, Color.WHITE, 12)
	focus.draw_center = false
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
