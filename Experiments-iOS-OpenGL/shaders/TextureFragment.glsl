
uniform float iTime;
uniform vec3 iResolution;
uniform sampler2D iChannel0;        // input channel. XX = 2D/Cube

vec4 textureLod(sampler2D sampler,vec2 par1, float par2){
    vec4 result = texture2D(sampler,par1,par2);
    return result;
}

//shadertoy function
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 p = (0.5 * iResolution.xy - fragCoord.xy)/iResolution.y;
    fragColor = textureLod(iChannel0,p.xy,0.);
}

void main(void) {
    mainImage(gl_FragColor,gl_FragCoord.xy);
}
