// «Плакат»: трафаретная печать в три краски. Плоские пятна, растр вместо теней, гравировка вместо
// градиентов. Там, где краски нет, видна бумага, то есть обои.
// Цвета: uC0 бумага (для справки, сама не печатается), uC1 белок, uC2 радужка, uC3 зрачок, uC4 блики,
//        uC5 линии век и штрихи тревоги, uC6 теневая краска, uC7 гравировка радужки.
// uP1.x = 1 — тень века ложится растром и на радужку (для светлой радужки).
// uP1.y = 1 — растр тени и сосуды печатаются теневой краской uC6, а не оставляются пробелами в белке:
//            для светлого листа, где пробел был бы почти не виден.
// uMood: x — тревога (лучи вокруг глаза), y — усталость (сосуды в уголках),
//        z — закрутка гравировки от −1 до 1, пока зрачок меняет размер,
//        w — влага от 0 до 1: светлая полоска воды у нижнего века, когда глаз слезится от смеха или зевка.
// uFace: x — перекос верхнего века от −1 до 1 (вершина дуги уходит вбок), y — улыбка: нижнее веко выгибается вверх,
//        z — печаль: верхнее веко складывается «домиком» — середина приподнята, края провисают.
const float PO_RI = 0.86;
const float PO_RAYS = 96.0;

// Точка растра: 1 внутри точки. Чем гуще тень, тем крупнее точки; сетка повёрнута, как в печати.
float poDots(vec2 q, float density) {
    const float cell = 0.050;
    vec2 f = fract(rot(0.52) * q / cell) - 0.5;
    float r = 0.56 * sqrt(clamp(density, 0.0, 1.0));
    float e = 0.6 * px() / cell;
    return 1.0 - smoothstep(r - e, r + e, length(f));
}

// Высота «домика» над точкой x: вершина в (0, k), скаты провисают к уголкам.
float poTentY(float x, float k) {
    const float a = 0.50;                                     // скругление вершины
    float s = (sqrt(x * x + a * a) - a) / (sqrt(EYE_W * EYE_W + a * a) - a);
    return k * (1.0 - pow(clamp(s, 0.0, 1.0), 0.72));
}

// Кромка верхнего века: дуга через уголки с вершиной в (0, k). Печаль превращает дугу в «домик».
// Возвращает расстояние со знаком: больше нуля ниже кромки.
float poTop(vec2 p, float k, float sad) {
    float d = arcBelow(p, EYE_W, k);
    if (sad < 0.001 || k > -0.05) return d;
    float kt = k - 0.12;                                      // вершина домика чуть выше дуги
    float y = poTentY(p.x, kt);
    float dy = (poTentY(p.x + 0.02, kt) - poTentY(p.x - 0.02, kt)) / 0.04;
    return mix(d, (p.y - y) / sqrt(1.0 + dy * dy), sad);
}

// Кромки век с мимикой. dTop > 0 ниже верхнего века, dBot > 0 выше нижнего; xs — координата вдоль
// верхнего века с учётом перекоса (нужна, чтобы толстая часть линии ресниц шла за вершиной дуги).
void poLids(vec2 q, out float dTop, out float dBot, out float xs) {
    float lt = clamp(uLidTop, 0.0, 1.0), lb = clamp(uLidBot, 0.0, 1.0);
    float t = q.x / EYE_W;
    xs = q.x - clamp(uFace.x, -1.0, 1.0) * 0.9 * max(0.0, 1.0 - t * t);
    // Пока веко закрывается (моргание), домик расправляется обратно в дугу.
    dTop = poTop(vec2(xs, q.y), mix(-1.0, 0.24, lt), clamp(uFace.z, 0.0, 1.0) * (1.0 - smoothstep(0.45, 0.85, lt)));
    dBot = -arcBelow(q, EYE_W, mix(0.88, 0.24, lb) - clamp(uFace.y, 0.0, 1.0) * 1.1 * (1.0 - lb));
}

// Сосуд: извилистая линия от уголка глаза к радужке. s — расстояние от уголка (или от развилки),
// y — высота точки, len — докуда он дорос. Тонкий в начале и к концу сходит на нет.
float poVein(float s, float y, float slope, float amp, float freq, float phase, float len) {
    float line = slope * s + amp * sin(s * freq + phase) * s;
    float hw = 0.0095 * min(s / 0.10, 1.0) * (1.0 - s / max(len, 0.001));
    return cover(abs(y - line) - hw) * step(0.0, s) * step(s, len) * step(0.02, len);
}

vec4 eye(vec2 q) {
    float dShape, dTop, dBot, xs;
    eyeGeom(q, 1.0, 0.88, 0.0, 0.24, dShape, dTop, dBot);
    poLids(q, dTop, dBot, xs);
    float w = px();
    float t = q.x / EYE_W, ts = xs / EYE_W;
    float taper = max(0.0, 1.0 - t * t), taperS = max(0.0, 1.0 - ts * ts);
    float lt = clamp(uLidTop, 0.0, 1.0);
    float alert = clamp(uMood.x, 0.0, 1.0), fatigue = clamp(uMood.y, 0.0, 1.0);

    // Фактура печати: край краски чуть неровный, сама краска лежит с мелкой «солью».
    float rough = (vnoise(q * 46.0) - 0.5) * 0.007;
    float salt = smoothstep(0.90, 1.0, hash21(floor(q * uUnit * 0.75) + 3.0));
    float ink = (1.0 - 0.5 * salt) * (0.955 + 0.045 * vnoise(q * 7.0));
    float inkDark = 1.0 - 0.22 * salt;        // на тёмной краске соль почти не видна
    // Раскрытие между веками. Дуги век — окружности, за уголками их обрезает силуэт.
    float open = cover(-min(dTop, dBot) + rough) * cover(dShape - 0.004);
    vec4 col = vec4(0.0);

    // Тень-плашка: тот же силуэт, сдвинутый вниз, как вторая краска в печати.
    float sShape, sTop, sBot, sx;
    eyeGeom(q - vec2(0.0, 0.085), 1.0, 0.88, 0.0, 0.24, sShape, sTop, sBot);
    poLids(q - vec2(0.0, 0.085), sTop, sBot, sx);
    col = over(col, uC6.rgb, cover(-min(sTop, sBot) + 1.5 * w) * cover(sShape - 0.004) * (1.0 - open) * ink);

    // Белок. Тень под верхним веком — растр: в точках краски нет, видна бумага.
    float shade = clamp(1.0 - dTop / 0.44, 0.0, 1.0);
    shade = shade * shade * 0.86;
    float dots = poDots(q, shade);
    // Усталость: от уголков к радужке растут сосуды. Это тоже «нет краски»: линии бумаги на белке.
    float veins = 0.0;
    if (fatigue > 0.01) {
        float s = EYE_W - abs(q.x);
        veins = max(max(poVein(s, q.y, -0.21, 0.050, 9.0, 0.6, 1.30 * fatigue), poVein(s, q.y, -0.07, 0.040, 12.0, 2.1, 0.95 * fatigue)),
                    max(poVein(s, q.y, 0.06, 0.045, 10.0, 4.0, 1.18 * fatigue), poVein(s, q.y, 0.18, 0.035, 13.0, 1.3, 0.80 * fatigue)));
        // Развилки на двух длинных сосудах: появляются, когда сосуд до них дорос.
        veins = max(veins, poVein(s - 0.42, q.y - (-0.21 * 0.42 + 0.050 * sin(0.42 * 9.0 + 0.6) * 0.42), -0.52, 0.03, 14.0, 0.0, 0.55 * fatigue - 0.12));
        veins = max(veins, poVein(s - 0.50, q.y - (0.06 * 0.50 + 0.045 * sin(0.50 * 10.0 + 4.0) * 0.50), 0.44, 0.03, 15.0, 1.0, 0.50 * fatigue - 0.12));
    }
    float gaps = max(dots, veins), printed = clamp(uP1.y, 0.0, 1.0);
    col = over(col, uC1.rgb, open * ink * (1.0 - gaps * (1.0 - printed)));
    col = over(col, uC6.rgb, open * ink * gaps * printed);

    // Радужка: плоский диск с гравировкой лучами. Толщина линий меняется по кругу, как блик
    // на шлифованном металле, и это «светлое» место поворачивается вместе со взглядом.
    vec2 c = irisCenter(uGaze, vec2(1.10, 0.26), -0.05);
    vec2 smear = c - irisCenter(uGaze2, vec2(1.10, 0.26), -0.05);   // на столько радужка «не успела» за взглядом
    float speed = length(smear);
    vec2 u = irisUV(q, c, PO_RI);
    // Поворот яблока: чем дальше взгляд от центра, тем сильнее диск радужки сплющен вдоль взгляда.
    vec2 gz = uGaze * vec2(1.0, 0.5);
    float turn = min(length(gz), 1.0);
    if (turn > 0.001) {
        vec2 d = gz / length(gz);
        u += d * dot(u, d) * (1.0 / mix(1.0, 0.84, turn * turn) - 1.0);
    }
    if (speed > 0.0005) {
        // Быстрый взгляд: диск едва заметно вытягивается вдоль движения и сразу собирается обратно.
        vec2 d = smear / speed;
        float k = 1.0 + min(speed * 0.40, 0.08);
        float par = dot(u, d);
        u = d * (par / k) + (u - d * par) * sqrt(k);
    }
    float r = length(u);
    float irisM = cover((r - 1.0) * PO_RI + rough) * open;
    float rp = 0.40 * uPupil;
    // Зрачок сидит глубже края радужки, поэтому внутри неё он смещён в сторону взгляда: так глаз
    // смотрит вбок, а не остаётся плоским кружком. В движении зрачок ещё и чуть отстаёт.
    // Лучи расходятся от центра зрачка, а к краю радужки возвращаются к её собственному центру.
    vec2 pc = uGaze * vec2(0.22, 0.13) + (uGaze2 - uGaze) * vec2(0.10, 0.06);
    vec2 up = u - pc * (1.0 - smoothstep(0.62, 1.0, r));
    float rq = length(up);
    // Гравировка слегка закручивается у зрачка, когда он сужается или расширяется.
    float ang = atan(up.y, up.x) + uMood.z * 0.45 * (1.0 - smoothstep(rp, 1.0, r));
    float a = ang / TAU * PO_RAYS;
    float m = mod(floor(a), 4.0);
    float len = m < 0.5 ? 0.925 : (abs(m - 2.0) < 0.5 ? 0.80 : 0.67);
    float lit = pow(abs(cos(ang - 0.95 - uGaze.x * 0.9)), 5.0);
    float frac = mix(0.15, 0.58, lit) + 0.2 * uEnergy;
    float dRay = (abs(fract(a) - 0.5) - 0.5 * frac) * (TAU * rq * PO_RI / PO_RAYS);
    float rays = cover(dRay) * cover((rp + 0.085 - rq) * PO_RI) * cover((r - len) * PO_RI);
    float rings = max(stroke((rq - rp - 0.045) * PO_RI, 0.8 * w), stroke((r - 0.962) * PO_RI, 0.8 * w));
    vec3 irisCol = mix(uC2.rgb, uC7.rgb, max(rays, rings));
    irisCol = mix(irisCol, uC3.rgb, cover((rq - rp) * PO_RI));
    col = over(col, irisCol, irisM * inkDark * (1.0 - dots * clamp(uP1.x, 0.0, 1.0)));

    // Блики почти стоят на месте, пока радужка движется.
    float h1 = cover(length(q - (c * 0.80 + vec2(-0.27, -0.30) * PO_RI)) - 0.135 * PO_RI);
    float h2 = cover(length(q - (c * 0.80 + vec2(0.27, 0.30) * PO_RI)) - 0.048 * PO_RI);
    col = over(col, uC4.rgb, max(h1, h2) * irisM * ink);

    // Влага: светлая полоска воды у нижнего века.
    float wet = clamp(uMood.w * 8.0, 0.0, 1.0);
    if (wet > 0.001) col = over(col, uC4.rgb, cover(abs(dBot - 0.036) - 0.022 * wet) * open * ink);

    // Верхнее веко: линия ресниц, толстая в середине и сходящая в остриё к уголкам.
    // Когда глаз распахнут, веко уходит под складку и линия становится тоньше.
    float lw = (0.012 + 0.092 * taperS * sqrt(taperS)) * mix(0.55, 1.0, smoothstep(0.0, 0.2, lt));
    float lash = cover(dTop + rough - 0.012) * cover(-(dTop + rough) - lw) * cover(dShape - lw - 0.004);
    col = over(col, uC5.rgb, lash * inkDark);
    // Нижнее веко — тонкая линия; в улыбке она толще.
    col = over(col, uC5.rgb, stroke(dBot, 0.003 + (0.007 + 0.02 * clamp(uFace.y, 0.0, 1.0)) * taper) * cover(dShape - 2.0 * w) * inkDark);

    // Штрихи вокруг глаза: коротко при пробуждении и испуге.
    float burst = max(uWake, alert);
    // Складка века над глазом; когда глаз распахнут, прижимается к веку.
    float lidApex = mix(-1.0, 0.24, lt);
    float gap = mix(0.15, 0.29, smoothstep(0.0, 0.3, lt)) * (1.0 - lt);
    float dCr = poTop(vec2(xs, q.y), lidApex - gap, clamp(uFace.z, 0.0, 1.0) * (1.0 - smoothstep(0.45, 0.85, lt)));
    float crease = stroke(dCr + rough, 0.006 + 0.017 * taperS) * smoothstep(0.98, 0.72, abs(t)) * cover(dTop + lw + 0.035);
    col = over(col, uC6.rgb, crease * (1.0 - burst) * ink);

    if (burst > 0.001) {
        // Лучи идут от центра глаза и расставлены ровно вдоль контура; толщина у всех одна.
        float sa = atan(q.y * 2.3, q.x) / TAU * 40.0;
        float k = floor(sa);
        float phi = (k + 0.5) / 40.0 * TAU;
        vec2 dir = normalize(vec2(cos(phi), sin(phi) / 2.3));
        float dAxis = abs(q.x * dir.y - q.y * dir.x);
        float longOne = step(0.5, mod(k, 2.0));
        float d0 = 0.12, d1 = d0 + (0.06 + 0.09 * longOne) * burst;
        col = over(col, uC5.rgb, cover(dAxis - 0.013) * cover(d0 - dShape) * cover(dShape - d1) * inkDark);
    }
    // Событие: от глаза расходится один контур, как круг по воде.
    if (uPulse > 0.0005) {
        col = over(col, uC5.rgb, stroke(dShape - 0.05 - uPulse * 0.24, 0.011 * (1.0 - uPulse)) * (1.0 - uPulse * uPulse));
    }
    return col * mix(0.6, 1.0, clamp(uDim, 0.0, 1.0));
}
