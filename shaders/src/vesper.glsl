// «Веспер»: прежний готический вид (Sanguine Ivory) на новой оптике. Винный бархат, кость, латунь. Цвета:
//   uC0 склера в центре (кость), uC1 склера у краёв, uC2 радужка у зрачка (тёмное вино), uC3 гранат,
//   uC4 латунь, uC5 зрачок, uC6 веко, uC7 кромка верхнего века (винно-розовая).
const float V_RI = 0.92;

vec4 eye(vec2 q) {
    float dShape, dTop, dBot;
    eyeGeom(q, 1.0, 0.88, 0.0, 0.24, dShape, dTop, dBot);
    float w = px();
    float inside = cover(dShape);
    float open = cover(-min(dTop, dBot));

    vec3 scl = mix(uC0.rgb, uC1.rgb, smoothstep(0.5, 2.7, length(q * vec2(1.0, 1.9))));
    scl = mix(uC1.rgb * 0.8, scl, 0.35 + 0.65 * smoothstep(0.0, 0.4, -dShape));

    float rI = V_RI * (1.0 + 0.06 * uEnergy);
    vec2 c = irisCenter(uGaze, vec2(1.05, 0.30), -0.07);
    vec2 u = irisUV(q, c, rI);
    float r = length(u);
    float ang = atan(u.y, u.x);
    float an = ang / TAU + 0.5;

    vec3 ir = mix(uC2.rgb, uC3.rgb, smoothstep(0.36, 0.66, r));
    ir = mix(ir, uC3.rgb * 0.30, smoothstep(0.72, 1.0, r));
    float fib = vnoiseWrap(vec2(an * 72.0, r * 2.4 + 5.0), 72.0) * 0.6 + vnoiseWrap(vec2(an * 190.0, r * 5.0), 190.0) * 0.4;
    float fibMask = smoothstep(0.42, 0.56, r) * (1.0 - smoothstep(0.86, 1.0, r));
    ir *= 1.0 + (fib - 0.5) * 0.42 * fibMask;
    ir += uC4.rgb * pow(fib, 5.0) * 0.20 * fibMask;
    // Тёплое латунное кольцо у зрачка.
    float ringGlow = 0.72 + 0.6 * uWake;
    ir = mix(ir, uC4.rgb, exp(-pow((r - 0.47) / 0.04, 2.0)) * ringGlow * 0.62);
    // Событие: сдержанный отсвет на краю радужки с нужной стороны.
    if (uPulse > 0.0005) {
        float side = smoothstep(0.55, 1.0, dot(u / max(r, 1e-3), uPulseDir));
        ir += uC4.rgb * side * smoothstep(0.6, 0.9, r) * (1.0 - smoothstep(0.9, 1.0, r)) * sin(uPulse * PI) * 0.6;
    }

    vec2 pOff = (uGaze2 - uGaze) * vec2(0.10, 0.06) + uGaze * vec2(0.05, 0.03);
    float dp = length(u - pOff) - 0.40 * uPupil;
    float aw = 1.5 * w / rI;
    ir = mix(ir, uC4.rgb, stroke(dp - 0.03, 0.9 * w / rI) * 0.38);
    ir = mix(ir, uC5.rgb, coverSoft(dp, aw));

    float irisMask = coverSoft(r - 1.0, aw);
    vec3 inner = mix(scl, ir, irisMask);
    float sh = exp(-max(dTop, 0.0) / 0.22) * 0.62 + exp(-max(dBot, 0.0) / 0.09) * 0.2;
    inner *= 1.0 - 0.72 * sh;

    // Костяные блики стоят на месте.
    vec2 hk = rot(0.35) * (q - (c * 0.55 + vec2(-0.26, -0.33) * V_RI));
    float key = coverSoft(length(hk / vec2(0.12, 0.08)) - 1.0, 0.25) * 0.62;
    float sec = coverSoft(length(q - (c * 0.55 + vec2(0.30, 0.27) * V_RI)) - 0.04, 0.02) * 0.24;
    inner = mix(inner, vec3(0.965, 0.91, 0.875), (key + sec) * mix(0.3, 1.0, irisMask));

    vec3 lid = uC6.rgb * (0.62 + 0.38 * smoothstep(-0.9, 0.9, -q.y));
    vec3 body = mix(lid, inner, open);
    body = mix(body, uC7.rgb, stroke(dTop, 0.9 * w) * 0.62);
    body = mix(body, uC4.rgb, stroke(dBot, 0.6 * w) * 0.42);

    float dOut = max(dShape, 0.0);
    float glow = exp(-dOut / 0.22) * 0.10 * (1.0 - inside) * (1.0 - smoothstep(0.06, 0.33, dOut));
    vec4 col = vec4(uC3.rgb * glow, glow);
    col = over(col, body, inside);
    col = over(col, uC4.rgb, stroke(dShape + 0.6 * w, 0.6 * w) * 0.55);
    // Четыре латунных штриха по осям, в духе ар-деко.
    vec2 a = abs(q);
    float tick = min(sdSegment(vec2(a.x, q.y), vec2(EYE_W + 0.10, 0.0), vec2(EYE_W + 0.24, 0.0)),
                 min(sdSegment(q, vec2(0.0, -1.12), vec2(0.0, -1.26)), sdSegment(q, vec2(0.0, 1.00), vec2(0.0, 1.14))));
    col = over(col, uC4.rgb, cover(tick - 0.6 * w) * 0.42);
    return col * mix(0.35, 1.0, clamp(uDim, 0.0, 1.0));
}
