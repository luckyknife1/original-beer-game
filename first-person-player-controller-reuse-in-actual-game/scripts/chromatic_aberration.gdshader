shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 5.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 offset = (uv - 0.5) * intensity * 0.02;

	vec4 col;
	col.r = texture(SCREEN_TEXTURE, uv + offset).r;
	col.g = texture(SCREEN_TEXTURE, uv).g;
	col.b = texture(SCREEN_TEXTURE, uv - offset).b;
	col.a = 1.0;

	COLOR = col;
}
