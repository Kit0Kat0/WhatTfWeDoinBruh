shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0);
uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// Base: apply palette tint while preserving alpha.
	vec3 base_rgb = tex.rgb * tint_color.rgb;
	// Flash: mix toward white without changing alpha.
	vec3 flashed = mix(base_rgb, vec3(1.0), flash);
	COLOR = vec4(flashed, tex.a * tint_color.a);
}

