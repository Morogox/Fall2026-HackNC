shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, ambient_light_disabled;

uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec4 color1 : source_color = vec4(0.0, 0.0, 0.0, 1.0); // Shadow color
uniform vec4 color2 : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Highlight color

uniform float normal_depth : hint_range(0.0, 1.0) = 0.1;
uniform float softness : hint_range(0.0, 1.0) = 0.7;       // 0 = hard Lambert, 1 = full half-Lambert wrap
uniform float ambient_amount : hint_range(-1.0, 1.0) = 0.0; // neutral gray ambient (hue ignored)

void fragment() {
    ALBEDO = vec3(1.0);

    NORMAL_MAP = texture(normal_texture, UV).rgb;
    NORMAL_MAP_DEPTH = normal_depth;

    // Neutral, uncolored ambient (replaces the disabled environment ambient)
    EMISSION = vec3(ambient_amount);
}

void light() {
    float NdotL = dot(normalize(NORMAL), normalize(LIGHT));

    // Wrap lighting: blend between hard Lambert and half-Lambert
    float wrapped = NdotL * (0.5 * softness) + (0.5 * softness) + (1.0 - softness) * max(NdotL, 0.0);
    float diffuse = smoothstep(0.0, 1.0, clamp(wrapped, 0.0, 1.0));

    vec3 shaded_color = mix(color1.rgb, color2.rgb, diffuse);

    // Use only the brightness of the light, not its color
    float light_intensity = dot(LIGHT_COLOR, vec3(0.299, 0.587, 0.114));

    DIFFUSE_LIGHT += shaded_color * light_intensity * ATTENUATION;
}