// Общая геометрия и утилиты. Координаты q — в «единицах глаза»:
// 1 единица = половина высоты раскрытого глаза (uUnit пикселей), ось y направлена вниз.
// Цвет на выходе eye() — с предумноженной альфой.
#define PI 3.14159265
#define TAU 6.28318531

// Рамка глаза одна для всех образов: полуширина раскрытия в единицах.
#define EYE_W 2.5
// Радиус глазного яблока: от него зависит, насколько радужка сплющивается при взгляде в сторону.
#define EYE_R 2.5

float hash11(float n) { return fract(sin(n * 127.1) * 43758.5453); }
float hash21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
vec2 hash22(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}
float vnoise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}
// Шум, замкнутый по x с периодом period: для узоров по углу без шва.
float vnoiseWrap(vec2 p, float period) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float x0 = mod(i.x, period), x1 = mod(i.x + 1.0, period);
    return mix(mix(hash21(vec2(x0, i.y)), hash21(vec2(x1, i.y)), f.x),
               mix(hash21(vec2(x0, i.y + 1.0)), hash21(vec2(x1, i.y + 1.0)), f.x), f.y);
}
mat2 rot(float a) { float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

// Ширина одного пикселя в единицах глаза и покрытие для сглаживания краёв.
float px() { return 1.0 / max(uUnit, 1.0); }
float cover(float d) { float w = px(); return 1.0 - smoothstep(-w, w, d); }
float coverSoft(float d, float w) { return 1.0 - smoothstep(-w, w, d); }
// Линия полуширины hw вокруг d = 0.
float stroke(float d, float hw) { return cover(abs(d) - hw); }

float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    return length(pa - ba * clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0));
}
float sdRoundBox(vec2 p, vec2 b, float r) {
    vec2 d = abs(p) - b + vec2(r);
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

// Кромка века — дуга окружности через оба уголка (±wi, 0) с вершиной в (0, k).
// Возвращает расстояние со знаком: больше нуля ниже дуги (y направлена вниз).
float arcBelow(vec2 q, float wi, float k) {
    if (abs(k) < 0.002) return q.y - k;
    float rad = (wi * wi + k * k) / (2.0 * abs(k));
    float cy = k < 0.0 ? k + rad : k - rad;
    float d = length(vec2(q.x, q.y - cy)) - rad;
    return k < 0.0 ? -d : d;
}

// Точное расстояние до линзы из двух дуг: верхняя с вершиной -hu, нижняя с вершиной +hl.
float sdLens(vec2 q, float wi, float hu, float hl) {
    float ru = (wi * wi + hu * hu) / (2.0 * hu), rl = (wi * wi + hl * hl) / (2.0 * hl);
    float cu = -hu + ru, cl = hl - rl;                 // центры: верхней дуги — ниже, нижней — выше
    vec2 a = vec2(abs(q.x), q.y);
    float d = max(length(vec2(a.x, a.y - cu)) - ru, length(vec2(a.x, a.y - cl)) - rl);
    // За уголком ближайшая точка — сам уголок.
    vec2 v = a - vec2(wi, 0.0);
    vec2 nu = vec2(wi, -cu), nl = vec2(wi, -cl);       // нормали дуг в уголке
    if (nu.x * v.y - nu.y * v.x > 0.0 && v.x * nl.y - v.y * nl.x > 0.0) d = length(v);
    return d;
}

// Силуэт глаза и раскрытие между веками. Все расстояния — в единицах глаза.
//   dShape < 0 внутри силуэта;
//   dTop > 0 ниже кромки верхнего века, dBot > 0 выше кромки нижнего (то есть в раскрытой части).
// rnd скругляет уголки; closeY — где смыкаются веки (ниже центра).
void eyeGeom(vec2 q, float hU, float hL, float rnd, float closeY,
             out float dShape, out float dTop, out float dBot) {
    float wi = EYE_W - rnd, hu = hU - rnd, hl = hL - rnd;
    dShape = sdLens(q, wi, hu, hl) - rnd;
    float lt = clamp(uLidTop, 0.0, 1.0), lb = clamp(uLidBot, 0.0, 1.0);
    dTop = arcBelow(q, wi, mix(-hu, closeY, lt)) + rnd * (1.0 - lt);
    dBot = -arcBelow(q, wi, mix(hl, closeY, lb)) + rnd * (1.0 - lb);
}

// Центр радужки на экране для направления взгляда g из [-1, 1].
vec2 irisCenter(vec2 g, vec2 travel, float y0) { return vec2(g.x * travel.x, g.y * travel.y + y0); }

// Координаты точки в плоскости радужки (в её радиусах): яблоко — шар,
// поэтому при взгляде в сторону диск сплющивается вдоль направления взгляда.
vec2 irisUV(vec2 q, vec2 c, float rI) {
    vec2 v = q - c;
    float cl = length(c);
    if (cl > 1e-4) {
        vec2 d = c / cl;
        float s = sqrt(max(0.2, 1.0 - cl * cl / (EYE_R * EYE_R)));
        float par = dot(v, d);
        v += d * (par / s - par);
    }
    return v / rI;
}

// Наложение источника с предумноженной альфой поверх накопленного цвета.
vec4 over(vec4 dst, vec3 rgb, float a) { return vec4(dst.rgb * (1.0 - a) + rgb * a, dst.a * (1.0 - a) + a); }
