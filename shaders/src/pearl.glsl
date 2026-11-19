// «Перламутр»: пастель. Цвета:
//   uC0 белок, uC1 тень (сирень), uC2 радужка у зрачка (голубой), uC3 середина (сирень),
//   uC4 край радужки (розовый), uC5 зрачок (чернила), uC6 веко, uC7 кромка (розовое золото).
const float P_HU = 1.0;
const float P_HL = 0.88;
const float P_RI = 0.90;

vec4 eye(vec2 q) {
    float dShape, dTop, dBot;
    eyeGeom(q, P_HU, P_HL, 0.10, 0.24, dShape, dTop, dBot);
    float w = px();
    float inside = cover(dShape);
    float open = cover(-min(dTop, dBot));

    // Белок: к краям уходит в сиреневую тень, сверху чуть розовее, снизу голубее.
    vec3 scl = mix(uC1.rgb, uC0.rgb, 0.45 + 0.55 * smoothstep(0.0, 0.38, -dShape));
    scl *= mix(vec3(1.0, 0.955, 0.975), vec3(0.955, 0.975, 1.0), smoothstep(-0.8, 0.8, q.y));

    // Радужка.
    vec2 c = irisCenter(uGaze, vec2(1.06, 0.30), -0.07);
    vec2 u = irisUV(q, c, P_RI);
    float r = length(u);
    float ang = atan(u.y, u.x);
    float an = ang / TAU + 0.5;
    float irisMask = coverSoft(r - 1.0, 1.5 * w / P_RI);

    vec3 ir = mix(uC2.rgb, uC3.rgb, smoothstep(0.30, 0.62, r));
    ir = mix(ir, uC4.rgb, smoothstep(0.58, 0.96, r));
    float f1 = vnoiseWrap(vec2(an * 64.0, r * 2.6 + 3.0), 64.0);
    float f2 = vnoiseWrap(vec2(an * 180.0, r * 5.0 + 11.0), 180.0);
    float fib = f1 * 0.62 + f2 * 0.38;
    float fibMask = smoothstep(0.34, 0.5, r) * (1.0 - smoothstep(0.86, 0.99, r));
    ir *= 1.0 + (fib - 0.5) * 0.30 * fibMask;
    ir += vec3(1.0) * pow(fib, 4.0) * 0.12 * fibMask;
    float wob = (vnoiseWrap(vec2(an * 24.0, 1.7), 24.0) - 0.5) * 0.07;
    float coll = exp(-pow((r - 0.44 - wob) / 0.075, 2.0));
    ir = mix(ir, mix(uC0.rgb, uC2.rgb, 0.35), coll * 0.42);
    // Перелив перламутра: оттенок смещается вслед за взглядом.
    float shift = 0.5 + 0.5 * sin(ang * 2.0 + dot(uGaze, vec2(2.6, 1.9)) + r * 3.0);
    ir = mix(ir, ir.bgr, shift * 0.22 * smoothstep(0.3, 0.7, r));
    vec3 limb = mix(uC3.rgb, uC5.rgb, 0.55);
    ir = mix(ir, limb, smoothstep(0.78, 1.0, r) * 0.80);
    // Свет падает сверху слева и собирается ярким серпом на противоположной стороне.
    vec2 L = normalize(vec2(-0.62, -0.78));
    float ca = smoothstep(0.1, 1.0, dot(u / max(r, 1e-3), -L)) * smoothstep(0.38, 0.72, r) * (1.0 - smoothstep(0.78, 0.98, r));
    ir += vec3(1.0, 0.97, 0.98) * ca * 0.13;

    // Зрачок чуть отстаёт от радужки: это и даёт глубину.
    vec2 pOff = (uGaze2 - uGaze) * vec2(0.10, 0.06) + uGaze * vec2(0.05, 0.03);
    float rp = 0.34 * uPupil;
    float dp = length(u - pOff) - rp;
    float pm = coverSoft(dp, 2.0 * w / P_RI);
    vec3 pcol = uC5.rgb + uC2.rgb * 0.10 * smoothstep(-0.3 * rp, 0.0, dp);
    ir = mix(ir, pcol, pm);
    ir += uC0.rgb * exp(-pow(dp / 0.035, 2.0)) * 0.10 * (1.0 - pm);

    vec3 inner = mix(scl, ir, irisMask);

    // Тень от век.
    float sh = exp(-max(dTop, 0.0) / 0.16) * 0.40 + exp(-max(dBot, 0.0) / 0.08) * 0.12;
    inner *= mix(vec3(1.0), uC1.rgb * 0.72, sh);

    // Блики стоят почти на месте, радужка движется под ними.
    vec2 hk = c * 0.55 + vec2(-0.34, -0.40) * P_RI;
    vec2 hq = rot(0.22) * (q - hk);
    float key = coverSoft(sdRoundBox(hq, vec2(0.20, 0.15) * P_RI, 0.05), 0.02);
    float bars = max(coverSoft(abs(hq.x) - 0.012, 0.008), coverSoft(abs(hq.y + 0.01) - 0.012, 0.008));
    key *= 1.0 - 0.75 * bars;
    vec2 hs = c * 0.55 + vec2(0.36, 0.40) * P_RI;
    float sec = coverSoft(length(q - hs) - 0.05 * P_RI, 0.012) * 0.7;
    float hl = clamp(key * 0.93 + sec, 0.0, 1.0) * mix(0.35, 1.0, irisMask);
    inner = mix(inner, vec3(1.0), hl);

    // Искра при пробуждении.
    if (uWake > 0.001) {
        vec2 s = q - hk;
        float star = max(exp(-abs(s.y) / 0.012) * max(0.0, 1.0 - abs(s.x) / 0.55),
                         exp(-abs(s.x) / 0.012) * max(0.0, 1.0 - abs(s.y) / 0.55));
        star += exp(-dot(s, s) / 0.004);
        inner += vec3(1.0) * star * uWake;
    }

    // Веки и их кромка.
    float dEdge = min(dTop, dBot);
    vec3 lid = uC6.rgb * (1.0 - 0.10 * exp(-max(-dEdge, 0.0) / 0.3));
    vec3 body = mix(lid, inner, open);
    body = mix(body, uC7.rgb, max(stroke(dTop, 0.8 * w) * 0.85, stroke(dBot, 0.6 * w) * 0.55));

    // Ореол вместо контура: розовый сверху, голубой снизу.
    float dOut = max(dShape, 0.0);
    vec3 haloCol = mix(uC4.rgb, uC2.rgb, smoothstep(-0.5, 0.5, q.y));
    float halo = exp(-dOut / 0.16) * mix(0.42, 0.20, uLight) + exp(-dOut / 0.045) * 0.25;
    // На светлом фоне свечения не видно: там глаз очерчивает мягкая сиреневая тень.
    haloCol = mix(haloCol, uC3.rgb * 0.7, uLight * 0.55);
    halo *= mix(1.0, 1.7, uLight) * (1.0 - inside);

    vec4 col = vec4(haloCol * halo, halo);
    col = over(col, body, inside);
    return col * mix(0.30, 1.0, clamp(uDim, 0.0, 1.0));
}
