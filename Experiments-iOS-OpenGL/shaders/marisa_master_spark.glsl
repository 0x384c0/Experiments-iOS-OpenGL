//channel1 = texture mask
//channel2 = spell audio

float audio_ampl( in sampler2D channel) {
    return texture( channel, vec2(0, 0.0) ).x; 
}


vec3 rayDistortion(vec2 uv,float timeScale){
    vec2 d = uv.xy;    
	d.x += iChannelResolution[0].x * -(iTime * timeScale / iResolution.y);
	return vec3(texture(iChannel0, d));
}

vec3 ray(vec2 uv, vec2 fragCoord, vec3 color, float hOffset ,float speed){
    float
        hOffsetPix = iResolution.x * hOffset,
        angleOffset = fragCoord.x * (hOffsetPix + sin(iTime)*10.) * -0.01,
        x = fragCoord.x,
        y = fragCoord.y + angleOffset,
        rayWidth = .001,
        halfResolution = (iResolution.y / 2.0) + hOffsetPix,
        curve = sqrt(x) * rayWidth - abs(y - halfResolution);
    
    //GLOW
    float i = clamp(curve, 0.0, 1.0);
    float glowIntensity = 3.0;
    float glowSize = 0.03;
    float glowPixelSize = (glowSize + sqrt(x * 0.0005)) * iResolution.y;
    i += clamp((glowPixelSize + curve) / glowPixelSize, 0.0, 1.0) * glowIntensity;
    
    vec3 d = rayDistortion(uv,speed) * (0.05 + speed * 0.05);
    return i * (color - d) * 0.28; 
}


vec3 rayOrigin(in vec2 fragCoord){
    float theta = atan(iResolution.y / 2.0 - fragCoord.y, fragCoord.x + 15. );
    float len = iResolution.y * (3.0 + sin(theta * 7.0 + float(int(iTime * 20.0)) * -35.0)) / 3.0;
    float d = max(-0.6, 1.0 - (sqrt(pow(abs(fragCoord.x), 2.5) + pow(abs(iResolution.y / 2.0 - ((fragCoord.y - iResolution.y / 2.0) * 4.0 + iResolution.y / 2.0)), 2.0)) / len));
    return vec3(
        d * (1.0 + sin(theta * 10.0 + floor(iTime * 10.0) * 10.77) * 0.3), 
        d * (1.0 + cos(theta * 8.0 - floor(iTime * 20.0) * 8.77) * 0.3), 
        d * (1.0 + sin(theta * 6.0 - floor(iTime * 30.0) * 134.77) * 0.3)
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec3 c = vec3(0.,0.,0.);
    c += ray(uv,fragCoord, vec3(1.0, 0.0, 0.0) * 1.2, 	.03,	0.5);
    c += ray(uv,fragCoord, vec3(0.5, 0.5, 0.0),     	.01,	1.0);
    c += ray(uv,fragCoord, vec3(0.0, 1.0, 0.0),       	.0,		3.0);
    c += ray(uv,fragCoord, vec3(0.0, 0.5, 1.0),    		-.01,	1.0);
    c += ray(uv,fragCoord, vec3(1.0, 0.5, 1.0) * 1.2,	-.03,	0.5);
    c += clamp(rayOrigin(fragCoord), 0.0, 1.0);
    
    float a = audio_ampl(iChannel1);
    c *= a;
    
    fragColor = vec4(c, 1.);
    
}
