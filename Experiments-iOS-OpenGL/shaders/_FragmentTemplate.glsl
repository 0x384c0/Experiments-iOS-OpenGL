#version 300 es
precision highp float;
precision highp int;

out vec4 fragmentColor;

uniform vec3        iResolution;            // viewport resolution (in pixels)
uniform float       iTime;                  // shader playback time (in seconds)
uniform vec4        iMouse;                 // mouse pixel coords. xy: current (if MLB down), zw: click
uniform sampler2D   iChannel0;              // input channel. XX = 2D/Cube
uniform sampler2D   iChannel1;              // input channel. XX = 2D/Cube
uniform sampler2D   iChannel2;              // input channel. XX = 2D/Cube
uniform sampler2D   iChannel3;              // input channel. XX = 2D/Cube
uniform vec3        iChannelResolution[4];  // channel resolution (in pixels)

//vec4 textureLod(sampler2D sampler,vec2 par1, float par2){
//    return texture2D(sampler,par1,par2);
//}
vec4 textureForCube(sampler2D sampler,vec3 par1){//TODO: add cube map support
    return texture(sampler,par1.xy,0.);
}
//vec4 texture(sampler2D sampler,vec2 par1){
//    return texture2D(sampler,par1,0.);
//}
//vec4 texture(sampler2D sampler,vec2 par1, float par2){
//    return texture2D(sampler,par1,par2);
//}
//mat3 transpose(mat3 par1){
//    return par1;
//}
//vec2 round(vec2 par1){
//    return par1;
//}

SHADER_TOY_CODE_PLACEHOLDER

void main() {
    mainImage(fragmentColor,gl_FragCoord.xy);
}
