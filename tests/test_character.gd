extends SceneTree

const DEMO := "res://demo/modeles/catalogue.json"
const OTHER := "res://tests/catalogue_alt.json"
var _errors := 0

func _initialize() -> void:
	call_deferred("_run")

func _expect(condition: bool, description: String) -> void:
	if not condition:
		_errors += 1
		push_error(description)
	else:
		print("OK  ", description)

func _run() -> void:
	var first := AvatarStudioCharacter.new()
	var second := AvatarStudioCharacter.new()
	var other := AvatarStudioCharacter.new()
	root.add_child(first)
	root.add_child(second)
	root.add_child(other)
	var ready := first.configure(DEMO) == OK and second.configure(DEMO) == OK and other.configure(OTHER) == OK
	_expect(ready, "Deux instances de la démo et un catalogue différent se chargent")
	if not ready:
		quit(1)
		return
	_expect(first.get_model_bounds().size.y > 1.8 and other.get_model_bounds().size.y < 1.3,
		"Cadre calculé pour chaque modèle")
	_expect(first.choose("hair", "waves"), "Changement de coupe accepté")
	_expect(not first.find_child("CheveuxBalayes", true, false).visible, "L’ancienne coupe disparaît")
	_expect(first.find_child("CheveuxOndules", true, false).visible, "La nouvelle coupe apparaît")
	_expect(second.find_child("CheveuxBalayes", true, false).visible, "La deuxième instance reste indépendante")
	_expect(first.choose("face", "smile"), "Le sourire est sélectionnable")
	var smile := first.find_child("Sourire", true, false) as MeshInstance3D
	_expect(is_equal_approx(smile.get_blend_shape_value(0), 1.0), "La déformation est appliquée à la maille")
	_expect(first.choose("skin", "deep"), "La couleur de peau est sélectionnable")
	var a := first.find_child("Visage", true, false) as MeshInstance3D
	var b := second.find_child("Visage", true, false) as MeshInstance3D
	_expect(a.get_active_material(0).albedo_color.is_equal_approx(Color("#81513E")), "La nouvelle couleur est visible")
	_expect(b.get_active_material(0).albedo_color.is_equal_approx(Color("#C68158")), "La couleur du deuxième avatar est préservée")
	_expect(first.choose("hair_color", "teal") and first.choose("hair", "braids"), "La couleur persiste au changement de coupe")
	var braid := first.find_child("CheveuxTresses", true, false)
	var highlight := braid.find_child("Tresse plaquée", true, false) as MeshInstance3D
	_expect(highlight.get_active_material(0).albedo_color.is_equal_approx(Color("#4E8B91")),
		"La palette de cheveux recolore aussi les reflets")
	_expect(first.choose("eyes", "lifted") and first.choose("eye_color", "jade")
		and first.find_child("YeuxEtires", true, false).visible and not first.find_child("YeuxAmande", true, false).visible,
		"La forme et la couleur des yeux se combinent")
	_expect(first.choose("outfit", "jacket") and not first.find_child("Pull", true, false).visible
		and first.find_child("Blouson", true, false).visible, "La tenue bascule entre deux pièces")
	_expect(first.choose("glasses", "round") and first.find_child("Lunettes", true, false).visible,
		"Accessoire ajouté")
	_expect(first.choose("glasses", "none") and not first.find_child("Lunettes", true, false).visible,
		"Accessoire retiré")
	_expect(first.choose("trousers", "cargo") and first.choose("shoes", "boots")
		and first.find_child("Cargo", true, false).visible and first.find_child("BottesPlateforme", true, false).visible
		and not first.find_child("BasketsCorail", true, false).visible, "Pantalons et chaussures se changent séparément")
	var saved := first.get_choices()
	var restored: Dictionary = JSON.parse_string(JSON.stringify(saved))
	_expect(second.restore(restored) and second.get_choices() == saved, "Copie d’apparence entre instances")
	restored["skin"] = "inconnue"
	_expect(not second.restore(restored) and second.get_choices() == saved, "Import inconnu refusé sans perte")
	second.reset()
	_expect(second.get_choices()["skin"] == "copper" and second.get_choices()["face"] == "neutral", "Réinitialisation")
	_expect(other.get_display_name() == "Second modèle" and other.choose("shape", "slant")
		and other.find_child("BlocIncline", true, false).visible, "Un autre modèle fonctionne avec le même composant")
	_verify_invalid_palette()
	quit(0 if _errors == 0 else 1)

func _verify_invalid_palette() -> void:
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DEMO))
	catalogue["model"] = "res://demo/modeles/ari.tscn"
	for category: Dictionary in catalogue["categories"]:
		if category.get("paletteFor") == "outfit":
			category["paletteItems"] = ["missing-outfit"]
	var path := "res://.godot/test-catalogue-%d.json" % OS.get_process_id()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_expect(false, "Le catalogue temporaire peut être écrit")
		return
	file.store_string(JSON.stringify(catalogue))
	file.close()
	var character := AvatarStudioCharacter.new()
	root.add_child(character)
	var result := character.configure(path)
	DirAccess.remove_absolute(path)
	_expect(result == ERR_INVALID_DATA, "Une palette qui référence une tenue inconnue est refusée")
	_expect(character.configure(DEMO) == OK, "La configuration peut être relancée après un catalogue invalide")
