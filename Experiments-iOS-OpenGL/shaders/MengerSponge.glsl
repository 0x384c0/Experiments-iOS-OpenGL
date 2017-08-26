
uniform highp float iTime;
uniform highp vec3 iResolution;



highp float maxcomp(in highp vec3 p ) { return max(p.x,max(p.y,p.z));}
highp float sdBox( highp vec3 p, highp vec3 b )
{
    highp vec3  di = abs(p) - b;
    highp float mc = maxcomp(di);
    return min(mc,length(max(di,0.0)));
}

const highp mat3 ma = mat3( 0.60, 0.00,  0.80,
                          0.00, 1.00,  0.00,
                          -0.80, 0.00,  0.60 );

highp vec4 map( in highp vec3 p )
{
    highp float d = sdBox(p,vec3(1.0));
    highp vec4 res = vec4( d, 1.0, 0.0, 0.0 );
    
    highp float ani = smoothstep( -0.2, 0.2, -cos(0.5*iTime) );
    highp float off = 1.5*sin( 0.01*iTime );
    
    highp float s = 1.0;
    for( int m=0; m<4; m++ )
    {
        p = mix( p, ma*(p+off), ani );
        
        highp vec3 a = mod( p*s, 2.0 )-1.0;
        s *= 3.0;
        highp vec3 r = abs(1.0 - 3.0*abs(a));
        highp float da = max(r.x,r.y);
        highp float db = max(r.y,r.z);
        highp float dc = max(r.z,r.x);
        highp float c = (min(da,min(db,dc))-1.0)/s;
        
        if( c>d )
        {
            d = c;
            res = vec4( d, min(res.y,0.2*da*db*dc), (1.0+float(m))/4.0, 0.0 );
        }
    }
    
    return res;
}

highp vec4 intersect( in highp vec3 ro, in highp vec3 rd )
{
    highp float t = 0.0;
    highp vec4 res = vec4(-1.0);
    highp vec4 h = vec4(1.0);
    for( int i=0; i<64; i++ )
    {
        if( h.x<0.002 || t>10.0 ) break;
        h = map(ro + rd*t);
        res = vec4(t,h.yzw);
        t += h.x;
    }
    if( t>10.0 ) res=vec4(-1.0);
    return res;
}

highp float softshadow( in highp vec3 ro, in highp vec3 rd, highp float mint, highp float k )
{
    highp float res = 1.0;
    highp float t = mint;
    highp float h = 1.0;
    for( int i=0; i<32; i++ )
    {
        h = map(ro + rd*t).x;
        res = min( res, k*h/t );
        t += clamp( h, 0.005, 0.1 );
    }
    return clamp(res,0.0,1.0);
}

highp vec3 calcNormal(in highp vec3 pos)
{
    highp vec3  eps = vec3(.001,0.0,0.0);
    highp vec3 nor;
    nor.x = map(pos+eps.xyy).x - map(pos-eps.xyy).x;
    nor.y = map(pos+eps.yxy).x - map(pos-eps.yxy).x;
    nor.z = map(pos+eps.yyx).x - map(pos-eps.yyx).x;
    return normalize(nor);
}

// light
highp vec3 light = normalize(vec3(1.0,0.9,0.3));

highp vec3 render( in highp vec3 ro, in highp vec3 rd )
{
    // background color
    highp vec3 col = mix( vec3(0.3,0.2,0.1)*0.5, vec3(0.7, 0.9, 1.0), 0.5 + 0.5*rd.y );
    
    highp vec4 tmat = intersect(ro,rd);
    if( tmat.x>0.0 )
    {
        highp vec3  pos = ro + tmat.x*rd;
        highp vec3  nor = calcNormal(pos);
        
        highp float occ = tmat.y;
        highp float sha = softshadow( pos, light, 0.01, 64.0 );
        
        highp float dif = max(0.1 + 0.9*dot(nor,light),0.0);
        highp float sky = 0.5 + 0.5*nor.y;
        highp float bac = max(0.4 + 0.6*dot(nor,vec3(-light.x,light.y,-light.z)),0.0);
        
        highp vec3 lin  = vec3(0.0);
        lin += 1.00*dif*vec3(1.10,0.85,0.60)*sha;
        lin += 0.50*sky*vec3(0.10,0.20,0.40)*occ;
        lin += 0.10*bac*vec3(1.00,1.00,1.00)*(0.5+0.5*occ);
        lin += 0.25*occ*vec3(0.15,0.17,0.20);
        
        highp vec3 matcol = vec3(
                                0.5+0.5*cos(0.0+2.0*tmat.z),
                                0.5+0.5*cos(1.0+2.0*tmat.z),
                                0.5+0.5*cos(2.0+2.0*tmat.z) );
        col = matcol * lin;
    }
    
    return pow( col, vec3(0.4545) );
}


//shadertoy function
void mainImage( out highp vec4 fragColor, in highp vec2 fragCoord ) {
    highp vec2 p = -1.0 + 2.0 * fragCoord.xy / iResolution.xy;
    p.x *= iResolution.x/iResolution.y;
    
    highp float ctime = iTime;
    // camera
    highp vec3 ro = 1.1*vec3(2.5*sin(0.25*ctime),1.0+1.0*cos(ctime*.13),2.5*cos(0.25*ctime));
    highp vec3 ww = normalize(vec3(0.0) - ro);
    highp vec3 uu = normalize(cross( vec3(0.0,1.0,0.0), ww ));
    highp vec3 vv = normalize(cross(ww,uu));
    highp vec3 rd = normalize( p.x*uu + p.y*vv + 2.5*ww );
    
    highp vec3 col = render( ro, rd );
    
    fragColor = vec4(col,1.0);
}

void main(void) {
    mainImage(gl_FragColor,gl_FragCoord.xy);
}
