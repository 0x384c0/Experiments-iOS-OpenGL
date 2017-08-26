uniform float iTime;
uniform vec3 iResolution;

//shadertoy function
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
//    if ((fragCoord.xy / iResolution.xy).y <= .5 && (fragCoord.xy / iResolution.xy).x <= .5){
//        fragColor = vec4(1.,0.,0.,1.);
//        return;
//    }
    vec2 uv = fragCoord.xy / iResolution.xy;
    fragColor = vec4(uv,0.5+0.5*sin(iTime),0.9+0.1*sin(iTime));
    
}

void main(void) {
    mainImage(gl_FragColor,gl_FragCoord.xy);
}
