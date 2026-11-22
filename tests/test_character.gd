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
	_expect(first.choose("outfit", "jacket") and not first.find_child("Pull", true, false).visible
		and first.find_child("Blouson", true, false).visible, "La tenue bascule entre deux pièces")
	_expect(first.choose("glasses", "round") and first.find_child("Lunettes", true, false).visible,
		"Accessoire ajouté")
	_expect(first.choose("glasses", "none") and not first.find_child("Lunettes", true, false).visible,
		"Accessoire retiré")
	var saved := first.get_choices()
	var restored: Dictionary = JSON.parse_string(JSON.stringify(saved))
	_expect(second.restore(restored) and second.get_choices() == saved, "Copie d’apparence entre instances")
	restored["skin"] = "inconnue"
	_expect(not second.restore(restored) and second.get_choices() == saved, "Import inconnu refusé sans perte")
	second.reset()
	_expect(second.get_choices()["skin"] == "copper" and second.get_choices()["face"] == "neutral", "Réinitialisation")
	_expect(other.get_display_name() == "Second modèle" and other.choose("shape", "slant")
		and other.find_child("BlocIncline", true, false).visible, "Un autre modèle fonctionne avec le même composant")
	quit(0 if _errors == 0 else 1)
