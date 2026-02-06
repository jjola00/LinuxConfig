//
// Simple night light shader for Hyprland screen_shader.
//

#version 300 es

precision mediump float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

void main() {
    vec4 c = texture(tex, v_texcoord);
    c.r *= 0.90;
    c.g *= 0.75;
    c.b *= 0.55;
    c.rgb *= 0.85;
    fragColor = c;
}
