// «Сеть»: глаз, сплетённый из узлов и связей; контура нет, силуэт держится плотностью ткани. Цвета:
//   uC0 связи, uC1 узлы, uC2 пакет и вспышка события (янтарь), uC3 редкие акцентные узлы (мята),
//   uC4 дымка радужки (объём шара), uC5 пустота зрачка (подложка), uC6 дальние связи у краёв,
//   uC7 ореол узлов.
// Устройство. Радужка — полярная решётка: корневой узел, кольца из 8, 16 и 32 узлов, между кольцами
// спицы «веером» (узел j держит узлы 2j и 2j+1 следующего кольца) и редкие диагонали. Белок — паутина
// в координатах (угол, доля пути от радужки до кромки миндаля): 32 сектора × 6 рядов, по узлу в ячейке;
// её первый ряд привязан к внешнему кольцу, поэтому при повороте взгляда ткань тянется.
// На пиксель считается постоянное число узлов и отрезков: своя ячейка и соседние.
const float LT_RI = 0.78;        // радиус радужки в единицах глаза
const float LT_N1 = 8.0;
const float LT_N2 = 16.0;
const float LT_N3 = 32.0;
const float LT_K = 6.0;          // рядов паутины
const float LT_R2 = 0.67;        // радиус среднего кольца (в радиусах радужки)
const float LT_PSI = 0.21;       // общий поворот решётки, чтобы она не была зеркальной
const float LT_JA = 0.5;         // разброс узла по углу, доля сектора
// Окружности век для высот 1.0 и 0.88 при полуширине 2.5: радиус и ордината центра.
// Радиусы уменьшены на LT_IN: крайний ряд паутины идёт с этим отступом от кромки миндаля.
const float LT_IN = 0.065;
const float LT_RU = 3.625 - LT_IN;
const float LT_CU = 2.625;
const float LT_RL = 3.991136 - LT_IN;
const float LT_CL = -3.111136;

vec2 ltD;      // направление сплющивания диска радужки
float ltS;     // коэффициент сплющивания
float ltHW;    // полуширина связи
vec4 ltA;      // накопители: x связи, y свечение связей, z ядра узлов, w ореолы узлов
vec2 ltB;      // то же для мятных узлов: x ядра, y ореолы

vec2 ltToPlane(vec2 v) { float par = dot(v, ltD); return (v + ltD * (par / ltS - par)) / LT_RI; }
vec2 ltToScreen(vec2 u) { vec2 v = u * LT_RI; float par = dot(v, ltD); return v + ltD * (par * ltS - par); }

// Где луч o + t·dir выходит из миндаля (пересечения двух окружностей век).
float ltEdge(vec2 o, vec2 dir) {
    vec2 a = o - vec2(0.0, LT_CU), b = o - vec2(0.0, LT_CL);
    float A = max(dot(dir, dir), 1e-6);
    float bu = dot(dir, a), bl = dot(dir, b);
    float tu = (-bu + sqrt(max(bu * bu - A * (dot(a, a) - LT_RU * LT_RU), 0.0))) / A;
    float tl = (-bl + sqrt(max(bl * bl - A * (dot(b, b) - LT_RL * LT_RL), 0.0))) / A;
    return min(tu, tl);
}

void ltLink(vec2 q, vec2 a, vec2 b, float al) {
    float d = sdSegment(q, a, b);
    ltA.x = max(ltA.x, al * cover(d - ltHW));
    ltA.y = max(ltA.y, al * clamp(1.0 - d / 0.05, 0.0, 1.0));
}

void ltDot(vec2 q, vec2 p, float r, float al, float gr, float mint) {
    float d = length(q - p);
    float core = al * cover(d - max(r, 0.7 * px()));
    float halo = al * exp(-d * d / (gr * gr));
    if (mint > 0.5) { ltB.x = max(ltB.x, core); ltB.y += halo; }
    else { ltA.z = max(ltA.z, core); ltA.w += halo; }
}

// Узел кольца i (замыкается по n); смещение от центра кольца в единицах глаза.
vec2 ltRing(float i, float n, float rad, float jr, float seed) {
    float k = mod(i, n);
    vec2 h = hash22(vec2(k, seed));
    float a = (k + 0.5 + (h.x - 0.5) * LT_JA) / n * TAU + LT_PSI;
    return ltToScreen(rad * (1.0 + (h.y - 0.5) * jr) * vec2(cos(a), sin(a)));
}

// Узел с характером: размер, мерцание и редкая мята зависят от номера.
void ltNode(vec2 q, vec2 p, float id, float seed, float nr, float gr, float al, float pm) {
    float h = hash21(vec2(id, seed + 3.0));
    float tw = 0.86 + 0.14 * sin(uTime * (0.6 + h) + h * 40.0);
    ltDot(q, p, nr * (0.78 + 0.5 * h), al * tw, gr, step(1.0 - pm, fract(h * 7.13)));
}

// Кольцо: цепочка звеньев, узлы и хорды через один узел.
void ltRingDraw(vec2 q, vec2 c, float n, float rad, float jr, float seed,
                float la, float pl, float nr, float gr, float pm, float chord, float margin) {
    vec2 u = ltToPlane(q - c);
    if (abs(length(u) - rad) > margin) return;
    float i = floor((atan(u.y, u.x) - LT_PSI) / TAU * n);
    vec2 a = c + ltRing(i - 1.0, n, rad, jr, seed);
    vec2 b = c + ltRing(i, n, rad, jr, seed);
    vec2 d = c + ltRing(i + 1.0, n, rad, jr, seed);
    float ia = mod(i - 1.0, n), ib = mod(i, n), id = mod(i + 1.0, n);
    float ha = hash21(vec2(ia, seed + 0.5)), hb = hash21(vec2(ib, seed + 0.5));
    ltLink(q, a, b, la * step(ha, pl) * (0.7 + 0.3 * ha));
    ltLink(q, b, d, la * step(hb, pl) * (0.7 + 0.3 * hb));
    ltNode(q, a, ia, seed, nr, gr, 1.0, pm);
    ltNode(q, b, ib, seed, nr, gr, 1.0, pm);
    ltNode(q, d, id, seed, nr, gr, 1.0, pm);
    if (chord > 0.0) {
        vec2 e = c + ltRing(i - 2.0, n, rad, jr, seed);
        vec2 g = c + ltRing(i + 2.0, n, rad, jr, seed);
        ltLink(q, e, b, chord * step(0.35, hash21(vec2(mod(i - 2.0, n), seed + 1.5))));
        ltLink(q, a, d, chord * step(0.35, hash21(vec2(ia, seed + 1.5))));
        ltLink(q, b, g, chord * step(0.35, hash21(vec2(ib, seed + 1.5))));
    }
}

// Веер между кольцом A (n узлов) и кольцом B (2n узлов): звенья узла j кольца A.
void ltFan(vec2 q, float j, float n, float ra, float ja, float sa, vec2 ca,
           float rb, float jb, float sb, vec2 cb, float al) {
    vec2 a = ca + ltRing(j, n, ra, ja, sa);
    vec2 b0 = cb + ltRing(2.0 * j, 2.0 * n, rb, jb, sb);
    vec2 b1 = cb + ltRing(2.0 * j + 1.0, 2.0 * n, rb, jb, sb);
    float h = hash21(vec2(mod(j, n), sa + 0.7));
    ltLink(q, a, b0, al * (0.65 + 0.35 * h));
    ltLink(q, a, b1, al * (1.0 - 0.35 * h));
    // Диагональ четырёхугольника между клиньями всегда выходит из узла своего клина:
    // так каждое звено видно из обеих ячеек, через которые оно проходит.
    float hr = fract(h * 13.7);
    float hq = fract(hash21(vec2(mod(j - 1.0, n), sa + 0.7)) * 13.7);
    if (hr < 0.30) ltLink(q, a, cb + ltRing(2.0 * j + 2.0, 2.0 * n, rb, jb, sb), al * 0.6);
    if (hq >= 0.30 && hq < 0.60) ltLink(q, a, cb + ltRing(2.0 * j - 1.0, 2.0 * n, rb, jb, sb), al * 0.6);
}

// Узел паутины белка: сектор i, ряд k (ряд -1 — узел внешнего кольца радужки).
vec2 ltWeb(float i, float k, vec2 c3, out float vis) {
    float ii = mod(i, LT_N3);
    vec2 h = hash22(vec2(ii, 40.0 + k));
    float a = (ii + 0.5 + (h.x - 0.5) * LT_JA) / LT_N3 * TAU + LT_PSI;
    vec2 e = vec2(cos(a), sin(a));
    if (k < -0.5) { vis = 1.0; return ltToScreen(e); }
    float span = ltEdge(c3, ltToScreen(e)) - 1.0;
    float hx = hash21(vec2(ii, k) + 17.3);
    float nu = 1.0;
    if (k > LT_K - 1.5) {
        // Крайний ряд лежит на самой кромке и держит силуэт, даже где белок совсем узкий.
        vis = step(hx, 0.93) * (0.55 + 0.35 * h.y) * smoothstep(0.03, 0.14, span) * step(k, LT_K - 0.5);
    } else {
        nu = (k + 0.5 + (h.y - 0.5) * 0.4) / LT_K;
        vis = step(hx, mix(0.95, 0.76, nu)) * smoothstep(0.55, 1.0, span);
    }
    return ltToScreen(e * (1.0 + nu * max(span, 0.0)));
}

void ltDiag(vec2 q, vec2 id, vec2 a, float va, vec2 b, float vb, vec2 c, float vc, vec2 d, float vd) {
    float h = hash21(id + vec2(5.3, 9.2));
    if (h < 0.30) ltLink(q, a, b, min(va, vb) * 0.30);
    else if (h < 0.58) ltLink(q, c, d, min(vc, vd) * 0.30);
}

// Звено вдоль ряда k между секторами i и i+1. Крайний ряд связан плотнее и обводит миндаль
// пунктиром узлов; ряд -1 — цепочка внешнего кольца, её рисует радужка.
void ltRowLink(vec2 q, vec2 a, float va, vec2 b, float vb, float i, float k) {
    if (k < -0.5) return;
    float h = hash21(vec2(i, k) + vec2(0.37, 7.1));
    ltLink(q, a, b, min(va, vb) * step(h, k > LT_K - 1.5 ? 0.90 : 0.68) * (0.36 + 0.2 * h));
}

void ltWebDraw(vec2 q, vec2 c3) {
    vec2 u = ltToPlane(q - c3);
    float rho = length(u);
    if (rho < 0.96) return;
    float span = ltEdge(c3, ltToScreen(u / rho)) - 1.0;
    if (span < 0.03) return;
    float nu = (rho - 1.0) / span;
    if (nu > 1.0 + 0.06 / (span * LT_RI)) return;
    float ci = floor((atan(u.y, u.x) - LT_PSI) / TAU * LT_N3);
    float ck = clamp(floor(nu * LT_K), 0.0, LT_K - 1.0);
    float v00, v10, v20, v01, v11, v21, v02, v12, v22;
    vec2 p00 = c3 + ltWeb(ci - 1.0, ck - 1.0, c3, v00);
    vec2 p10 = c3 + ltWeb(ci, ck - 1.0, c3, v10);
    vec2 p20 = c3 + ltWeb(ci + 1.0, ck - 1.0, c3, v20);
    vec2 p01 = c3 + ltWeb(ci - 1.0, ck, c3, v01);
    vec2 p11 = c3 + ltWeb(ci, ck, c3, v11);
    vec2 p21 = c3 + ltWeb(ci + 1.0, ck, c3, v21);
    vec2 p02 = c3 + ltWeb(ci - 1.0, ck + 1.0, c3, v02);
    vec2 p12 = c3 + ltWeb(ci, ck + 1.0, c3, v12);
    vec2 p22 = c3 + ltWeb(ci + 1.0, ck + 1.0, c3, v22);
    float il = mod(ci - 1.0, LT_N3), im = mod(ci, LT_N3);
    // Вдоль ряда. Соседние ряды тоже: у уголка глаза хорда звена заходит в чужую ячейку.
    ltRowLink(q, p01, v01, p11, v11, il, ck);
    ltRowLink(q, p11, v11, p21, v21, im, ck);
    ltRowLink(q, p00, v00, p10, v10, il, ck - 1.0);
    ltRowLink(q, p10, v10, p20, v20, im, ck - 1.0);
    ltRowLink(q, p02, v02, p12, v12, il, ck + 1.0);
    ltRowLink(q, p12, v12, p22, v22, im, ck + 1.0);
    // Вдоль луча.
    float hd = hash21(vec2(im, ck - 1.0) + vec2(3.1, 1.7)), hu = hash21(vec2(im, ck) + vec2(3.1, 1.7));
    ltLink(q, p10, p11, min(v10, v11) * step(hd, 0.86) * (0.46 + 0.2 * hd));
    ltLink(q, p11, p12, min(v11, v12) * step(hu, 0.86) * (0.46 + 0.2 * hu));
    // По одной диагонали на четырёхугольник.
    ltDiag(q, vec2(il, ck - 1.0), p00, v00, p11, v11, p10, v10, p01, v01);
    ltDiag(q, vec2(im, ck - 1.0), p10, v10, p21, v21, p20, v20, p11, v11);
    ltDiag(q, vec2(il, ck), p01, v01, p12, v12, p11, v11, p02, v02);
    ltDiag(q, vec2(im, ck), p11, v11, p22, v22, p21, v21, p12, v12);
    float hn = hash21(vec2(im, ck) + 2.9);
    float edge = step(LT_K - 1.5, ck);
    ltDot(q, p11, (0.0105 + 0.007 * hn) * mix(1.0, 0.85, edge), v11 * mix(v11, 1.0, edge) * 0.95, 0.022, step(0.92, fract(hn * 5.3)));
    // Редкие опорные узлы — с тонким кольцом, как у корня.
    if (fract(hn * 11.7) > 0.86 && edge < 0.5 && span > 1.0)
        ltA.x = max(ltA.x, v11 * 0.6 * stroke(length(q - p11) - 0.032, 0.8 * ltHW));
}

// Пыль дальнего плана: редкие точки без связей, по одной на клетку.
float ltDust(vec2 q) {
    vec2 gq = q / 0.17;
    vec2 id = floor(gq);
    vec2 h = hash22(id + 91.0);
    float d = length((fract(gq) - 0.25 - 0.5 * h) * 0.17);
    return step(hash21(id + 13.7), 0.42) * (0.3 + 0.7 * h.x) * cover(d - max(0.0058, 0.65 * px()));
}

// Ордината дуги века с вершиной k на абсциссе x.
float ltArcY(float x, float k) {
    if (abs(k) < 0.002) return k;
    float rad = (EYE_W * EYE_W + k * k) / (2.0 * abs(k));
    float s = sqrt(max(rad * rad - x * x, 0.0));
    return k < 0.0 ? k + rad - s : k - rad + s;
}

vec2 ltLidNode(float n, float k) {
    float x = (n + (hash11(n + 7.7) - 0.5) * 0.5 * step(0.5, abs(n))) * 0.3;
    return vec2(x, ltArcY(x, k));
}

// Цепочка узлов по кромке века; lash — «ресницы», короткие связи с концевыми узлами вниз.
void ltLidChain(vec2 q, float k, float al, float lash) {
    float i = floor(q.x / 0.3 + 0.5);
    vec2 a = ltLidNode(i - 1.0, k), b = ltLidNode(i, k), c = ltLidNode(i + 1.0, k);
    ltLink(q, a, b, al * 0.9);
    ltLink(q, b, c, al * 0.9);
    for (int s = -1; s <= 1; s++) {
        float n = i + float(s);
        vec2 p = s < 0 ? a : (s > 0 ? c : b);
        float h = hash11(n + 3.3);
        float mid = 1.0 - step(0.5, abs(n));
        ltDot(q, p, mix(0.014 + 0.012 * h, 0.034, mid), al, mix(0.04, 0.09, mid), mid * lash);
        if (lash > 0.001 && h > 0.35) {
            vec2 e = p + vec2(p.x * 0.05, 0.10 + 0.09 * fract(h * 9.1)) * lash;
            ltLink(q, p, e, al * 0.42 * lash);
            ltDot(q, e, 0.009, al * 0.8 * lash, 0.02, 0.0);
        }
    }
}

// Перегон пакета по звену a→b: след позади головы, слабая подсветка маршрута впереди.
void ltHop(vec2 q, vec2 a, vec2 b, float sHead, inout float cum, inout float trail, inout vec2 head) {
    vec2 pa = q - a, ba = b - a;
    float len = max(length(ba), 1e-4);
    float h = clamp(dot(pa, ba) / (len * len), 0.0, 1.0);
    float d = length(pa - ba * h);
    float back = sHead - (cum + h * len);
    float tr = back > 0.0 ? 0.16 + 0.84 * exp(-back / 0.36) : 0.16 * exp(back / 0.5);
    trail = max(trail, tr * cover(d - 1.25 * ltHW));
    if (sHead >= cum && sHead <= cum + len) head = a + ba * ((sHead - cum) / len);
    cum += len;
}

vec4 eye(vec2 q) {
    float dShape, dTop, dBot;
    eyeGeom(q, 1.0, 0.88, 0.0, 0.24, dShape, dTop, dBot);
    if (dShape > 0.2) return vec4(0.0);
    float w = px();
    ltHW = max(0.0042, 0.5 * w);

    vec2 g = clamp(uGaze, vec2(-1.0), vec2(1.0));
    vec2 lag = clamp(uGaze2 - uGaze, vec2(-0.7), vec2(0.7));
    vec2 cG = irisCenter(g, vec2(1.12, 0.12), -0.03);
    float cl = length(cG);
    ltD = cl > 1e-4 ? cG / cl : vec2(1.0, 0.0);
    ltS = sqrt(max(0.2, 1.0 - cl * cl / (EYE_R * EYE_R)));
    // Слои сети идут за взглядом по-разному: корень и первое кольцо забегают вперёд,
    // внешнее кольцо и паутина отстают.
    vec2 c3 = cG + lag * vec2(0.20, 0.10);
    vec2 c2 = cG + lag * vec2(0.09, 0.05) + g * vec2(0.022, 0.012);
    vec2 c1 = cG + g * vec2(0.048, 0.026);
    vec2 c0 = cG - lag * vec2(0.06, 0.03) + g * vec2(0.072, 0.040);
    float r1 = 0.36 * clamp(uPupil, 0.6, 1.6);
    float en = clamp(uEnergy, 0.0, 1.0);

    // Белок.
    ltA = vec4(0.0); ltB = vec2(0.0);
    ltWebDraw(q, c3);
    vec4 wA = ltA; vec2 wB = ltB;

    // Радужка.
    ltA = vec4(0.0); ltB = vec2(0.0);
    vec2 u3 = ltToPlane(q - c3);
    float rho3 = length(u3);
    vec2 u1 = ltToPlane(q - c1);
    float rho1 = length(u1);
    if (rho3 < 1.16) {
        ltRingDraw(q, c3, LT_N3, 1.0, 0.0, 39.0, 0.95, 1.0, 0.0135, 0.030, 0.07, 0.30, 0.15);
        vec2 cm = 0.5 * (c2 + c3);
        vec2 um = ltToPlane(q - cm);
        float rm = length(um);
        if (rm > LT_R2 - 0.14 && rm < 1.07) {
            float f = (atan(um.y, um.x) - LT_PSI) / TAU * LT_N2;
            float j = floor(f);
            ltFan(q, j, LT_N2, LT_R2, 0.10, 31.0, c2, 1.0, 0.0, 39.0, c3, 0.42);
            ltFan(q, j + (fract(f) > 0.5 ? 1.0 : -1.0), LT_N2, LT_R2, 0.10, 31.0, c2, 1.0, 0.0, 39.0, c3, 0.42);
        }
        ltRingDraw(q, c2, LT_N2, LT_R2, 0.10, 31.0, 0.52, 0.72, 0.0185, 0.042, 0.10, 0.0, 0.16);
        cm = 0.5 * (c1 + c2);
        um = ltToPlane(q - cm);
        rm = length(um);
        if (rm > r1 - 0.12 && rm < LT_R2 + 0.12) {
            float f = (atan(um.y, um.x) - LT_PSI) / TAU * LT_N1;
            float j = floor(f);
            ltFan(q, j, LT_N1, r1, 0.06, 23.0, c1, LT_R2, 0.10, 31.0, c2, 0.56);
            ltFan(q, j + (fract(f) > 0.5 ? 1.0 : -1.0), LT_N1, r1, 0.06, 23.0, c1, LT_R2, 0.10, 31.0, c2, 0.56);
        }
        ltRingDraw(q, c1, LT_N1, r1, 0.06, 23.0, 0.88, 1.0, 0.025, 0.06, 0.0, 0.0, 0.24);
        // Спицы от корневого узла через пустоту зрачка.
        vec2 u0 = ltToPlane(q - c0);
        if (rho1 < r1 + 0.12) {
            float f = (atan(u0.y, u0.x) - LT_PSI) / TAU * LT_N1;
            float j = floor(f);
            float fall = 1.0 - 0.55 * smoothstep(0.0, r1, length(u0));
            ltLink(q, c0, c1 + ltRing(j, LT_N1, r1, 0.06, 23.0), 0.62 * fall);
            ltLink(q, c0, c1 + ltRing(j + (fract(f) > 0.5 ? 1.0 : -1.0), LT_N1, r1, 0.06, 23.0), 0.62 * fall);
        }
    }
    // Корневой узел: ядро, ореол и тонкое кольцо.
    float d0 = length(q - c0);
    float rootR = 0.040 * (1.0 + 0.3 * en);
    float rootCore = cover(d0 - rootR);
    float rootHalo = exp(-d0 * d0 / 0.012) * (0.55 + 0.6 * en) + exp(-d0 / 0.13) * 0.12;
    float rootRing = stroke(d0 - 0.088, 0.9 * ltHW) * 0.75;

    // Маски: края миндаля и веки.
    float fadeWeb = smoothstep(0.0, 0.05, -dShape) * (1.0 - 0.8 * smoothstep(1.9, 2.45, abs(q.x)));
    float fadeIris = smoothstep(-0.03, 0.17, -dShape);
    float lidAmt = max(clamp(uLidTop, 0.0, 1.0), clamp(uLidBot, 0.0, 1.0));
    float fray = 0.02 + 0.16 * vnoise(vec2(q.x * 7.0, 3.0)) * smoothstep(0.0, 0.3, lidAmt);
    float open = smoothstep(0.0, fray, min(dTop, dBot));

    // Свет: блик шара стоит почти на месте, сеть под ним белеет.
    vec2 hk = cG * 0.55 + vec2(-0.30, -0.33) * LT_RI;
    float hl = exp(-dot(q - hk, q - hk) / 0.085);
    float shade = 1.0 - 0.28 * smoothstep(-0.3, 1.0, dot(u3, vec2(0.6, 0.8)));
    float inIris = 1.0 - smoothstep(0.98, 1.06, rho3);

    // Пробуждение: волна яркости от центра по сети; впереди волны сеть ещё тусклая.
    float boost = 1.0;
    float wave = 0.0;
    float amber = 0.0;
    float wk = clamp(uWake, 0.0, 1.0);
    if (wk > 0.001) {
        float Rw = (1.0 - wk) * 3.3;
        float band = exp(-pow((d0 - Rw) / 0.26, 2.0));
        boost *= mix(1.0, 0.42, smoothstep(Rw - 0.05, Rw + 0.35, d0) * smoothstep(0.0, 0.12, wk));
        wave = band * sqrt(wk);
        boost += 1.1 * wave;
        rootHalo *= 1.0 + 2.0 * wk;
    }
    // Событие, конец пути: корень вспыхивает, по сети расходится янтарное кольцо.
    float pu = clamp(uPulse, 0.0, 1.0);
    float flash = 0.0;
    if (pu > 0.70) {
        float x = (pu - 0.72) / 0.28;
        float amp = smoothstep(0.70, 0.76, pu) * sqrt(max(1.0 - x, 0.0));
        float band = exp(-pow((length(ltToPlane(q - c0)) - 1.25 * x) / 0.16, 2.0));
        amber = clamp(band * amp * 1.5, 0.0, 1.0);
        boost += 0.7 * band * amp;
        flash = smoothstep(0.70, 0.76, pu) * pow(max(1.0 - x, 0.0), 0.8);
    }

    // Сборка цвета.
    float deep = smoothstep(0.0, 0.6, -dShape);
    vec3 webLine = mix(mix(uC6.rgb, uC0.rgb, 0.35 + 0.65 * deep), uC1.rgb, 0.6 * wave);
    vec3 irisLine = mix(uC0.rgb, uC1.rgb, clamp(0.10 + 0.55 * hl + 0.6 * wave, 0.0, 1.0));
    float mW = fadeWeb * open * boost * (1.0 - 0.75 * inIris);
    float mI = fadeIris * open * boost;
    vec3 rgb = vec3(0.0);
    // Дымка радужки: купол, пустой в зрачке.
    float dome = sqrt(max(1.0 - rho3 * rho3, 0.0));
    float haze = smoothstep(r1 - 0.03, r1 + 0.26, rho1) * (0.30 + 0.70 * dome) * inIris;
    rgb += uC4.rgb * haze * (0.55 + 0.9 * hl) * shade * fadeIris * open;
    // Тонкое свечение обода: шар чуть светится в темноте.
    rgb += uC0.rgb * exp(-abs(rho3 - 1.0) * LT_RI / 0.055) * 0.11 * mI;
    rgb += mix(uC6.rgb, uC1.rgb, 0.45) * ltDust(q - c3 * 0.10) * 0.8 * smoothstep(0.02, 0.42, -dShape) * open * boost * (1.0 - inIris);
    rgb += webLine * (wA.x + 0.22 * wA.y * wA.y) * mW;
    rgb += uC7.rgb * wA.w * 0.42 * mW + uC3.rgb * (wB.x + 0.5 * wB.y) * mW;
    rgb = mix(rgb, uC1.rgb, clamp(wA.z * mW, 0.0, 1.0));
    vec3 il = mix(irisLine, uC2.rgb, amber);
    rgb += il * (ltA.x * shade + 0.30 * ltA.y * ltA.y) * mI;
    rgb += mix(uC7.rgb, uC2.rgb, amber) * ltA.w * (0.50 + 0.7 * en) * mI + uC3.rgb * (ltB.x + 0.6 * ltB.y) * mI;
    rgb = mix(rgb, mix(uC1.rgb, uC2.rgb, amber * 0.8), clamp(ltA.z * mI, 0.0, 1.0));
    // Корень.
    float mR = fadeIris * open;
    vec3 rootCol = mix(uC1.rgb, uC2.rgb, 0.75 * flash);
    rgb += mix(uC0.rgb, uC2.rgb, flash) * (rootRing + rootHalo * (1.0 + 2.2 * flash)) * mR * min(boost, 1.6);
    rgb += uC2.rgb * flash * exp(-d0 * d0 / 0.09) * 0.55 * mR;
    rgb = mix(rgb, rootCol, rootCore * mR);

    // Пакет: по звеньям одного сектора от кромки к корню.
    if (pu > 0.0005 && pu < 0.999) {
        float m = floor((atan(uPulseDir.y, uPulseDir.x) - LT_PSI) / TAU * LT_N3);
        float vv;
        vec2 pa = c3 + ltWeb(m, 5.0, c3, vv);
        vec2 pb = c3 + ltWeb(m, 4.0, c3, vv);
        vec2 p0 = c3 + ltWeb(m, 3.0, c3, vv);
        vec2 p1 = c3 + ltWeb(m, 2.0, c3, vv);
        vec2 p2 = c3 + ltWeb(m, 1.0, c3, vv);
        vec2 p3 = c3 + ltWeb(m, 0.0, c3, vv);
        vec2 p4 = c3 + ltWeb(m, -1.0, c3, vv);
        vec2 p5 = c2 + ltRing(floor(m / 2.0), LT_N2, LT_R2, 0.10, 31.0);
        vec2 p6 = c1 + ltRing(floor(m / 4.0), LT_N1, r1, 0.06, 23.0);
        float total = length(pb - pa) + length(p0 - pb) + length(p1 - p0) + length(p2 - p1) + length(p3 - p2) + length(p4 - p3)
                    + length(p5 - p4) + length(p6 - p5) + length(c0 - p6);
        float sHead = total * clamp(pu / 0.72, 0.0, 1.0);
        float cum = 0.0, trail = 0.0;
        vec2 head = c0;
        ltHop(q, pa, pb, sHead, cum, trail, head);
        ltHop(q, pb, p0, sHead, cum, trail, head);
        ltHop(q, p0, p1, sHead, cum, trail, head);
        ltHop(q, p1, p2, sHead, cum, trail, head);
        ltHop(q, p2, p3, sHead, cum, trail, head);
        ltHop(q, p3, p4, sHead, cum, trail, head);
        ltHop(q, p4, p5, sHead, cum, trail, head);
        ltHop(q, p5, p6, sHead, cum, trail, head);
        ltHop(q, p6, c0, sHead, cum, trail, head);
        float env = smoothstep(0.0, 0.05, pu) * (1.0 - smoothstep(0.72, 0.9, pu));
        float dh = length(q - head);
        float pk = (exp(-dh * dh / 0.0045) * 0.9 + exp(-dh / 0.09) * 0.22) * env;
        float mP = smoothstep(0.0, 0.12, -dShape) * open;
        rgb = mix(rgb, uC2.rgb, clamp(trail * env * mP, 0.0, 1.0));
        rgb += uC2.rgb * pk * mP;
        rgb = mix(rgb, mix(uC2.rgb, vec3(1.0), 0.55), cover(dh - 0.024) * env * mP);
    }

    // Веки: по кромке каждого идёт цепочка узлов; у закрытого глаза остаётся она одна.
    float lt = clamp(uLidTop, 0.0, 1.0), lb = clamp(uLidBot, 0.0, 1.0);
    float shut = smoothstep(0.85, 1.0, min(lt, lb));
    float aT = smoothstep(0.04, 0.45, lt), aB = smoothstep(0.04, 0.45, lb) * (1.0 - shut);
    if (aT + aB > 0.001) {
        float side = 1.0 - smoothstep(1.5, 2.36, abs(q.x));
        ltA = vec4(0.0); ltB = vec2(0.0);
        if (aT > 0.001) ltLidChain(q, mix(-1.0, 0.24, lt), aT, smoothstep(0.5, 1.0, lt));
        if (aB > 0.001) ltLidChain(q, mix(0.88, 0.24, lb), aB * 0.8, 0.0);
        vec3 ch = uC0.rgb * (ltA.x + 0.25 * ltA.y * ltA.y) + uC7.rgb * ltA.w * 0.5 + uC3.rgb * (ltB.x + 0.6 * ltB.y);
        rgb += ch * side;
        rgb = mix(rgb, uC1.rgb, clamp(ltA.z * side, 0.0, 1.0));
    }

    // Подложка: пустота зрачка остаётся тёмной и на светлых обоях.
    float veil = (0.30 * inIris + 0.40 * (1.0 - smoothstep(r1 - 0.06, r1 + 0.04, rho1))) * fadeIris * open;
    float k = mix(0.30, 1.0, clamp(uDim, 0.0, 1.0));
    rgb = min(rgb * k, vec3(1.0));
    float lum = max(rgb.r, max(rgb.g, rgb.b));
    return vec4(rgb + uC5.rgb * veil * (1.0 - lum), lum + veil * (1.0 - lum));
}
