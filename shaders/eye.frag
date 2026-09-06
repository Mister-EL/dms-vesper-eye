#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;
    float logicalEyeHeight;
    vec2 irisOffset;
    vec2 pupilOffset;
    float irisRadius;
    float pupilRadius;
    float topLidProgress;
    float bottomLidProgress;
    float outlineWidth;
    vec4 scleraColor;
    vec4 irisInnerColor;
    vec4 irisMiddleColor;
    vec4 irisOuterColor;
    vec4 pupilColor;
    vec4 accentColor;
    vec4 highlightColor;
    vec4 lidColor;
} ubuf;

float softMask(float distanceValue, float width) {
    return 1.0 - smoothstep(-width, width, distanceValue);
}

void main() {
    vec2 size = max(ubuf.itemSize, vec2(1.0));
    vec2 p = (qt_TexCoord0 - vec2(0.5)) * size;
    float aa = 1.35;

    float halfWidth = size.x * 0.496;
    float halfHeight = ubuf.logicalEyeHeight * 0.22;
    float nx = abs(p.x) / halfWidth;
    float arch = pow(max(0.0, 1.0 - nx * nx), 1.08);
    float curve = halfHeight * arch;
    float shapeDistance = max(abs(p.y) - curve, (nx - 1.0) * halfHeight);
    if (shapeDistance > aa) {
        fragColor = vec4(0.0);
        return;
    }
    float shapeMask = softMask(shapeDistance, aa);
    float innerMask = softMask(shapeDistance + ubuf.outlineWidth, aa);

    float topBoundary = mix(-curve + ubuf.outlineWidth, 0.0, clamp(ubuf.topLidProgress, 0.0, 1.0));
    float bottomBoundary = mix(curve - ubuf.outlineWidth, 0.0, clamp(ubuf.bottomLidProgress, 0.0, 1.0));
    float lidDistance = max(topBoundary - p.y, p.y - bottomBoundary);
    float apertureMask = (ubuf.topLidProgress >= 0.999 && ubuf.bottomLidProgress >= 0.999) ? 0.0 : softMask(lidDistance, aa);
    float contentMask = innerMask * apertureMask;

    vec3 color = ubuf.scleraColor.rgb;
    vec2 irisPoint = p - ubuf.irisOffset;
    float irisLimit = ubuf.irisRadius + aa;
    if (contentMask > 0.0001 && dot(irisPoint, irisPoint) < irisLimit * irisLimit) {
        float irisDistance = length(irisPoint);
        float irisUnit = irisDistance / max(ubuf.irisRadius, 1.0);
        float irisMask = (1.0 - smoothstep(0.985, 1.015, irisUnit)) * contentMask;
        vec2 gradientCenter = ubuf.irisOffset - vec2(ubuf.irisRadius * 0.15);
        float gradientDistance = length(p - gradientCenter) / max(ubuf.irisRadius, 1.0);
        vec3 iris = mix(ubuf.irisInnerColor.rgb,
                        ubuf.irisMiddleColor.rgb,
                        smoothstep(0.08, 0.62, gradientDistance));
        iris = mix(iris,
                   ubuf.irisOuterColor.rgb,
                   smoothstep(0.62, 1.0, gradientDistance));
        float angle = atan(irisPoint.y, irisPoint.x);
        float fibers = sin(angle * 47.0 + irisUnit * 9.0) * sin(angle * 71.0 - irisUnit * 5.0);
        float fiberMask = smoothstep(0.62, 0.72, irisUnit) * (1.0 - smoothstep(0.90, 1.0, irisUnit));
        iris *= 1.0 + fibers * fiberMask * 0.075;
        float warmRing = exp(-pow((irisUnit - 0.68) * 34.0, 2.0));
        iris = mix(iris, ubuf.accentColor.rgb, warmRing * 0.28);
        color = mix(color, iris, irisMask);

        vec2 pupilPoint = irisPoint - ubuf.pupilOffset;
        float pupilLimit = ubuf.pupilRadius + aa;
        if (dot(pupilPoint, pupilPoint) < pupilLimit * pupilLimit) {
            float pupilDistance = length(pupilPoint);
            float pupilMask = (1.0 - smoothstep(ubuf.pupilRadius - aa,
                                                ubuf.pupilRadius + aa,
                                                pupilDistance)) * irisMask;
            color = mix(color, ubuf.pupilColor.rgb, pupilMask);
        }

        vec2 highlightCenter = ubuf.irisOffset - vec2(ubuf.irisRadius * 0.28);
        float highlightRadius = ubuf.irisRadius * 0.105;
        float highlightMask = (1.0 - smoothstep(0.0,
                                                highlightRadius,
                                                length(p - highlightCenter))) * irisMask;
        color = mix(color,
                    ubuf.highlightColor.rgb,
                    highlightMask * ubuf.highlightColor.a);
    }

    // Eyelids: painted with the background tone so the eye owns its lids
    // instead of relying on the wallpaper showing through the aperture.
    float lidMask = innerMask * (1.0 - apertureMask);
    float lidDepth = 1.0 - smoothstep(0.0, ubuf.logicalEyeHeight * 0.14, lidDistance);
    vec3 lid = ubuf.lidColor.rgb * (1.0 - lidDepth * 0.16);
    float rimLine = 1.0 - smoothstep(0.8, 3.2, lidDistance);
    lid = mix(lid, ubuf.accentColor.rgb, rimLine * 0.35);
    color = mix(color, lid, lidMask);

    float outlineMask = max(0.0, shapeMask - innerMask);
    color = mix(color, ubuf.accentColor.rgb, outlineMask * 0.55);

    float alpha = shapeMask * ubuf.qt_Opacity;
    fragColor = vec4(color * alpha, alpha);
}
