extends RefCounted

static var _cache: Dictionary = {}

static func get_icon(category: String) -> Texture2D:
	if _cache.has(category):
		return _cache[category]
	var lines: Array
	match category:
		"hair":
			lines = [[[4,16],[4,10],[6,5],[10,3],[15,3],[19,6],[20,12],[20,16]],
				[[4,13],[9,11],[14,6],[17,10],[20,11]],[[7,16],[8,20],[12,22],[16,20],[17,16]]]
		"face", "expression":
			lines = [_loop(Vector2(12,12), 9), [[8,10],[8,9]], [[16,10],[16,9]],
				[[7,14],[9,17],[12,18],[15,17],[17,14]]]
		"skin":
			lines = [[[12,2],[8,8],[5,13],[5,17],[7,20],[12,22],[17,20],[19,17],[19,13],[16,8],[12,2]],
				[[8,15],[8,17],[10,18]]]
		"outfit", "top", "jacket_color":
			lines = [[[8,4],[11,6],[13,6],[16,4],[22,8],[19,13],[17,11],[17,20],[7,20],[7,11],
				[5,13],[2,8],[8,4]]]
		"glasses", "eyewear":
			lines = [_loop(Vector2(6.6,13.1), 4.5), _loop(Vector2(17.4,13.1), 4.5), [[11,12],[12,11],[13,12]]]
		"hair_color":
			lines = [[[4,17],[5,11],[9,6],[14,4],[20,4],[19,8],[16,11],[11,13],[8,17],[8,21]],[[13,13],[19,13],[17,18],[19,21],[21,18],[19,13]]]
		"eyes":
			lines = [[[2,12],[6,8],[12,6],[18,8],[22,12],[18,16],[12,18],[6,16],[2,12]],_loop(Vector2(12,12), 4)]
		"eye_color":
			lines = [_loop(Vector2(12,12), 9), _loop(Vector2(12,12), 4), [[12,3],[12,7]],[[21,12],[17,12]],[[12,21],[12,17]],[[3,12],[7,12]]]
		"eyebrows":
			lines = [[[2,13],[5,10],[8,10],[10,12]],[[14,12],[16,10],[19,10],[22,13]],[[3,16],[6,14],[9,15]],[[15,15],[18,14],[21,16]]]
		"nose":
			lines = [[[12,3],[11,8],[8,13],[7,16],[8,19],[12,20],[16,18],[17,15]],[[15,16],[14,18]]]
		"trousers":
			lines = [[[5,4],[19,4],[21,21],[14,21],[12,11],[10,21],[3,21],[5,4]],[[5,7],[19,7]]]
		"shoes":
			lines = [[[4,6],[11,6],[11,11],[15,14],[21,15],[22,18],[22,20],[3,20],[3,17],[4,6]],[[3,17],[21,17]],[[9,11],[13,11]]]
		"jewelry":
			lines = [_loop(Vector2(12,13), 7), [[10,5],[12,2],[14,5]],[[11,19],[12,22],[13,19]]]
		"close":
			lines = [[[6,6],[18,18]],[[6,18],[18,6]]]
		"previous":
			lines = [[[15,5],[8,12],[15,19]]]
		"next":
			lines = [[[9,5],[16,12],[9,19]]]
		"undo", "redo":
			lines = [[[9,5],[4,10],[9,14]],[[4,10],[14,10],[17,11],[19,14],[19,17],[17,20]]]
			if category == "redo":
				for line: Array in lines:
					for point: Array in line:
						point[0] = 24 - point[0]
		"full":
			lines = [[[9,4],[4,4],[4,9]],[[15,4],[20,4],[20,9]],[[4,15],[4,20],[9,20]],[[15,20],[20,20],[20,15]]]
		"portrait":
			lines = [_loop(Vector2(12, 9), 3.3), [[5,20],[6,17],[9,15],[15,15],[18,17],[19,20]]]
		"check":
			lines = [[[5,12],[10,17],[19,7]]]
		"categories":
			lines = []
			for x in [4, 14]:
				for y in [4, 14]:
					lines.append([[x,y],[x+6,y],[x+6,y+6],[x,y+6],[x,y]])
		_:
			lines = [[[12,2],[21,8],[21,16],[12,22],[3,16],[3,8],[12,2]],
				[[3,8],[12,13],[21,8]],[[12,13],[12,22]]]
	var segments: Array = []
	for line in lines:
		for i in line.size()-1:
			segments.append([Vector2(line[i][0],line[i][1]), Vector2(line[i+1][0],line[i+1][1])])
	var image := Image.create(48,48,false,Image.FORMAT_RGBA8)
	for y in 48:
		for x in 48:
			var point := Vector2(x+0.5,y+0.5)*0.5
			var nearest := 24.0
			for segment in segments:
				var closest := Geometry2D.get_closest_point_to_segment(point,segment[0],segment[1])
				nearest = minf(nearest, point.distance_to(closest))
			var edge := 1.0-smoothstep(0.82,1.42,nearest)
			image.set_pixel(x,y,Color(1,1,1,edge))
	_cache[category] = ImageTexture.create_from_image(image)
	return _cache[category]

static func _loop(center: Vector2, radius: float) -> Array:
	var points: Array = []
	for i in 17:
		var p := center + Vector2.from_angle(TAU*float(i)/16)*radius
		points.append([p.x,p.y])
	return points
