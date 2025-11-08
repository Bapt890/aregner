shader_type canvas_item;

uniform bool allow_out_of_bounds = true;
uniform float outline_thickness: hint_range(0.0, 50.0, 1.0) = 1.0;
uniform vec4 outline_color: source_color = vec4(1.0);
uniform int sample_quality: hint_range(4, 16, 1) = 8; // Reduce for better performance

vec4 blend(vec4 bottom, vec4 top) {
    float alpha = top.a + bottom.a * (1.0 - top.a);
    if (alpha < 0.0001) return vec4(0.0);
    vec3 color = mix(bottom.rgb * bottom.a, top.rgb, top.a) / alpha;
    return vec4(color, alpha);
}

void vertex() {
	if (allow_out_of_bounds) {
		VERTEX += (UV * 2.0 - 1.0) * outline_thickness;
	}
}

void fragment() {
	vec2 uv = UV;
	vec4 texture_color = texture(TEXTURE, UV);

	// Process outline only if needed
	if (outline_thickness > 0.0 && outline_color.a > 0.0) {
		if (allow_out_of_bounds) {
			vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(outline_thickness * 2.0));
			uv = (uv - texture_pixel_size * outline_thickness) * TEXTURE_PIXEL_SIZE / texture_pixel_size;

			if (uv == clamp(uv, vec2(0.0), vec2(1.0))) {
				texture_color = texture(TEXTURE, uv);
			} else {
				texture_color = vec4(0.0);
			}
		}

		// Only calculate outline if pixel is not already opaque
		if (texture_color.a < 0.99) {
			// Use circular sampling instead of nested loops
			float max_alpha = 0.0;
			float angle_step = 6.28318530718 / float(sample_quality); // 2*PI / samples
			float thickness_sq = outline_thickness * outline_thickness;

			// Sample in concentric circles
			int rings = int(ceil(outline_thickness));
			for (int r = 1; r <= rings; r++) {
				float ring_radius = float(r);
				if (ring_radius * ring_radius > thickness_sq) break;

				for (int a = 0; a < sample_quality; a++) {
					float angle = float(a) * angle_step;
					vec2 offset = vec2(cos(angle), sin(angle)) * ring_radius * TEXTURE_PIXEL_SIZE;
					vec2 sample_uv = uv + offset;

					// Check bounds only once
					if (sample_uv == clamp(sample_uv, vec2(0.0), vec2(1.0))) {
						float sample_alpha = texture(TEXTURE, sample_uv).a;
						max_alpha = max(max_alpha, sample_alpha);

						// Early exit if we found full opacity
						if (max_alpha > 0.99) break;
					}
				}

				if (max_alpha > 0.99) break;
			}

			COLOR = blend(vec4(outline_color.rgb, max_alpha * outline_color.a), texture_color);
		} else {
			COLOR = texture_color;
		}
	} else {
		COLOR = texture_color;
	}
}