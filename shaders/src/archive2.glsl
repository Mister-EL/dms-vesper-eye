// «Архив II»: второй глаз — Vesper Eye 0.1, осень 2026 года. Исходный шейдер перенесён как был:
// костяной белок, гранатовая радужка с тонкими волокнами и светлым кольцом у зрачка, крупный чёрный зрачок,
// один мягкий блик, тонкий контур. Веки у этого глаза свои, цвета фона: закрытый глаз остаётся линзой с контуром.
// Цвета: uC0 веки, uC1 белок, uC2 радужка, uC3 зрачок, uC4 блик, uC5 контур и кайма век,
//        uC6 радужка у зрачка, uC7 радужка у края. Мимика, тревога, позы и сон не используются.
const float A2_W = 2.80;                 // полуширина глаза
const float A2_L = 2.971;                // «логическая высота» исходника: W / 0.9424
const float A2_H = 0.6537;               // полувысота: 0,22 L
const float A2_RI = 0.804;               // радиус радужки: 0,2706 L
const float A2_GO = 0.3137;              // наибольший сдвиг радужки: 0,1056 L, предел круглый

vec4 eye(vec2 q) {
    float w = px(), aa = 1.35 * w;
    float nx = abs(q.x) / A2_W;
    float curve = A2_H * pow(max(0.0, 1.0 - nx * nx), 1.08);
    float dShape = max(abs(q.y) - curve, (nx - 1.0) * A2_H);
    if (dShape > aa) return vec4(0.0);
    float ow = max(w, 5.7 / 800.0);                          // контур: 1/800 ширины виджета
    float shape = coverSoft(dShape, aa), inner = coverSoft(dShape + ow, aa);
    // Веки сходятся к средней линии. В моргании движок доводит нижнее веко до 0,9: здесь это уже «закрыто».
    // Нижнее веко в покое чуть приподнято: под белком видна тонкая полоска века, как на исходном глазе.
    float lt = clamp(uLidTop, 0.0, 1.0), lb = max(0.045, clamp(uLidBot / 0.9, 0.0, 1.0));
    float dLid = max(mix(-curve + ow, 0.0, lt) - q.y, q.y - mix(curve - ow, 0.0, lb));
    float aperture = (lt >= 0.999 && lb >= 0.999) ? 0.0 : coverSoft(dLid, aa);
    float content = inner * aperture;

    vec3 col = uC1.rgb;
    float m = length(uGaze);
    vec2 c = m > 0.0001 ? uGaze / m * A2_GO * (1.0 - exp(-4.0 * m)) : vec2(0.0);
    vec2 ip = q - c;
    float iu = length(ip) / A2_RI;
    if (content > 0.0001 && iu < 1.05) {
        float irisM = (1.0 - smoothstep(0.985, 1.015, iu)) * content;
        float gd = length(q - (c - vec2(A2_RI * 0.15))) / A2_RI;        // светлее вверху слева
        vec3 iris = mix(uC6.rgb, uC2.rgb, smoothstep(0.08, 0.62, gd));
        iris = mix(iris, uC7.rgb, smoothstep(0.62, 1.0, gd));
        float ang = atan(ip.y, ip.x);
        float fibers = sin(ang * 47.0 + iu * 9.0) * sin(ang * 71.0 - iu * 5.0);
        iris *= 1.0 + fibers * smoothstep(0.62, 0.72, iu) * (1.0 - smoothstep(0.90, 1.0, iu)) * 0.075;
        float ring = (iu - 0.68) * 34.0;
        iris = mix(iris, uC5.rgb, exp(-ring * ring) * 0.28);
        col = mix(col, iris, irisM);
        float rp = A2_RI * 0.66 * clamp(uPupil, 0.6, 1.3);
        col = mix(col, uC3.rgb, (1.0 - smoothstep(rp - aa, rp + aa, length(ip - c * 0.08))) * irisM);
        float glint = (1.0 - smoothstep(0.0, A2_RI * 0.105, length(q - (c - vec2(A2_RI * 0.28))))) * irisM;
        col = mix(col, uC4.rgb, glint * 0.65);
    }
    // Веки закрашены тоном фона, у самой кромки чуть темнее, по кромке идёт тонкая кайма.
    float lidDepth = 1.0 - smoothstep(0.0, A2_L * 0.14, dLid);
    vec3 lid = uC0.rgb * (1.0 - lidDepth * 0.16);
    lid = mix(lid, uC5.rgb, (1.0 - smoothstep(0.55 * ow, 2.3 * ow, dLid)) * 0.35);
    col = mix(col, lid, inner * (1.0 - aperture));
    col = mix(col, uC5.rgb, max(0.0, shape - inner) * 0.55);
    return vec4(col * shape, shape);
}
