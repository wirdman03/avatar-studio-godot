shader_type canvas_item;

void fragment() {
	vec2 centered = (UV - vec2(0.48, 0.48)) * vec2(1.12, 0.83);
	float glow = exp(-5.2 * dot(centered, centered));
	vec3 background = mix(vec3(0.025,0.062,0.058),vec3(0.082,0.245,0.205),glow);
	float bounce = exp(-18.0 * abs(UV.y - 0.86));
	background += vec3(0.037,0.099,0.079) * bounce * (1.0 - abs(UV.x - 0.5));
	vec2 floor_point = (UV - vec2(0.5,0.904)) * vec2(2.0,16.0);
	float shadow = exp(-5.0 * dot(floor_point,floor_point));
	vec2 corner = abs(UV - 0.5) - vec2(0.474, 0.468);
	float rounded = 1.0 - smoothstep(0.024, 0.028, length(max(corner, vec2(0.0))));
	COLOR = vec4(background * (1.0 - shadow * 0.22), rounded);
}
