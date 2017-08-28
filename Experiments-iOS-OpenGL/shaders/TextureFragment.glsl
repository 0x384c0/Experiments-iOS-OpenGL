//shadertoy function
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 p = (0.5 * iResolution.xy - fragCoord.xy)/iResolution.y;
    fragColor = textureLod(iChannel0,p.xy,0.);
}
