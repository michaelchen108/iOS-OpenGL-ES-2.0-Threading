varying highp vec2 texCoordVarying;
uniform sampler2D texture;
precision mediump float;

void main() {
    gl_FragColor = texture2D(texture, texCoordVarying);
    
}