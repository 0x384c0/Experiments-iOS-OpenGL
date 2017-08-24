varying lowp vec4 DestinationColor;
uniform lowp float iTime;
uniform lowp vec3 iResolution;



lowp float maxcomp(in lowp vec3 p ) { return max(p.x,max(p.y,p.z));}
lowp float sdBox( lowp vec3 p, lowp vec3 b )
{
    lowp vec3  di = abs(p) - b;
    lowp float mc = maxcomp(di);
    return min(mc,length(max(di,0.0)));
}

const lowp mat3 ma = mat3( 0.60, 0.00,  0.80,
                          0.00, 1.00,  0.00,
                          -0.80, 0.00,  0.60 );

lowp vec4 map( in lowp vec3 p )
{
    lowp float d = sdBox(p,vec3(1.0));
    lowp vec4 res = vec4( d, 1.0, 0.0, 0.0 );
    
    lowp float ani = smoothstep( -0.2, 0.2, -cos(0.5*iTime) );
    lowp float off = 1.5*sin( 0.01*iTime );
    
    lowp float s = 1.0;
    for( int m=0; m<4; m++ )
    {
        p = mix( p, ma*(p+off), ani );
        
        lowp vec3 a = mod( p*s, 2.0 )-1.0;
        s *= 3.0;
        lowp vec3 r = abs(1.0 - 3.0*abs(a));
        lowp float da = max(r.x,r.y);
        lowp float db = max(r.y,r.z);
        lowp float dc = max(r.z,r.x);
        lowp float c = (min(da,min(db,dc))-1.0)/s;
        
        if( c>d )
        {
            d = c;
            res = vec4( d, min(res.y,0.2*da*db*dc), (1.0+float(m))/4.0, 0.0 );
        }
    }
    
    return res;
}

lowp vec4 intersect( in lowp vec3 ro, in lowp vec3 rd )
{
    lowp float t = 0.0;
    lowp vec4 res = vec4(-1.0);
    lowp vec4 h = vec4(1.0);
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

lowp float softshadow( in lowp vec3 ro, in lowp vec3 rd, lowp float mint, lowp float k )
{
    lowp float res = 1.0;
    lowp float t = mint;
    lowp float h = 1.0;
    for( int i=0; i<32; i++ )
    {
        h = map(ro + rd*t).x;
        res = min( res, k*h/t );
        t += clamp( h, 0.005, 0.1 );
    }
    return clamp(res,0.0,1.0);
}

lowp vec3 calcNormal(in lowp vec3 pos)
{
    lowp vec3  eps = vec3(.001,0.0,0.0);
    lowp vec3 nor;
    nor.x = map(pos+eps.xyy).x - map(pos-eps.xyy).x;
    nor.y = map(pos+eps.yxy).x - map(pos-eps.yxy).x;
    nor.z = map(pos+eps.yyx).x - map(pos-eps.yyx).x;
    return normalize(nor);
}

// light
lowp vec3 light = normalize(vec3(1.0,0.9,0.3));

lowp vec3 render( in lowp vec3 ro, in lowp vec3 rd )
{
    // background color
    lowp vec3 col = mix( vec3(0.3,0.2,0.1)*0.5, vec3(0.7, 0.9, 1.0), 0.5 + 0.5*rd.y );
    
    lowp vec4 tmat = intersect(ro,rd);
    if( tmat.x>0.0 )
    {
        lowp vec3  pos = ro + tmat.x*rd;
        lowp vec3  nor = calcNormal(pos);
        
        lowp float occ = tmat.y;
        lowp float sha = softshadow( pos, light, 0.01, 64.0 );
        
        lowp float dif = max(0.1 + 0.9*dot(nor,light),0.0);
        lowp float sky = 0.5 + 0.5*nor.y;
        lowp float bac = max(0.4 + 0.6*dot(nor,vec3(-light.x,light.y,-light.z)),0.0);
        
        lowp vec3 lin  = vec3(0.0);
        lin += 1.00*dif*vec3(1.10,0.85,0.60)*sha;
        lin += 0.50*sky*vec3(0.10,0.20,0.40)*occ;
        lin += 0.10*bac*vec3(1.00,1.00,1.00)*(0.5+0.5*occ);
        lin += 0.25*occ*vec3(0.15,0.17,0.20);
        
        lowp vec3 matcol = vec3(
                                0.5+0.5*cos(0.0+2.0*tmat.z),
                                0.5+0.5*cos(1.0+2.0*tmat.z),
                                0.5+0.5*cos(2.0+2.0*tmat.z) );
        col = matcol * lin;
    }
    
    return pow( col, vec3(0.4545) );
}


//shadertoy function
void mainImage( out lowp vec4 fragColor, in lowp vec2 fragCoord ) {
    lowp vec2 p = -1.0 + 2.0 * fragCoord.xy / iResolution.xy;
    p.x *= iResolution.x/iResolution.y;
    
    lowp float ctime = iTime;
    // camera
    lowp vec3 ro = 1.1*vec3(2.5*sin(0.25*ctime),1.0+1.0*cos(ctime*.13),2.5*cos(0.25*ctime));
    lowp vec3 ww = normalize(vec3(0.0) - ro);
    lowp vec3 uu = normalize(cross( vec3(0.0,1.0,0.0), ww ));
    lowp vec3 vv = normalize(cross(ww,uu));
    lowp vec3 rd = normalize( p.x*uu + p.y*vv + 2.5*ww );
    
    lowp vec3 col = render( ro, rd );
    
    fragColor = vec4(col,1.0);
}

void main(void) {
    mainImage(gl_FragColor,gl_FragCoord.xy);
}
