// Buf A is a uniform grid data structure, but storage in each pixel is 1 particle
// (.xy=vel, .zw=pos). For each bucket, searches neighbourhood for newly arriving particle,
// greedily takes first one so particles can annihilate each other if they land in the same
// pixel bucket.

// Flock or perhaps even SPH behavious could probably be implemented on a similar framework.

#define R 5.
#define RESTITUTION .5

// scene data
#define GRAVITY_ENABLED 0
#define COLISIONS_ENABLED 0
#define COL0 vec2(2.5,0.5)/iResolution.xy
#define COL1 vec2(3.5,0.5)/iResolution.xy
#define COL2 vec2(4.5,0.5)/iResolution.xy

vec2 GetVel( vec4 part ) { return part.xy; }
void SetVel( inout vec4 part, vec2 newVel ) { part.xy = newVel; }
vec2 GetPos( vec4 part ) { return part.zw; }
void SetPos( inout vec4 part, vec2 newPos ) { part.zw = newPos; }

vec2 FindArrivingParticle( vec2 arriveCoord, out vec4 partData )
{
    for( float i = -R; i <= R; i++ )
    {
        for( float j = -R; j <= R; j++ )
        {
            vec2 partCoord = arriveCoord + vec2( i, j );
            
            vec4 part = textureLod( iChannel0, partCoord / iResolution.xy, 0. );
            
            // particle in this bucket?
            if( dot(part,part) < 0.001 )
                continue;
            
            // is the particle going to arrive at the current pixel after one timestep?
            vec2 partPos = GetPos( part );
            vec2 partVel = GetVel( part );
            vec2 nextPos = partPos + partVel;
            // arrival means within half a pixel of this bucket
            vec2 off = nextPos - arriveCoord;
            if( abs(off.x)<=.5 && abs(off.y)<=.5 )
            {
                // yes! greedily take this particle.
                // a better algorithm might be to inspect all particles that arrive here
                // and pick the one with the highest velocity.
                partData = part;
                return partCoord;
            }
        }
    }
    // no particle arriving at this bucket.
    return vec2(-1.);
}

void Clip( inout vec4 partData, vec2 col0Pos, vec2 col1Pos, vec2 col2Pos )
{
    vec2 pos = GetPos( partData );
    vec2 vel = GetVel( partData );
    
    vec2 nextPos = pos + vel;
    if( nextPos.y < 0. ) vel.y *= -RESTITUTION;
    if( nextPos.x < 0. ) vel.x *= -RESTITUTION;
    if( nextPos.y > iResolution.y ) vel.y *= -RESTITUTION;
    if( nextPos.x > iResolution.x ) vel.x *= -RESTITUTION;

    vec2 off; float loff2;
    off = nextPos - col0Pos;
    loff2 = dot(off,off);
    if( loff2 < 0. ) {
        loff2 = sqrt(loff2);
        vec2 n = off/loff2;
        vel -= (1.+RESTITUTION) * dot( vel, n ) * n;
        SetPos( partData, col0Pos + 50.*n );
    }
    off = nextPos - col1Pos;
    loff2 = dot(off,off);
    if( loff2 < 0. ) {
        loff2 = sqrt(loff2);
        vec2 n = off/loff2;
        vel -= (1.+RESTITUTION) * dot( vel, n ) * n;
        SetPos( partData, col1Pos + 50.*n );
    }
    off = nextPos - col2Pos;
    loff2 = dot(off,off);
    if( loff2 < 0. ) {
        loff2 = sqrt(loff2);
        vec2 n = off/loff2;
        vel -= (1.+RESTITUTION) * dot( vel, n ) * n;
        SetPos( partData, col2Pos + 50.*n );
    }

    SetVel( partData, vel );
}


//emitters
bool emitMouse(out vec4 fragColor, in vec2 fragCoord ){
    // mouse emits
    if( iMouse.z > 0. && length(iMouse.xy-fragCoord.xy) < 9.)
    {
        vec4 newPart;
        SetPos( newPart, fragCoord );
        SetVel( newPart, 3. * normalize(fragCoord.xy-iMouse.xy));
        fragColor = newPart;
        return true;
    }
    return false;
}

#define SPEED_PIX 3.
bool emitParticle(vec2 pos, float angle, out vec4 fragColor, in vec2 fragCoord){
    float centerOffset = 10.;
    pos += vec2(sin(angle) * centerOffset,cos(angle) * centerOffset);
    
    if (floor(fragCoord) == floor(pos)){
        
    	vec2 vel = vec2(sin(angle) * SPEED_PIX,cos(angle) * SPEED_PIX);
        
        vec4 newPart;
        SetPos( newPart, pos );
        SetVel( newPart, vel);
        fragColor = newPart;
        return true;
    }
    return false;
}

#define M_PI 3.1415926
#define ANGLES 11.
#define FREQUENCY 2. // in frames 
bool emitBullets(out vec4 fragColor, in vec2 fragCoord){
    
    float angleMod = sin(iTime * M_PI/4.) * 10. - 6.; // rotation function
    
    vec2 origin = iResolution.xy/2.;
    if( iMouse.z > 0.)
        origin = iMouse.xy;
    
    origin.x += sin(iTime / 2.) * iResolution.x / 35.;
    origin.y += sin(iTime / 3.) * iResolution.y / 25.;
    
    if (mod(float(iFrame),FREQUENCY) == 0.){
        bool result = false;
        const float andgleDiff = 2. * M_PI/ANGLES;
        for (float angle = 0.001; angle <= 2. * M_PI; angle += andgleDiff){
        	result = emitParticle(origin, angle + angleMod ,fragColor,fragCoord) || result;
        }
        return result;
    }
	return false;
}




void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 col0Data = textureLod(iChannel2, COL0, 0.).xyz;
    vec3 col1Data = textureLod(iChannel2, COL1, 0.).xyz;
    vec3 col2Data = textureLod(iChannel2, COL2, 0.).xyz;
    
    //emitters
    //if (emitMouse(fragColor,fragCoord)) {return;}
    if (emitBullets(fragColor,fragCoord)) {return;}
    
    
    // look for a particle arriving at the current bucket
    vec4 partData;
    vec2 partCoord = FindArrivingParticle( fragCoord, partData );
    if( partCoord.x < 0. )
    {
        // no particle, empty this bucket
        fragColor = vec4(0.);
        return;
    }
    
    vec2 pos = GetPos( partData );
    vec2 vel = GetVel( partData );
    
    // integrate pos using current vel
    SetPos( partData, pos + vel );
    
    // gravity
#if GRAVITY_ENABLED
    vel += vec2(0.,-.05);
#endif
    
    
    
    SetVel( partData, vel );
    
#if COLISIONS_ENABLED
    Clip( partData, col0Data.xy, col1Data.xy, col2Data.xy );
#endif
    
    
    fragColor = partData;
}

