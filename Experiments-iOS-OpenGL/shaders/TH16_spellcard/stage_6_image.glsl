void mainImage( out vec4 f, vec2 g )
{
	f = texture(iChannel0, g/iResolution.xy);
}