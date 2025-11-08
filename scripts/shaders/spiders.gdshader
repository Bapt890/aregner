shader_type canvas_item;

void fragment() {
    vec2 uv = UV;
    // Get the UV offset from instance custom data
    float u_offset = INSTANCE_CUSTOM.r;
    // Adjust UV to show 1/6th of the texture, offset by u_offset
    uv.x = uv.x / 6.0 + u_offset;
    COLOR = texture(TEXTURE, uv);
}