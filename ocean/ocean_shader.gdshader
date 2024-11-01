shader_type spatial;

uniform vec3 albedo : source_color; //vec3(0.0, 0.1, 0.28)
uniform float metalic : hint_range(0.0, 1.0)=0;
uniform float roughtness : hint_range(0.0, 1.0)=0.02;

uniform int wave_count = 20;
uniform float init_wave_amplitude = 1.0;
uniform float init_wave_frequence = 1.0;
uniform float wave_frequence_increase = 1.0;
uniform float amplitude_decay = 0.82;
uniform float correct_height = 10;
uniform float wave_speed =1;

float rand(float n) {
    return fract(sin(n) * 43758.5453123);
}

vec2 getWaveDirection(int index, int totalWaves) {
    float angle = rand(float(index)) * 2.0 * PI;
    return vec2(cos(angle), sin(angle));
}


float sinWave(vec2 pos, vec2 direction, float w, float speed, float amplitude) {
    return exp(amplitude * sin(dot(direction, pos) * w + (TIME * speed)) - 1.0);
}

vec3 normalWave(vec2 pos, vec2 direction, float w, float speed, float amplitude) {
    float dx = w*dot(direction, vec2(1,0))*amplitude*cos(dot(direction,pos)*w+(TIME * speed))*exp(amplitude * sin(dot(direction, pos) * w + (TIME * speed))-1.0);   //* amplitude*cos(dot(direction,pos) * w + (TIME * speed));
	float dy = w*dot(direction, vec2(0,1))*amplitude*cos(dot(direction,pos)*w+(TIME * speed))*exp(amplitude * sin(dot(direction, pos) * w + (TIME * speed))-1.0);

    return vec3(-dx, 1, -dy);
}

vec4 createWave(vec2 pos, vec2 direction, float w, float speed, float amplitude) {
    float yval = sinWave(pos, direction, w, speed, amplitude);
    vec3 normal = normalWave(pos, direction, w, speed, amplitude);
    return vec4(normal.x, normal.y, normal.z, yval);
}

void vertex() {
    vec4 res = vec4(0.0);
    float amplitude = init_wave_amplitude;
	float w = init_wave_frequence;

    for (int i = 0; i < wave_count; i++) {
        vec2 direction = getWaveDirection(i, wave_count); // é quase aleatório
        res += createWave(vec2(VERTEX.x, VERTEX.z), direction, w, wave_speed, amplitude);
        amplitude *= amplitude_decay;
		w *= wave_frequence_increase;

	}

	res.a -= correct_height;

    VERTEX.y = res.a;
    NORMAL = res.xyz;
}

void fragment() {
    ALBEDO = albedo.rgb;
	//METALLIC = metalic;
	//ROUGHNESS = roughtness;
	//NORMAL_MAP = NORMAL;
}
