varying lowp vec4 DestinationColor;
uniform lowp float iTime;           // shader playback time (in seconds)
uniform lowp vec3 iResolution;      // viewport resolution (in pixels)
lowp vec4 iMouse = vec4(1.0,1.0,1.0,1.0);   // mouse pixel coords. xy: current (if MLB down), zw: click //TODO: replace with touch recognizer
uniform sampler2D iChannel0;        // input channel. XX = 2D/Cube

lowp vec4 textureLod(sampler2D iChannel0,lowp vec2 par1, lowp float par2){
	lowp vec4 result = texture2D(iChannel0,par1,par2);
    result.x = result.x - 0.1;
    result.y = result.y + 0.1;
    //TODO:
    //Filter linear
    //Wrap repeat
    //VFlip
	return result;
}

lowp float noise( in lowp vec3 x )
{
    lowp vec3 p = floor(x);
    lowp vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
    
#if 1
	lowp vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
    lowp vec2 rg = textureLod( iChannel0, (uv+ 0.5)/256.0, 0. ).yx;

#else
    ivec3 q = ivec3(p);
	ivec2 uv = q.xy + ivec2(37,17)*q.z;

	vec2 rg = mix( mix( texelFetch( iChannel0, (uv           )&255, 0 ),
				        texelFetch( iChannel0, (uv+ivec2(1,0))&255, 0 ), f.x ),
				   mix( texelFetch( iChannel0, (uv+ivec2(0,1))&255, 0 ),
				        texelFetch( iChannel0, (uv+ivec2(1,1))&255, 0 ), f.x ), f.y ).yx;
#endif    
    
	return -1.0+2.0*mix( rg.x, rg.y, f.z );
}

lowp float map5( in lowp vec3 p )
{
	lowp vec3 q = p - vec3(0.0,0.1,1.0)*iTime;
	lowp float f;
    f  = 0.50000*noise( q ); q = q*2.02;
    f += 0.25000*noise( q ); q = q*2.03;
    f += 0.12500*noise( q ); q = q*2.01;
    f += 0.06250*noise( q ); q = q*2.02;
    f += 0.03125*noise( q );
	return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
}

lowp float map4( in lowp vec3 p )
{
	lowp vec3 q = p - vec3(0.0,0.1,1.0)*iTime;
	lowp float f;
    f  = 0.50000*noise( q ); q = q*2.02;
    f += 0.25000*noise( q ); q = q*2.03;
    f += 0.12500*noise( q ); q = q*2.01;
    f += 0.06250*noise( q );
	return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
}
lowp float map3( in lowp vec3 p )
{
	lowp vec3 q = p - vec3(0.0,0.1,1.0)*iTime;
	lowp float f;
    f  = 0.50000*noise( q ); q = q*2.02;
    f += 0.25000*noise( q ); q = q*2.03;
    f += 0.12500*noise( q );
	return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
}
lowp float map2( in lowp vec3 p )
{
	lowp vec3 q = p - vec3(0.0,0.1,1.0)*iTime;
	lowp float f;
    f  = 0.50000*noise( q ); q = q*2.02;
    f += 0.25000*noise( q );;
	return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
}

lowp vec3 sundir = normalize( vec3(-1.0,0.0,-1.0) );

lowp vec4 integrate( in lowp vec4 sum, in lowp float dif, in lowp float den, in lowp vec3 bgcol, in lowp float t )
{
    // lighting
    lowp vec3 lin = vec3(0.65,0.7,0.75)*1.4 + vec3(1.0, 0.6, 0.3)*dif;        
    lowp vec4 col = vec4( mix( vec3(1.0,0.95,0.8), vec3(0.25,0.3,0.35), den ), den );
    col.xyz *= lin;
    col.xyz = mix( col.xyz, bgcol, 1.0-exp(-0.003*t*t) );
    // front to back blending    
    col.a *= 0.4;
    col.rgb *= col.a;
    return sum + col*(1.0-sum.a);
}

#define MARCH(STEPS,MAPLOD) for(int i=0; i<STEPS; i++) { lowp vec3  pos = ro + t*rd; if( pos.y<-3.0 || pos.y>2.0 || sum.a > 0.99 ) break; lowp float den = MAPLOD( pos ); if( den>0.01 ) { lowp float dif =  clamp((den - MAPLOD(pos+0.3*sundir))/0.6, 0.0, 1.0 ); sum = integrate( sum, dif, den, bgcol, t ); } t += max(0.05,0.02*t); }

lowp vec4 raymarch( in lowp vec3 ro, in lowp vec3 rd, in lowp vec3 bgcol, in lowp ivec2 px )
{
	lowp vec4 sum = vec4(0.0);

	lowp float t = 0.0;//0.05*texelFetch( iChannel0, px&255, 0 ).x;

    MARCH(30,map5);
    MARCH(30,map4);
    MARCH(30,map3);
    MARCH(30,map2);

    return clamp( sum, 0.0, 1.0 );
}

lowp mat3 setCamera( in lowp vec3 ro, in lowp vec3 ta, lowp float cr )
{
	lowp vec3 cw = normalize(ta-ro);
	lowp vec3 cp = vec3(sin(cr), cos(cr),0.0);
	lowp vec3 cu = normalize( cross(cw,cp) );
	lowp vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

lowp vec4 render( in lowp vec3 ro, in lowp vec3 rd, in lowp ivec2 px )
{
    // background sky     
	lowp float sun = clamp( dot(sundir,rd), 0.0, 1.0 );
	lowp vec3 col = vec3(0.6,0.71,0.75) - rd.y*0.2*vec3(1.0,0.5,1.0) + 0.15*0.5;
	col += 0.2*vec3(1.0,.6,0.1)*pow( sun, 8.0 );

    // clouds    
    lowp vec4 res = raymarch( ro, rd, col, px );
    col = col*(1.0-res.w) + res.xyz;
    
    // sun glare    
	col += 0.2*vec3(1.0,0.4,0.2)*pow( sun, 3.0 );

    return vec4( col, 1.0 );
}


//shadertoy function
void mainImage( out lowp vec4 fragColor, in lowp vec2 fragCoord ) {
    lowp vec2 p = (-iResolution.xy + 2.0*fragCoord.xy)/ iResolution.y;

    iMouse.x = iTime;
    lowp vec2 m = iMouse.xy/iResolution.xy;
    
    // camera
    lowp vec3 ro = 4.0*normalize(vec3(sin(3.0*m.x), 0.4*m.y, cos(3.0*m.x)));
	lowp vec3 ta = vec3(0.0, -1.0, 0.0);
    lowp mat3 ca = setCamera( ro, ta, 0.0 );
    // ray
    lowp vec3 rd = ca * normalize( vec3(p.xy,1.5));
    
    fragColor = render( ro, rd, ivec2(fragCoord-0.5) );
}

void main(void) {
    mainImage(gl_FragColor,gl_FragCoord.xy);
}
