
shader_type spatial;
render_mode unshaded;

uniform sampler2D albedo_tex : source_color;
uniform vec2 content_scale = vec2(1.0, 1.0);
uniform vec2 content_offset = vec2(0.0, 0.0);
uniform vec4 background_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 fitted_uv = (UV - content_offset) / content_scale;

	if (any(lessThan(fitted_uv, vec2(0.0))) ||
		any(greaterThan(fitted_uv, vec2(1.0)))) {
		ALBEDO = background_color.rgb;
		ALPHA = background_color.a;
	} else {
		vec4 color = texture(albedo_tex, fitted_uv);
		ALBEDO = color.rgb;
		ALPHA = color.a;
	}
}
