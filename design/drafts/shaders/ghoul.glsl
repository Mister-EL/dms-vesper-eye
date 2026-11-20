// «Гуль»: глаз зомби. Анатомия та же, что у «Смотрителя» и «Ростка», но вокруг — лоскут серо-зелёной кожи
// с тяжёлым веком и мешком под глазом; уголки зашиты. Белок желтоватый, в сосудах, радужка маленькая
// и блёклая, зрачок точкой. Рисунок тот же мультяшный: толстая обводка, тени с жёстким краем.
// Цвета: uC0 кожа, uC1 белок, uC2 радужка, uC3 зрачок, uC4 блик и свет луны, uC5 обводка, uC6 тень на коже
//        и мешок под глазом, uC7 сосуды и воспалённая кромка века.
// uMood: x — тревога (штрихи вокруг), y — усталость (сосудов больше), z — закрутка радужки, w — влага.
// uFace: x — перекос верхнего века, y — улыбка, z — печаль. uPose.w — глаз навыкате.
const float GH_S = 0.86;
const vec4 GH_GEO = vec4(2.30, 1.10, 1.00, 0.30);
const float GH_RI = 0.54;
const float GH_OL = 0.055;

float ghCv(float d) { return cover(d * GH_S); }

// Сосуд от уголка к радужке: s — расстояние от уголка, y — высота, len — докуда дорос.
float ghVein(float s, float y, float slope, float amp, float freq, float phase, float len) {
    float line = slope * s + amp * sin(s * freq + phase) * s;
    float hw = 0.021 * min(s / 0.10, 1.0) * (1.0 - s / max(len, 0.001));
    return ghCv(abs(y - line) - hw) * step(0.0, s) * step(s, len) * step(0.02, len);
}

// Лоскут кожи вокруг глаза: линза шире раскрытия, край слегка неровный (одинаково слева и справа).
float ghPatch(vec2 p) {
    float lump = 0.016 * sin(abs(p.x) * 2.6 + 0.7) * sin(p.y * 2.1 + 1.1);
    return sdLens(p, GH_GEO.x + 0.30, GH_GEO.y + 0.10, GH_GEO.z + 0.14) - 0.15 + lump;
}

vec4 eye(vec2 q) {
    vec2 p = q / GH_S;
    float lt = clamp(uLidTop, 0.0, 1.0), lb = max(clamp(uLidBot, 0.0, 1.0), 0.10 * (1.0 - clamp(uPose.w, 0.0, 1.0)));
    float alert = clamp(max(uMood.x, uWake), 0.0, 1.0), fatigue = clamp(uMood.y, 0.0, 1.0);
    float smile = clamp(uFace.y, 0.0, 1.0);
    float W = GH_GEO.x;
    float dTop, dBot, xs;
    eyLids(p, GH_GEO, lt, lb, dTop, dBot, xs);
    float dOpen = sdLens(p, W, GH_GEO.y, GH_GEO.z);
    float dPatch = ghPatch(p);
    float open = ghCv(-min(dTop, dBot)) * ghCv(dOpen);
    float t = p.x / W, ts = xs / W;
    float taper = max(0.0, 1.0 - t * t), taperS = max(0.0, 1.0 - ts * ts);
    vec2 pm = vec2(abs(p.x), p.y);
    vec4 col = vec4(0.0);

    // Тень под глазом и обводка лоскута.
    col = over(col, uC5.rgb, ghCv(ghPatch(p - vec2(0.0, 0.11)) - GH_OL) * 0.34);
    col = over(col, uC5.rgb, ghCv(dPatch - GH_OL));

    // Кожа: сверху холодный свет луны, под глазом тёмный мешок, по коже редкие пятна.
    float low = ghCv(dBot) * smoothstep(-0.06, 0.06, p.y);
    vec3 skin = uC0.rgb;
    float blot = smoothstep(0.58, 0.70, vnoise(vec2(abs(p.x) * 1.7 + 3.0, p.y * 2.3 + 1.0)));
    skin = mix(skin, uC6.rgb, 0.22 * blot);
    skin = mix(skin, uC6.rgb, 0.62 * low);
    // Мешок: два серпа под нижним веком.
    float bag1 = ghCv(abs(dBot + 0.17 + 0.05 * taper) - 0.012 * taper) * ghCv(abs(p.x) - 1.65);
    float bag2 = ghCv(abs(dBot + 0.30 + 0.10 * taper) - 0.010 * taper) * ghCv(abs(p.x) - 1.15);
    skin = mix(skin, uC5.rgb, 0.50 * max(bag1, bag2) * low);
    skin = mix(skin, mix(uC0.rgb, uC4.rgb, 0.35), 0.55 * smoothstep(0.3, -1.3, p.y) * (1.0 - low));
    // Блик луны по верхнему краю.
    float hx = abs(p.x) / 1.35;
    float rimLight = ghCv(abs(dPatch + 0.10) - 0.030 * sqrt(max(0.0, 1.0 - hx * hx))) * step(hx, 1.0) * step(p.y, -0.2);
    skin = mix(skin, uC4.rgb, 0.45 * rimLight);
    // Складка тяжёлого века над кромкой.
    float kCr = mix(-GH_GEO.y, GH_GEO.w, lt) - mix(0.16, 0.30, smoothstep(0.0, 0.3, lt)) * (1.0 - 0.6 * lt);
    float dCr = arcBelow(vec2(xs, p.y), W, kCr);
    float crease = ghCv(abs(dCr) - (0.008 + 0.016 * taperS)) * smoothstep(0.98, 0.70, abs(t)) * ghCv(dTop + 0.05) * ghCv(dOpen + 0.03);
    skin = mix(skin, uC5.rgb, 0.55 * crease);
    col = over(col, skin, ghCv(dPatch));

    // Швы в уголках: разрез от уголка наружу, стянутый тремя стежками.
    float sx = pm.x - W;
    float seam = ghCv(abs(pm.y - 0.012) - 0.018) * step(0.02, sx) * step(sx, 0.40);
    float st = fract((sx - 0.065) / 0.115);
    float stitch = ghCv(abs(st - 0.5) * 0.115 - 0.018) * ghCv(abs(pm.y - 0.012) - 0.095) * step(0.05, sx) * step(sx, 0.40);
    col = over(col, uC5.rgb, max(seam, stitch) * ghCv(dPatch + 0.03));

    // Белок: желтоватый, с тенью от века и сосудами от уголков. Сосуды есть всегда, от усталости их больше.
    float shadeM = ghCv(dTop - 0.16 - 0.05 * taperS);
    vec3 white = mix(uC1.rgb, mix(uC1.rgb, uC6.rgb, 0.50), shadeM);
    float fat = 0.50 + 0.50 * fatigue;
    float s = W - abs(p.x);
    float veins = max(max(ghVein(s, p.y, -0.20, 0.050, 9.0, 0.6, 1.25 * fat), ghVein(s, p.y, -0.06, 0.040, 12.0, 2.1, 0.90 * fat)),
                      max(ghVein(s, p.y, 0.07, 0.045, 10.0, 4.0, 1.10 * fat), ghVein(s, p.y, 0.19, 0.035, 13.0, 1.3, 0.78 * fat)));
    veins = max(veins, ghVein(s - 0.42, p.y - (-0.20 * 0.42 + 0.050 * sin(0.42 * 9.0 + 0.6) * 0.42), -0.52, 0.03, 14.0, 0.0, 0.55 * fat - 0.12));
    veins = max(veins, ghVein(s - 0.50, p.y - (0.07 * 0.50 + 0.045 * sin(0.50 * 10.0 + 4.0) * 0.50), 0.44, 0.03, 15.0, 1.0, 0.50 * fat - 0.12));
    white = mix(white, uC7.rgb, 0.85 * veins);
    col = over(col, white, open);

    // Радужка: маленькая и блёклая, с тёмным ободком и мутным светлым кольцом у зрачка.
    vec2 c, u, up;
    float bulge = 1.0 + 0.30 * clamp(uPose.w, 0.0, 1.0);
    eyIris(p, vec2(1.26, 0.40), 0.02, GH_RI * bulge, c, u, up);
    float r = length(u), rq = length(up);
    float irisM = ghCv((r - 1.0) * GH_RI) * open;
    float rp = 0.30 * uPupil;
    vec3 iris = mix(uC2.rgb, uC1.rgb, 0.55 * smoothstep(0.80, 0.25, rq));
    float a = atan(up.y, up.x) + uMood.z * 0.45 * (1.0 - smoothstep(rp, 1.0, r));
    float an = a / TAU * 14.0;
    iris = mix(iris, mix(uC2.rgb, uC5.rgb, 0.40), 0.40 * ghCv((abs(fract(an) - 0.5) * 2.0 - 0.22) * rq * GH_RI * 0.2) * ghCv((rq - 0.80) * GH_RI) * ghCv((rp + 0.16 - rq) * GH_RI));
    iris = mix(iris, mix(uC2.rgb, uC5.rgb, 0.55), ghCv((0.78 - r) * GH_RI));
    iris = mix(iris, uC3.rgb, ghCv((rq - rp) * GH_RI));
    iris = mix(iris, mix(uC1.rgb, uC6.rgb, 0.50), 0.45 * shadeM);
    col = over(col, iris, irisM);
    col = over(col, uC5.rgb, ghCv(abs(r - 1.0) * GH_RI - 0.024) * open);
    // Один тусклый блик.
    float h1 = ghCv(length(p - (c * 0.82 + vec2(-0.30, -0.34) * GH_RI)) - 0.17 * GH_RI);
    col = over(col, uC4.rgb, h1 * irisM * 0.85);

    // Воспалённая кромка нижнего века и влага.
    col = over(col, uC7.rgb, ghCv(abs(dBot - 0.035) - 0.030) * open * 0.80);
    float wet = clamp(uMood.w * 8.0, 0.0, 1.0);
    if (wet > 0.001) col = over(col, uC4.rgb, ghCv(abs(dBot - 0.085) - 0.022 * wet) * open);

    // Кромки век: верхняя тяжёлая.
    float lw = 0.036 + 0.075 * taperS * sqrt(taperS);
    col = over(col, uC5.rgb, ghCv(dTop - 0.012) * ghCv(-dTop - lw) * ghCv(dOpen - lw));
    float lwb = 0.028 + (0.022 + 0.030 * smile) * taper;
    col = over(col, uC5.rgb, ghCv(dBot - 0.012) * ghCv(-dBot - lwb) * ghCv(dOpen - lwb));

    // Штрихи вокруг: коротко при пробуждении и испуге.
    if (alert > 0.001) {
        float sa = atan(p.y * 2.0, p.x) / TAU * 28.0;
        float k = floor(sa);
        float phi = (k + 0.5) / 28.0 * TAU;
        vec2 d2 = normalize(vec2(cos(phi), sin(phi) / 2.0));
        float dAxis = abs(p.x * d2.y - p.y * d2.x);
        float longOne = step(0.5, mod(k, 2.0));
        float d0 = 0.16, d1 = d0 + (0.07 + 0.10 * longOne) * alert;
        col = over(col, uC4.rgb, ghCv(dAxis - 0.020) * ghCv(d0 - dPatch) * ghCv(dPatch - d1) * step(0.34, abs(d2.y)));
    }
    if (uPulse > 0.0005) {
        col = over(col, uC4.rgb, ghCv(abs(dPatch - 0.12 - uPulse * 0.26) - 0.016 * (1.0 - uPulse)) * (1.0 - uPulse * uPulse));
    }
    return col * mix(0.6, 1.0, clamp(uDim, 0.0, 1.0));
}
