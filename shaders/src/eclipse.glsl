// «Затмение»: полное солнечное затмение как глаз неба. Зрачок — диск Луны, радужка — корона. Цвета:
//   uC0 корона (жемчужный белый), uC1 золото: Солнце, «бриллиантовое кольцо» и тепло у края диска,
//   uC2 хромосфера и протуберанцы, uC3 небо возле Солнца (индиго), uC4 небо в уголках (почти чёрное),
//   uC5 диск Луны, uC6 холодный оттенок: дальняя корона, звёзды, отсвет по силуэту, uC7 веки (тень).
// Солнце стоит в центре радужки; Луна чуть больше и съезжает по взгляду, открывая серп с обратной стороны.
const float EC_RI = 0.90;      // радиус радужки в единицах глаза
const float EC_R0 = 0.40;      // радиус Солнца в радиусах радужки при uPupil = 1
const float EC_MOON = 1.045;   // во сколько раз Луна больше Солнца
const float EC_TILT = -0.14;   // наклон солнечного экватора, рад

// Расстояние по углу, угол в оборотах.
float ecArc(float a) { return abs(fract(a + 0.5) - 0.5); }

// Длинный стример: ось a0 (обороты), изгиб bend, полуширина у основания wid, длина затухания len (в радиусах Солнца).
// Основание широкое, дальше луч сходится в остриё.
float ecStreamer(float an, float x, float a0, float bend, float wid, float len) {
    float d = ecArc(an - a0 - bend * x / (1.0 + x));
    float w = wid * (0.04 + 0.96 / pow(1.0 + x, 1.6));
    return exp(-d * d / (w * w)) * exp(-x / len);
}

// Протуберанец: язычок над краем Солнца. h — высота над краем в радиусах радужки.
float ecProm(float an, float h, float a0, float wid, float height) {
    float d = ecArc(an - a0 - h * 0.3);
    float k = h / height;
    return exp(-d * d / (wid * wid)) * exp(-k * k);
}

// Неподвижные звёзды: не больше одной на ячейку, яркость разная.
float ecStars(vec2 q, float cell, float seed, float keep) {
    vec2 g = q / cell + vec2(seed, seed * 1.7);
    vec2 id = floor(g);
    float sel = hash21(id + vec2(seed * 3.1, 5.3));
    if (sel < keep) return 0.0;
    float b = (sel - keep) / (1.0 - keep);
    vec2 p = (fract(g) - (0.22 + 0.56 * hash22(id + vec2(1.7, seed)))) * cell;
    float sr = max(0.010, 1.05 * px()) * (0.75 + 0.6 * b);
    float tw = 1.0 + 0.22 * sin(uTime * (1.3 + 2.0 * b) + sel * 40.0);
    float s = exp(-dot(p, p) / (sr * sr));
    // У самых ярких — мягкий ореол.
    s += smoothstep(0.70, 1.0, b) * 0.22 * exp(-length(p) / (2.2 * sr));
    return s * (0.10 + 0.90 * b * b) * tw;
}

vec4 eye(vec2 q) {
    float dShape, dTop, dBot;
    eyeGeom(q, 1.0, 0.88, 0.05, 0.24, dShape, dTop, dBot);
    float w = px();
    float aw = 1.2 * w / EC_RI;
    float pup = clamp(uPupil, 0.6, 1.6);
    float energy = clamp(uEnergy, 0.0, 1.0);
    float wake = clamp(uWake, 0.0, 1.0);

    // Солнце — в центре радужки.
    vec2 c = irisCenter(uGaze, vec2(1.05, 0.30), -0.07);
    vec2 u = irisUV(q, c, EC_RI);
    float r = length(u);
    float rs = EC_R0 * pup, rm = rs * EC_MOON;
    // Луна: сдвиг по запаздывающему взгляду и на долю самого взгляда; при пробуждении диск на миг съезжает.
    vec2 mOff = uGaze2 * vec2(0.036, 0.031) + uGaze * vec2(0.028, 0.024) + wake * vec2(0.046, 0.037);
    float dm = length(u - mOff) - rm;

    // --- Корона ---
    float ang = atan(u.y, u.x + 1e-5) - EC_TILT;   // сдвиг: в самом центре угол не определён
    float an = ang / TAU + 0.5;
    float x = max(r - rs, 0.0) / EC_R0;           // высота над краем Солнца в его радиусах
    float xf = x / (1.0 + x);
    float eq = cos(ang); eq *= eq;                // 1 на экваторе, 0 на полюсах
    // Силовые линии: от полюсов лучи расходятся к экватору.
    float an0 = an + 0.050 * sin(2.0 * ang) * xf;
    float drift = uTime * 0.02;
    float pxa = r * EC_RI * TAU / w;              // пикселей в окружности на этом радиусе
    float env = vnoiseWrap(vec2(an0 * 7.0, 1.3), 7.0);
    float env2 = vnoiseWrap(vec2(an0 * 17.0, 4.1 + x * 0.15), 17.0);
    float n1 = vnoiseWrap(vec2(an0 * 40.0, x * 0.50 + 2.0 - drift), 40.0);
    float n2 = mix(0.5, vnoiseWrap(vec2(an0 * 104.0, x * 0.80 + 7.0 - drift), 104.0), smoothstep(1.5, 3.5, pxa / 104.0));
    float n3 = mix(0.5, vnoiseWrap(vec2(an0 * 250.0, x * 1.20 + 13.0 - drift), 250.0), smoothstep(1.5, 3.5, pxa / 250.0));
    float fine = n2 * 0.62 + n3 * 0.38;
    float fil = n1 * 0.40 + n2 * 0.36 + n3 * 0.24;
    float away = smoothstep(0.02, 0.50, x);
    // У каждого луча своя длина: короткие перья у полюсов, длинные — вдоль экватора.
    float Lr = (0.15 + 0.46 * eq * (0.30 + env) + 0.30 * env * env2) * (0.50 + 1.00 * n1) * (1.0 + 0.25 * energy);
    float lum = 2.6 * exp(-x / 0.060)
              + 0.90 * exp(-x / (0.22 + 0.16 * eq))
              + 0.60 * exp(-x / Lr) * mix(1.0, 0.30 + 1.9 * fine * fine + 0.5 * n1, away)
              + 0.085 * exp(-x / (0.9 + 1.3 * eq * (0.4 + env)));
    // Тонкие нити поверх лучей.
    float nt = vnoiseWrap(vec2(an0 * 58.0, x * 0.30 + 21.0 - drift), 58.0);
    float thr = pow(1.0 - abs(2.0 * nt - 1.0), 5.0) * smoothstep(1.5, 4.0, pxa / 58.0);
    lum += 0.22 * thr * exp(-x / (1.5 * Lr + 0.12)) * away;
    float st = 1.00 * ecStreamer(an, x, 0.988, 0.012, 0.052, 1.60)
             + 0.90 * ecStreamer(an, x, 0.515, -0.010, 0.046, 1.35)
             + 0.60 * ecStreamer(an, x, 0.452, 0.018, 0.028, 0.90)
             + 0.62 * ecStreamer(an, x, 0.066, -0.016, 0.030, 1.00)
             + 0.45 * ecStreamer(an, x, 0.902, 0.014, 0.024, 0.75)
             + 0.36 * ecStreamer(an, x, 0.392, -0.012, 0.020, 0.60)
             + 0.42 * ecStreamer(an, x, 0.612, 0.010, 0.024, 0.80);
    lum += st * 0.80 * mix(1.0, 0.50 + 1.0 * fil, away);
    lum *= 1.0 + 0.7 * energy;
    float tone = 1.0 - exp(-lum);
    vec3 cor = mix(uC6.rgb, uC0.rgb, smoothstep(0.0, 0.26, tone)) * tone;
    cor = mix(cor, uC1.rgb * tone, 0.22 * exp(-x / 0.30));
    cor += vec3(1.0) * smoothstep(0.80, 1.0, tone) * 0.10;

    // --- Небо и звёзды ---
    float sd = length((q - c * 0.35) * vec2(0.50, 1.0));
    vec3 col = mix(uC3.rgb, uC4.rgb, smoothstep(0.10, 1.45, sd));
    float stars = ecStars(q, 0.52, 6.1, 0.62) + 0.45 * ecStars(q, 0.29, 14.9, 0.70);
    col += mix(uC6.rgb, vec3(1.0), 0.55) * stars * pow(1.0 - tone, 6.0);
    col += cor;

    // --- Хромосфера и протуберанцы ---
    float h = max(r - rs, 0.0);
    // Нить хромосферы видна не по всему краю, а дугами.
    float thread = smoothstep(0.30, 0.72, vnoiseWrap(vec2(an * 9.0, 0.7), 9.0));
    float hk = h / (0.024 * pup);
    float chroma = exp(-hk * hk) * (0.20 + 1.5 * thread);
    chroma += 1.00 * ecProm(an, h, 0.305, 0.011, 0.046 * pup)
            + 0.95 * ecProm(an, h, 0.585, 0.014, 0.052 * pup)
            + 0.90 * ecProm(an, h, 0.835, 0.008, 0.042 * pup)
            + 0.80 * ecProm(an, h, 0.075, 0.006, 0.038 * pup);
    float hot = 0.0;
    if (uPulse > 0.0005) {
        // Событие: арка протуберанца на краю лунного диска с той стороны, откуда оно пришло.
        float grow = sin(clamp(uPulse, 0.0, 1.0) * PI);
        vec2 pd = uPulseDir / max(length(uPulseDir), 1e-3);
        vec2 v = u - mOff - pd * rm;
        float n = dot(v, pd), t = dot(v, vec2(-pd.y, pd.x)) + 0.25 * n;      // арка чуть наклонена
        vec2 ax = vec2(0.090, 0.040 + 0.200 * grow);
        vec2 ev = vec2(t, n + 0.02) / ax;
        float el = length(ev);
        float phi = atan(ev.y, ev.x);                  // 0 и PI — основания, PI/2 — вершина
        float mn = min(ax.x, ax.y);
        // Не замкнутое кольцо, а нить: плотная у основания, к другому концу истончается и гаснет.
        float fade = 1.0 - smoothstep(1.5, 2.9, phi);
        float th = mix(0.021, 0.007, smoothstep(0.0, 2.6, phi));
        float knots = 0.60 + 0.70 * vnoise(vec2(phi * 3.2 + 4.0, 1.5));
        float dl = (el - 1.0) * mn;
        float arch = exp(-dl * dl / (th * th)) * knots * fade;
        float dl2 = (el - 0.74 - 0.10 * sin(phi * 2.0)) * mn;
        float arch2 = exp(-dl2 * dl2 / (0.45 * th * th)) * (1.0 - smoothstep(0.9, 2.2, phi)) * 0.55;
        float veil = exp(-abs(dl) / 0.050) * 0.14 * fade;
        // Вспышка хромосферы по краю диска у основания.
        float base = exp(-t * t / 0.020) * exp(-n * n / 0.0009);
        chroma += grow * ((1.4 * arch + arch2 + veil) * smoothstep(-0.02, 0.03, n) + 0.9 * base);
        hot = grow * arch * arch;
    }
    chroma = max(chroma - 0.05, 0.0) / 0.95;
    chroma = clamp(chroma, 0.0, 1.0);
    col = mix(col, uC2.rgb + vec3(0.12) * chroma + vec3(0.30) * min(hot, 1.0), chroma * 0.92);

    // --- Солнце и Луна ---
    float sunMask = coverSoft(r - rs, aw);
    col = mix(col, mix(uC1.rgb, vec3(1.0), 0.80), sunMask);
    float moonMask = coverSoft(dm, aw);
    col = mix(col, uC5.rgb, moonMask);

    // «Бриллиантовое кольцо»: свечение вокруг открытого серпа.
    float off = length(mOff);
    float tC = max(off - (rm - rs), 0.0);         // наибольшая толщина серпа
    if (tC > 0.0) {
        float bAmt = 1.0 - exp(-tC / 0.007);
        vec2 bd = mOff / max(off, 1e-4);
        vec2 pb = -bd * (rs + rm - off) * 0.5;    // середина серпа
        vec2 e = u - pb;
        float db = length(e);
        float dC = max(max(r - rs, -dm), 0.0);    // расстояние до серпа
        float s = 0.050 + 1.1 * tC, sc = 0.034 + 0.35 * tC;
        // Толщина серпа в этом направлении: ореол держится у серпа, а не по всему краю.
        float tl = max(off * dot(u / max(r, 1e-4), -bd) - (rm - rs), 0.0);
        float tight = exp(-dC / (0.014 + 0.16 * tC)) * (1.0 - exp(-tl / 0.006));
        float bloom = exp(-db / 0.8) / (1.0 + db * db / (s * s));
        float core = exp(-db * db / (sc * sc)) * (1.0 - 0.5 * smoothstep(0.012, 0.045, tC));
        vec2 e2 = rot(0.52) * e;
        float sl = 0.05 + 0.20 * wake * bAmt, sw = 0.005 + 0.8 * aw;
        float spike = exp(-abs(e2.y) / sw) * exp(-abs(e2.x) / sl) + exp(-abs(e2.x) / sw) * exp(-abs(e2.y) / sl);
        // На лунный диск свет заходит только у самого края: диск остаётся чёрным.
        float din = min(dm, 0.0);
        float nearM = mix(1.0, 0.55 * exp(din / 0.012), moonMask), wideM = mix(1.0, 0.50 * exp(din / 0.045), moonMask);
        vec3 glow = vec3(1.0) * (tight * 0.85 + core) * nearM
                  + mix(uC1.rgb, uC0.rgb, 0.45) * bloom * (0.80 - 0.25 * smoothstep(0.012, 0.045, tC)) * wideM
                  + uC0.rgb * spike * 0.40 * wake * (1.0 - moonMask);
        col += glow * bAmt * (1.0 + 0.8 * wake);
    }

    // --- Веки: мягкая тень сверху и снизу ---
    float dEdge = min(dTop, dBot);
    float open = smoothstep(-0.015, 0.075, dEdge);
    float shade = 1.0 - 0.50 * exp(-max(dTop, 0.0) / 0.22) - 0.22 * exp(-max(dBot, 0.0) / 0.12);
    vec3 body = mix(uC7.rgb, col * shade, open);
    // Сомкнутые веки: тончайшая светлая дуга по линии смыкания.
    float sdm = max(abs(dTop), abs(dBot));
    float shut = smoothstep(0.55, 1.0, min(uLidTop, uLidBot));
    float along = exp(-pow((q.x - c.x * 0.6) / 1.30, 2.0));
    float seam = (exp(-sdm / (0.9 * w)) * 0.95 + exp(-sdm / 0.035) * 0.16) * along * shut;
    body += mix(uC1.rgb, uC0.rgb, 0.6) * seam;

    // --- Силуэт: мягкий край и едва заметный отсвет ---
    float inside = 1.0 - smoothstep(-0.030, 0.0, dShape);
    float rim = exp(dShape / 0.07) * mix(0.036, 0.055, open);
    body += uC6.rgb * rim;
    // Подмешиваем шум в полшага яркости: тёмные переходы на экране идут без полос.
    body += (hash21(floor(q * uUnit) + vec2(0.5, 7.5)) - 0.5) / 255.0 * min(1.0, body.b * 150.0);
    float dOut = max(dShape, 0.0);
    float halo = exp(-dOut / 0.07) * 0.045 * (1.0 - smoothstep(0.12, 0.28, dOut)) * (1.0 - inside);
    vec4 res = vec4(uC6.rgb * halo, halo);
    res = over(res, clamp(body, 0.0, 1.0), inside);
    return res * mix(0.30, 1.0, clamp(uDim, 0.0, 1.0));
}
