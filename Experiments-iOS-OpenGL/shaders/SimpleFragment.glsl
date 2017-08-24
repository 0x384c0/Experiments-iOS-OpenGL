varying lowp vec4 DestinationColor;
uniform lowp float iTime;
uniform lowp vec3 iResolution;

//shadertoy function
void mainImage( out lowp vec4 fragColor, in lowp vec2 fragCoord ) {
    lowp vec2 uv = fragCoord.xy / iResolution.xy;
    fragColor = vec4(uv,0.5+0.5*sin(iTime),0.9+0.1*sin(iTime));
}

void main(void) {
    mainImage(gl_FragColor,gl_FragCoord.xy);
}
