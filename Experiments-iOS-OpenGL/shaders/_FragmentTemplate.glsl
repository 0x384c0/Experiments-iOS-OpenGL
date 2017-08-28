uniform float iTime;
uniform vec3 iResolution;
uniform vec4 iMouse;
uniform sampler2D iChannel0;

vec4 textureLod(sampler2D sampler,vec2 par1, float par2){
    vec4 result = texture2D(sampler,par1,par2);
    return result;
}

SHADER_TOY_CODE_PLACEHOLDER

void main(void) {
    mainImage(gl_FragColor,gl_FragCoord.xy);
}
