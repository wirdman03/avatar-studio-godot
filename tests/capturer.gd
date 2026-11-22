extends SceneTree
## Runs the real editor scene with graphics enabled and saves review images.

var _editor := AvatarStudioEditor.new()
var _saved: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_editor.catalogue_path = "res://demo/modeles/catalogue.json"
	_editor.save_requested.connect(func(choices: Dictionary) -> void: _saved = choices)
	root.add_child(_editor)
	_editor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _editor.get_character().get_choices().is_empty():
		push_error("Impossible de charger la démo")
		quit(1)
		return
	await _capture("01-demo.png")
	await _press("Cheveux")
	await _press("Ondulés")
	await _press("Visage")
	await _press("Sourire")
	await _press("Tenue")
	await _press("Blouson")
	await _press("Lunettes")
	await _press("Rondes")
	await _press("Teint")
	await _press("Foncé")
	await _press("Zoom visage")
	await _press("Garder")
	await _capture("02-personnalisation.png")
	var expected := {"hair": "waves", "face": "smile", "outfit": "jacket", "glasses": "round", "skin": "deep"}
	if _saved != expected or _editor.get_character().get_choices() != expected:
		push_error("La commande Garder ne contient pas les choix de l’écran : " + str(_saved))
		quit(1)
		return
	print("OK  Les choix utilisent l’écran réel, avec demande de sauvegarde vérifiée.")
	quit(0)

func _press(label: String) -> void:
	var button: Button
	for node in _editor.find_children("*", "Button", true, false):
		if node.text == label:
			button = node
			break
	assert(button != null, label)
	var point := button.get_global_rect().get_center()
	var click := InputEventMouseButton.new()
	click.position = point
	click.global_position = point
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	root.push_input(click)
	click = click.duplicate()
	click.pressed = false
	root.push_input(click)
	await process_frame
	await process_frame

func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	assert(image.save_png(ProjectSettings.globalize_path("res://preuves/" + name)) == OK)
