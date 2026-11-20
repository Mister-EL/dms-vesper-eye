// «Сириус»: плоская рисовка, как кадр мультфильма. Глаз — прорезь прямо в небе: вокруг него ничего нет,
// и у закрытого глаза остаётся одна линия с меховыми прядями в уголках. Заливки ровные, тень одна
// и с чётким краем, без градиентов и свечения.
// Цвета: uC0 кость (белок и пряди), uC1 линии век, uC2 розовый радужки, uC3 бирюзовый радужки, uC4 блики,
//        uC5 зрачок, uC6 тень века на белке, uC7 ободок радужки.
// uP0.rgb — золото: кончики прядей, кольцо у зрачка, искры.
// uP1.x — рисунок радужки: 0 — звезда вокруг зрачка, 1 — три полосы перелива.
// uP1.y — пряди: 0 — три пряди в уголках, 1 — без прядей.
// uP1.z — 1: белок тёмный, как окно в глубокий космос, со звёздами. uP1.w — 1: пряди тонкие и цвета линии века.
// uMood: x — тревога (пряди дыбом, лучи вокруг), y — усталость (пряди обвисают), z — поворот звезды,
//        w — влага у нижнего века.
// uPose: x — пряди дрожат, y — пряди прижаты, w — глаз навыкате.
const float SI_S = 0.94;                                    // масштаб: место под пряди
const vec4 SI_GEO = vec4(2.5, 1.0, 0.88, 0.24);             // геометрия «Смотрителя»
const float SI_RI = 0.90;

float siCv(float d) { return cover(d * SI_S); }
float siSt(float d, float hw) { return cover((abs(d) - hw) * SI_S); }

// Четырёхлучевая звёздочка радиуса r: приближённое расстояние до края, меньше нуля внутри.
float siStar(vec2 v, float r) {
    v = abs(v) + 1e-4;
    float f = pow(v.x, 0.55) + pow(v.y, 0.55) - pow(r, 0.55);
    return f / (0.55 * length(vec2(pow(v.x, -0.45), pow(v.y, -0.45))));
}

// Звёздочка с показателем e: чем он больше, тем толще лучи.
float siStarE(vec2 v, float r, float e) {
    v = abs(v) + 1e-4;
    float f = pow(v.x, e) + pow(v.y, e) - pow(r, e);
    return f / (e * length(vec2(pow(v.x, e - 1.0), pow(v.y, e - 1.0))));
}

// Прядь меха: изогнутое веретено от основания (0, 0) вдоль x длиной len — узкое у основания, шире всего
// на четверти длины (полуширина wd), дальше длинное остриё; bend загибает прядь вверх.
// t — доля длины (для кончика другого цвета).
float siSpike(vec2 v, float len, float wd, float bend, out float t) {
    t = clamp(v.x / len, 0.0, 1.0);
    float y = v.y + bend * len * t * t;
    float d = abs(y) - wd * pow(max(sin(PI * pow(t, 0.50)), 0.0), 0.80);
    if (v.x < 0.0) d = length(vec2(v.x, y));
    if (v.x > len) d = length(vec2(v.x - len, y));
    return d;
}

vec4 eye(vec2 q) {
    vec2 p = q / SI_S;
    float lt = clamp(uLidTop, 0.0, 1.0), lb = clamp(uLidBot, 0.0, 1.0);
    float alert = clamp(max(uMood.x, uWake), 0.0, 1.0), tired = clamp(uMood.y, 0.0, 1.0);
    float smile = clamp(uFace.y, 0.0, 1.0), sad = clamp(uFace.z, 0.0, 1.0);
    float asleep = clamp((1.0 - uDim) / 0.35, 0.0, 1.0), light = clamp(uLight, 0.0, 1.0);
    float hide = clamp(uPose.y, 0.0, 1.0);
    float bulge = 1.0 + 0.12 * clamp(uPose.w, 0.0, 1.0);
    vec4 geo = vec4(SI_GEO.x, SI_GEO.y * bulge, SI_GEO.z * bulge, SI_GEO.w);
    float W = geo.x;
    float dTop, dBot, xs;
    eyLids(p, geo, lt, lb, dTop, dBot, xs);
    float dShape = sdLens(p, W, geo.y, geo.z);
    float t = p.x / W, ts = xs / W;
    float taper = max(0.0, 1.0 - t * t), taperS = max(0.0, 1.0 - ts * ts);
    float open = siCv(-min(dTop, dBot)) * siCv(dShape - 0.004);
    vec3 gold = uP0.rgb;
    vec4 col = vec4(0.0);

    // Тень-плашка под глазом: тот же силуэт, сдвинутый вниз, одним ровным тоном.
    float sTop, sBot, sx;
    vec2 ps = p - vec2(0.0, 0.085);
    eyLids(ps, geo, lt, lb, sTop, sBot, sx);
    col = over(col, uC5.rgb * 0.25, siCv(-min(sTop, sBot)) * siCv(sdLens(ps, W, geo.y, geo.z) - 0.004) * (1.0 - open) * mix(0.55, 0.16, light) * (1.0 - smoothstep(0.80, 0.98, lt)));

    // Белок и тень века: одна ступенька с чётким краем, шире к середине.
    float deep = clamp(uP1.z, 0.0, 1.0);
    float shBand = siCv(dTop - (0.07 + 0.13 * taperS));
    col = over(col, mix(mix(uC0.rgb, uC6.rgb, shBand), uC5.rgb * mix(0.62, 0.42, shBand), deep), open);
    if (deep > 0.5) {
        vec2 cell = floor(p * 7.0), f = fract(p * 7.0) - 0.5;
        float rr = mix(0.05, 0.11, hash21(cell + 3.0));
        col = over(col, uC0.rgb, step(0.78, hash21(cell + 11.0)) * cover((length(f - (hash22(cell) - 0.5) * 0.6) - rr) / 7.0 * SI_S) * open);
    }

    // Радужка: плоский диск с тёмным ободком.
    vec2 c, u, up;
    eyIris(p, vec2(1.10, 0.26), -0.05, SI_RI, c, u, up);
    float r = length(u), k = SI_RI * SI_S;
    float irisM = siCv((r - 1.0) * SI_RI) * open;
    float narrow = mix(0.74, 1.0, smoothstep(0.70, 1.25, uPupil)) * mix(1.0, 0.66, light);   // днём зрачок щелью, как у зверя на свету
    float rp = 0.40 * uPupil;
    float rq = length(vec2(up.x / narrow, up.y));
    vec3 ic = uC3.rgb;
    if (uP1.x < 0.5) {
        // Четырёхлучевая звезда вокруг зрачка.
        vec2 sv = rot(uMood.z * 0.45 + 0.10 * uGaze.x) * up;
        float g = 0.86 + 0.14 * clamp(uPupil, 0.5, 1.4);
        float dStar = siStarE(sv, 0.90 * g, 0.64);
        ic = mix(ic, uC2.rgb, cover(dStar * k));
        ic = mix(ic, uC7.rgb, 1.0 - cover((r - 0.90) * k));
    } else {
        // Перелив в три ровные полосы; полосы съезжают, когда глаз поворачивается.
        float ph = dot(u, vec2(0.50, 0.87)) + 0.30 * uGaze.x - 0.16 * uGaze.y + 0.07 * sin(u.x * 4.0 - u.y * 2.0 + 1.0);
        ic = mix(uC2.rgb, uC7.rgb, cover(-(ph + 0.24) * k));
        ic = mix(ic, uC3.rgb, cover(-(ph - 0.22) * k));
        ic = mix(ic, uC5.rgb, 1.0 - cover((r - 0.89) * k));
    }
    ic = mix(ic, gold, cover((rq - rp - 0.055) * k));
    ic = mix(ic, uC5.rgb, cover((rq - rp) * k));
    ic = mix(ic, uC5.rgb, 0.34 * shBand);
    col = over(col, ic, irisM);

    // Блики стоят почти на месте, пока радужка движется.
    vec2 hp = c * 0.80 + vec2(-0.33, -0.34) * SI_RI;
    float h1 = uP1.x < 0.5 ? siCv(length(p - hp) - 0.135 * SI_RI) : cover(siStar(p - hp, 0.27 * SI_RI) * SI_S);
    float h2 = siCv(length(p - (c * 0.80 + vec2(0.27, 0.30) * SI_RI)) - 0.050 * SI_RI);
    col = over(col, uC4.rgb, max(h1, h2) * irisM);

    // Влага: светлая полоска у нижнего века.
    float wet = clamp(uMood.w * 8.0, 0.0, 1.0);
    if (wet > 0.001) col = over(col, uC4.rgb, siSt(dBot - 0.036, 0.022 * wet) * open);

    // Линия верхнего века: толстая в середине, сходит в остриё к уголкам. Нижнее веко — тонкая линия.
    float lw = (0.014 + 0.108 * taperS * sqrt(taperS)) * mix(0.60, 1.0, smoothstep(0.0, 0.2, lt));
    col = over(col, uC1.rgb, siCv(dTop - 0.012) * siCv(-dTop - lw) * siCv(dShape - lw - 0.004));
    col = over(col, uC1.rgb, siSt(dBot, 0.004 + (0.008 + 0.02 * smile) * taper) * siCv(dShape - 2.0 * px() / SI_S));

    // Складка века над глазом; когда глаз распахнут, прижимается к веку, у закрытого сливается с линией.
    float gap = mix(0.15, 0.29, smoothstep(0.0, 0.3, lt)) * (1.0 - lt);
    float dCr = eyTop(vec2(xs, p.y), W, mix(-geo.y, geo.w, lt) - gap, sad * (1.0 - smoothstep(0.45, 0.85, lt)));
    col = over(col, uC7.rgb, siSt(dCr, 0.005 + 0.012 * taperS) * smoothstep(0.98, 0.72, abs(t)) * siCv(dTop + lw + 0.035) * (1.0 - alert) * mix(0.60, 0.40, light));

    // Пряди меха в уголках: по три с каждой стороны, зеркально. Настроение поднимает их и опускает.
    if (uP1.y < 0.5) {
        float side = p.x < 0.0 ? -1.0 : 1.0;
        float lift = 0.50 * alert + 0.22 * smile - 0.55 * sad - 0.45 * tired - 0.40 * asleep - 0.90 * hide
                   + clamp(uPose.x, 0.0, 1.0) * 0.16 * sin(uTime * 14.0 + side);
        float puff = (1.0 + 0.10 * alert) * (1.0 - 0.35 * hide);
        float slim = clamp(uP1.w, 0.0, 1.0);                      // 1 — тонкие пряди цвета линии, 0 — костяные потолще
        vec2 v = vec2(abs(p.x), p.y) - vec2(W - 0.10, 0.0);
        float wd = mix(0.088, 0.070, slim);
        float t1, t2, t3;
        float d1 = siSpike(rot(0.80 + 0.45 * lift) * v, 0.74 * puff, wd, 0.14, t1);
        float d2 = siSpike(rot(0.42 + 0.35 * lift) * v, 0.57 * puff, wd * 0.92, 0.09, t2);
        float d3 = siSpike(rot(0.04 + 0.30 * lift) * v, 0.40 * puff, wd * 0.84, 0.04, t3);
        float tip = d1 < d2 ? (d1 < d3 ? t1 : t3) : (d2 < d3 ? t2 : t3);
        vec3 fur = mix(mix(uC0.rgb, gold, smoothstep(0.56, 0.60, tip)), uC1.rgb, slim);
        col = over(col, fur, siCv(min(d1, min(d2, d3))));
    }

    // Тревога: от глаза расходятся лучи, как у вспыхнувшей звезды, — длинные через один, к концу сходят в остриё.
    float scare = smoothstep(0.15, 0.85, uMood.x);              // лёгкое напряжение лучей не даёт
    if (scare > 0.001) {
        float kk = floor(atan(p.y * 2.3, p.x) / TAU * 28.0);
        float phi = (kk + 0.5) / 28.0 * TAU;
        vec2 dir = normalize(vec2(cos(phi), sin(phi) / 2.3));
        float d0 = 0.17, d1 = d0 + (0.09 + 0.13 * step(0.5, mod(kk, 2.0))) * scare;
        float along = clamp((dShape - d0) / max(d1 - d0, 0.001), 0.0, 1.0);
        col = over(col, gold, siCv(abs(p.x * dir.y - p.y * dir.x) - 0.024 * (1.0 - along)) * siCv(d0 - dShape) * siCv(dShape - d1)
                              * smoothstep(W - 0.05, W - 0.55, abs(p.x)));
    }
    // Пробуждение: вокруг на миг вспыхивают звёздочки.
    if (uWake > 0.001) {
        vec2 a = vec2(abs(p.x), p.y);
        float g = clamp(uWake, 0.0, 1.0);
        col = over(col, gold, cover(min(siStar(a - vec2(1.20, -1.26), 0.16 * g), siStar(a - vec2(1.75, 1.10), 0.12 * g)) * SI_S));
        col = over(col, uC0.rgb, cover(siStar(a - vec2(2.20, -0.96), 0.11 * g) * SI_S));
    }
    // Событие: от глаза расходится один контур.
    if (uPulse > 0.0005) col = over(col, gold, siSt(dShape - 0.06 - uPulse * 0.26, 0.012 * (1.0 - uPulse)) * (1.0 - uPulse * uPulse));
    return col * mix(0.6, 1.0, clamp(uDim, 0.0, 1.0));
}
