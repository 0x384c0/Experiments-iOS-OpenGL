void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 tex = texture(iChannel1, uv);
    vec2 x = dFdx(tex.rg);
    vec2 y = dFdx(tex.gb);
    fragColor = texture2DGradEXT(iChannel0, uv, x, y);
}
