//RENDERER SHADER


//--- draw one star:  (I.filter(color)).dirac * PSF ------------------ 
#define SCALE 40.
#define STAR_SIZE 0.0001
#define LENSE_EFFECT 0
const float star_luminosity = 1e3;
vec3 star_color = vec3(210./255., 166./255., 99./255.)*star_luminosity;
vec2 FragCoord;
vec3 draw_star(vec2 pos, float I) {
    I *= pow(300./iResolution.y,3.);
    
    pos -= FragCoord.xy/iResolution.y; 
    
    float d = length(pos)*SCALE;
    
    vec3 col, spectrum = I*star_color;
    
    col = spectrum/(d*d*d);
#if LENSE_EFFECT
    d = length(pos*vec2(50.,.5))*SCALE;
    col += spectrum/(d*d*d);
    d = length(pos*vec2(.5,50.))*SCALE;
    col += spectrum/(d*d*d);
#endif

    return col;
}

void draw_stars(out vec4 fragColor, in vec2 fragCoord ){
    float mixResValue = 0.;
    if (iResolution.x < iResolution.y){
        mixResValue = iResolution.x;
    } else {
        mixResValue = iResolution.y;
    }
    
    const int searchRange = 7;
	fragColor = vec4(0.);
    for (int x = -searchRange; x <= searchRange; x += 1){
        for (int y = -searchRange; y <= searchRange; y += 1){
            vec2 coord = fragCoord + vec2(x,y); //pixel coord
            vec4 particleData = texture(iChannel1, coord/iResolution.xy);
            if (dot(particleData,particleData) != 0.){
                vec2 particleCoord = vec2(coord.x/mixResValue,coord.y/mixResValue);
                fragColor += vec4(draw_star(particleCoord,STAR_SIZE),1.);
            }
        }
    }
    
}


// main

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    FragCoord = fragCoord; //for star
    
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv.x *= iResolution.x / iResolution.y;
    
    //prepare background
    //fragColor = vec4(0.0);
    fragColor = clamp(texture(iChannel0, fragCoord / iResolution.xy)  * 0.3,-100.,100.); //tracer
    
    //render
    //fragColor += texture(iChannel1, fragCoord/iResolution.xy);
    draw_stars(fragColor,fragCoord);
    
    
#if 0
    //grid
    if (round(mod(fragCoord.x,100.)) == 100. ||
        round(mod(fragCoord.y,100.)) == 100. ){
        fragColor = vec4(1.,0.,0.,1.);
    }
    //mouse
    if (fragCoord.x >= iMouse.x && fragCoord.x <= iMouse.x + 1.||
        fragCoord.y >= iMouse.y && fragCoord.y <= iMouse.y + 1.){
        fragColor = vec4(0.,1.,0.,1.);
    }
#endif
}