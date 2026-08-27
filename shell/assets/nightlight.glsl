precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {
    vec4 color = texture2D(tex, v_texcoord);
    
    color.r *= 1.00;
    color.g *= 0.80;
    color.b *= 0.65;
    
    gl_FragColor = color;
}
