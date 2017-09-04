// Author : Sebastien Berube
// Created : Dec 2014
// Modified : Sept 2016
//
// Shorter version of https://www.shadertoy.com/view/MscXzn, without sliders
// Based on primitives shader from Inigo Quilez : https://www.shadertoy.com/view/Xds3zN
//
// Notes:
//
// - Most logic can be found in renderIce() and mainImage()
// - distance function map() works as usual, as all boolean operations and signed distance functions do.
// - castRay() function was modified for volume raymarching (sign added, simple as that).
// - triplanar noise projection used for surface normal noise.
// - smooth subtraction was implemented to smooth out boolean shape.
//
// License : Creative Commons Non-commercial (NC) license
//

//----------------------
// Constants
const float GEO_MAX_DIST  = 1000.0;
const int MATERIALID_NONE      = 0;
const int MATERIALID_FLOOR     = 1;
const int MATERIALID_ICE_OUTER = 2;
const int MATERIALID_ICE_INNER = 3;
const int MATERIALID_SKY       = 4;
const float PI             = 3.14159;
const float ROUGHNESS      = 1.25;
const float ISOVALUE       = 0.03;
const float REFRACTION_IDX = 1.31;

vec3 NORMALMAP_main(vec3 p, vec3 n);
float softshadow(vec3 ro, vec3 rd, float coneWidth);
float sdPlane( vec3 p ){
    return p.y;
}
float sdSphere( vec3 p, float s ){
    return length(p)-s;
}
float sdBox( vec3 p, vec3 b ){
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}
float udRoundBox( vec3 p, vec3 b, float r ){
    return length(max(abs(p)-b,0.0))-r;
}
float sdTorus( vec3 p, vec2 t ){
    return length( vec2(length(p.xz)-t.x,p.y) )-t.y;
}
float sdTriPrism( vec3 p, vec2 h ){
    vec3 q = abs(p);
    float d1 = q.z-h.y;
    float d2 = max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5;
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}
float sdCylinder( vec3 p, vec2 h ){
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
float length2( vec2 p ){
    return sqrt( p.x*p.x + p.y*p.y );
}
float length8( vec2 p ){
    p = p*p; p = p*p; p = p*p;
    return pow( p.x + p.y, 1.0/8.0 );
}
float sdTorus88( vec3 p, vec2 t ){
    vec2 q = vec2(length8(p.xz)-t.x,p.y);
    return length8(q)-t.y;
}
float opSmoothSubtract( float d1, float d2 ){
    return length(vec2(max(d1,0.),min(d2,0.0)));
}
float opU( float d1, float d2 ){
    return (d1<d2) ? d1 : d2;
}
vec3 opTwist( vec3 p ){
    float  c = cos(10.0*p.y+10.0);
    float  s = sin(10.0*p.y+10.0);
    mat2   m = mat2(c,-s,s,c);
    return vec3(m*p.xz,p.y);
}
struct DF_out{
    float d;  //Distance to geometry
    int matID;//Geometry material ID
};
DF_out map( in vec3 pos ){
    float dist = opU( sdPlane(     pos-vec3( -1.4) ),
                     sdSphere(    pos-vec3( 0.0,0.25, 0.0), 0.25 ) );
    dist = opU( dist, udRoundBox(  pos-vec3( 1.0,0.25, 1.0), vec3(0.15), 0.1 ) );
    dist = opU( dist, sdTorus(     pos-vec3( 0.0,0.25, 1.0), vec2(0.20,0.05) ) );
    dist = opU( dist, sdTriPrism(  pos-vec3(-1.0,0.25,-1.0), vec2(0.25,0.05) ) );
    dist = opU( dist, sdCylinder(  pos-vec3( 1.0,0.30,-1.0), vec2(0.10,0.20) ) );
    dist = opU( dist, sdTorus88(   pos-vec3(-1.0,0.25, 1.0), vec2(0.20,0.05) ) );
    dist = opU( dist, opSmoothSubtract(
                                       udRoundBox(  pos-vec3(-1.0,0.2, 0.0), vec3(0.15),0.05),
                                       sdSphere(    pos-vec3(-1.0,0.2, 0.0), 0.25)) );
    dist = opU( dist, sdBox(       pos-vec3( 0.0,0.20,-1.0), vec3(0.25)) );
    dist = opU( dist, 0.5*sdTorus( opTwist(pos-vec3( 1.0,0.25, 0.0)),vec2(0.15,0.02)) );
    DF_out outData;
    outData.d = dist-ISOVALUE;
    outData.matID = MATERIALID_ICE_OUTER;
    return outData;
}
vec3 gradient( in vec3 p ){
    const float d = 0.001;
    return vec3(map(p+vec3(d,0,0)).d-map(p-vec3(d,0,0)).d,
                map(p+vec3(0,d,0)).d-map(p-vec3(0,d,0)).d,
                map(p+vec3(0,0,d)).d-map(p-vec3(0,0,d)).d);
}
vec2 castRay( const vec3 o, const vec3 d, const float tmin, const float eps, const bool bInternal){
    float tmax = 10.0, t = tmin, dist = GEO_MAX_DIST;
    for( int i=0; i<50; i++ ){
        vec3 p = o+d*t;
        dist = (bInternal?-1.:1.)*map(p).d;//[modified for internal marching]
        if( abs(dist)<eps || t>tmax )
            break;
        t += dist;
    }
    dist = (dist<tmax)?dist:GEO_MAX_DIST;
    return vec2( t, dist );
}
#define saturate(x) clamp(x,0.0,1.0)
float softshadow( vec3 o, vec3 L, float coneWidth ){
    float t = 0.0, minAperture = 1.0, dist = GEO_MAX_DIST;
    for( int i=0; i<6; i++ ){
        vec3 p = o+L*t; //Sample position = ray origin + ray direction * travel distance
        float dist = map( p ).d;
        float curAperture = dist/t; //Aperture ~= cone angle tangent (sin=dist/cos=travelDist)
        minAperture = min(minAperture,curAperture);
        t += 0.03+dist; //0.03 : min step size.
    }
    return saturate(minAperture/coneWidth); //Should never exceed [0-1]. 0 = shadow, 1 = fully lit.
}
struct TraceData{
    float rayLen;
    vec3  rayDir;
    vec3  normal;
    int   matID;
    vec3  matUVW;
    float alpha;
};
TraceData TRACE_getFront(const in TraceData tDataA, const in TraceData tDataB){
    if(tDataA.rayLen<tDataB.rayLen)
        return tDataA;
    else
        return tDataB;
}
TraceData TRACE_cheap(vec3 o, vec3 d){
    TraceData floorData;
    floorData.rayLen  = dot(vec3(-0.1)-o,vec3(0,1,0))/dot(d,vec3(0,1,0));
    if(floorData.rayLen<0.0) floorData.rayLen = GEO_MAX_DIST;
    floorData.rayDir  = d;
    floorData.normal  = vec3(0,1,0);
    floorData.matUVW  = o+d*floorData.rayLen;
    floorData.matID   = MATERIALID_FLOOR;
    floorData.alpha   = 1.0;
    
    TraceData skyData;
    skyData.rayLen  = 50.0;
    skyData.rayDir  = d;
    skyData.normal  = -d;
    skyData.matUVW  = d;
    skyData.matID   = MATERIALID_SKY;
    skyData.alpha   = 1.0;
    return TRACE_getFront(floorData,skyData);
}
TraceData TRACE_reflexion(vec3 o, vec3 d){
    return TRACE_cheap(o,d);
}
TraceData TRACE_geometry(vec3 o, vec3 d){
    TraceData cheapTrace = TRACE_cheap(o,d);
    
    TraceData iceTrace;
    vec2 rayLen_geoDist = castRay(o,d,0.1,0.0001,false);
    vec3 iceHitPosition = o+rayLen_geoDist.x*d;
    iceTrace.rayDir     = d;
    iceTrace.rayLen     = rayLen_geoDist.x;
    iceTrace.normal     = normalize(gradient(iceHitPosition));
    iceTrace.matUVW     = iceHitPosition;
    iceTrace.matID      = MATERIALID_ICE_OUTER;
    iceTrace.alpha      = 0.0;
    
    return TRACE_getFront(cheapTrace,iceTrace);
}
TraceData TRACE_translucentDensity(vec3 o, vec3 d){
    TraceData innerIceTrace;
    
    vec2 rayLen_geoDist   = castRay(o,d,0.01,0.001,true).xy;
    vec3 iceExitPosition  = o+rayLen_geoDist.x*d;
    innerIceTrace.rayDir  = d;
    innerIceTrace.rayLen  = rayLen_geoDist.x;
    innerIceTrace.normal  = normalize(gradient(iceExitPosition));
    innerIceTrace.matUVW  = iceExitPosition;
    innerIceTrace.matID   = MATERIALID_ICE_INNER;
    innerIceTrace.alpha   = rayLen_geoDist.x;
    return innerIceTrace;
}
vec3 NORMALMAP_smoothSampling(vec2 uv){
    vec2 x = fract(uv*64.+0.5);
    return texture(iChannel0,uv-(x)/64.+(6.*x*x-15.0*x+10.)*x*x*x/64.,-100.0).xyz;
}
float NORMALMAP_triplanarSampling(vec3 p, vec3 n){
    float fTotal = abs(n.x)+abs(n.y)+abs(n.z);
    return  (abs(n.x)*NORMALMAP_smoothSampling(p.yz).x
             +abs(n.y)*NORMALMAP_smoothSampling(p.xz).x
             +abs(n.z)*NORMALMAP_smoothSampling(p.xy).x)/fTotal;
}
float NORMALMAP_triplanarNoise(vec3 p, vec3 n){
    const mat2 m2 = mat2(0.90,0.44,-0.44,0.90);
    const float BUMP_MAP_UV_SCALE = 0.2;
    float fTotal = abs(n.x)+abs(n.y)+abs(n.z);
    float f1 = NORMALMAP_triplanarSampling(p*BUMP_MAP_UV_SCALE,n);
    p.xy = m2*p.xy; p.xz = m2*p.xz; p *= 2.1;
    float f2 = NORMALMAP_triplanarSampling(p*BUMP_MAP_UV_SCALE,n);
    p.yx = m2*p.yx; p.yz = m2*p.yz; p *= 2.3;
    float f3 = NORMALMAP_triplanarSampling(p*BUMP_MAP_UV_SCALE,n);
    return f1+0.5*f2+0.25*f3;
}
vec3 NORMALMAP_main(vec3 p, vec3 n){
    float d = 0.005;
    float po = NORMALMAP_triplanarNoise(p,n);
    return normalize(vec3((NORMALMAP_triplanarNoise(p+vec3(d,0,0),n)-po)/d,
                          (NORMALMAP_triplanarNoise(p+vec3(0,d,0),n)-po)/d,
                          (NORMALMAP_triplanarNoise(p+vec3(0,0,d),n)-po)/d));
}
struct Cam{vec3 R;vec3 U;vec3 D;vec3 o;};
struct IceTracingData{
    TraceData reflectTraceData;
    TraceData translucentTraceData;
    TraceData exitTraceData;
};
IceTracingData renderIce(TraceData iceSurface, vec3 ptIce, vec3 dir){
    IceTracingData iceData;
    vec3 normalDelta = NORMALMAP_main(ptIce*ROUGHNESS,iceSurface.normal)*ROUGHNESS/10.;
    vec3 iceSurfaceNormal = normalize(iceSurface.normal+normalDelta);
    vec3 refract_dir = refract(dir,iceSurfaceNormal,1.0/REFRACTION_IDX); //Ice refraction index = 1.31
    vec3 reflect_dir = reflect(dir,iceSurfaceNormal);
    
    //Trace reflection
    iceData.reflectTraceData = TRACE_reflexion(ptIce,reflect_dir);
    
    //Balance between refraction and reflection (not entirely physically accurate, Fresnel could be used here).
    float fReflectAlpha = 0.5*(1.0-abs(dot(normalize(dir),iceSurfaceNormal)));
    iceData.reflectTraceData.alpha = fReflectAlpha;
    vec3 ptReflect = ptIce+iceData.reflectTraceData.rayLen*reflect_dir;
    
    //Trace refraction
    iceData.translucentTraceData = TRACE_translucentDensity(ptIce,refract_dir);
    
    vec3 ptRefract = ptIce+iceData.translucentTraceData.rayLen*refract_dir;
    vec3 exitRefract_dir = refract(refract_dir,-iceData.translucentTraceData.normal,REFRACTION_IDX);
    
    //This value fades around total internal refraction angle threshold.
    if(length(exitRefract_dir)<=0.95)
    {
        //Total internal reflection (either refraction or reflexion, to keep things cheap).
        exitRefract_dir = reflect(refract_dir,-iceData.translucentTraceData.normal);
    }
    
    //Trace environment upon exit.
    iceData.exitTraceData = TRACE_cheap(ptRefract,exitRefract_dir);
    iceData.exitTraceData.matID = MATERIALID_FLOOR;
    
    return iceData;
}
vec4 MAT_apply(vec3 pos, TraceData traceData){
    if(traceData.matID==MATERIALID_NONE)
        return vec4(0,0,0,1);
    if(traceData.matID==MATERIALID_ICE_INNER)
        return vec4(1.0);
    if(traceData.matID==MATERIALID_SKY)
        return vec4(0.6,0.7,0.85,1.0);
    vec3 cDiff = pow(texture(iChannel1,traceData.matUVW.xz).rgb,vec3(1.2));
    float dfss = softshadow(pos, normalize(vec3(-0.6,0.7,-0.5)), 0.07);
    return vec4(cDiff*(0.45+1.2*(dfss)),1);
}
void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 uv = (fragCoord.xy-0.5*iResolution.xy) / iResolution.xx;
    float rotX = 2.0*PI*(iMouse.x/iResolution.x+iTime*0.05);
    Cam cam;
    cam.o = vec3(cos(rotX),0.475,sin(rotX))*2.3;
    cam.D = normalize(vec3(0,-0.25,0)-cam.o);
    cam.R = normalize(cross(cam.D,vec3(0,1,0)));
    cam.U = cross(cam.R,cam.D);
    vec2 cuv = uv*2.0*iResolution.x/iResolution.y;//camera uv
    vec3 dir = normalize(cuv.x*cam.R+cuv.y*cam.U+cam.D*2.5);
    
    vec3 ptReflect = vec3(0);
    TraceData geometryTraceData = TRACE_geometry(cam.o, dir);
    vec3 ptGeometry = cam.o+geometryTraceData.rayLen*dir;
    
    IceTracingData iceData;
    iceData.translucentTraceData.rayLen = 0.0;
    if(geometryTraceData.matID == MATERIALID_ICE_OUTER && geometryTraceData.rayLen < GEO_MAX_DIST){
        vec3 ptIce = ptGeometry;
        iceData = renderIce(geometryTraceData, ptIce, dir);
        geometryTraceData = iceData.exitTraceData;
        vec3 ptRefract = ptIce+iceData.translucentTraceData.rayLen*iceData.translucentTraceData.rayDir;
        ptReflect = ptIce+iceData.reflectTraceData.rayLen*iceData.reflectTraceData.rayDir;
        ptGeometry = ptRefract+geometryTraceData.rayLen*dir;
    }
    vec4 cTerrain  = MAT_apply(ptGeometry,geometryTraceData);
    vec4 cIceInner = MAT_apply(ptGeometry,iceData.translucentTraceData);
    vec4 cReflect  = MAT_apply(ptReflect,iceData.reflectTraceData);
    if(iceData.translucentTraceData.rayLen > 0.0 ){
        float fTrav = iceData.translucentTraceData.rayLen;
        vec3 cRefract = cTerrain.rgb;
        cRefract.rgb = mix(cRefract,cIceInner.rgb,0.3*fTrav+0.2*sqrt(fTrav*3.0));
        cRefract.rgb += fTrav*0.3;
        vec3 cIce = mix(cRefract,cReflect.rgb,iceData.reflectTraceData.alpha);
        fragColor.rgb = cIce;
    }
    else
        fragColor.rgb = cTerrain.rgb;
    
    //Vignetting + Gamma
    float lensRadius = 0.65;
    uv /= lensRadius;
    float sin2 = uv.x*uv.x+uv.y*uv.y;
    float cos2 = 1.0-min(sin2*sin2,1.0);
    fragColor.rgb = pow(fragColor.rgb*cos2*cos2,vec3(0.4545)); //2.2 Gamma compensation
}
