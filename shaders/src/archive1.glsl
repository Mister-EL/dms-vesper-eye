// «Архив I»: самый первый глаз, каким он жил в оболочке Noctalia в январе 2026 года.
// Три ровных пятна без линий, бликов и теней: тёмный белок, розовая радужка, светлый зрачок.
// Век не видно — они цвета фона: моргая, глаз просто сужается к средней линии и пропадает.
// Цвета: uC1 белок, uC2 радужка, uC3 зрачок. Мимика, тревога, позы и сон этим рисунком не используются.
const float A1_W = 2.80;                 // полуширина глаза
const float A1_H = 0.72;                 // полувысота
const float A1_RI = 0.905;               // радиус радужки
const float A1_RP = 0.585;               // радиус зрачка
const float A1_GO = 0.345;               // наибольший сдвиг радужки; предел круглый, как в исходном коде

vec4 eye(vec2 q) {
    float nx = q.x / A1_W;
    float curve = A1_H * pow(max(0.0, 1.0 - nx * nx), 0.96);
    // Веки сходятся к средней линии. В моргании движок доводит нижнее веко до 0,9: здесь это уже «закрыто».
    float lt = clamp(uLidTop, 0.0, 1.0), lb = clamp(uLidBot / 0.9, 0.0, 1.0);
    float dOpen = max(-curve * (1.0 - lt) - q.y, q.y - curve * (1.0 - lb));
    float open = cover(dOpen) * cover(abs(q.x) - A1_W) * (1.0 - smoothstep(0.985, 1.0, min(lt, lb)));
    if (open < 0.001) return vec4(0.0);
    // Радужка ходит недалеко и упирается в круг: чем дальше указатель, тем ближе к краю круга.
    float m = length(uGaze);
    vec2 c = m > 0.0001 ? uGaze / m * A1_GO * (1.0 - exp(-4.0 * m)) : vec2(0.0);
    vec3 col = uC1.rgb;
    col = mix(col, uC2.rgb, cover(length(q - c) - A1_RI));
    col = mix(col, uC3.rgb, cover(length(q - c * 1.08) - A1_RP * clamp(uPupil, 0.6, 1.3)));
    return vec4(col * open, open);
}
