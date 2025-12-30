shader_type canvas_item;

// Use the full-screen image
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Crosshatching controls
uniform sampler2D hatch_tex;
uniform float hatch_scale = 4.0;
uniform float shadow_threshold = 0.3;
uniform float brightness_boost = 1.2;
uniform float contrast = 1.2;

void fragment() {
    // Sample the screen color
    vec3 screen_col = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;

    // Compute brightness
    float brightness = dot(screen_col, vec3(0.299, 0.587, 0.114));
    brightness = (brightness - 0.5) * contrast + 0.5;
    brightness *= brightness_boost;

    // Mix hatching based on brightness
    float shadow = smoothstep(shadow_threshold, 0.0, brightness);
    vec2 hatch_uv = SCREEN_UV * hatch_scale;
    float hatch_value = texture(hatch_tex, hatch_uv).r;
    float final_brightness = mix(brightness, hatch_value, shadow);

    COLOR = vec4(screen_col * final_brightness, 1.0);
}
