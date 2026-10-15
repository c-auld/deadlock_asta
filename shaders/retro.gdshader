shader_type canvas_item;

uniform float danger : hint_range(0.0, 1.0) = 0.0;
uniform float damage : hint_range(0.0, 1.0) = 0.0;
uniform float elapsed = 0.0;
uniform float grain_strength = 0.025;

float noise(vec2 point) {
    return fract(sin(dot(point, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec4 source = texture(TEXTURE, UV);
    vec2 pixel = floor(UV * vec2(480.0, 270.0));
    float dither = mod(pixel.x + mod(pixel.y, 2.0), 2.0) * 0.012;
    vec3 color = floor((source.rgb + dither) * 31.0) / 31.0;
    float grain = noise(pixel + floor(elapsed * 12.0)) - 0.5;
    color += grain * grain_strength;
    color *= 1.0 - 0.07 * mod(pixel.y, 2.0);
    vec2 centered = UV * 2.0 - 1.0;
    float vignette = smoothstep(0.35, 1.45, length(centered));
    color *= 1.0 - vignette * 0.48;
    color = mix(color, vec3(0.26, 0.035, 0.025), vignette * danger * 0.48);
    color = mix(color, vec3(0.45, 0.045, 0.025), damage * (0.12 + vignette * 0.38));
    COLOR = vec4(color, source.a);
}
