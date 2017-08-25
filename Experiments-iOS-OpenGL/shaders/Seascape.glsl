varying lowp vec4 DestinationColor;
uniform lowp float iTime;
uniform lowp vec3 iResolution;
lowp vec4 iMouse = vec4(1.0,1.0,1.0,1.0);   // mouse pixel coords. xy: current (if MLB down), zw: click //TODO: replace with touch recognizer

const lowp int NUM_STEPS = 8;
const lowp float PI	 	= 3.141592;
const lowp float EPSILON	= 1e-3;
#define EPSILON_NRM (0.1 / iResolution.x)

// sea
const lowp int ITER_GEOMETRY = 3;
const lowp int ITER_FRAGMENT = 5;
const lowp float SEA_HEIGHT = 0.6;
const lowp float SEA_CHOPPY = 4.0;
const lowp float SEA_SPEED = 0.8;
const lowp float SEA_FREQ = 0.16;
const lowp vec3 SEA_BASE = vec3(0.1,0.19,0.22);
const lowp vec3 SEA_WATER_COLOR = vec3(0.8,0.9,0.6);
#define SEA_TIME (1.0 + iTime * SEA_SPEED)
const lowp mat2 octave_m = mat2(1.6,1.2,-1.2,1.6);

// math
lowp mat3 fromEuler(lowp vec3 ang) {
    lowp vec2 a1 = vec2(sin(ang.x),cos(ang.x));
    lowp vec2 a2 = vec2(sin(ang.y),cos(ang.y));
    lowp vec2 a3 = vec2(sin(ang.z),cos(ang.z));
    lowp mat3 m;
    m[0] = vec3(a1.y*a3.y+a1.x*a2.x*a3.x,a1.y*a2.x*a3.x+a3.y*a1.x,-a2.y*a3.x);
    m[1] = vec3(-a2.y*a1.x,a1.y*a2.y,a2.x);
    m[2] = vec3(a3.y*a1.x*a2.x+a1.y*a3.x,a1.x*a3.x-a1.y*a3.y*a2.x,a2.y*a3.y);
    return m;
}
lowp float hash( lowp vec2 p ) {
    lowp float h = dot(p,vec2(127.1,311.7));
    return fract(sin(h)*43758.5453123);
}
lowp float noise( in lowp vec2 p ) {
    lowp vec2 i = floor( p );
    lowp vec2 f = fract( p );
    lowp vec2 u = f*f*(3.0-2.0*f);
    return -1.0+2.0*mix( mix( hash( i + vec2(0.0,0.0) ),
                             hash( i + vec2(1.0,0.0) ), u.x),
                        mix( hash( i + vec2(0.0,1.0) ),
                            hash( i + vec2(1.0,1.0) ), u.x), u.y);
}

// lighting
lowp float diffuse(lowp vec3 n,lowp vec3 l,lowp float p) {
    return pow(dot(n,l) * 0.4 + 0.6,p);
}
lowp float specular(lowp vec3 n,lowp vec3 l,lowp vec3 e,lowp float s) {
    lowp float nrm = (s + 8.0) / (PI * 8.0);
    return pow(max(dot(reflect(e,n),l),0.0),s) * nrm;
}

// sky
lowp vec3 getSkyColor(lowp vec3 e) {
    e.y = max(e.y,0.0);
    return vec3(pow(1.0-e.y,2.0), 1.0-e.y, 0.6+(1.0-e.y)*0.4);
}

// sea
lowp float sea_octave(lowp vec2 uv, lowp float choppy) {
    uv += noise(uv);
    lowp vec2 wv = 1.0-abs(sin(uv));
    lowp vec2 swv = abs(cos(uv));
    wv = mix(wv,swv,wv);
    return pow(1.0-pow(wv.x * wv.y,0.65),choppy);
}

lowp float map(lowp vec3 p) {
    lowp float freq = SEA_FREQ;
    lowp float amp = SEA_HEIGHT;
    lowp float choppy = SEA_CHOPPY;
    lowp vec2 uv = p.xz; uv.x *= 0.75;
    
    lowp float d, h = 0.0;
    for(int i = 0; i < ITER_GEOMETRY; i++) {
        d = sea_octave((uv+SEA_TIME)*freq,choppy);
        d += sea_octave((uv-SEA_TIME)*freq,choppy);
        h += d * amp;
        uv *= octave_m; freq *= 1.9; amp *= 0.22;
        choppy = mix(choppy,1.0,0.2);
    }
    return p.y - h;
}

lowp float map_detailed(lowp vec3 p) {
    lowp float freq = SEA_FREQ;
    lowp float amp = SEA_HEIGHT;
    lowp float choppy = SEA_CHOPPY;
    lowp vec2 uv = p.xz; uv.x *= 0.75;
    
    lowp float d, h = 0.0;
    for(int i = 0; i < ITER_FRAGMENT; i++) {
        d = sea_octave((uv+SEA_TIME)*freq,choppy);
        d += sea_octave((uv-SEA_TIME)*freq,choppy);
        h += d * amp;
        uv *= octave_m; freq *= 1.9; amp *= 0.22;
        choppy = mix(choppy,1.0,0.2);
    }
    return p.y - h;
}

lowp vec3 getSeaColor(lowp vec3 p, lowp vec3 n, lowp vec3 l, lowp vec3 eye, lowp vec3 dist) {
    lowp float fresnel = clamp(1.0 - dot(n,-eye), 0.0, 1.0);
    fresnel = pow(fresnel,3.0) * 0.65;
    
    lowp vec3 reflected = getSkyColor(reflect(eye,n));
    lowp vec3 refracted = SEA_BASE + diffuse(n,l,80.0) * SEA_WATER_COLOR * 0.12;
    
    lowp vec3 color = mix(refracted,reflected,fresnel);
    
    lowp float atten = max(1.0 - dot(dist,dist) * 0.001, 0.0);
    color += SEA_WATER_COLOR * (p.y - SEA_HEIGHT) * 0.18 * atten;
    
    color += vec3(specular(n,l,eye,60.0));
    
    return color;
}

// tracing
lowp vec3 getNormal(lowp vec3 p, lowp float eps) {
    lowp vec3 n;
    n.y = map_detailed(p);
    n.x = map_detailed(vec3(p.x+eps,p.y,p.z)) - n.y;
    n.z = map_detailed(vec3(p.x,p.y,p.z+eps)) - n.y;
    n.y = eps;
    return normalize(n);
}

lowp float heightMapTracing(lowp vec3 ori, lowp vec3 dir, out lowp vec3 p) {
    lowp float tm = 0.0;
    lowp float tx = 1000.0;
    lowp float hx = map(ori + dir * tx);
    if(hx > 0.0) return tx;
    lowp float hm = map(ori + dir * tm);
    lowp float tmid = 0.0;
    for(int i = 0; i < NUM_STEPS; i++) {
        tmid = mix(tm,tx, hm/(hm-hx));
        p = ori + dir * tmid;
        lowp float hmid = map(p);
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
void mainImage( out lowp vec4 fragColor, in lowp vec2 fragCoord ) {
    lowp vec2 uv = fragCoord.xy / iResolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    lowp float time = iTime * 0.3 + iMouse.x*0.01;
    
    // ray
    lowp vec3 ang = vec3(sin(time*3.0)*0.1,sin(time)*0.2+0.3,time);
    lowp vec3 ori = vec3(0.0,3.5,time*5.0);
    lowp vec3 dir = normalize(vec3(uv.xy,-2.0)); dir.z += length(uv) * 0.15;
    dir = normalize(dir) * fromEuler(ang);
    
    // tracing
    lowp vec3 p;
    heightMapTracing(ori,dir,p);
    lowp vec3 dist = p - ori;
    lowp vec3 n = getNormal(p, dot(dist,dist) * EPSILON_NRM);
    lowp vec3 light = normalize(vec3(0.0,1.0,0.8));
    
    // color
    lowp vec3 color = mix(
                     getSkyColor(dir),
                     getSeaColor(p,n,light,dir,dist),
                     pow(smoothstep(0.0,-0.05,dir.y),0.3));
    
    // post
    fragColor = vec4(pow(color,vec3(0.75)), 1.0);
}


void main(void) {
    mainImage(gl_FragColor,gl_FragCoord.xy);
}
