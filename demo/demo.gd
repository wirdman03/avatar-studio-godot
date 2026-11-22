extends Control

const LOOK_PATH := "user://ari_appearance.json"
var _editor := AvatarStudioEditor.new()

func _ready() -> void:
	_editor.catalogue_path = "res://demo/modeles/catalogue.json"
	_editor.save_requested.connect(_save)
	_editor.catalogue_loaded.connect(_restore)
	_editor.catalogue_failed.connect(func(error: Error) -> void: push_error(error_string(error)))
	add_child(_editor)
	_editor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _save(choices: Dictionary) -> void:
	var file := FileAccess.open(LOOK_PATH, FileAccess.WRITE)
	if file == null:
		_editor.show_status("Enregistrement impossible.")
		return
	file.store_string(JSON.stringify({"version": 1, "choices": choices}))
	_editor.show_status("Avatar gardé sur cet appareil.")

func _restore() -> void:
	if OS.get_cmdline_user_args().has("--review") or not FileAccess.file_exists(LOOK_PATH):
		return
	var document: Variant = JSON.parse_string(FileAccess.get_file_as_string(LOOK_PATH))
	if document is Dictionary and document.get("version") == 1 and document.get("choices") is Dictionary:
		_editor.restore(document["choices"])
