
shader_type sky;

uniform vec4 color1 : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 color2 : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color3 : source_color = vec4(0.0, 0.0, 0.0, 1.0);

vec3 lerpColor(vec3 colorA, vec3 colorB, float value) {
    float clampedValue = clamp(value, 0.0, 1.0);
    
    return mix(colorA, colorB, clampedValue);
}


vec3 hash3(vec3 p) {
    p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
             dot(p, vec3(269.5, 183.3, 246.1)),
             dot(p, vec3(113.5, 271.9, 124.6)));
    return fract(sin(p) * 43758.5453123);
}

vec4 voronoi3d(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);

    float min_dist = 8.0;
    vec3 closest_cell = vec3(0.0);

    // Loop through 3x3x3 neighboring cells
    for (int k = -1; k <= 1; k++) {
        for (int j = -1; j <= 1; j++) {
            for (int i = -1; i <= 1; i++) {
                vec3 cell_offset = vec3(float(i), float(j), float(k));
                // Get random position inside the cell boundary
                vec3 cell_position = hash3(p + cell_offset);
                
                // Vector from input point to the random cell point
                vec3 r = cell_offset + cell_position - f;
                float d = dot(r, r); // Squared distance for performance

                if (d < min_dist) {
                    min_dist = d;
                    closest_cell = cell_offset + cell_position + p;
                }
            }
        }
    }
    
    // Return sqrt of distance for true Euclidean distance, and cell center
    return vec4(sqrt(min_dist), closest_cell);
}

void sky() {
    float phi = SKY_COORDS.x * PI * 2.0;
    float theta = SKY_COORDS.y * PI;
    vec3 dir = vec3(sin(theta) * sin(phi), cos(theta), sin(theta) * cos(phi));
    vec3 rotated_dir = vec3(dir.x, -dir.z, dir.y); 
    
    vec2 rotated_uv;
    rotated_uv.x = atan(rotated_dir.x, rotated_dir.z) / (PI * 2.0) + 0.5;
    rotated_uv.y = acos(rotated_dir.y*0.6) / PI;
    
	vec4 voronoi = voronoi3d(vec3(rotated_uv*15.0,TIME*0.4));
	float value = pow(voronoi.r,4);
	
	float distanceValue = pow(distance(rotated_uv, vec2(0.5,0.5))*4.0,1.3);
	//COLOR = vec3(distanceValue,distanceValue,distanceValue);
	vec3 newBlue = lerpColor(color3.rgb,color1.rgb, distanceValue);
    COLOR = lerpColor(newBlue, color2.rgb, value);
}
