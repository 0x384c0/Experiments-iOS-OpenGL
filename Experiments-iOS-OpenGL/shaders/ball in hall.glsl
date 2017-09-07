vec4 ray(mat4 transformation, mat4 inv) {
    
    // Sphere collision
    vec4 p = transformation * vec4(0,0,0,1);
    float distance_squared = dot(p.xy, p.xy);
    
    if (distance_squared < 0.99) {
        // calculate collision position
        vec3 norm = vec3(-p.x, -p.y, - sqrt(1.0 - distance_squared));
        vec3 spec = reflect(vec3(0, 0, 1), norm);
        return pow(textureForCube(iChannel0, (inv * vec4(spec, 0)).xyz), vec4(1.45 - 0.25 * distance_squared)) * 0.8 +
        vec4(0.11, 0.10, 0.09, 0.0); // ambient light
    }
    
    return textureForCube(iChannel0, (inv * vec4(0,0,1,0)).xyz);
}

mat4 Transpose(mat4 v) {
    return
    mat4(v[0].x, v[1].x, v[2].x, v[3].x,
         v[0].y, v[1].y, v[2].y, v[3].y,
         v[0].z, v[1].z, v[2].z, v[3].z,
         v[0].w, v[1].w, v[2].w, v[3].w);
    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord.xy - iResolution.xy / 2.0) / iResolution.x;
    
    vec2 y = normalize(vec2(uv.x, 1));
    vec2 x = normalize(vec2(-uv.y, 1));
    
    float angle = iTime + 2.4 * iMouse.x / iResolution.x;
    
    float c = cos(angle);
    float s = sin(angle);
    mat4 t = mat4(1, 0, 0, 0,
                  0, 1, 0, 0,
                  0, 0, 1, 0,
                  0, 0, 3.0 + 0.3 * s, 1);
    mat4 tr = mat4(c, 0, s, 0,
                   0, 1, 0, 0,
                   -s,0, c, 0,
                   0, 0, 0, 1);
    
    mat4 xr = mat4(1, 0, 0, 0,
                   0, x.y, x.x, 0,
                   0, -x.x, x.y, 0,
                   0, 0, 0, 1) * t;
    mat4 yr = mat4(y.y, 0, y.x, 0,
                   0, 1, 0, 0,
                   -y.x, 0, y.y, 0,
                   0, 0, 0, 1);
    
    // Cast a ray, see if we hit anything.
    fragColor = ray(yr * xr * t * tr,
                    Transpose(tr) * Transpose(t) * Transpose(xr) * Transpose(yr));
    // fragColor = vec4(uv, 0,1);
}
