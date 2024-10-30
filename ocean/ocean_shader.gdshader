shader_type spatial;

uniform vec4 water_color;

float sinWave(vec2 pos, vec2 direction, float waveLength, float speed, float height_scale) {
    float w = 2.0 * PI / waveLength;
    return height_scale * sin(dot(direction, pos) * w + (TIME * speed));
}

vec3 normalWave(vec2 pos, vec2 direction, float waveLength, float speed, float height_scale) {
    float w = 2.0 * PI / waveLength;

    float dx = w * dot(direction, vec2(1,0)) * height_scale*cos(dot(direction,pos) * w + (TIME * speed));
	float dy = w * dot(direction, vec2(0,1)) * height_scale*cos(dot(direction,pos) * w + (TIME * speed));

    return vec3(-dx,1,-dy);
}

vec4 createWave(vec2 pos, vec2 direction, float waveLength, float speed, float height_scale){
	float yval = sinWave(pos, direction, waveLength, speed, height_scale);
	vec3 normal = normalWave(pos, direction, waveLength, speed, height_scale);
	return vec4(normal.x, normal.y, normal.z, yval);
}

void vertex() {
	vec4 res;
	res = createWave(vec2(VERTEX.x, VERTEX.z), vec2(1, 1), 0.5, 0.7, 0.05);
	res += createWave(vec2(VERTEX.x, VERTEX.z), vec2(-1, -1), 1, 0.6, 0.025);
	res += createWave(vec2(VERTEX.x, VERTEX.z), vec2(-1, 1), 1, 1, 0.05);
	res += createWave(vec2(VERTEX.x, VERTEX.z), vec2(1, -1), 0.8, 0.5, 0.025);
	
    VERTEX.y = res.a;
	NORMAL = vec3(res.x, res.y, res.z);
}

void fragment() {
	// Definir a cor do material com base na intensidade da luz
    ALBEDO = water_color.rgb;
}
