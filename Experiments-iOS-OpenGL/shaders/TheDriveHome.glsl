
uniform highp float iTime;
uniform highp vec3 iResolution;
highp vec4 iMouse = vec4(1.0,1.0,1.0,1.0);

#define S(x, y, z) smoothstep(x, y, z)
#define B(a, b, edge, t) S(a-edge, a+edge, t)*S(b+edge, b-edge, t)
#define sat(x) clamp(x,0.,1.)

#define streetLightCol vec3(1., .7, .3)
#define headLightCol vec3(.8, .8, 1.)
#define tailLightCol vec3(1., .1, .1)

#define HIGH_QUALITY
#define CAM_SHAKE 1.
#define LANE_BIAS .5
#define RAIN
//#define DROP_DEBUG

highp vec3 ro, rd;

highp float N(highp float t) {
    return fract(sin(t*10234.324)*123423.23512);
}
highp vec3 N31(highp float p) {
    //  3 out, 1 in... DAVE HOSKINS
    highp vec3 p3 = fract(vec3(p) * vec3(.1031,.11369,.13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}
highp float N2(highp vec2 p)
{	// Dave Hoskins - https://www.shadertoy.com/view/4djSRW
    highp vec3 p3  = fract(vec3(p.xyx) * vec3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}


highp float DistLine(highp vec3 ro, highp vec3 rd, highp vec3 p) {
    return length(cross(p-ro, rd));
}

highp vec3 ClosestPoint(highp vec3 ro, highp vec3 rd, highp vec3 p) {
    // returns the closest point on ray r to point p
    return ro + max(0., dot(p-ro, rd))*rd;
}

highp float Remap(highp float a, highp float b, highp float c, highp float d, highp float t) {
    return ((t-a)/(b-a))*(d-c)+c;
}

highp float BokehMask(highp vec3 ro, highp vec3 rd, highp vec3 p, highp float size, highp float blur) {
    highp float d = DistLine(ro, rd, p);
    highp float m = S(size, size*(1.-blur), d);
    
#ifdef HIGH_QUALITY
    m *= mix(.7, 1., S(.8*size, size, d));
#endif
    
    return m;
}



highp float SawTooth(highp float t) {
    return cos(t+cos(t))+sin(2.*t)*.2+sin(4.*t)*.02;
}

highp float DeltaSawTooth(highp float t) {
    return 0.4*cos(2.*t)+0.08*cos(4.*t) - (1.-sin(t))*sin(t+cos(t));
}

highp vec2 GetDrops(highp vec2 uv, highp float seed, highp float m) {
    
    highp float t = iTime+m*30.;
    highp vec2 o = vec2(0.);
    
#ifndef DROP_DEBUG
    uv.y += t*.05;
#endif
    
    uv *= vec2(10., 2.5)*2.;
    highp vec2 id = floor(uv);
    highp vec3 n = N31(id.x + (id.y+seed)*546.3524);
    highp vec2 bd = fract(uv);
    
    highp vec2 uv2 = bd;
    
    bd -= .5;
    
    bd.y*=4.;
    
    bd.x += (n.x-.5)*.6;
    
    t += n.z * 6.28;
    highp float slide = SawTooth(t);
    
    highp float ts = 1.5;
    highp vec2 trailPos = vec2(bd.x*ts, (fract(bd.y*ts*2.-t*2.)-.5)*.5);
    
    bd.y += slide*2.;								// make drops slide down
    
#ifdef HIGH_QUALITY
    highp float dropShape = bd.x*bd.x;
    dropShape *= DeltaSawTooth(t);
    bd.y += dropShape;								// change shape of drop when it is falling
#endif
    
    highp float d = length(bd);							// distance to main drop
    
    highp float trailMask = S(-.2, .2, bd.y);				// mask out drops that are below the main
    trailMask *= bd.y;								// fade dropsize
    highp float td = length(trailPos*max(.5, trailMask));	// distance to trail drops
    
    highp float mainDrop = S(.2, .1, d);
    highp float dropTrail = S(.1, .02, td);
    
    dropTrail *= trailMask;
    o = mix(bd*mainDrop, trailPos, dropTrail);		// mix main drop and drop trail
    
#ifdef DROP_DEBUG
    if(uv2.x<.02 || uv2.y<.01) o = vec2(1.);
#endif
    
    return o;
}

void CameraSetup(highp vec2 uv, highp vec3 pos, highp vec3 lookat, highp float zoom, highp float m) {
    ro = pos;
    highp vec3 f = normalize(lookat-ro);
    highp vec3 r = cross(vec3(0., 1., 0.), f);
    highp vec3 u = cross(f, r);
    highp float t = iTime;
    
    highp vec2 offs = vec2(0.);
#ifdef RAIN
    highp vec2 dropUv = uv;
    
#ifdef HIGH_QUALITY
    highp float x = (sin(t*.1)*.5+.5)*.5;
    x = -x*x;
    highp float s = sin(x);
    highp float c = cos(x);
    
    highp mat2  rot = mat2(c, -s, s, c);
    
#ifndef DROP_DEBUG
    dropUv = uv*rot;
    dropUv.x += -sin(t*.1)*.5;
#endif
#endif
    
    offs = GetDrops(dropUv, 1., m);
    
#ifndef DROP_DEBUG
    offs += GetDrops(dropUv*1.4, 10., m);
#ifdef HIGH_QUALITY
    offs += GetDrops(dropUv*2.4, 25., m);
    //offs += GetDrops(dropUv*3.4, 11.);
    //offs += GetDrops(dropUv*3., 2.);
#endif
    
    highp float ripple = sin(t+uv.y*3.1415*30.+uv.x*124.)*.5+.5;
    ripple *= .005;
    offs += vec2(ripple*ripple, ripple);
#endif
#endif
    highp vec3 center = ro + f*zoom;
    highp vec3 i = center + (uv.x-offs.x)*r + (uv.y-offs.y)*u;
    
    rd = normalize(i-ro);
}

highp vec3 HeadLights(highp float i, highp float t) {
    highp float z = fract(-t*2.+i);
    highp vec3 p = vec3(-.3, .1, z*40.);
    highp float d = length(p-ro);
    
    highp float size = mix(.03, .05, S(.02, .07, z))*d;
    highp float m = 0.;
    highp float blur = .1;
    m += BokehMask(ro, rd, p-vec3(.08, 0., 0.), size, blur);
    m += BokehMask(ro, rd, p+vec3(.08, 0., 0.), size, blur);
    
#ifdef HIGH_QUALITY
    m += BokehMask(ro, rd, p+vec3(.1, 0., 0.), size, blur);
    m += BokehMask(ro, rd, p-vec3(.1, 0., 0.), size, blur);
#endif
    
    highp float distFade = max(.01, pow(1.-z, 9.));
    
    blur = .8;
    size *= 2.5;
    highp float r = 0.;
    r += BokehMask(ro, rd, p+vec3(-.09, -.2, 0.), size, blur);
    r += BokehMask(ro, rd, p+vec3(.09, -.2, 0.), size, blur);
    r *= distFade*distFade;
    
    return headLightCol*(m+r)*distFade;
}


highp vec3 TailLights(highp float i, highp float t) {
    t = t*1.5+i;
    
    highp float id = floor(t)+i;
    highp vec3 n = N31(id);
    
    highp float laneId = S(LANE_BIAS, LANE_BIAS+.01, n.y);
    
    highp float ft = fract(t);
    
    highp float z = 3.-ft*3.;						// distance ahead
    
    laneId *= S(.2, 1.5, z);				// get out of the way!
    highp float lane = mix(.6, .3, laneId);
    highp vec3 p = vec3(lane, .1, z);
    highp float d = length(p-ro);
    
    highp float size = .05*d;
    highp float blur = .1;
    highp float m = BokehMask(ro, rd, p-vec3(.08, 0., 0.), size, blur) +
    BokehMask(ro, rd, p+vec3(.08, 0., 0.), size, blur);
    
#ifdef HIGH_QUALITY
    highp float bs = n.z*3.;						// start braking at random distance
    highp float brake = S(bs, bs+.01, z);
    brake *= S(bs+.01, bs, z-.5*n.y);		// n.y = random brake duration
    
    m += (BokehMask(ro, rd, p+vec3(.1, 0., 0.), size, blur) +
          BokehMask(ro, rd, p-vec3(.1, 0., 0.), size, blur))*brake;
#endif
    
    highp float refSize = size*2.5;
    m += BokehMask(ro, rd, p+vec3(-.09, -.2, 0.), refSize, .8);
    m += BokehMask(ro, rd, p+vec3(.09, -.2, 0.), refSize, .8);
    highp vec3 col = tailLightCol*m*ft;
    
    highp float b = BokehMask(ro, rd, p+vec3(.12, 0., 0.), size, blur);
    b += BokehMask(ro, rd, p+vec3(.12, -.2, 0.), refSize, .8)*.2;
    
    highp vec3 blinker = vec3(1., .7, .2);
    blinker *= S(1.5, 1.4, z)*S(.2, .3, z);
    blinker *= sat(sin(t*200.)*100.);
    blinker *= laneId;
    col += blinker*b;
    
    return col;
}

highp vec3 StreetLights(highp float i, highp float t) {
    highp float side = sign(rd.x);
    highp float offset = max(side, 0.)*(1./16.);
    highp float z = fract(i-t+offset);
    highp vec3 p = vec3(2.*side, 2., z*60.);
    highp float d = length(p-ro);
    highp float blur = .1;
    highp vec3 rp = ClosestPoint(ro, rd, p);
    highp float distFade = Remap(1., .7, .1, 1.5, 1.-pow(1.-z,6.));
    distFade *= (1.-z);
    highp float m = BokehMask(ro, rd, p, .05*d, blur)*distFade;
    
    return m*streetLightCol;
}

highp vec3 EnvironmentLights(highp float i, highp float t) {
    highp float n = N(i+floor(t));
    
    highp float side = sign(rd.x);
    highp float offset = max(side, 0.)*(1./16.);
    highp float z = fract(i-t+offset+fract(n*234.));
    highp float n2 = fract(n*100.);
    highp vec3 p = vec3((3.+n)*side, n2*n2*n2*1., z*60.);
    highp float d = length(p-ro);
    highp float blur = .1;
    highp vec3 rp = ClosestPoint(ro, rd, p);
    highp float distFade = Remap(1., .7, .1, 1.5, 1.-pow(1.-z,6.));
    highp float m = BokehMask(ro, rd, p, .05*d, blur);
    m *= distFade*distFade*.5;
    
    m *= 1.-pow(sin(z*6.28*20.*n)*.5+.5, 20.);
    highp vec3 randomCol = vec3(fract(n*-34.5), fract(n*4572.), fract(n*1264.));
    highp vec3 col = mix(tailLightCol, streetLightCol, fract(n*-65.42));
    col = mix(col, randomCol, n);
    return m*col*.2;
}


//shadertoy function
void mainImage( out highp vec4 fragColor, in highp vec2 fragCoord ) {
    highp float t = iTime;
    highp vec3 col = vec3(0.);
    highp vec2 uv = fragCoord.xy / iResolution.xy; // 0 <> 1
    
    uv -= .5;
    uv.x *= iResolution.x/iResolution.y;
    
    highp vec2 mouse = iMouse.xy/iResolution.xy;
    
    highp vec3 pos = vec3(.3, .15, 0.);
    
    highp float bt = t * 5.;
    highp float h1 = N(floor(bt));
    highp float h2 = N(floor(bt+1.));
    highp float bumps = mix(h1, h2, fract(bt))*.1;
    bumps = bumps*bumps*bumps*CAM_SHAKE;
    
    pos.y += bumps;
    highp float lookatY = pos.y+bumps;
    highp vec3 lookat = vec3(0.3, lookatY, 1.);
    highp vec3 lookat2 = vec3(0., lookatY, .7);
    lookat = mix(lookat, lookat2, sin(t*.1)*.5+.5);
    
    uv.y += bumps*4.;
    CameraSetup(uv, pos, lookat, 2., mouse.x);
    
    t *= .03;
    t += mouse.x;
    
    // fix for GLES devices by MacroMachines
#ifdef GL_ES
    const highp float stp = 1./8.;
#else
    highp float stp = 1./8.
#endif
    
    for(highp float i=0.; i<1.; i+=stp) {
        col += StreetLights(i, t);
    }
    
    for(highp float i=0.; i<1.; i+=stp) {
        highp float n = N(i+floor(t));
        col += HeadLights(i+n*stp*.7, t);
    }
    
#ifndef GL_ES
#ifdef HIGH_QUALITY
    stp = 1./32.;
#else
    stp = 1./16.;
#endif
#endif
    
    for(highp float i=0.; i<1.; i+=stp) {
        col += EnvironmentLights(i, t);
    }
    
    col += TailLights(0., t);
    col += TailLights(.5, t);
    
    col += sat(rd.y)*vec3(.6, .5, .9);
    
    fragColor = vec4(col, 0.);
}

void main(void) {
    mainImage(gl_FragColor,gl_FragCoord.xy);
}
