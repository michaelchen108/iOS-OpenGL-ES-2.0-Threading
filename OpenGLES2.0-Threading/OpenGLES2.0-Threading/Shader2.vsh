attribute vec4 position;
attribute vec4 texture_coord;

//commenting this out doesn't change anything
//uniform sampler2D texture;

varying vec2 texCoordVarying;


void main() {
    gl_Position = position;
    texCoordVarying = texture_coord.st;
    
}

