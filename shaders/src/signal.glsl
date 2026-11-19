// «Сигнал»: чёрный, белый, серый и один зелёный объект. Плоская графика, без градиентов. Цвета:
//   uC0 линии, uC1 заливка внутри контура, uC2 радужка (единственный цвет), uC3 зрачок,
//   uC4 блик, uC5 засечки, uC6 веко, uC7 точка-индикатор во сне.
const float S_RI = 0.74;

float sgBayer2(vec2 a) { a = floor(a); return fract(a.x * 0.5 + a.y * a.y * 0.75); }
float sgBayer4(vec2 a) { return sgBayer2(0.5 * a) * 0.25 + sgBayer2(a); }

vec4 eye(vec2 q) {
    float dShape, dTop, dBot;
    eyeGeom(q, 1.0, 0.88, 0.0, 0.24, dShape, dTop, dBot);
    float w = px();
    float lw = w * (1.0 + 1.2 * uWake);                 // полуширина линии: 2 пикселя, при пробуждении толще
    float inside = cover(dShape);
    float open = cover(-min(dTop, dBot));

    vec2 c = irisCenter(uGaze, vec2(1.25, 0.16), -0.04);
    vec2 u = irisUV(q, c, S_RI);
    float r = length(u);
    float aw = w / S_RI;

    // Радужка — сплошной диск; тень века на ней — точечный растр, без размытия.
    vec3 ir = uC2.rgb;
    float shade = clamp(1.0 - dTop / 0.36, 0.0, 1.0);
    float cell = sgBayer4(floor((q * uUnit + 0.5 * uSize) / 2.0));
    ir = mix(ir, ir * 0.36, step(cell + 0.04, shade * 0.9));
    vec2 pOff = (uGaze2 - uGaze) * vec2(0.12, 0.08) + uGaze * vec2(0.06, 0.03);
    ir = mix(ir, uC3.rgb, coverSoft(length(u - pOff) - 0.42 * uPupil, aw));
    ir = mix(ir, uC0.rgb, stroke((r - 1.0) * S_RI + w, w) * uLight);   // на бумаге у диска тонкий контур
    vec2 hq = q - (c * 0.8 + vec2(-0.27, -0.29) * S_RI);
    ir = mix(ir, uC4.rgb, cover(max(abs(hq.x), abs(hq.y)) - 0.075));

    vec3 inner = mix(uC1.rgb, ir, coverSoft(r - 1.0, aw));
    // Событие: тонкое кольцо расходится от радужки.
    if (uPulse > 0.0005) {
        float ring = stroke(length(q - c) - S_RI * (1.0 + 0.9 * uPulse), w);
        inner = mix(inner, uC2.rgb, ring * (1.0 - uPulse));
    }

    vec3 body = mix(uC6.rgb, inner, open);
    body = mix(body, uC0.rgb, max(stroke(dTop, lw), stroke(dBot, lw)));
    // Сон: на линии смыкания остаётся точка-индикатор.
    float closed = smoothstep(0.9, 1.0, uLidTop) * smoothstep(0.9, 1.0, uLidBot);
    body = mix(body, uC7.rgb, cover(length(q - vec2(0.0, 0.24)) - 0.04) * closed);

    vec4 col = over(vec4(0.0), body, inside);
    col = over(col, uC0.rgb, stroke(dShape + lw, lw));

    // Засечки по сторонам света.
    vec2 a = abs(q);
    float tick = min(sdSegment(vec2(a.x, q.y), vec2(EYE_W + 0.10, 0.0), vec2(EYE_W + 0.26, 0.0)),
                 min(sdSegment(q, vec2(0.0, -1.14), vec2(0.0, -1.30)), sdSegment(q, vec2(0.0, 1.02), vec2(0.0, 1.18))));
    col = over(col, uC5.rgb, cover(tick - 0.75 * w));
    return col * mix(0.45, 1.0, clamp(uDim, 0.0, 1.0));
}
