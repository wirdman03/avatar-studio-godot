extends SceneTree
## Runs the real editor scene with graphics enabled and saves review images.

var _editor := AvatarStudioEditor.new()
var _saved: Dictionary = {}
var _close_requested := false
var _wide := false
var _nova := false
var _compact := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_wide = OS.get_cmdline_user_args().has("--wide")
	_nova = OS.get_cmdline_user_args().has("--nova")
	_compact = OS.get_cmdline_user_args().has("--compact")
	if _wide:
		root.size = Vector2i(1050, 840)
	elif _compact:
		root.size = Vector2i(360, 720)
	else:
		root.size = Vector2i(430, 864)
	_editor.catalogue_path = "res://demo/modeles/nova_catalogue.json" if _nova else "res://demo/modeles/catalogue.json"
	_editor.title = "Nova" if _nova else "Mon avatar"
	_editor.show_close_button = true
	_editor.save_requested.connect(func(choices: Dictionary) -> void: _saved = choices)
	_editor.close_requested.connect(func() -> void: _close_requested = true)
	root.add_child(_editor)
	_editor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _editor.get_character().get_choices().is_empty():
		push_error("Impossible de charger la démo")
		quit(1)
		return
	await process_frame
	await process_frame
	var modes_visible := _editor.size.x >= 740
	if _wide != modes_visible:
		push_error("Le mode attendu ne correspond pas à la largeur détectée.")
		quit(1)
		return
	if not _wide:
		var rail := _editor.find_child("CategoryRail", true, false) as Control
		var gallery := _editor.find_child("OptionGallery", true, false) as Control
		var tabs := _editor.find_child("EditorSections", true, false) as Control
		if rail.get_global_rect().end.y > gallery.get_global_rect().position.y:
			push_error("Les réglages de l’onglet actif doivent se trouver au-dessus de la galerie.")
			quit(1)
			return
		if tabs.get_child_count() != 2 or tabs.get_global_rect().position.y < gallery.get_global_rect().end.y or _find_button("Avatar") == null or _find_button("Tenue") == null:
			push_error("Le pied de page doit contenir uniquement Avatar et Tenue.")
			quit(1)
			return
		if not _nova:
			var family := _find_button("Cheveux")
			var cut := _find_button("Coupe")
			if family == null or cut == null or family.get_global_rect().end.y > cut.get_global_rect().position.y:
				push_error("L’onglet Cheveux doit être au-dessus de Coupe et Couleur.")
				quit(1)
				return
	var initial_panel_y := _gallery().get_global_rect().position.y
	if _nova:
		await _verify_nova_layout()
		return
	var expected := _editor.get_character().get_choices()
	await _press("Coupe")
	if not await _verify_thumbnails("Balayés", "Ondulés"):
		quit(1)
		return
	if not await _verify_thumbnails("Chignon", "Crête"):
		quit(1)
		return
	if not await _verify_thumbnails("Rasés", "Deux chignons"):
		quit(1)
		return
	await _capture("04-grand-ecran.png" if _wide else "01-demo.png")
	if not await _drag_preview():
		push_error("Le glissement n’a pas fait tourner l’avatar.")
		quit(1)
		return
	await _press("Ondulés")
	await _press("Annuler")
	if _editor.get_character().get_choices()["hair"] != "swept":
		push_error("Annuler n’a pas remis la coiffure initiale")
		quit(1)
		return
	await _press("Rétablir")
	if _editor.get_character().get_choices()["hair"] != "waves":
		push_error("Rétablir n’a pas remis le dernier choix")
		quit(1)
		return
	await _press("Couleur des cheveux")
	if _find_button("Bleu pétrole") == null:
		push_error("Le sous-onglet doit ouvrir les couleurs de cheveux.")
		quit(1)
		return
	if not await _verify_thumbnails("Bleu pétrole", "Brun prune"):
		quit(1)
		return
	if not _wide:
		await _capture("sous-onglets-portrait.png")
	await _press("Bleu pétrole")
	await _press("Coupe")
	if _find_button("Ondulés") == null:
		push_error("Le sous-onglet Coupe doit rouvrir les coiffures.")
		quit(1)
		return
	await _press("Tresses")
	await _press("Teint")
	if _find_button("Couleur des cheveux") != null or _find_button("Cheveux") == null:
		push_error("Quitter Cheveux doit replier ses sous-onglets.")
		quit(1)
		return
	await _press("Foncé")
	await _press("Yeux")
	if not await _verify_thumbnails("En amande", "Étirés"):
		quit(1)
		return
	await _press("Étirés")
	await _press("Couleur des yeux")
	await _press("Jade")
	await _press("Sourcils")
	await _press("Arquées")
	await _press("Nez")
	if not await _verify_thumbnails("Fin", "Retroussé"):
		quit(1)
		return
	await _press("Retroussé")
	await _press("Bouche")
	await _press("Sourire")
	await _press_with_keyboard("Tenue")
	if _find_button("Maille") == null or _find_button("Cheveux") != null:
		push_error("Tenue doit ouvrir les vêtements et masquer les réglages du visage.")
		quit(1)
		return
	await _press("Hauts")
	if not await _verify_thumbnails("Maille", "Blouson"):
		quit(1)
		return
	if _palette().visible:
		push_error("La palette doit être réservée aux vêtements recolorables.")
		quit(1)
		return
	await _press("Blouson")
	if not _palette().visible or _palette().get_global_rect().get_center().x <= _palette().get_parent().size.x * 0.68:
		push_error("Le blouson doit afficher sa palette à droite.")
		quit(1)
		return
	await _press("Indigo")
	var mesh := _editor.get_character().find_child("Blouson", true, false).find_child("Buste", true, false) as MeshInstance3D
	if mesh == null or not mesh.get_active_material(0).albedo_color.is_equal_approx(Color("#44587D")):
		push_error("La palette doit réellement recolorer le vêtement.")
		quit(1)
		return
	if not _wide:
		await _capture("palette-vetement-portrait.png")
	await _press("Annuler")
	if not mesh.get_active_material(0).albedo_color.is_equal_approx(Color("#AB5B43")):
		push_error("Annuler doit remettre la couleur précédente du blouson.")
		quit(1)
		return
	await _press("Rétablir")
	await _press("Perfecto")
	await _press("Pantalons")
	await _press("Cargo")
	await _press("Chaussures")
	if not await _verify_thumbnails("Baskets corail", "Bottes plateforme"):
		quit(1)
		return
	await _press("Bottes plateforme")
	await _press("Lunettes")
	await _press("Rectangulaires")
	await _press("Bijoux")
	await _press("Anneaux")
	await _press("Hauts")
	if not _wide:
		if not await _verify_thumbnails("Perfecto", "T-shirt brique"):
			quit(1)
			return
		await _capture("03-habillage.png")
	await _press("Avatar")
	if _find_button("Sourire") == null or _find_button("Anneaux") != null:
		push_error("La catégorie Bouche doit afficher les expressions.")
		quit(1)
		return
	if not _wide and not is_equal_approx(initial_panel_y, _gallery().get_global_rect().position.y):
		push_error("Le panneau portrait doit rester au même endroit d’une catégorie à l’autre.")
		quit(1)
		return
	await _press("Cheveux")
	await _press("Couleur des cheveux")
	await _press("Enregistrer")
	if not _wide:
		await _capture("02-personnalisation.png")
	expected.merge({
		"hair": "braids", "hair_color": "teal", "face": "smile", "eyes": "lifted",
		"eye_color": "jade", "eyebrows": "arched", "nose": "upturned", "outfit": "biker",
		"trousers": "cargo", "shoes": "boots", "glasses": "square", "jewelry": "hoops",
		"skin": "deep", "outfit_color": "indigo",
	}, true)
	if _saved != expected or _editor.get_character().get_choices() != expected:
		push_error("La commande Enregistrer ne contient pas les choix de l’écran : " + str(_saved))
		quit(1)
		return
	await _press("Fermer")
	if not _close_requested:
		push_error("Le bouton Fermer doit avertir l’application hôte.")
		quit(1)
		return
	print("OK  Onglets directs, clavier, galerie, rotation, annulation, rétablissement, sauvegarde et fermeture vérifiés. Grand écran : ", _wide)
	quit(0)

func _gallery() -> ScrollContainer:
	return _editor.find_child("OptionGallery", true, false) as ScrollContainer

func _palette() -> Control:
	return _editor.find_child("GarmentPalette", true, false) as Control

func _verify_nova_layout() -> void:
	var gallery := _gallery()
	var stage := _editor.find_children("*", "SubViewportContainer", true, false)[0] as Control
	var panel_y := gallery.get_global_rect().position.y
	if not is_equal_approx(stage.size.y, roundf(_editor.size.y * 0.425)):
		push_error("Le panneau doit rester à la même hauteur même avec trois choix.")
		quit(1)
		return
	await _capture("nova-portrait.png")
	await _press("Cuivre")
	await _press("Tenue")
	await _press("Indigo")
	if not _palette().visible or not is_equal_approx(panel_y, gallery.get_global_rect().position.y):
		push_error("La palette latérale ne doit pas déplacer le panneau.")
		quit(1)
		return
	await _capture("nova-plein-pied.png")
	await _press("Enregistrer")
	if _saved.get("hair_color") != "copper" or _saved.get("jacket_color") != "indigo":
		push_error("Les boutons directs doivent enregistrer les changements.")
		quit(1)
		return
	print("OK  Panneau fixe et palette latérale sur Nova.")
	quit()

func _press_with_keyboard(label: String) -> void:
	var button := _find_button(label)
	assert(button != null and not button.accessibility_name.is_empty(), label)
	button.grab_focus()
	await process_frame
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await process_frame
	await process_frame

func _find_button(label: String) -> Button:
	for node in _editor.find_children("*", "Button", true, false):
		if (node.text == label or node.tooltip_text == label) and node.is_visible_in_tree():
			return node
	return null

func _verify_thumbnails(a: String, b: String) -> bool:
	for frame in 120:
		var first := _find_button(a)
		var second := _find_button(b)
		if first != null and second != null and first.icon != null and second.icon != null:
			var source := first.icon.get_image()
			var target := second.icon.get_image()
			if not source.get_used_rect().has_area() or not target.get_used_rect().has_area():
				push_error("Vignette transparente ou vide")
				return false
			if source.get_data() == target.get_data():
				push_error("Les deux vignettes utilisent le même rendu")
				return false
			print("OK  Vignettes distinctes du modèle 3D : ", a, " et ", b)
			return true
		await RenderingServer.frame_post_draw
	push_error("Les vignettes n’ont pas été rendues")
	return false

func _press(label: String) -> void:
	var button := _find_button(label)
	assert(button != null, label)
	for name in ["CategoryRail", "OptionGallery"]:
		var scroll := _editor.find_child(name, true, false) as ScrollContainer
		if scroll.is_ancestor_of(button):
			scroll.ensure_control_visible(button)
			await process_frame
	var point := button.get_global_rect().get_center()
	var click := InputEventMouseButton.new()
	click.position = point
	click.global_position = point
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	root.push_input(click, true)
	click = click.duplicate()
	click.pressed = false
	root.push_input(click, true)
	await process_frame
	await process_frame

func _drag_preview() -> bool:
	var stage := _editor.find_children("*", "SubViewportContainer", true, false)[0] as Control
	var center := stage.get_global_rect().get_center()
	var before := _editor.get_character().rotation.y
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = center
	press.global_position = center
	press.pressed = true
	root.push_input(press, true)
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.relative = Vector2(48, 0)
	motion.position = center + motion.relative
	motion.global_position = motion.position
	root.push_input(motion, true)
	var release := press.duplicate() as InputEventMouseButton
	release.position = motion.position
	release.global_position = motion.global_position
	release.pressed = false
	root.push_input(release, true)
	await process_frame
	return absf(_editor.get_character().rotation.y - before) > 0.3

func _capture(name: String) -> void:
	if _compact:
		return
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	assert(image.save_png(ProjectSettings.globalize_path("res://preuves/" + name)) == OK)
