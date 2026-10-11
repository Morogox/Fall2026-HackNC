shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float roughness : hint_range(0.0, 1.0) = 0.5;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

uniform vec4 color1 : source_color = vec4(0.0, 0.0, 0.0, 1.0); // Shadow color
uniform vec4 color2 : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Highlight color
uniform float threshold : hint_range(0.0, 1.0) = 0.5;          // Cel split point

vec3 lerpColor(vec3 colorA, vec3 colorB, float value) {
    float clampedValue = clamp(value, 0.0, 1.0);
    return mix(colorA, colorB, clampedValue);
}

void fragment() {
    vec4 tex_color = texture(albedo_texture, UV);
    ALBEDO = tex_color.rgb * albedo_tint.rgb;
    ROUGHNESS = roughness;
    METALLIC = metallic;
}

void light() {
    float NdotL = dot(NORMAL, LIGHT);
    float diffuse = clamp(NdotL, 0.0, 1.0);
    
    float cel = step(threshold, diffuse);
    
    vec3 shaded_color = lerpColor(color1.rgb, color2.rgb, cel);
    
    DIFFUSE_LIGHT += ALBEDO * shaded_color * ATTENUATION;
}