// «Росток»: глаз растения. Анатомия та же, что у «Смотрителя», а веки — две половинки стручка: гладкая
// зелёная кожица с толстой тёмно-зелёной обводкой и глянцевым бликом, как в мультфильме. Вместо ресниц —
// кончики листьев за уголками: они поднимаются, когда глаз оживлён, и обвисают, когда он грустит или спит.
// Цвета: uC0 кожица век, uC1 белок, uC2 радужка, uC3 зрачок, uC4 блики, uC5 обводка, uC6 тень на кожице,
//        uC7 свет в радужке.
// uMood: x — тревога (листья торчком, штрихи вокруг), y — усталость (кожица желтеет, листья вянут),
//        z — закрутка лучей радужки, w — влага у нижнего века.
// uFace: x — перекос верхнего века, y — улыбка, z — печаль. uPose: x — листья машут, y — прижимаются, w — глаз навыкате.
const float SP_S = 0.86;                              // глаз чуть меньше рамки: место для листьев
const vec4 SP_GEO = vec4(2.34, 1.08, 0.96, 0.26);
const float SP_RI = 0.95;
const float SP_RIM = 0.19;                            // толщина века вокруг раскрытия
const float SP_OL = 0.055;                            // толщина обводки
const float SP_LEAF = 1.00;                           // длина листа

float spCv(float d) { return cover(d * SP_S); }

vec4 eye(vec2 q) {
    vec2 p = q / SP_S;
    float lt = clamp(uLidTop, 0.0, 1.0), lb = clamp(uLidBot, 0.0, 1.0);
    float alert = clamp(max(uMood.x, uWake), 0.0, 1.0), wilt = clamp(uMood.y, 0.0, 1.0);
    float smile = clamp(uFace.y, 0.0, 1.0), sad = clamp(uFace.z, 0.0, 1.0);
    float W = SP_GEO.x, w = px() / SP_S;
    float dTop, dBot, xs;
    eyLids(p, SP_GEO, lt, lb, dTop, dBot, xs);
    float dOpen = sdLens(p, W, SP_GEO.y, SP_GEO.z);
    float dPod = sdLens(p, W - 0.02, SP_GEO.y + 0.13, SP_GEO.z + 0.01) - SP_RIM;
    float open = spCv(-min(dTop, dBot)) * spCv(dOpen);
    float t = p.x / W, ts = xs / W;
    float taper = max(0.0, 1.0 - t * t), taperS = max(0.0, 1.0 - ts * ts);

    // Листья за уголками. Угол над горизонталью: бодрость и улыбка поднимают, печаль, усталость и сон опускают.
    vec2 pm = vec2(abs(p.x), p.y);
    float asleep = clamp((1.0 - uDim) / 0.35, 0.0, 1.0);
    float side = p.x < 0.0 ? 1.7 : 0.0;
    float ang = 0.20 + 0.62 * alert + 0.26 * smile - 0.70 * sad - 0.50 * wilt - 0.36 * asleep - 0.22 * lt * (1.0 - asleep)
              - 1.05 * clamp(uPose.y, 0.0, 1.0)
              + 0.030 * sin(uTime * 1.3 + side) + clamp(uPose.x, 0.0, 1.0) * 0.38 * sin(uTime * 15.0 + side)
              + (uGaze2.y - uGaze.y) * 0.5;
    vec2 dir = vec2(cos(ang), -sin(ang)), nrm = vec2(sin(ang), cos(ang));
    vec2 lv = pm - vec2(W - 0.20, 0.04);
    lv = vec2(dot(lv, dir), dot(lv, nrm));
    float lt01;
    lv.y += 0.20 * lv.x * lv.x / SP_LEAF;                                // лист слегка выгнут вверх
    float dLeaf = eyDrop(lv, SP_LEAF, 0.25, lt01);

    vec3 skin = mix(uC0.rgb, vec3(0.84, 0.82, 0.30), 0.55 * wilt);
    vec3 skinDark = mix(uC6.rgb, vec3(0.60, 0.58, 0.16), 0.55 * wilt);
    vec3 skinLight = mix(skin, vec3(1.0, 1.0, 0.82), 0.55);
    vec4 col = vec4(0.0);

    // Тень под глазом: тот же силуэт ниже, как у «Смотрителя».
    vec2 ps = p - vec2(0.0, 0.11);
    vec2 lvs = vec2(abs(ps.x), ps.y) - vec2(W - 0.20, 0.04);
    lvs = vec2(dot(lvs, dir), dot(lvs, nrm));
    float ts01;
    lvs.y += 0.20 * lvs.x * lvs.x / SP_LEAF;
    float dSh = min(sdLens(ps, W - 0.02, SP_GEO.y + 0.13, SP_GEO.z + 0.01) - SP_RIM, eyDrop(lvs, SP_LEAF, 0.25, ts01)) - SP_OL;
    col = over(col, uC5.rgb, spCv(dSh) * 0.30);

    // Листья: обводка, заливка в два тона по обе стороны от жилки, сама жилка.
    col = over(col, uC5.rgb, spCv(dLeaf - SP_OL));
    vec3 leaf = mix(mix(skin, skinDark, 0.30), mix(skin, skinDark, 0.85), spCv(-lv.y));       // нижняя половина в тени
    float side2 = abs(lv.y) - (lv.x - 0.30) * 0.55;                                              // боковые жилки под углом к главной
    float veins = spCv(abs(fract(side2 / 0.16 + 0.5) - 0.5) * 0.16 - 0.008) * spCv(0.34 - lv.x) * spCv(lv.x - 0.80) * spCv(dLeaf + 0.05);
    leaf = mix(leaf, skinLight, 0.45 * veins);
    leaf = mix(leaf, skinLight, spCv(abs(lv.y) - 0.016 * (1.0 - lt01)) * spCv(lv.x - 0.88) * spCv(0.24 - lv.x) * 0.90);
    col = over(col, leaf, spCv(dLeaf));

    // Стручок: обводка и кожица. Нижнее веко в тени, по верхнему идёт глянцевый блик.
    col = over(col, uC5.rgb, spCv(dPod - SP_OL));
    float low = spCv(dBot) * smoothstep(-0.06, 0.06, p.y);
    vec3 pod = mix(skin, skinDark, 0.80 * low);
    // Мягкий свет сверху и жёсткий блик-полумесяц.
    pod = mix(pod, skinLight, 0.35 * smoothstep(0.2, -1.2, p.y) * (1.0 - low));
    float hx = abs(p.x) / 1.30;
    float gloss = spCv(abs(dPod + 0.125) - 0.046 * sqrt(max(0.0, 1.0 - hx * hx))) * step(hx, 1.0) * step(p.y, -0.2);
    // Опущенное веко — лист: главная жилка идёт вдоль века, боковые расходятся к кромке.
    float kMid = 0.5 * (mix(-SP_GEO.y, SP_GEO.w, lt) - SP_GEO.y - 0.20);
    float dMid = arcBelow(vec2(xs, p.y), W, kMid);
    float lidShow = smoothstep(0.22, 0.55, lt) * (1.0 - low) * spCv(dTop + 0.04) * spCv(dOpen + 0.02);
    float sv = abs(xs) + dMid * 0.85;
    float lidVeins = max(spCv(abs(dMid) - 0.014 * taperS), spCv(abs(fract(sv / 0.46) - 0.5) * 0.46 - 0.010) * spCv(-dMid) * spCv(abs(xs) - 1.75) * step(0.23, abs(xs)));
    pod = mix(pod, mix(skin, skinDark, 0.55), 0.75 * lidVeins * lidShow);
    pod = mix(pod, vec3(1.0), 0.66 * gloss);
    // Отсвет снизу, чтобы нижнее веко не было плоским.
    pod = mix(pod, mix(skin, skinLight, 0.3), 0.55 * low * spCv(abs(dPod + 0.085) - 0.022) * smoothstep(1.9, 1.2, abs(p.x)));
    col = over(col, pod, spCv(dPod));

    // Белок с тенью от верхнего века: жёсткий край, как в рисованной анимации.
    vec3 white = mix(uC1.rgb, mix(uC1.rgb, uC6.rgb, 0.36), spCv(dTop - 0.17 - 0.05 * taperS));
    col = over(col, white, open);

    // Радужка: солнце внутри. Ободок темнее, снизу светлый серп, от зрачка расходятся короткие лучи.
    vec2 c, u, up;
    float bulge = 1.0 + 0.16 * clamp(uPose.w, 0.0, 1.0);
    eyIris(p, vec2(1.04, 0.28), -0.03, SP_RI * bulge, c, u, up);
    float r = length(u), rq = length(up);
    float irisM = spCv((r - 1.0) * SP_RI) * open;
    float rp = 0.45 * uPupil;
    float a = atan(up.y, up.x) + uMood.z * 0.45 * (1.0 - smoothstep(rp, 1.0, r));
    vec3 rim = mix(uC2.rgb, uC3.rgb, 0.42);
    vec3 iris = mix(uC2.rgb, uC7.rgb, 0.85 * smoothstep(0.05, 0.75, u.y) * smoothstep(0.98, 0.55, r));
    float an = a / TAU * 24.0;
    float ray = abs(fract(an) - 0.5) * 2.0;                               // 0 на оси луча, 1 между лучами
    float m3 = mod(floor(an), 3.0);
    float rayLen = m3 < 0.5 ? 0.80 : (m3 < 1.5 ? 0.62 : 0.70);
    float rayW = 0.50 * (1.0 - smoothstep(rp, rayLen, rq));              // луч сужается к концу
    iris = mix(iris, rim, 0.50 * spCv((ray - rayW) * rq * SP_RI * 0.13) * spCv((rq - rayLen) * SP_RI) * spCv((rp + 0.02 - rq) * SP_RI));
    iris = mix(iris, rim, spCv((0.845 - r) * SP_RI));                    // тёмный ободок
    iris = mix(iris, uC3.rgb, spCv((rq - rp) * SP_RI));                  // зрачок
    iris = mix(iris, mix(uC1.rgb, uC6.rgb, 0.36), 0.42 * spCv(dTop - 0.17 - 0.05 * taperS));   // тень века и на радужке
    col = over(col, iris, irisM);
    col = over(col, uC5.rgb, spCv(abs(r - 1.0) * SP_RI - 0.022) * open);  // обводка радужки
    // Блики почти стоят на месте, пока радужка движется.
    float h1 = spCv(length(p - (c * 0.80 + vec2(-0.30, -0.33) * SP_RI)) - 0.175 * SP_RI);
    float h2 = spCv(length(p - (c * 0.80 + vec2(0.30, 0.33) * SP_RI)) - 0.070 * SP_RI);
    col = over(col, uC4.rgb, max(h1, h2) * irisM);

    // Влага: светлая полоска у нижнего века.
    float wet = clamp(uMood.w * 8.0, 0.0, 1.0);
    if (wet > 0.001) col = over(col, uC4.rgb, spCv(abs(dBot - 0.05) - 0.026 * wet) * open);

    // Кромки век: верхняя толще в середине, как линия ресниц у «Смотрителя».
    float lw = 0.030 + 0.062 * taperS * sqrt(taperS);
    col = over(col, uC5.rgb, spCv(dTop - 0.012) * spCv(-dTop - lw) * spCv(dOpen - lw));
    float lwb = 0.026 + (0.020 + 0.030 * smile) * taper;
    col = over(col, uC5.rgb, spCv(dBot - 0.012) * spCv(-dBot - lwb) * spCv(dOpen - lwb));

    // Штрихи вокруг: коротко при пробуждении и испуге.
    if (alert > 0.001) {
        float sa = atan(p.y * 2.1, p.x) / TAU * 28.0;
        float k = floor(sa);
        float phi = (k + 0.5) / 28.0 * TAU;
        vec2 d2 = normalize(vec2(cos(phi), sin(phi) / 2.1));
        float dAxis = abs(p.x * d2.y - p.y * d2.x);
        float longOne = step(0.5, mod(k, 2.0));
        float d0 = 0.17, d1 = d0 + (0.07 + 0.10 * longOne) * alert;
        col = over(col, uC5.rgb, spCv(dAxis - 0.020) * spCv(d0 - dPod) * spCv(dPod - d1) * step(0.34, abs(d2.y) + 0.0) );
    }
    // Событие: от глаза расходится один контур.
    if (uPulse > 0.0005) {
        col = over(col, uC5.rgb, spCv(abs(dPod - 0.12 - uPulse * 0.26) - 0.016 * (1.0 - uPulse)) * (1.0 - uPulse * uPulse));
    }
    return col * mix(0.6, 1.0, clamp(uDim, 0.0, 1.0));
}
