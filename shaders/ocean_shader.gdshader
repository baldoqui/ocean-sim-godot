shader_type spatial;

uniform sampler2D depth_texture : source_color, hint_depth_texture;
uniform sampler2D screen_texture: hint_screen_texture, filter_linear_mipmap;

uniform vec3 albedo : source_color = vec3(0, 0.321569, 0.431373);
uniform vec3 albedo2 : source_color = vec3(0, 0.47451, 0.764706);
uniform float metallic : hint_range(0.0, 1.0) = 0;
uniform float roughness : hint_range(0.0, 1.0) = 0.02;

// waves
uniform int wave_count = 20;
uniform float init_amplitude = 1.0;
uniform float init_frequence = 1.0;
uniform float frequence_increase = 1.0;
uniform float amplitude_decay = 0.82;
uniform float wave_speed =1;

uniform vec4 color_deep : source_color = vec4(0.105882, 0.294118, 0.329412, 1); // Deep depth color
uniform vec4 color_shallow : source_color =  vec4(0, 0.552941, 0.65098, 1); // Shallow depth color
uniform float beers_law = 2.0; // Beer's law application
uniform float depth_offset = -0.75; // Offset

uniform float edge_scale = 0.1;
uniform float near = 1.0;
uniform float far = 100.0;
uniform vec3 edge_color : source_color;

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}
float edge(float depth){
	depth = 2.0 * depth - 1.0;
	return near * far / (far + depth * (near - far));
}

float rand(float n) {
    return fract(sin(n) * 43758.5453123);
}

vec2 getWaveDirection(int index, int totalWaves) {
    float angle = rand(float(index)) * 2.0 * PI;
    return vec2(cos(angle), sin(angle));
}

float sinWave(vec2 pos, vec2 direction, float w, float speed, float amplitude) {
	float funcsin = amplitude * sin(dot(direction, pos) * w + (TIME * speed));
    return exp(funcsin)-exp(funcsin/2.0);
}

vec3 normalWave(vec2 pos, vec2 direction, float w, float speed, float amplitude) {
    float funccos = amplitude * sin(dot(direction, pos) * w + (TIME * speed));
	float funccosx = amplitude * w * dot(direction, vec2(1,0)) * cos(dot(direction, pos) * w + (TIME * speed));
	float funccosy = amplitude * w * dot(direction, vec2(0,1)) * cos(dot(direction, pos) * w + (TIME * speed));

	float dx = funccosx*exp(funccos);
	float dy = funccosy*exp(funccos);

    return vec3(-dx, 1, -dy);
}

vec4 createWave(vec2 pos, vec2 direction, float w, float speed, float amplitude) {
    float phaseconstant = speed / w;

	float yval = sinWave(pos, direction, w, phaseconstant, amplitude);
    vec3 normal = normalWave(pos, direction, w, phaseconstant, amplitude);
    return vec4(normal.x, normal.y, normal.z, yval);
}

void vertex() {
    vec4 res = vec4(0,0,0,0);
    float amplitude = init_amplitude;
	float w = init_frequence;

    for (int i = 0; i < wave_count; i++) {
        vec2 direction = getWaveDirection(i, wave_count); // almost random

		res += createWave(vec2(VERTEX.x, VERTEX.z), direction, w, wave_speed, amplitude);

		amplitude *= amplitude_decay;
		w *= frequence_increase;
	}

	res.y=1.0;

    VERTEX.y = res.a;
    NORMAL = res.xyz;
}

void fragment() {
    float raw_depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
    vec4 world = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, raw_depth, 1.0);
    world.xyz /= world.w;

    float linear_depth = -world.z;

	float depth_blend = exp(((linear_depth)+VERTEX.z + depth_offset) * -beers_law);
	depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
	float depth_blend_power = clamp(pow(depth_blend, 2.5), 0.0, 1.0);

	// Retrieving depth color and applying the deep and shallow colors
	vec3 screen_color = textureLod(screen_texture, SCREEN_UV, depth_blend_power * 2.5).rgb;
	vec3 depth_color = mix(color_shallow.rgb, color_deep.rgb, depth_blend_power);
	vec3 color = mix(screen_color * depth_color, depth_color * 0.25, depth_blend_power * 0.5);

	// Getting edge depth calc
	float z_depth = edge(linear_depth);
	float z_pos = edge(FRAGCOORD.z);
	float z_dif = z_pos - z_depth;

	float fresnel = fresnel(5.0, NORMAL, VIEW);
	vec3 surface_color = mix(albedo, albedo2, fresnel);

	vec3 depth_color_adj = mix(edge_color, color, step(edge_scale, z_dif));

	ALBEDO = clamp(surface_color + depth_color_adj,vec3(0.0),vec3(1.0));
	METALLIC = metallic;
	ROUGHNESS = roughness;
}
