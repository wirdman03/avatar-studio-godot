shader_type canvas_item;

void fragment() {
	vec2 centered = UV - vec2(0.5, 0.46);
	float glow = exp(-4.65 * dot(centered, centered));
	vec3 background = mix(vec3(0.10,0.20,0.23),vec3(0.41,0.55,0.47),glow);
	vec2 grid = fract(FRAGCOORD.xy / 18.0) - 0.50;
	float dots = 1.0 - smoothstep(0.023,0.066,length(grid));
	background += vec3(0.13,0.15,0.10) * dots * 0.42;
	vec2 floor_point = (UV - vec2(0.5,0.904)) * vec2(2.0,16.0);
	float shadow = exp(-5.0 * dot(floor_point,floor_point));
	COLOR = vec4(background * (1.0 - shadow * 0.28), 1.0);
}
