float rand(float co) {
return fract(sin(dot(co,12.9898+78.233)) * 43758.5453);
}
void mainImage( out vec4 o, in vec2 fragCoord ) {
vec2 uv = fragCoord.xy / iResolution.xy;
vec2 uv1 = uv;
uv1.y-=rand(uv.x*iTime)/60.;
vec4 e = texture(iChannel0,uv1);
vec4 bn = vec4(vec3(e.r+e.g+e.b)/3.,1.0);

vec2 offset = vec2(0.01*rand(iTime),sin(iTime)/30.);
e.r = texture(iChannel0, uv+offset.xy).r;
e.g = texture(iChannel0, uv).g;
e.b = texture(iChannel0, uv+offset.yx).b;
uv.y+=rand(iTime)/(sin(iTime)*10.);
uv.x-=rand(iTime+2.)/(sin(iTime)*10.)/30.;
if(sin(iTime*rand(iTime))<0.99) {
o=mix(e,bn,0.6);
} else {
o=texture(iChannel0,uv);
}
}
