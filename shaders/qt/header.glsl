#version 440
// Собирается tools/build.py: заголовок Qt + common.glsl + образ + хвост.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float uTime;
    vec2 uSize;
    float uUnit;
    float uPupil;
    vec2 uGaze;
    vec2 uGaze2;
    float uLidTop;
    float uLidBot;
    float uEnergy;
    float uWake;
    float uPulse;
    float uDim;
    vec2 uPulseDir;
    float uLight;
    vec4 uC0;
    vec4 uC1;
    vec4 uC2;
    vec4 uC3;
    vec4 uC4;
    vec4 uC5;
    vec4 uC6;
    vec4 uC7;
    vec4 uP0;
    vec4 uP1;
} ubuf;
#define uTime ubuf.uTime
#define uSize ubuf.uSize
#define uUnit ubuf.uUnit
#define uPupil ubuf.uPupil
#define uGaze ubuf.uGaze
#define uGaze2 ubuf.uGaze2
#define uLidTop ubuf.uLidTop
#define uLidBot ubuf.uLidBot
#define uEnergy ubuf.uEnergy
#define uWake ubuf.uWake
#define uPulse ubuf.uPulse
#define uDim ubuf.uDim
#define uPulseDir ubuf.uPulseDir
#define uLight ubuf.uLight
#define uC0 ubuf.uC0
#define uC1 ubuf.uC1
#define uC2 ubuf.uC2
#define uC3 ubuf.uC3
#define uC4 ubuf.uC4
#define uC5 ubuf.uC5
#define uC6 ubuf.uC6
#define uC7 ubuf.uC7
#define uP0 ubuf.uP0
#define uP1 ubuf.uP1
