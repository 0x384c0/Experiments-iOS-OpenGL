
uniform highp float iTime;
uniform highp vec3 iResolution;
highp vec4 iMouse = vec4(1.0,1.0,1.0,1.0);   // mouse pixel coords. xy: current (if MLB down), zw: click //TODO: replace with touch recognizer

const highp int NUM_STEPS = 8;
const highp float PI	 	= 3.141592;
const highp float EPSILON	= 1e-3;
#define EPSILON_NRM (0.1 / iResolution.x)

// sea
const highp int ITER_GEOMETRY = 3;
const highp int ITER_FRAGMENT = 5;
const highp float SEA_HEIGHT = 0.6;
const highp float SEA_CHOPPY = 4.0;
const highp float SEA_SPEED = 0.8;
const highp float SEA_FREQ = 0.16;
const highp vec3 SEA_BASE = vec3(0.1,0.19,0.22);
const highp vec3 SEA_WATER_COLOR = vec3(0.8,0.9,0.6);
#define SEA_TIME (1.0 + iTime * SEA_SPEED)
const highp mat2 octave_m = mat2(1.6,1.2,-1.2,1.6);

// math
highp mat3 fromEuler(highp vec3 ang) {
    highp vec2 a1 = vec2(sin(ang.x),cos(ang.x));
    highp vec2 a2 = vec2(sin(ang.y),cos(ang.y));
    highp vec2 a3 = vec2(sin(ang.z),cos(ang.z));
    highp mat3 m;
    m[0] = vec3(a1.y*a3.y+a1.x*a2.x*a3.x,a1.y*a2.x*a3.x+a3.y*a1.x,-a2.y*a3.x);
    m[1] = vec3(-a2.y*a1.x,a1.y*a2.y,a2.x);
    m[2] = vec3(a3.y*a1.x*a2.x+a1.y*a3.x,a1.x*a3.x-a1.y*a3.y*a2.x,a2.y*a3.y);
    return m;
}
highp float hash( highp vec2 p ) {
    highp float h = dot(p,vec2(127.1,311.7));
    return fract(sin(h)*43758.5453123);
}
highp float noise( in highp vec2 p ) {
    highp vec2 i = floor( p );
    highp vec2 f = fract( p );
    highp vec2 u = f*f*(3.0-2.0*f);
    return -1.0+2.0*mix( mix( hash( i + vec2(0.0,0.0) ),
                             hash( i + vec2(1.0,0.0) ), u.x),
                        mix( hash( i + vec2(0.0,1.0) ),
                            hash( i + vec2(1.0,1.0) ), u.x), u.y);
}

// lighting
highp float diffuse(highp vec3 n,highp vec3 l,highp float p) {
    return pow(dot(n,l) * 0.4 + 0.6,p);
}
highp float specular(highp vec3 n,highp vec3 l,highp vec3 e,highp float s) {
    highp float nrm = (s + 8.0) / (PI * 8.0);
    return pow(max(dot(reflect(e,n),l),0.0),s) * nrm;
}

// sky
highp vec3 getSkyColor(highp vec3 e) {
    e.y = max(e.y,0.0);
    return vec3(pow(1.0-e.y,2.0), 1.0-e.y, 0.6+(1.0-e.y)*0.4);
}

// sea
highp float sea_octave(highp vec2 uv, highp float choppy) {
    uv += noise(uv);
    highp vec2 wv = 1.0-abs(sin(uv));
    highp vec2 swv = abs(cos(uv));
    wv = mix(wv,swv,wv);
    return pow(1.0-pow(wv.x * wv.y,0.65),choppy);
}

highp float map(highp vec3 p) {
    highp float freq = SEA_FREQ;
    highp float amp = SEA_HEIGHT;
    highp float choppy = SEA_CHOPPY;
    highp vec2 uv = p.xz; uv.x *= 0.75;
    
    highp float d, h = 0.0;
    for(int i = 0; i < ITER_GEOMETRY; i++) {
        d = sea_octave((uv+SEA_TIME)*freq,choppy);
        d += sea_octave((uv-SEA_TIME)*freq,choppy);
        h += d * amp;
        uv *= octave_m; freq *= 1.9; amp *= 0.22;
        choppy = mix(choppy,1.0,0.2);
    }
    return p.y - h;
}

highp float map_detailed(highp vec3 p) {
    highp float freq = SEA_FREQ;
    highp float amp = SEA_HEIGHT;
    highp float choppy = SEA_CHOPPY;
    highp vec2 uv = p.xz; uv.x *= 0.75;
    
    highp float d, h = 0.0;
    for(int i = 0; i < ITER_FRAGMENT; i++) {
        d = sea_octave((uv+SEA_TIME)*freq,choppy);
        d += sea_octave((uv-SEA_TIME)*freq,choppy);
        h += d * amp;
        uv *= octave_m; freq *= 1.9; amp *= 0.22;
        choppy = mix(choppy,1.0,0.2);
    }
    return p.y - h;
}

highp vec3 getSeaColor(highp vec3 p, highp vec3 n, highp vec3 l, highp vec3 eye, highp vec3 dist) {
    highp float fresnel = clamp(1.0 - dot(n,-eye), 0.0, 1.0);
    fresnel = pow(fresnel,3.0) * 0.65;
    
    highp vec3 reflected = getSkyColor(reflect(eye,n));
    highp vec3 refracted = SEA_BASE + diffuse(n,l,80.0) * SEA_WATER_COLOR * 0.12;
    
    highp vec3 color = mix(refracted,reflected,fresnel);
    
    highp float atten = max(1.0 - dot(dist,dist) * 0.001, 0.0);
    color += SEA_WATER_COLOR * (p.y - SEA_HEIGHT) * 0.18 * atten;
    
    color += vec3(specular(n,l,eye,60.0));
    
    return color;
}

// tracing
highp vec3 getNormal(highp vec3 p, highp float eps) {
    highp vec3 n;
    n.y = map_detailed(p);
    n.x = map_detailed(vec3(p.x+eps,p.y,p.z)) - n.y;
    n.z = map_detailed(vec3(p.x,p.y,p.z+eps)) - n.y;
    n.y = eps;
    return normalize(n);
}

highp float heightMapTracing(highp vec3 ori, highp vec3 dir, out highp vec3 p) {
    highp float tm = 0.0;
    highp float tx = 1000.0;
    highp float hx = map(ori + dir * tx);
    if(hx > 0.0) return tx;
    highp float hm = map(ori + dir * tm);
    highp float tmid = 0.0;
    for(int i = 0; i < NUM_STEPS; i++) {
        tmid = mix(tm,tx, hm/(hm-hx));
        p = ori + dir * tmid;
        highp float hmid = map(p);
        if(hmid < 0.0) {
            tx = tmid;
            hx = hmid;
        } else {
            tm = tmid;
            hm = hmid;
        }
    }
    return tmid;
}




//shadertoy function
void mainImage( out highp vec4 fragColor, in highp vec2 fragCoord ) {
    highp vec2 uv = fragCoord.xy / iResolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    highp float time = iTime * 0.3 + iMouse.x*0.01;
    
    // ray
    highp vec3 ang = vec3(sin(time*3.0)*0.1,sin(time)*0.2+0.3,time);
    highp vec3 ori = vec3(0.0,3.5,time*5.0);
    highp vec3 dir = normalize(vec3(uv.xy,-2.0)); dir.z += length(uv) * 0.15;
    dir = normalize(dir) * fromEuler(ang);
    
    // tracing
    highp vec3 p;
    heightMapTracing(ori,dir,p);
    highp vec3 dist = p - ori;
    highp vec3 n = getNormal(p, dot(dist,dist) * EPSILON_NRM);
    highp vec3 light = normalize(vec3(0.0,1.0,0.8));
    
    // color
    highp vec3 color = mix(
                     getSkyColor(dir),
                     getSeaColor(p,n,light,dir,dist),
                     pow(smoothstep(0.0,-0.05,dir.y),0.3));
    
    // post
    fragColor = vec4(pow(color,vec3(0.75)), 1.0);
}


void main(void) {
    mainImage(gl_FragColor,gl_FragCoord.xy);
}
