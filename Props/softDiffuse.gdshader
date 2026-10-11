shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform vec3 shadow_color : source_color = vec3(0.12, 0.08, 0.25);
uniform vec3 light_color : source_color = vec3(1.0, 0.75, 0.4);


uniform vec3 channel_mask = vec3(1.0, 0.0, 0.0);

uniform float softness : hint_range(0.0, 1.0) = 0.7;

uniform float falloff : hint_range(0.1, 4.0) = 1.0;

uniform float intensity : hint_range(0.0, 4.0) = 1.0;

void fragment() {
    ALBEDO = vec3(1.0);
}

void light() {
    float ndotl = dot(NORMAL, LIGHT);
    float lambert = max(ndotl, 0.0);
    float half_lambert = ndotl * 0.5 + 0.5;
    float d = mix(lambert, half_lambert, softness);

    d = pow(clamp(d, 0.0, 1.0), falloff);

    float light_channel = dot(LIGHT_COLOR, channel_mask);
    d *= light_channel * ATTENUATION * intensity;
    d = clamp(d, 0.0, 1.0);

    DIFFUSE_LIGHT += mix(shadow_color, light_color, d);
}