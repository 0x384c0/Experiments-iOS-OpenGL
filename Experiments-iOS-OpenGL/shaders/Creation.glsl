
uniform highp float iTime;
uniform highp vec3 iResolution;

#define t iTime
#define r iResolution.xy

//shadertoy function
void mainImage( out highp vec4 fragColor, in highp vec2 fragCoord ) {
    highp vec3 c;
    highp float l,z=t;
    for(int i=0;i<3;i++) {
        highp vec2 uv,p=fragCoord.xy/r;
        uv=p;
        p-=.5;
        p.x*=r.x/r.y;
        z+=.07;
        l=length(p);
        uv+=p/l*(sin(z)+1.)*abs(sin(l*9.-z*2.));
        c[i]=.01/length(abs(mod(uv,1.)-.5));
    }
    fragColor=vec4(c/l,t);
}

void main(void) {
    mainImage(gl_FragColor,gl_FragCoord.xy);
}
