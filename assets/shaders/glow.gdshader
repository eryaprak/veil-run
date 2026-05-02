shader_type canvas_item;

// Neon Glow Shader for Veil Run
// Creates outer glow effect for sprites

uniform vec4 glow_color : source_color = vec4(0.8, 0.4, 1.0, 1.0);
uniform float glow_strength : hint_range(0.0, 2.0) = 1.0;
uniform float glow_size : hint_range(0.0, 0.5) = 0.1;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	
	// Sample surrounding pixels for glow
	float alpha_sum = 0.0;
	int samples = 8;
	float angle_step = 6.28318 / float(samples);
	
	for (int i = 0; i < samples; i++) {
		float angle = float(i) * angle_step;
		vec2 offset = vec2(cos(angle), sin(angle)) * glow_size;
		alpha_sum += texture(TEXTURE, UV + offset).a;
	}
	
	alpha_sum /= float(samples);
	
	// Combine original with glow
	vec4 glow = glow_color * alpha_sum * glow_strength;
	COLOR = mix(glow, tex, tex.a);
	COLOR.a = max(tex.a, glow.a);
}
