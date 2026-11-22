extends SceneTree
## Rebuilds the fictional character bundled with the Godot demo.
## godot --headless --path . --script sources/generate_demo.gd

var _model := Node3D.new()
var _ink := _material("Encre", "#2f2437")
var _skin := _material("Peau", "#c68158")
var _blush := _material("Intérieur oreille", "#ac573f")
var _hair := _material("Cheveux", "#503342")
var _hair_light := _material("Volume cheveux", "#624055")
var _hair_dark := _material("Cheveux foncés", "#382B3C")
var _brow := _material("Sourcils", "#46313B")
var _white := _material("Ivoire", "#fff1dc")
var _iris := _material("Iris", "#74462b")
var _mouth := _material("Bouche", "#6e342e")

func _initialize() -> void:
	_model.name = "Ari"
	var body := _group("Corps")
	var bob := _group("CheveuxBalayes")
	var waves := _group("CheveuxOndules")
	var crop := _group("CheveuxCourts")
	var bun := _group("CheveuxChignon")
	var bob_long := _group("CheveuxCarre")
	var pony := _group("CheveuxAttaches")
	var split := _group("CheveuxRaie")
	var crest := _group("CheveuxCrete")
	var knit := _group("Pull")
	var jacket := _group("Blouson")
	var stand_collar := _group("Veste")
	var glasses := _group("Lunettes")
	var trainer := _material("Chaussures", "#c36051")

	_ball(body, "Nuque", Vector3(0, 1.365, 0), Vector3(0.086, 0.126, 0.091), _skin)
	_head(body)
	_face_details()
	_trousers(_group("Jean"), _material("Denim", "#3b5375"), _material("Couture jean", "#52688A"), 1.0, false)
	_trousers(_group("Cargo"), _material("Toile charbon", "#282631"), _material("Poche cargo", "#453F4C"), 1.10, true)
	_trousers(_group("PantalonVinyle"), _material("Vinyle prune", "#503146", 0.28), _material("Taille vinyle", "#352537"), 0.92, false)
	_footwear(_group("BasketsCorail"), trainer, _material("Semelle", "#e8d9c3"), false)
	_footwear(_group("BasketsNoires"), _material("Chaussures noires", "#2a2733"), _material("Semelle anthracite", "#5C5967"), false)
	_footwear(_group("BottesPlateforme"), _material("Cuir noir", "#25212e", 0.38), _material("Caoutchouc", "#444150"), true)
	for side in [-1.0, 1.0]:
		_ball(body, "Oreille", Vector3(side * 0.226, 1.618, 0.035), Vector3(0.050, 0.078, 0.050), _skin, side * 0.14)
		_ball(body, "Conque", Vector3(side * 0.245, 1.618, 0.071), Vector3(0.023, 0.047, 0.010), _blush)
		_ball(body, "Main", Vector3(side * 0.306, 0.828, 0.024), Vector3(0.058, 0.091, 0.045), _skin, side * 0.21)
		_ball(body, "Pouce", Vector3(side * 0.266, 0.839, 0.048), Vector3(0.026, 0.046, 0.023), _skin, side * 0.25)
		_torus(glasses, "Monture", Vector3(side * 0.088, 1.671, 0.255), 0.070, 0.0042, _ink)
		_ball(glasses, "Branche", Vector3(side * 0.181, 1.690, 0.152), Vector3(0.049, 0.005, 0.111), _ink)
	_ball(glasses, "Pont", Vector3(0, 1.680, 0.254), Vector3(0.026, 0.004, 0.004), _ink)
	_add_accessories()
	_add_mouth(body)

	_ball(bob, "Volume arrière", Vector3(0, 1.780, -0.025), Vector3(0.236, 0.188, 0.200), _hair)
	_ball(bob, "Mèche", Vector3(-0.075, 1.832, 0.118), Vector3(0.145, 0.073, 0.102), _hair_light, 0.32)
	_ball(bob, "Frange", Vector3(0.054, 1.850, 0.108), Vector3(0.166, 0.061, 0.112), _hair, -0.34)
	_fringe_detail(bob, Vector3(0.054, 1.850, 0.108), Vector3(0.166, 0.061, 0.112), -0.34)
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
	_ball(crop, "Coupe courte", Vector3(0, 1.798, -0.019), Vector3(0.235, 0.146, 0.193), _hair_dark)
	_ball(crop, "Mèche courte", Vector3(0.030, 1.850, 0.113), Vector3(0.171, 0.064, 0.093), _hair, -0.19)
	_ball(crop, "Mèche courte", Vector3(-0.087, 1.861, 0.061), Vector3(0.117, 0.066, 0.096), _hair_light, 0.14)
	_ball(bun, "Coiffure tirée", Vector3(0, 1.802, -0.036), Vector3(0.232, 0.155, 0.193), _hair)
	_ball(bun, "Mèche brillante", Vector3(-0.033, 1.851, 0.105), Vector3(0.153, 0.060, 0.104), _hair_light, 0.16)
	_ball(bun, "Chignon", Vector3(-0.057, 1.962, -0.106), Vector3(0.112, 0.094, 0.109), _hair)
	_ball(bun, "Courbe du chignon", Vector3(-0.079, 1.986, -0.117), Vector3(0.086, 0.068, 0.088), _hair_light, 0.29)
	_ball(bob_long, "Masse", Vector3(0, 1.723, -0.052), Vector3(0.245, 0.242, 0.201), _hair)
	for side in [-1.0, 1.0]:
		_ball(bob_long, "Longueur", Vector3(side * 0.197, 1.622, 0.038), Vector3(0.071, 0.175, 0.108), _hair, side * -0.14)
	_ball(bob_long, "Frange", Vector3(-0.035, 1.834, 0.119), Vector3(0.201, 0.066, 0.092), _hair_light, 0.087)
	_ball(pony, "Coiffure attachée", Vector3(0, 1.789, -0.036), Vector3(0.229, 0.159, 0.192), _hair)
	_ball(pony, "Queue", Vector3(0.176, 1.609, -0.143), Vector3(0.108, 0.190, 0.101), _hair_light, -0.54)
	_ball(pony, "Élastique", Vector3(0.121, 1.775, -0.114), Vector3(0.043, 0.056, 0.044), trainer)
	_ball(pony, "Frange", Vector3(-0.051, 1.847, 0.113), Vector3(0.160, 0.058, 0.096), _hair, 0.14)
	_ball(split, "Coque", Vector3(0, 1.793, -0.039), Vector3(0.231, 0.170, 0.193), _hair)
	for side in [-1.0, 1.0]:
		_ball(split, "Raie", Vector3(side * 0.099, 1.821, 0.113), Vector3(0.110, 0.061, 0.103), _hair_light, side * 0.49)
	_ball(crest, "Dégradé", Vector3(0, 1.795, -0.031), Vector3(0.229, 0.145, 0.191), _hair_dark)
	for i in 5:
		_ball(crest, "Volume coiffé", Vector3(-0.044 + i * 0.019, 1.947 - i * 0.008, 0.126 - i * 0.036),
			Vector3(0.068, 0.087 - i * 0.006, 0.074), _hair_light if i % 2 == 0 else _hair, -0.29)
	_clothe(knit, _material("Laine", "#39766c"), _material("Bord-côte", "#2b584d"), false)
	_clothe(jacket, _material("Toile", "#ab5b43"), _material("Coutures", "#75443d"), true)
	var navy := _material("Marine", "#44577c")
	var mauve := _material("Surpiqûres", "#758cb1")
	_clothe(stand_collar, navy, mauve, true)
	_ball(stand_collar, "Col montant", Vector3(0, 1.358, 0.004), Vector3(0.118, 0.074, 0.099), navy)
	for side in [-1.0, 1.0]:
		_ball(stand_collar, "Poche", Vector3(side * 0.093, 1.080, 0.126), Vector3(0.041, 0.006, 0.012), mauve, side * -0.35)
	_add_haircuts()
	_add_tops()

	var packed := PackedScene.new()
	if packed.pack(_model) != OK:
		_model.free()
		quit(1)
		return
	var error := ResourceSaver.save(packed, "res://demo/modeles/ari.tscn")
	_model.free()
	quit(0 if error == OK else 1)

func _face_details() -> void:
	var noses := [
		["NezDroit", Vector3(0.043, 0.048, 0.042), 1.607],
		["NezFin", Vector3(0.031, 0.061, 0.040), 1.611],
		["NezLarge", Vector3(0.060, 0.042, 0.046), 1.601],
		["NezRetrousse", Vector3(0.045, 0.034, 0.060), 1.613],
	]
	for shape in noses:
		var nose := _group(shape[0])
		_ball(nose, "Arête", Vector3(0, 1.643, 0.214), Vector3(shape[1].x * 0.62, 0.045, 0.026), _skin)
		_ball(nose, "Pointe", Vector3(0, shape[2], 0.225), shape[1], _skin)
	_brows(_group("SourcilsDoux"), 0.0067, 0.010, 0.0)
	_brows(_group("SourcilsArques"), 0.0063, 0.024, 0.009)
	_brows(_group("SourcilsDroits"), 0.0055, 0.003, -0.005)
	_brows(_group("SourcilsDenses"), 0.010, 0.014, 0.0)
	_eyes(_group("YeuxAmande"), 0.055, 0.032, 0.085)
	_eyes(_group("YeuxRonds"), 0.050, 0.044, 0.025)
	_eyes(_group("YeuxEtires"), 0.063, 0.024, 0.17)
	_eyes(_group("YeuxDoux"), 0.052, 0.029, -0.075)

func _brows(parent: Node3D, weight: float, arch: float, slant: float) -> void:
	for side in [-1.0, 1.0]:
		var points := PackedVector3Array()
		var radii := PackedVector2Array()
		for index in 17:
			var t := float(index) / 16.0
			var height := 1.731 + sin(PI * t) * arch + t * slant
			var center := Vector3(side * lerpf(0.040, 0.150, t), height, lerpf(0.211, 0.166, t * t))
			var taper := minf(1.0, sqrt(t * 11.0)) * pow(1.0 - t, 0.58)
			points.append(center)
			radii.append(Vector2(weight * maxf(0.03, taper), 0.012 * maxf(0.03, taper)))
		_swept_detail(parent, "Arc", points, radii, _brow)

func _fringe_detail(parent: Node3D, center: Vector3, axes: Vector3, tilt: float) -> void:
	for strand in 3:
		var points := PackedVector3Array()
		var radii := PackedVector2Array()
		for step in 21:
			var t := float(step) / 20.0
			var x := lerpf(-0.83 + strand * 0.04, 0.78 - strand * 0.04, t)
			var y := 0.19 + strand * 0.15 - 0.24 * (t - 0.32) * (t - 0.32)
			var z := sqrt(maxf(0.0, 1.0 - x * x - y * y))
			points.append(center + Vector3(x * axes.x, y * axes.y, z * axes.z).rotated(Vector3.BACK, tilt))
			radii.append(Vector2(0.0024, 0.0017) * maxf(0.03, sin(PI * t)))
		_swept_detail(parent, "Relief de mèche", points, radii, _hair_light)

func _swept_detail(parent: Node3D, title: String, points: PackedVector3Array, radii: PackedVector2Array, material: Material) -> void:
	const SIDES := 8
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(material)
	for index in points.size():
		var tangent := (points[mini(points.size() - 1, index + 1)] - points[maxi(0, index - 1)]).normalized()
		var up := tangent.cross(Vector3.BACK).normalized()
		var front := up.cross(tangent)
		for side in SIDES:
			var angle := TAU * float(side) / SIDES
			var y := up * cos(angle)
			var z := front * sin(angle)
			var radius := radii[index]
			surface.set_normal((y / radius.x + z / radius.y).normalized())
			surface.add_vertex(points[index] + y * radius.x + z * radius.y)
	for row in points.size() - 1:
		for side in SIDES:
			var a := row * SIDES + side
			var b := row * SIDES + (side + 1) % SIDES
			for index in [a, b, a + SIDES, b, b + SIDES, a + SIDES]:
				surface.add_index(index)
	var node := MeshInstance3D.new()
	node.name = title
	node.mesh = surface.commit()
	parent.add_child(node, true)
	node.owner = _model

func _eyes(parent: Node3D, width: float, height: float, lift: float) -> void:
	for side in [-1.0, 1.0]:
		var x: float = side * 0.090
		_ball(parent, "Contour", Vector3(x, 1.670, 0.203), Vector3(width + 0.0028, height + 0.003, 0.027), _brow, side * lift)
		_ball(parent, "Blanc", Vector3(x, 1.669, 0.211), Vector3(width, height, 0.023), _white, side * lift)
		var iris_height := minf(0.027, height * 0.87)
		var iris_x: float = x - side * 0.005
		_ball(parent, "Iris", Vector3(iris_x, 1.669, 0.232), Vector3(0.025, iris_height, 0.007), _iris)
		_ball(parent, "Pupille", Vector3(iris_x, 1.669, 0.239), Vector3(0.013, iris_height * 0.60, 0.004), _ink)
		_ball(parent, "Reflet", Vector3(iris_x - 0.007, 1.678, 0.243), Vector3(0.005, 0.005, 0.0022), _white)

func _add_haircuts() -> void:
	var buzz := _group("CheveuxRases")
	_ball(buzz, "Duvet", Vector3(0, 1.797, -0.026), Vector3(0.208, 0.105, 0.161), _hair_dark)
	var braid := _group("CheveuxTresses")
	_ball(braid, "Base", Vector3(0, 1.800, -0.041), Vector3(0.229, 0.154, 0.194), _hair_dark)
	for index in 7:
		var x := (float(index) - 3.0) * 0.056
		_ball(braid, "Tresse plaquée", Vector3(x, 1.886 - absf(x) * 0.22, 0.003), Vector3(0.025, 0.040, 0.172 - absf(x) * 0.30), _hair_light if index % 2 == 0 else _hair)
	var long := _group("CheveuxLongs")
	_ball(long, "Masse arrière", Vector3(0, 1.624, -0.107), Vector3(0.239, 0.320, 0.143), _hair_dark)
	_ball(long, "Raie latérale", Vector3(-0.064, 1.856, 0.092), Vector3(0.175, 0.065, 0.112), _hair_light, 0.34)
	var double_bun := _group("CheveuxDoubleChignon")
	_ball(double_bun, "Base tirée", Vector3(0, 1.795, -0.043), Vector3(0.233, 0.158, 0.182), _hair)
	for side in [-1.0, 1.0]:
		for index in 10:
			var x: float = side * (0.177 + float(index) * 0.004)
			var y := 1.716 - float(index) * 0.042
			var offset := 0.017 * cos(float(index) * PI)
			_ball(braid, "Tresse pendante", Vector3(x + offset, y, 0.045 + float(index) * 0.002), Vector3(0.043, 0.031, 0.037), _hair_light if index % 2 == 0 else _hair, side * 0.57)
		_ball(long, "Longueur avant", Vector3(side * 0.203, 1.590, 0.042), Vector3(0.066, 0.244, 0.098), _hair, side * 0.04)
		_ball(double_bun, "Chignon haut", Vector3(side * 0.184, 1.946, -0.041), Vector3(0.097, 0.099, 0.093), _hair, side * 0.28)
		_ball(double_bun, "Reflet chignon", Vector3(side * 0.195, 1.974, -0.013), Vector3(0.078, 0.068, 0.069), _hair_light, side * -0.42)

func _add_tops() -> void:
	var hoodie := _group("SweatCapuche")
	var plum := _material("Molleton", "#684B74")
	var plum_rib := _material("Ourlet prune", "#473448")
	_clothe(hoodie, plum, plum_rib, false)
	_ball(hoodie, "Capuche rabattue", Vector3(0, 1.353, -0.075), Vector3(0.173, 0.089, 0.088), plum)
	_ball(hoodie, "Poche kangourou", Vector3(0, 1.068, 0.129), Vector3(0.118, 0.056, 0.019), plum_rib)
	for side in [-1.0, 1.0]:
		_ball(hoodie, "Cordon", Vector3(side * 0.055, 1.261, 0.116), Vector3(0.005, 0.068, 0.010), _white, side * 0.15)

	var biker := _group("Perfecto")
	var leather := _material("Cuir graphite", "#34303C", 0.35)
	var lapel := _material("Revers satin", "#26212D", 0.28)
	var hardware := _material("Métal brossé", "#aca4af", 0.38)
	_clothe(biker, leather, lapel, true)
	for side in [-1.0, 1.0]:
		_ball(biker, "Revers", Vector3(side * 0.081, 1.264, 0.117), Vector3(0.045, 0.114, 0.019), lapel, side * -0.50)
		_ball(biker, "Bouton-pression", Vector3(side * 0.103, 1.268, 0.137), Vector3(0.010, 0.011, 0.006), hardware)
		_ball(biker, "Zip de poche", Vector3(side * 0.118, 1.079, 0.122), Vector3(0.046, 0.005, 0.012), hardware, side * -0.64)

	var tee := _group("TShirt")
	var cotton := _material("Coton brique", "#a14a56")
	var rib := _material("Col brique", "#6F3948")
	_ball(tee, "Buste", Vector3(0, 1.128, 0), Vector3(0.204, 0.265, 0.125), cotton)
	_ball(tee, "Col", Vector3(0, 1.347, 0.002), Vector3(0.108, 0.054, 0.091), rib)
	_ball(tee, "Ourlet", Vector3(0, 0.953, -0.004), Vector3(0.185, 0.080, 0.122), rib)
	for side in [-1.0, 1.0]:
		_ball(tee, "Avant-bras", Vector3(side * 0.283, 0.992, 0.012), Vector3(0.054, 0.145, 0.056), _skin, side * 0.20)
		_ball(tee, "Manche courte", Vector3(side * 0.230, 1.222, 0), Vector3(0.081, 0.112, 0.079), cotton, side * 0.30)

func _trousers(parent: Node3D, fabric: Material, detail: Material, width: float, pockets: bool) -> void:
	_ball(parent, "Taille", Vector3(0, 0.900, -0.008), Vector3(0.191, 0.133, 0.132), fabric)
	for side in [-1.0, 1.0]:
		_ball(parent, "Jambe", Vector3(side * 0.106, 0.602, -0.012), Vector3(0.091 * width, 0.360, 0.103), fabric, side * 0.047)
		_ball(parent, "Bas", Vector3(side * 0.125, 0.267, -0.008), Vector3(0.069 * width, 0.169, 0.069), fabric)
		_ball(parent, "Ourlet", Vector3(side * 0.125, 0.178, 0), Vector3(0.067 * width, 0.036, 0.065), detail)
		if pockets:
			_ball(parent, "Poche cargo", Vector3(side * 0.162, 0.649, 0.072), Vector3(0.052, 0.074, 0.031), detail, side * 0.13)
			_ball(parent, "Rabat cargo", Vector3(side * 0.159, 0.685, 0.095), Vector3(0.048, 0.015, 0.015), fabric, side * 0.13)

func _footwear(parent: Node3D, upper: Material, sole: Material, boots: bool) -> void:
	for side in [-1.0, 1.0]:
		var x: float = side * 0.127
		_ball(parent, "Semelle", Vector3(x, 0.037, 0.070), Vector3(0.096, 0.036, 0.162), sole)
		_ball(parent, "Empeigne", Vector3(x, 0.088, 0.066), Vector3(0.093, 0.067, 0.157), upper)
		if boots:
			_ball(parent, "Tige", Vector3(x, 0.190, -0.014), Vector3(0.082, 0.142, 0.098), upper)
			_ball(parent, "Bord supèrieur", Vector3(x, 0.265, -0.014), Vector3(0.079, 0.029, 0.091), sole)
			for i in 4:
				_ball(parent, "Lacet de botte", Vector3(x, 0.230 - i * 0.028, 0.076 + i * 0.007), Vector3(0.038, 0.005, 0.016), sole)
		else:
			for i in 3:
				_ball(parent, "Lacet", Vector3(x, 0.136 - i * 0.006, 0.109 + i * 0.023), Vector3(0.042, 0.005, 0.007), sole)

func _add_accessories() -> void:
	var square := _group("LunettesRectangles")
	var pearl := _group("ClousArgent")
	var hoops := _group("Anneaux")
	var silver := _material("Argent", "#d4d6df", 0.32)
	for side in [-1.0, 1.0]:
		var x: float = side * 0.089
		for edge in [-1.0, 1.0]:
			_ball(square, "Horizontal", Vector3(x, 1.671 + edge * 0.043, 0.256), Vector3(0.067, 0.006, 0.008), _ink)
			_ball(square, "Vertical", Vector3(x + edge * 0.061, 1.671, 0.254), Vector3(0.007, 0.045, 0.009), _ink)
		_ball(square, "Branche", Vector3(side * 0.161, 1.691, 0.150), Vector3(0.010, 0.008, 0.107), _ink)
		_ball(pearl, "Clou", Vector3(side * 0.247, 1.578, 0.079), Vector3(0.014, 0.014, 0.011), silver)
		_torus(hoops, "Anneau", Vector3(side * 0.249, 1.555, 0.068), 0.032, 0.005, silver)
	_ball(square, "Pont", Vector3(0, 1.681, 0.254), Vector3(0.028, 0.005, 0.007), _ink)

func _head(parent: Node3D) -> void:
	var shape := [
		Vector4(1.391, 0.027, 0.042, 0.084),
		Vector4(1.410, 0.090, 0.097, 0.090),
		Vector4(1.446, 0.140, 0.133, 0.079),
		Vector4(1.498, 0.178, 0.159, 0.060),
		Vector4(1.553, 0.204, 0.181, 0.050),
		Vector4(1.613, 0.224, 0.188, 0.038),
		Vector4(1.673, 0.231, 0.190, 0.030),
		Vector4(1.734, 0.229, 0.182, 0.022),
		Vector4(1.792, 0.204, 0.156, 0.016),
		Vector4(1.843, 0.155, 0.124, 0.014),
		Vector4(1.873, 0.094, 0.083, 0.012),
		Vector4(1.888, 0.027, 0.037, 0.012),
	]
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	mesh.set_material(_skin)
	var ring_points: Array[Vector3] = []
	const SIDES := 56
	for band in shape.size() - 1:
		for row in 4:
			var u := float(row) / 4.0
			var previous: Vector4 = shape[maxi(0, band - 1)]
			var next: Vector4 = shape[mini(shape.size() - 1, band + 2)]
			var ring: Vector4 = shape[band].cubic_interpolate(shape[band + 1], previous, next, u)
			for side in SIDES:
				var t := TAU * float(side) / SIDES
				ring_points.append(Vector3(ring.y * sin(t), ring.x, ring.w + ring.z * cos(t)))
	var last: Vector4 = shape[-1]
	for side in SIDES:
		var t := TAU * float(side) / SIDES
		ring_points.append(Vector3(last.y * sin(t), last.x, last.w + last.z * cos(t)))
	for point in ring_points:
		mesh.set_smooth_group(0)
		mesh.add_vertex(point)
	var total_rings := int(ring_points.size() / SIDES)
	for row in total_rings - 1:
		for side in SIDES:
			var a := row * SIDES + side
			var b := row * SIDES + ((side + 1) % SIDES)
			for index in [a, a + SIDES, b, b, a + SIDES, b + SIDES]:
				mesh.add_index(index)
	mesh.generate_normals()
	var node := MeshInstance3D.new()
	node.name = "Visage"
	node.mesh = mesh.commit()
	parent.add_child(node)
	node.owner = _model

func _material(title: String, color: String, roughness := 0.80) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = title
	material.albedo_color = Color(color)
	material.roughness = roughness
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
	var pout := PackedVector3Array()
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
		pout.append(Vector3(x * -0.30, -0.011 * t * t - 0.003, 0.008))
		pout.append(Vector3(x * -0.30, 0.006 * (1.0 - t * t), 0.008))
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
	mesh.add_blend_shape("Moue")
	var pout_morph := morph.duplicate()
	pout_morph[Mesh.ARRAY_VERTEX] = pout
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array, [morph, pout_morph])
	_mouth.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, _mouth)
	var node := MeshInstance3D.new()
	node.name = "Sourire"
	node.mesh = mesh
	parent.add_child(node)
	node.owner = _model
