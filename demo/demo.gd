extends Control

const LOOK_PATH := "user://ari_appearance.json"
const NOVA_LOOK_PATH := "user://nova_appearance.json"
const NOVA_CATALOGUE := "res://demo/modeles/nova_catalogue.json"
var _editor := AvatarStudioEditor.new()
var _saved_look: Dictionary
var _look_path := LOOK_PATH

func _ready() -> void:
	_editor.catalogue_path = "res://demo/modeles/catalogue.json"
	if OS.get_cmdline_user_args().has("--nova") and FileAccess.file_exists(NOVA_CATALOGUE):
		_editor.catalogue_path = NOVA_CATALOGUE
		_editor.title = "Nova"
		_look_path = NOVA_LOOK_PATH
		var window := get_window()
		window.title = "Avatar Studio · Nova"
	_editor.show_close_button = true
	_editor.save_requested.connect(_save)
	_editor.close_requested.connect(_close)
	_editor.catalogue_loaded.connect(_restore)
	_editor.catalogue_failed.connect(func(error: Error) -> void: push_error(error_string(error)))
	add_child(_editor)
	_editor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _save(choices: Dictionary) -> void:
	var file := FileAccess.open(_look_path, FileAccess.WRITE)
	if file == null:
		_editor.show_status("Enregistrement impossible.")
		return
	file.store_string(JSON.stringify({"version": 3, "choices": choices}))
	_saved_look = choices
	_editor.show_status("Avatar enregistré sur cet appareil.")

func _restore() -> void:
	if not OS.get_cmdline_user_args().has("--review") and FileAccess.file_exists(_look_path):
		var document: Variant = JSON.parse_string(FileAccess.get_file_as_string(_look_path))
		if document is Dictionary and document.get("choices") is Dictionary:
			if document.get("version") in [1, 2]:
				var expanded := _editor.get_character().get_choices()
				expanded.merge(document["choices"], true)
				_editor.restore(expanded)
			elif document.get("version") == 3:
				_editor.restore(document["choices"])
	_saved_look = _editor.get_character().get_choices()

func _close() -> void:
	if _editor.get_character().get_choices() == _saved_look:
		get_tree().quit()
		return
	var confirm := ConfirmationDialog.new()
	confirm.title = "Quitter l’éditeur ?"
	confirm.dialog_text = "Les modifications en cours seront perdues."
	confirm.ok_button_text = "Quitter"
	confirm.cancel_button_text = "Continuer l’édition"
	confirm.confirmed.connect(func() -> void: get_tree().quit())
	confirm.canceled.connect(confirm.queue_free)
	add_child(confirm)
	confirm.popup_centered()
