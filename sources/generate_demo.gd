extends SceneTree
## Rebuilds the fictional character bundled with the Godot demo.
## godot --headless --path . --script sources/generate_demo.gd

var _model := Node3D.new()
var _ink := _material("Encre", "#2f2437")
var _skin := _material("Peau", "#c68158")
var _blush := _material("Intérieur oreille", "#ac573f")
var _hair := _material("Cheveux", "#503342")
var _hair_light := _material("Volume cheveux", "#624055")
var _white := _material("Ivoire", "#fff1dc")
var _iris := _material("Iris", "#74462b")
var _mouth := _material("Bouche", "#6e342e")

func _initialize() -> void:
	_model.name = "Ari"
	var body := _group("Corps")
	var bob := _group("CheveuxBalayes")
	var waves := _group("CheveuxOndules")
	var knit := _group("Pull")
	var jacket := _group("Blouson")
	var glasses := _group("Lunettes")
	var denim := _material("Denim", "#3b5375")
	var shoelace := _material("Semelle", "#e8d9c3")
	var trainer := _material("Chaussures", "#c36051")

	_ball(body, "Nuque", Vector3(0, 1.365, 0), Vector3(0.086, 0.126, 0.091), _skin)
	_ball(body, "Visage", Vector3(0, 1.645, 0.036), Vector3(0.232, 0.272, 0.195), _skin)
	_ball(body, "Mâchoire", Vector3(0, 1.507, 0.085), Vector3(0.175, 0.126, 0.150), _skin)
	_ball(body, "Nez", Vector3(0, 1.607, 0.225), Vector3(0.048, 0.052, 0.047), _skin)
	_ball(body, "Bassin", Vector3(0, 0.893, -0.008), Vector3(0.191, 0.142, 0.135), denim)
	for side in [-1.0, 1.0]:
		_ball(body, "Oreille", Vector3(side * 0.226, 1.618, 0.035), Vector3(0.050, 0.078, 0.050), _skin, side * 0.14)
		_ball(body, "Conque", Vector3(side * 0.245, 1.618, 0.071), Vector3(0.023, 0.047, 0.010), _blush)
		_ball(body, "Œil", Vector3(side * 0.087, 1.664, 0.202), Vector3(0.059, 0.057, 0.032), _white)
		_ball(body, "Iris", Vector3(side * 0.081, 1.666, 0.232), Vector3(0.030, 0.034, 0.012), _iris)
		_ball(body, "Pupille", Vector3(side * 0.081, 1.666, 0.243), Vector3(0.016, 0.019, 0.005), _ink)
		_ball(body, "Lueur", Vector3(side * 0.081 - 0.007, 1.678, 0.247), Vector3(0.0058, 0.0061, 0.0028), _white)
		_ball(body, "Sourcil", Vector3(side * 0.090, 1.745, 0.205), Vector3(0.058, 0.013, 0.015), _hair, side * -0.14)
		_ball(body, "Jambe", Vector3(side * 0.106, 0.604, -0.012), Vector3(0.091, 0.358, 0.096), denim, side * 0.042)
		_ball(body, "Cheville", Vector3(side * 0.125, 0.258, -0.009), Vector3(0.067, 0.159, 0.070), denim)
		_ball(body, "Basket", Vector3(side * 0.127, 0.083, 0.065), Vector3(0.095, 0.071, 0.161), trainer)
		_ball(body, "Semelle", Vector3(side * 0.127, 0.034, 0.070), Vector3(0.097, 0.032, 0.164), shoelace)
		for i in 3:
			_ball(body, "Lacet", Vector3(side * 0.127, 0.141 - i * 0.007, 0.113 + i * 0.022), Vector3(0.042, 0.006, 0.006), shoelace)
		_ball(body, "Main", Vector3(side * 0.306, 0.828, 0.024), Vector3(0.058, 0.091, 0.045), _skin, side * 0.21)
		_ball(body, "Pouce", Vector3(side * 0.266, 0.839, 0.048), Vector3(0.026, 0.046, 0.023), _skin, side * 0.25)
		_torus(glasses, "Monture", Vector3(side * 0.088, 1.671, 0.255), 0.070, 0.0042, _ink)
		_ball(glasses, "Branche", Vector3(side * 0.181, 1.690, 0.152), Vector3(0.049, 0.005, 0.111), _ink)
	_ball(glasses, "Pont", Vector3(0, 1.680, 0.254), Vector3(0.026, 0.004, 0.004), _ink)
	_add_mouth(body)

	_ball(bob, "Volume arrière", Vector3(0, 1.780, -0.025), Vector3(0.236, 0.188, 0.200), _hair)
	_ball(bob, "Mèche", Vector3(-0.075, 1.832, 0.118), Vector3(0.145, 0.073, 0.102), _hair_light, 0.32)
	_ball(bob, "Frange", Vector3(0.054, 1.850, 0.108), Vector3(0.166, 0.061, 0.112), _hair, -0.34)
	_ball(bob, "Tempe", Vector3(-0.191, 1.759, 0.071), Vector3(0.059, 0.113, 0.100), _hair, -0.24)
	_ball(bob, "Tempe", Vector3(0.198, 1.784, 0.031), Vector3(0.058, 0.119, 0.096), _hair, 0.18)

	_ball(waves, "Volume arrière", Vector3(0, 1.784, -0.037), Vector3(0.246, 0.182, 0.205), _hair)
	for index in 12:
		var t := TAU * float(index) / 12.0
		var center := Vector3(0.162 * sin(t), 1.882 + 0.024 * cos(2.0 * t), 0.119 * cos(t))
		_ball(waves, "Boucle", center, Vector3(0.084, 0.076, 0.081), _hair_light if index % 3 == 0 else _hair, 0.31 * sin(t))
	for side in [-1.0, 1.0]:
		_ball(waves, "Boucle latérale", Vector3(side * 0.199, 1.785, 0.071), Vector3(0.065, 0.081, 0.095), _hair)
		_ball(waves, "Boucle latérale", Vector3(side * 0.227, 1.735, 0.035), Vector3(0.057, 0.074, 0.089), _hair_light)
	_clothe(knit, _material("Laine", "#39766c"), _material("Bord-côte", "#2b584d"), false)
	_clothe(jacket, _material("Toile", "#ab5b43"), _material("Coutures", "#75443d"), true)

	var packed := PackedScene.new()
	if packed.pack(_model) != OK:
		_model.free()
		quit(1)
		return
	var error := ResourceSaver.save(packed, "res://demo/modeles/ari.tscn")
	_model.free()
	quit(0 if error == OK else 1)

func _material(title: String, color: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = title
	material.albedo_color = Color(color)
	material.roughness = 0.80
	return material

func _group(title: String) -> Node3D:
	var group := Node3D.new()
	group.name = title
	_model.add_child(group)
	group.owner = _model
	return group

func _ball(parent: Node3D, title: String, center: Vector3, axes: Vector3, material: Material, tilt := 0.0) -> void:
	var sphere := SphereMesh.new()
	sphere.radial_segments = 32
	sphere.rings = 16
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.material = material
	var node := MeshInstance3D.new()
	node.name = title.validate_node_name()
	node.mesh = sphere
	node.position = center
	node.scale = axes
	node.rotation.z = tilt
	parent.add_child(node, true)
	node.owner = _model

func _torus(parent: Node3D, title: String, center: Vector3, radius: float, thickness: float, material: Material) -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = radius - thickness
	torus.outer_radius = radius + thickness
	torus.rings = 40
	torus.ring_segments = 8
	torus.material = material
	var node := MeshInstance3D.new()
	node.name = title.validate_node_name()
	node.mesh = torus
	node.position = center
	node.rotation.x = PI / 2.0
	parent.add_child(node, true)
	node.owner = _model

func _clothe(parent: Node3D, fabric: Material, hem: Material, zip: bool) -> void:
	_ball(parent, "Buste", Vector3(0, 1.131, 0), Vector3(0.221, 0.261, 0.140), fabric)
	_ball(parent, "Taille", Vector3(0, 0.947, -0.003), Vector3(0.190, 0.088, 0.132), hem)
	_ball(parent, "Col", Vector3(0, 1.346, 0.010), Vector3(0.122, 0.058, 0.098), hem)
	for side in [-1.0, 1.0]:
		_ball(parent, "Manche", Vector3(side * 0.248, 1.137, 0.001), Vector3(0.093, 0.236, 0.087), fabric, side * 0.25)
		_ball(parent, "Poignet", Vector3(side * 0.287, 0.926, 0.002), Vector3(0.062, 0.069, 0.062), hem, side * 0.25)
	if zip:
		_ball(parent, "Fermeture", Vector3(0, 1.140, 0.140), Vector3(0.009, 0.171, 0.011), hem)
		_ball(parent, "Tirette", Vector3(0, 1.251, 0.143), Vector3(0.013, 0.025, 0.011), _white)
	else:
		_ball(parent, "Poche", Vector3(0.074, 1.154, 0.135), Vector3(0.050, 0.052, 0.011), hem)

func _add_mouth(parent: Node3D) -> void:
	var base := PackedVector3Array()
	var smile := PackedVector3Array()
	var normals := PackedVector3Array()
	var triangles := PackedInt32Array()
	for i in 15:
		var t := float(i) / 14.0 * 2.0 - 1.0
		var x := 0.068 * t
		var y := 1.544 + 0.008 * t * t
		var z := 0.236 - 0.020 * t * t
		var curve := 0.027 * t * t - 0.004
		base.append(Vector3(x, y - 0.004, z))
		base.append(Vector3(x, y + 0.004, z))
		smile.append(Vector3(x * 0.13, curve, 0.001))
		smile.append(Vector3(x * 0.13, curve, 0.001))
		normals.append(Vector3(0, 0, 1))
		normals.append(Vector3(0, 0, 1))
		if i < 14:
			var first := i * 2
			triangles.append_array(PackedInt32Array([first, first + 1, first + 2, first + 1, first + 3, first + 2]))
	var array: Array = []
	array.resize(Mesh.ARRAY_MAX)
	array[Mesh.ARRAY_VERTEX] = base
	array[Mesh.ARRAY_NORMAL] = normals
	array[Mesh.ARRAY_INDEX] = triangles
	var morph: Array = []
	morph.resize(Mesh.ARRAY_MAX)
	morph[Mesh.ARRAY_VERTEX] = smile
	var zero_normals := PackedVector3Array()
	zero_normals.resize(normals.size())
	morph[Mesh.ARRAY_NORMAL] = zero_normals
	var mesh := ArrayMesh.new()
	mesh.blend_shape_mode = Mesh.BLEND_SHAPE_MODE_RELATIVE
	mesh.add_blend_shape("Sourire")
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array, [morph])
	_mouth.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, _mouth)
	var node := MeshInstance3D.new()
	node.name = "Sourire"
	node.mesh = mesh
	parent.add_child(node)
	node.owner = _model
