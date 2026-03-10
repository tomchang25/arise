shader_type canvas_item;

uniform float overlay_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 overlay_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);

	if (texture_color.a == 0.0) {
		COLOR = texture_color;
	} else {
		vec3 final_rgb = mix(texture_color.rgb, overlay_color.rgb, overlay_amount);
		COLOR = vec4(final_rgb, texture_color.a);
	}
}