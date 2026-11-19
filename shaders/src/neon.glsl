// «Неон-нуар»: оптический имплант. Тёмное стекло, диафрагма из восьми лепестков, тонкий неон. Цвета:
//   uC0 стекло «белка», uC1 циан (нить контура, кольцо, деления, кромки лепестков, блик),
//   uC2 маджента (внешний контур с разрывами, дуга взгляда, сканер события), uC3 фиолетовый (сетка, отсветы, фаски),
//   uC4 жёлтый (только микродетали), uC5 лазер (точка в зрачке, огонёк сна),
//   uC6 бронепластины век и рамка, uC7 металл объектива и лепестков.
const float NN_RI = 0.74;        // радиус объектива в единицах глаза
const float NN_BEZEL = 0.062;    // ширина рамки между маджентой и циановой нитью
const float NN_D8 = 0.78539816;  // шаг лепестков: 45°

float nnAtan(vec2 v) { return atan(v.y, abs(v.x) < 1e-5 ? 1e-5 : v.x); }
float nnEdge(vec2 p, vec2 a, vec2 b) { vec2 e = b - a; return dot(p - a, normalize(vec2(e.y, -e.x))); }
// 1 внутри отрезка [a, b] по одной координате.
float nnInW(float x, float a, float b, float w) { return smoothstep(a - w, a + w, x) * (1.0 - smoothstep(b - w, b + w, x)); }
float nnIn(float x, float a, float b) { return nnInW(x, a, b, px()); }
float nnBand(float d, float hw) { return cover(abs(d) - hw); }

// Силуэт-визор: вытянутый шестиугольник со срезанными уголками, вписан в линзу eyeGeom.
float nnBody(vec2 q) {
    vec2 a = vec2(abs(q.x), q.y);
    float d = max(-0.89 - q.y, q.y - 0.80);
    d = max(d, nnEdge(a, vec2(0.87, -0.89), vec2(2.27, -0.20)));
    d = max(d, nnEdge(a, vec2(2.27, -0.20), vec2(2.03, 0.32)));
    d = max(d, nnEdge(a, vec2(2.03, 0.32), vec2(0.80, 0.80)));
    return d;
}

// Разрывы внешнего контура: 1 там, где линия есть.
float nnSegs(vec2 q, float sw) {
    float x = abs(q.x);
    float gap = q.y < 0.06
        ? max(nnInW(x, 0.50, 0.58, sw), max(nnInW(x, 0.66, 0.74, sw), nnInW(x, 1.52, 1.66, sw)))
        : max(nnInW(x, 0.22, 0.34, sw), max(nnInW(x, 1.08, 1.16, sw), nnInW(x, 1.24, 1.32, sw)));
    return 1.0 - gap;
}

// Гексагональная сетка: расстояние до ребра ячейки (ширина ячейки 1), id — центр ячейки.
float nnHex(vec2 p, out vec2 id) {
    vec2 r = vec2(1.0, 1.7320508), h = r * 0.5;
    vec2 a = mod(p, r) - h, b = mod(p - h, r) - h;
    vec2 g = dot(a, a) < dot(b, b) ? a : b;
    id = p - g;
    g = abs(g);
    return 0.5 - max(g.x, dot(g, vec2(0.5, 0.8660254)));
}

vec4 nnScene(vec2 q) {
    float dShape, dTop, dBot;
    eyeGeom(q, 1.0, 0.88, 0.0, 0.24, dShape, dTop, dBot);
    float w = px();
    float lw = max(0.75 * w, 0.0055);                   // полуширина неоновой нити
    float dB = max(nnBody(q), dShape);
    float inside = cover(dB);
    float dWin = dB + NN_BEZEL;                         // окно стекла внутри рамки
    float win = cover(dWin);
    float open = cover(-min(dTop, dBot));
    float lt = clamp(uLidTop, 0.0, 1.0), lb = clamp(uLidBot, 0.0, 1.0);
    float closed = smoothstep(0.85, 1.0, lt) * smoothstep(0.85, 1.0, lb);
    float en = clamp(uEnergy, 0.0, 1.0);

    vec3 cy = uC1.rgb, mg = uC2.rgb, vi = uC3.rgb, ye = uC4.rgb, lz = uC5.rgb;

    // ── Объектив: положение и слои на разной глубине ────────────────────────────────────────────
    vec2 c = irisCenter(uGaze, vec2(1.12, 0.22), -0.045);
    vec2 u = irisUV(q, c, NN_RI);
    float r = length(u);
    float aw = w / NN_RI;
    // Сдвиг глубоких слоёв: ствол объектива виден под углом, дальние детали отстают.
    vec2 par = -uGaze * vec2(1.0, 0.8) + (uGaze2 - uGaze) * vec2(1.4, 1.0);
    par *= min(1.0, 1.25 / max(length(par), 1e-4));

    // ── Стекло ─────────────────────────────────────────────────────────────────────────────────
    vec3 glass = uC0.rgb * (0.62 + 0.55 * smoothstep(0.9, -0.9, q.y));
    float sb = q.x + q.y * 1.5;                                                       // косые отсветы на стекле
    glass += vi * (0.040 * (1.0 - smoothstep(0.0, 0.42, abs(sb + 1.15))) + 0.026 * (1.0 - smoothstep(0.0, 0.10, abs(sb + 0.52))));
    float cell = 0.092;
    vec2 hid;
    float hd = nnHex(q / cell + vec2(0.5, 0.0), hid) * cell;
    float gridVis = smoothstep(4.5, 9.0, cell * uUnit);
    float away = smoothstep(1.0, 1.7, r);                                             // у объектива сетка гаснет
    glass += vi * (cover(hd - 0.45 * w) * 0.085 + step(0.94, hash21(hid)) * 0.035) * gridVis * (0.35 + 0.65 * away);
    glass *= 1.0 - 0.55 * exp(-max(r - 1.0, 0.0) / 0.10);                             // тень корпуса на стекле
    glass += vi * 0.055 * exp(-max(r - 1.0, 0.0) / 0.32) * step(1.0, r);              // отсвет вокруг объектива
    glass += cy * 0.10 * exp(dWin / 0.035);                                           // свет нити на краю стекла

    // Микродетали в уголках стекла.
    {
        float tw = max(0.6 * w, 0.0042);
        // слева: шкала
        float sx = q.x + 1.98;
        float sIn = nnIn(q.x, -1.98 - tw, -1.62 + tw);
        float base = nnBand(q.y - 0.03, tw) * sIn;
        float mx = mod(sx + 0.03, 0.06) - 0.03;
        float m3 = mod(sx + 0.09, 0.18) - 0.09;
        float tk = cover(abs(mx) - tw) * nnIn(q.y, 0.03, 0.062) * sIn;
        float tk3 = cover(abs(m3) - tw) * nnIn(q.y, 0.03, 0.085) * sIn;
        glass = mix(glass, cy, max(base, max(tk, tk3)) * 0.42);
        glass = mix(glass, ye, cover(max(abs(q.x + 1.71), abs(q.y + 0.045)) - 0.016) * 0.9);
        // справа: метка-штрихкод и уголок
        float by = nnIn(q.y, -0.04, 0.04);
        float bars = max(nnIn(q.x, 1.640, 1.652), max(nnIn(q.x, 1.676, 1.712), max(nnIn(q.x, 1.736, 1.748), nnIn(q.x, 1.766, 1.778)))) * by;
        glass = mix(glass, ye, bars * 0.85);
        float br = max(nnBand(q.x - 1.90, tw) * nnIn(q.y, -0.07, 0.07), max(nnBand(q.y + 0.07, tw), nnBand(q.y - 0.07, tw)) * nnIn(q.x, 1.84, 1.90));
        glass = mix(glass, cy, br * 0.42);
    }

    // ── Корпус объектива (передняя оправа) ───────────────────────────────────────────────────────
    float A = nnAtan(u);
    float deg = A * 57.29578;
    vec2 ud = u / max(r, 1e-4);
    vec2 L = normalize(vec2(-0.55, -0.83) - uGaze * 0.8);                             // свет: отблеск уходит от взгляда
    float face = dot(ud, L);
    vec3 lens = uC7.rgb * (0.30 + 0.16 * face) * (0.75 + 0.5 * smoothstep(1.0, 0.80, r));
    lens = mix(lens, vi * 0.55, nnBand((r - 0.992) * NN_RI, 0.6 * lw));               // фаска по краю корпуса

    // Кольцо делений: короткие каждые 5°, длинные каждые 30°, жёлтые по сторонам света.
    {
        float tw = max(0.55 * w, 0.0038);
        float arcLen = r * NN_RI * 0.0174533;
        float a5 = mod(deg + 2.5, 5.0) - 2.5;
        float a30 = mod(deg + 15.0, 30.0) - 15.0;
        float a90 = mod(deg + 45.0, 90.0) - 45.0;
        float sVis = smoothstep(2.4, 4.5, 5.0 * arcLen * uUnit);
        float tS = cover(abs(a5) * arcLen - tw) * nnBand((r - 0.905) * NN_RI, 0.020 * NN_RI) * sVis;
        float tL = cover(abs(a30) * arcLen - 1.25 * tw) * nnBand((r - 0.888) * NN_RI, 0.037 * NN_RI);
        float card = step(abs(a90), 2.0);
        // Музыка: деления загораются от нижней точки вверх по обе стороны.
        float fromBottom = abs(mod(deg - 90.0 + 180.0, 360.0) - 180.0);
        float vu = smoothstep(0.0, 0.06, en) * (1.0 - smoothstep(en * 170.0 - 3.0, en * 170.0 + 3.0, fromBottom));
        vec3 tcol = mix(cy, mg, vu);
        lens = mix(lens, tcol * mix(0.50, 1.0, vu), tS * 0.9);
        lens = mix(lens, mix(tcol, ye, card * (1.0 - vu)), tL);
    }

    // Сегментная дуга мадженты: собирается в сторону взгляда, по центру — полное кольцо.
    {
        float phase = uGaze.x * 42.0 - uGaze.y * 24.0;
        float sd = deg - phase;
        float si = floor(sd / 15.0);
        float sl = abs(sd - (si + 0.5) * 15.0);
        float sc = ((si + 0.5) * 15.0 + phase) * 0.0174533;
        float gl = length(uGaze);
        vec2 gd = uGaze / max(gl, 1e-4);
        float cosW = mix(-1.4, 0.50, smoothstep(0.04, 0.42, gl));
        float lit = smoothstep(cosW - 0.14, cosW + 0.14, dot(vec2(cos(sc), sin(sc)), gd));
        float seg = cover((sl - 5.9) * r * NN_RI * 0.0174533) * nnBand((r - 0.962) * NN_RI, max(0.011 * NN_RI, 0.8 * w));
        float halo = exp(-abs(r - 0.962) * NN_RI / 0.028) * (1.0 - smoothstep(5.0, 7.5, sl)) * 0.22;
        lens = mix(lens, mg, seg * mix(0.26, 1.0, lit));
        lens += mg * halo * lit * (0.8 + 0.6 * en);
    }

    // Ствол: стенка между оправой и диафрагмой.
    vec2 u1 = u - par * 0.025;
    float r1 = length(u1);
    vec3 wall = uC7.rgb * (0.10 + 0.34 * smoothstep(-1.0, 1.0, -dot(u1 / max(r1, 1e-4), L)));
    wall += cy * 0.10 * smoothstep(0.70, 0.80, r1);                                   // отсвет кольца на стенке
    lens = mix(lens, wall, coverSoft((r1 - 0.765) * NN_RI, w));

    // Сплошное циановое кольцо.
    {
        float dr = (r - 0.795) * NN_RI;
        lens = mix(lens, cy, nnBand(dr, lw));
        lens += cy * exp(-abs(dr) / 0.022) * (0.20 + 0.30 * en);
    }

    // ── Диафрагма ────────────────────────────────────────────────────────────────────────────────
    vec2 p = u - par * 0.062;
    float rp = length(p);
    float ap = 0.365 * uPupil * (1.0 + 0.07 * en);                                    // апофема отверстия
    float phi = 0.30 + 1.55 * (uPupil - 1.0) + 0.30 * uGaze.x;                        // поворот лепестков
    float th = nnAtan(p);
    float beta = acos(clamp(ap / max(rp, 1e-4), 0.0, 1.0));
    float kb = floor((th + beta - phi) / NN_D8);                                      // верхний лепесток в точке
    float thk = phi + kb * NN_D8;
    vec2 n1 = vec2(cos(thk), sin(thk));
    vec2 n2 = vec2(cos(thk + NN_D8), sin(thk + NN_D8));
    float s1 = dot(p, n1) - ap;                                                       // от своей кромки вглубь лепестка
    float s2 = ap - dot(p, n2);                                                       // до кромки лепестка, лежащего сверху
    float tl = dot(p, vec2(-n1.y, n1.x));
    float e = min(abs(s1), s2);

    float bl = dot(n1, L);
    vec3 blade = uC7.rgb * (0.50 + 0.50 * smoothstep(-0.5, 1.0, bl));
    blade *= mix(1.30, 0.72, smoothstep(0.0, 0.30, s1));
    blade *= 0.86 + 0.28 * smoothstep(-0.5, 0.5, tl);
    blade *= 1.0 + (vnoise(vec2(s1 * 85.0, kb * 3.1 + 5.0)) - 0.5) * 0.22 * smoothstep(60.0, 130.0, uUnit);   // шлифовка вдоль кромки
    blade += vi * 0.16 * pow(max(bl, 0.0), 3.0) * exp(-s1 / 0.16);
    blade = mix(blade, blade * 1.5 + vi * 0.05, nnBand((s1 - 0.045) * NN_RI, 0.5 * lw) * 0.7);          // фаска вдоль кромки
    blade *= 1.0 - 0.72 * exp(-s2 / 0.050);                                           // тень верхнего лепестка
    blade += lz * 0.16 * exp(-max(rp - ap, 0.0) / 0.07);                              // отсвет лазера на кромках
    blade *= 0.55 + 0.45 * smoothstep(0.71, 0.56, rp);                                // к стенке темнее

    // Зрачок: чернота, едва заметный отсвет линзы и точка лазера.
    vec2 p3 = u - par * 0.105;
    float d3 = length(p3) * NN_RI;
    float dotR = max(0.026, 1.3 * w) * (1.0 + 0.5 * en);
    vec3 hole = vi * 0.035 * smoothstep(0.9, 0.2, length(p - vec2(-0.10, -0.12)) / ap) * smoothstep(0.0, 0.05, -s1);
    hole = mix(hole, vi * 0.30, nnBand(d3 - 0.56 * ap * NN_RI, 0.5 * lw) * 0.8);                     // кольцо линзы в глубине
    hole += lz * (exp(-d3 / (0.035 + 0.03 * en)) * 0.55 + exp(-d3 / 0.12) * 0.10);
    hole = mix(hole, mix(lz, vec3(1.0), 0.35), cover(d3 - dotR));
    hole = mix(hole, vec3(1.0, 0.92, 0.92), cover(d3 - dotR * 0.38));

    vec3 dia = mix(hole, blade, coverSoft(-s1 * NN_RI, w));
    float eline = cover(e * NN_RI - 0.8 * lw);
    vec3 ecol = mix(cy, vi, smoothstep(ap, 0.66, rp) * 0.75) * mix(1.0, 0.55, smoothstep(ap, 0.70, rp));
    dia = mix(dia, ecol, eline * 0.92);
    dia += cy * exp(-e * NN_RI / 0.012) * 0.10 * (1.0 - smoothstep(ap, 0.6, rp));
    lens = mix(lens, dia, coverSoft((rp - 0.705) * NN_RI, w));
    lens = mix(lens, uC7.rgb * 0.9, nnBand((rp - 0.705) * NN_RI, 0.55 * lw) * 0.8);   // обод диафрагмы

    // Выпуклое стекло поверх объектива: мягкий серп сверху.
    float dome = smoothstep(0.2, 1.0, face) * smoothstep(1.0, 0.55, r) * smoothstep(0.30, 0.62, r);
    lens += vi * 0.060 * dome;

    vec3 inner = mix(glass, lens, coverSoft((r - 1.0) * NN_RI, w));

    // ── Событие: дуга-сканер сходится к зрачку со стороны uPulseDir ──────────────────────────────
    if (uPulse > 0.0005) {
        float pu = clamp(uPulse, 0.0, 1.0);
        vec2 v = q - c;
        float rv = length(v);
        float R = mix(2.05, 0.16, pu);
        float pl = length(uPulseDir);
        float ca = pl > 0.01 ? dot(v / max(rv, 1e-4), uPulseDir / pl) : 1.0;
        float thr = mix(0.70, -1.3, smoothstep(0.55, 0.95, pu));                      // у зрачка дуга смыкается в кольцо
        float span = smoothstep(thr - 0.10, thr + 0.02, ca);
        float fade = smoothstep(0.0, 0.10, pu) * (1.0 - smoothstep(0.86, 1.0, pu));
        float pa = nnAtan(v) * 57.29578;
        float dash = step(0.35, fract(pa / 6.0));
        float a1 = nnBand(rv - R, 1.3 * lw) + exp(-abs(rv - R) / 0.035) * 0.30;
        float a2 = nnBand(rv - R - 0.085, 0.8 * lw) * 0.75;
        float a3 = nnBand(rv - R - 0.150, 0.8 * lw) * dash * 0.55;
        float trail = exp(-max(rv - R, 0.0) / 0.30) * step(R, rv) * 0.10;
        inner += (mg * (a1 + trail) + cy * (a2 + a3)) * span * fade;
    }

    // Тень века на содержимом.
    inner *= 1.0 - 0.55 * exp(-max(dTop, 0.0) / 0.10) - 0.25 * exp(-max(dBot, 0.0) / 0.06);

    // ── Блик: анаморфная полоска, почти неподвижная ─────────────────────────────────────────────
    {
        vec2 hq = q - (c * 0.55 + vec2(-0.24, -0.29));
        float fall = max(0.0, 1.0 - abs(hq.x) / 0.62);
        float streak = exp(-abs(hq.y) / max(0.008, 1.1 * w)) * fall * fall;
        float core = exp(-(hq.x * hq.x / 0.010 + hq.y * hq.y / 0.00035));
        float soft = exp(-abs(hq.y) / 0.05) * fall * fall * 0.10;
        inner += cy * (streak * 0.85 + soft) + vec3(1.0) * core * 0.9;
        vec2 h2 = q - (c * 0.55 + vec2(0.30, 0.31));
        float f2 = max(0.0, 1.0 - abs(h2.x) / 0.20);
        inner += mg * exp(-abs(h2.y) / max(0.006, 0.9 * w)) * f2 * f2 * 0.50;
    }

    // ── Веки: бронепластины ─────────────────────────────────────────────────────────────────────
    float isTop = step(dTop, 0.0);
    float dl = mix(dBot, dTop, isTop);                  // меньше нуля внутри пластины
    float ed = max(-dl, 0.0);
    vec3 plate = uC6.rgb * (0.80 + 0.55 * smoothstep(0.7, -0.9, q.y));
    plate *= 1.0 + 0.9 * (1.0 - smoothstep(0.070, 0.085, ed));                        // фаска у кромки
    plate = mix(plate, vi * 0.40, nnBand(ed - 0.085, 0.6 * lw) * 0.8);                // внутренняя линия
    float sx1 = abs(q.x) + 0.30 * q.y;
    float seam = max(nnBand(sx1 - 0.92, 0.7 * lw), nnBand(sx1 - 1.72, 0.7 * lw)) * step(0.085, ed);
    plate = mix(plate, vi * 0.26, seam * 0.9);
    float vent = max(nnBand(ed - 0.20, lw), max(nnBand(ed - 0.25, lw), nnBand(ed - 0.30, lw))) * nnIn(abs(q.x), -1.0, 0.20) * isTop;
    plate = mix(plate, vi * 0.36, vent);
    float label = max(nnIn(q.x, -1.36, -1.24), nnIn(q.x, -1.20, -1.17)) * nnBand(ed - 0.042, 0.014) * isTop;
    plate = mix(plate, ye, label * mix(0.9, 0.22, closed));
    plate += cy * exp(-ed / 0.030) * 0.16 * (1.0 - 0.7 * closed);

    vec3 body = mix(plate, inner, open);
    float lidLine = max(stroke(dTop, lw), stroke(dBot, lw));
    body = mix(body, cy * mix(1.0, 0.42, closed), lidLine);
    // Сон: один слабый огонёк на стыке.
    {
        float dd = length(q - vec2(0.0, 0.24));
        body = mix(body, lz, cover(dd - max(0.026, 1.4 * w)) * closed);
        body += lz * exp(-dd / 0.06) * 0.35 * closed;
    }

    // ── Пробуждение: строка развёртки ───────────────────────────────────────────────────────────
    if (uWake > 0.001) {
        float wk = clamp(uWake, 0.0, 1.0);
        float ys = mix(-0.95, 0.86, 1.0 - wk);
        float env = smoothstep(0.0, 0.15, wk);
        float below = smoothstep(-0.01, 0.03, q.y - ys);
        body *= mix(1.0, 0.50, below * env);                                          // ниже строки картинка ещё не «проявлена»
        float row = 0.5 + 0.5 * step(0.5, fract(q.y * uUnit / 3.0));
        body += cy * exp(-max(ys - q.y, 0.0) / 0.22) * (1.0 - below) * 0.16 * row * env;
        body += mix(cy, vec3(1.0), 0.55) * exp(-abs(q.y - ys) / max(0.007, 1.1 * w)) * env;
        body += cy * exp(-abs(q.y - ys) / 0.05) * 0.22 * env;
    }

    // ── Рамка и двойной контур ──────────────────────────────────────────────────────────────────
    float segs = nnSegs(q, w);
    float quiet = mix(1.0, 0.45, closed);
    vec3 frame = uC6.rgb * (1.25 + 0.5 * smoothstep(0.7, -0.9, q.y));
    frame += mg * exp(dB / 0.030) * 0.16 * segs * quiet;
    frame += cy * exp(-max(dWin, 0.0) / 0.022) * 0.14 * quiet;
    frame = mix(frame, ye, nnIn(abs(q.x), -1.0, 0.045) * nnIn(dB, -0.050, -0.024) * step(q.y, 0.0) * mix(0.9, 0.25, closed));   // риска сверху
    body = mix(frame, body, win);
    body = mix(body, cy * quiet, stroke(dWin, 0.62 * lw));
    body = mix(body, mg * quiet, stroke(dB + 1.15 * lw, 1.15 * lw) * segs);

    // ── Свечение снаружи: только от сегментов мадженты, гаснет до нуля у края холста ─────────────
    float dOut = max(dB, 0.0);
    float glow = (exp(-dOut / 0.040) * 0.30 + exp(-dOut / 0.13) * 0.08) * (0.45 + 0.55 * nnSegs(q, 0.03 + 0.9 * dOut));
    glow *= (1.0 - smoothstep(0.10, 0.30, dOut)) * (1.0 - inside) * quiet * (1.0 + 0.5 * en);

    vec4 col = vec4(mg * glow, glow);
    col = over(col, body, inside);
    return col;
}

vec4 eye(vec2 q) {
    // «Сбой картинки», пока веки в движении: срыв строк и расслоение красного и синего.
    float lt = clamp(uLidTop, 0.0, 1.0), lb = clamp(uLidBot, 0.0, 1.0);
    // Сбой привязан к нижнему веку: оно движется только при моргании и засыпании,
    // а в дремоте стоит на месте, поэтому застывшего «сбоя» у дремлющего глаза нет.
    float g = smoothstep(0.12, 0.34, lb) * (1.0 - smoothstep(0.66, 0.90, lb));
    vec4 col;
    if (g > 0.003) {
        float band = floor((q.y + 1.5) * 11.0) + floor(lt * 7.0) * 5.3 + floor(lb * 5.0) * 2.9;
        float tear = step(0.72, hash11(band)) * (hash11(band + 7.3) - 0.5) * 0.11 * g;
        vec2 qq = q + vec2(tear, 0.0);
        float dx = max(2.0 * px(), 0.013) * g;
        vec4 cg = nnScene(qq);
        vec4 cr = nnScene(qq + vec2(dx, 0.0));
        vec4 cb = nnScene(qq - vec2(dx, 0.0));
        col = vec4(cr.r, cg.g, cb.b, max(cg.a, max(cr.a, cb.a)));
    } else {
        col = nnScene(q);
    }
    return col * mix(0.35, 1.0, clamp(uDim, 0.0, 1.0));
}
