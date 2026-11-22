extends SubViewport
## Sequentially renders catalogue choices with a separate character instance.

const LIMIT := 64
const THUMBNAIL_LAYER := 1 << 4

var _figure: AvatarStudioCharacter
var _camera: Camera3D
var _catalogue_path := ""
var _textures: Dictionary = {}
var _requested: Dictionary = {}
var _revision := 0
var _running := false
var _ready_to_render := false
var _meshes: Array[Node] = []
var _category_items: Dictionary = {}

func setup(path: String) -> void:
	_catalogue_path = path
	if DisplayServer.get_name() == "headless":
		return
	size = Vector2i(172, 168)
	transparent_bg = true
	world_3d = World3D.new()
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	msaa_3d = Viewport.MSAA_2X
	_figure = AvatarStudioCharacter.new()
	add_child(_figure)
	if _figure.configure(path) != OK:
		return
	for category: Dictionary in _figure.get_categories():
		var groups: Dictionary = {}
		for item: Dictionary in category["items"]:
			if item.has("group"):
				groups[item["id"]] = item["group"]
		_category_items[category["id"]] = groups
	_figure.rotation.y = -0.23
	_meshes = _figure.find_children("*", "GeometryInstance3D", true, false)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	add_child(_camera)
	_camera.current = true
	var studio := WorldEnvironment.new()
	studio.environment = Environment.new()
	studio.environment.background_mode = Environment.BG_CLEAR_COLOR
	studio.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	studio.environment.ambient_light_color = Color("#fff4e9")
	studio.environment.ambient_light_energy = 0.56
	add_child(studio)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-37, -22, 0)
	key.light_energy = 1.15
	key.layers = 1 | THUMBNAIL_LAYER
	add_child(key)
	_ready_to_render = true

func show_options(category: Dictionary, choices: Dictionary, buttons: Dictionary) -> void:
	if not _ready_to_render:
		return
	_revision += 1
	var context := choices.duplicate()
	context.erase(category["id"])
	_requested = {
		"revision": _revision,
		"category": category,
		"choices": choices.duplicate(),
		"buttons": buttons.duplicate(),
		"key": _catalogue_path + "|" + category["id"] + "|" + JSON.stringify(context, "", true),
	}
	if not _running:
		_render_queue()

func _render_queue() -> void:
	_running = true
	while not _requested.is_empty():
		var job := _requested
		_requested = {}
		var category: Dictionary = job["category"]
		_frame(category.get("thumbnailFraming", category.get("framing", "face")))
		for item in category["items"]:
			if job["revision"] != _revision:
				break
			var button: Button = job["buttons"].get(item["id"])
			if not is_instance_valid(button) or button.is_queued_for_deletion():
				continue
			var key: String = job["key"] + "|" + item["id"]
			if not _textures.has(key):
				var look: Dictionary = job["choices"].duplicate()
				look[category["id"]] = item["id"]
				if not _figure.restore(look):
					continue
				_filter_parts(category, item, look)
				render_target_update_mode = SubViewport.UPDATE_ONCE
				await RenderingServer.frame_post_draw
				if not is_inside_tree() or job["revision"] != _revision:
					break
				var image := get_texture().get_image()
				if image == null or image.is_empty():
					continue
				if _textures.size() >= LIMIT:
					_textures.erase(_textures.keys()[0])
				_textures[key] = ImageTexture.create_from_image(image)
			if is_instance_valid(button) and not button.is_queued_for_deletion():
				button.icon = _textures[key]
	_running = false

func _filter_parts(category: Dictionary, item: Dictionary, choices: Dictionary) -> void:
	var names: Variant = category.get("thumbnailParts")
	if not names is Array:
		_camera.cull_mask = 0xfffff
		return
	var parts: Array[Node] = []
	var option_group: Variant = item.get("group")
	var part_names: Array = names.duplicate()
	if option_group is String:
		part_names.append(option_group)
	var from: Variant = category.get("thumbnailFromCategory")
	if from is String and _category_items.has(from):
		var selected: Variant = _category_items[from].get(choices.get(from))
		if selected is String:
			part_names.append(selected)
	for name in part_names:
		if not name is String:
			continue
		var node := _figure.find_child(name, true, false)
		if node != null:
			parts.append(node)
	if parts.is_empty():
		_camera.cull_mask = 0xfffff
		return
	for mesh in _meshes:
		mesh.layers = 1
		for part in parts:
			if part == mesh or part.is_ancestor_of(mesh):
				mesh.layers |= THUMBNAIL_LAYER
				break
	_camera.cull_mask = THUMBNAIL_LAYER

func _frame(mode: String) -> void:
	var bounds := _figure.get_model_bounds()
	var h := maxf(0.2, bounds.size.y)
	var center := bounds.get_center()
	var framing := Vector3(0.81, 0.37, 0.85)
	match mode:
		"full":
			framing = Vector3(0.51, 1.14, 1.11)
		"upper":
			framing = Vector3(0.56, 0.38, 0.82)
		"legs":
			framing = Vector3(0.26, 0.54, 0.86)
		"shoes":
			framing = Vector3(0.10, 0.32, 0.85)
		"eyes":
			framing = Vector3(0.81, 0.18, 0.53)
		"brows":
			framing = Vector3(0.84, 0.18, 0.53)
		"nose":
			framing = Vector3(0.78, 0.17, 0.38)
		"mouth":
			framing = Vector3(0.75, 0.16, 0.38)
	var height := bounds.position.y + h * framing.x
	_camera.position = Vector3(center.x, height + h*0.03, center.z + maxf(4, h*2.4))
	_camera.look_at(Vector3(center.x, height, center.z))
	_camera.size = maxf(h * framing.y, bounds.size.x * framing.z)
