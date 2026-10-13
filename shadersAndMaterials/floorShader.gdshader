shader_type spatial;

uniform sampler2D normal_map : hint_normal;
uniform float metallic : hint_range(0.0, 1.0) = 0.96;
uniform float roughness : hint_range(0.0, 1.0) = 0.18; 
uniform vec4 base_color : source_color = vec4(1.0);
uniform float texture_scale = 0.2; 

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	ALBEDO = base_color.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	
	vec2 world_uv = world_position.xz * texture_scale;
	
	NORMAL_MAP = texture(normal_map, world_uv).rgb;
	NORMAL_MAP_DEPTH = 0.1;
}
