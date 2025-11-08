shader_type canvas_item;
uniform float strength = 1.0;

void fragment() {
	vec3 sprite_color = texture(TEXTURE, UV).rgb;
	vec3 color = mix(sprite_color, vec3(1), mod(sin(TIME * 3.) / 30. + 0.05, 0));
	COLOR.rgb = color;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
