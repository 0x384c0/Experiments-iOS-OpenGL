
uniform highp float iTime;
uniform highp vec3 iResolution;
uniform sampler2D iChannel0;        // input channel. XX = 2D/Cube

highp vec4 textureLod(sampler2D sampler,highp vec2 par1, highp float par2){
    highp vec4 result = texture2D(sampler,par1,par2);
    return result;
}

//shadertoy function
void mainImage( out highp vec4 fragColor, in highp vec2 fragCoord ) {
    highp vec2 p = (0.5 * iResolution.xy - fragCoord.xy)/iResolution.y;
    fragColor = textureLod(iChannel0,p.xy,0.);
}

void main(void) {
    mainImage(gl_FragColor,gl_FragCoord.xy);
}
