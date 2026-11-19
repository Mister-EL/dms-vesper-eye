// «Связи»: глаз — объёмный шар из узлов и связей. От зрачка связи расходятся деревом,
// за краем радужки сходятся к заднему полюсу; задняя половина шара просвечивает сквозь переднюю.
// Цвета: uC0 связи, uC1 узлы, uC2 ядро и пакеты (янтарь), uC3 редкие узлы (мята),
//        uC4 дымка радужки, uC5 линии век, uC6 дальняя половина шара, uC7 свет на краю шара.
// Сигналы: uP0.x сеть есть (1) или нет (0), uP0.y защищённый канал, uP0.z активный рабочий стол (с 1),
//          uP0.w сколько рабочих столов (0 — цепочку не рисовать).
const float NX_R = 0.98;          // радиус шара в единицах глаза
const float NX_PUPIL = 0.20;      // угловой радиус зрачка, радианы
const float NX_LIMB = 0.62;       // край радужки

// Кольца шара: угол от полюса взгляда и число узлов. До края радужки узлов вдвое больше
// на каждом шаге, дальше — вдвое меньше, пока все связи не сойдутся в заднем полюсе.
void nxRing(float k, out float th, out float n) {
    if (k < 0.5) { th = NX_PUPIL; n = 8.0; }
    else if (k < 1.5) { th = 0.34; n = 16.0; }
    else if (k < 2.5) { th = 0.48; n = 32.0; }
    else if (k < 3.5) { th = NX_LIMB; n = 32.0; }
    else if (k < 4.5) { th = 0.98; n = 16.0; }
    else if (k < 5.5) { th = 1.45; n = 8.0; }
    else if (k < 6.5) { th = 2.05; n = 4.0; }
    else if (k < 7.5) { th = 2.70; n = 2.0; }
    else { th = PI; n = 1.0; }
}

// Узел кольца k с номером i как точка на единичной сфере (ось z — взгляд).
vec3 nxNode(float k, float i) {
    float th, n;
    nxRing(k, th, n);
    i = mod(i, n);
    vec2 h = hash22(vec2(k * 7.3 + 1.0, i + 3.7));
    if (k > 3.5 && k < 7.5) th += (h.x - 0.5) * 0.10;                 // за радужкой сеть свободнее
    float ph = (i + 0.5) * TAU / n + (h.y - 0.5) * (k > 3.5 ? 0.30 : 0.10) * TAU / n;
    float s = sin(th);
    return vec3(s * cos(ph), s * sin(ph), cos(th));
}

// Состояние текущего пикселя: оси шара в пространстве экрана, точка на диске и глубина со знаком.
vec3 gAx, gAy, gPole;
vec2 gD;
float gZ;

vec3 nxView(vec3 l) { return gAx * l.x + gAy * l.y + gPole * l.z; }

// Расстояние на экране (в радиусах шара) от пикселя до дуги большого круга a–b.
// Делится на длину экранного градиента, поэтому нить одной толщины и в центре, и у края шара.
float nxArc(vec3 p, vec3 a, vec3 b) {
    vec3 n = cross(a, b);
    float ln = length(n);
    if (ln < 1e-4) return 1e3;
    n /= ln;
    if (dot(cross(a, p), n) < 0.0 || dot(cross(p, b), n) < 0.0) return 1e3;   // концы дуги закрыты узлами
    vec3 nv = nxView(n);
    vec2 g = nv.xy - nv.z * gD / gZ;
    return abs(dot(p, n)) / max(length(g), 0.08);
}
// Расстояние на экране до узла; узел с другой стороны шара не виден.
float nxDot(vec3 a) {
    vec3 v = nxView(a);
    return v.z * gZ > 0.0 ? length(v.xy - gD) : 1e3;
}
// Расстояние на экране до кольца с углом th от полюса.
float nxCircle(vec3 p, float th) {
    float t = acos(clamp(p.z, -1.0, 1.0));
    vec2 g = gPole.xy - gPole.z * gD / gZ;
    return abs(t - th) * max(sin(t), 0.05) / max(length(g), 0.08);
}

// Сеть в точке p сферы: x — связи, y — узлы, z — редкие мятные узлы. hw — полуширина нити на экране.
vec3 nxWeb(vec3 p, float hw) {
    float th = acos(clamp(p.z, -1.0, 1.0));
    float ph = atan(p.y, p.x);
    if (ph < 0.0) ph += TAU;
    float k = 0.0;
    float tA, nA, tB, nB;
    for (int j = 0; j < 8; j++) {
        nxRing(float(j) + 1.0, tB, nB);
        if (th > tB) k = float(j) + 1.0;
    }
    k = min(k, 7.0);
    nxRing(k, tA, nA);
    nxRing(k + 1.0, tB, nB);
    float link = 0.0, node = 0.0, mint = 0.0;
    if (th >= NX_PUPIL - 0.03) {
        float d = 1e3;
        if (nA == nB) {
            float i = floor(ph / (TAU / nA));
            d = nxArc(p, nxNode(k, i), nxNode(k + 1.0, i));
        } else {
            bool fanOut = nB > nA;
            float nc = fanOut ? nA : nB;
            float kc = fanOut ? k : k + 1.0, kf = fanOut ? k + 1.0 : k;
            float i = floor(ph / (TAU / nc));
            vec3 c = nxNode(kc, i), f0 = nxNode(kf, 2.0 * i), f1 = nxNode(kf, 2.0 * i + 1.0);
            // Дуга ориентирована от меньшего угла к большему, чтобы проверка «внутри дуги» работала в обе стороны.
            d = fanOut ? min(nxArc(p, c, f0), nxArc(p, c, f1)) : min(nxArc(p, f0, c), nxArc(p, f1, c));
        }
        link = 1.0 - smoothstep(hw, hw + px() / NX_R, d);
        float face = 0.45 + 0.55 * abs(gZ);
        for (int s = 0; s < 2; s++) {
            float kk = k + float(s);
            float tt, nn;
            nxRing(kk, tt, nn);
            float ii = floor(ph / (TAU / nn));
            float h = hash21(vec2(kk * 3.1, mod(ii, nn) + 9.0));
            float rad = (kk < 3.5 ? 0.013 : 0.019) * (0.8 + 0.5 * h) * (1.0 + 0.6 * uEnergy) * face;
            float m = 1.0 - smoothstep(rad - 0.5 * px() / NX_R, rad + 0.5 * px() / NX_R, nxDot(nxNode(kk, ii)));
            node = max(node, m);
            if (h > 0.93) mint = max(mint, m);
        }
    }
    return vec3(link, node, mint);
}

vec4 eye(vec2 q) {
    float dShape, dTop, dBot;
    eyeGeom(q, 1.0, 0.88, 0.0, 0.24, dShape, dTop, dBot);
    float w = px();
    float open = cover(-min(dTop, dBot));
    float online = mix(0.45, 1.0, clamp(uP0.x, 0.0, 1.0));
    vec4 col = vec4(0.0);

    // Шар и его поворот: полюс смотрит туда же, куда глаз.
    vec2 c0 = vec2(0.0, -0.04);
    float yaw = uGaze.x * 0.62, pitch = uGaze.y * 0.42;
    vec3 pole = vec3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch));
    vec3 ax = normalize(cross(vec3(0.0, 1.0, 0.0), pole));
    vec3 ay = cross(pole, ax);
    vec2 d = (q - c0) / NX_R;
    float rr = dot(d, d);

    if (rr < 1.0) {
        float z = sqrt(1.0 - rr);
        float hw = 0.55 * w / NX_R;
        vec3 nf = vec3(d, z), nb = vec3(d, -z);
        gAx = ax; gAy = ay; gPole = pole; gD = d;
        // Тело шара: чуть темнее фона, чтобы сеть читалась и на обоях.
        col = over(col, vec3(0.0), 0.34 * smoothstep(0.0, 0.25, z));
        // Дальняя половина: тоньше, тише и холоднее; у края шара гаснет.
        gZ = -max(z, 0.02);
        vec3 pb = vec3(dot(nb, ax), dot(nb, ay), dot(nb, pole));
        vec3 back = nxWeb(pb, hw * 0.8);
        float fb = (0.05 + 0.22 * z) * online;
        col = over(col, uC6.rgb, back.x * fb);
        col = over(col, uC6.rgb, back.y * fb * 1.8);
        // Ближняя половина.
        gZ = max(z, 0.02);
        vec3 pf = vec3(dot(nf, ax), dot(nf, ay), dot(nf, pole));
        vec3 front = nxWeb(pf, hw);
        float thF = acos(clamp(pf.z, -1.0, 1.0));
        float iris = 1.0 - smoothstep(NX_LIMB - 0.01, NX_LIMB + 0.01, thF);
        col = over(col, uC4.rgb, iris * (0.07 + 0.11 * smoothstep(NX_PUPIL, NX_LIMB, thF)));
        float pupil = 1.0 - smoothstep(NX_PUPIL - 0.012, NX_PUPIL + 0.004, thF);
        col = over(col, vec3(0.0), pupil * 0.5);
        float wave = uWake > 0.001 ? exp(-pow((thF - (1.0 - uWake) * 2.2) / 0.18, 2.0)) * uWake : 0.0;
        float fl = (mix(0.30, 0.66, iris) + 0.22 * z + 1.4 * wave) * online * smoothstep(0.0, 0.18, z);
        col = over(col, mix(uC0.rgb, uC1.rgb, wave), front.x * clamp(fl, 0.0, 1.0));
        // Кольца: зрачок и край радужки сплошные; второй контур — когда канал защищён.
        float e = px() / NX_R;
        float rings = (1.0 - smoothstep(hw * 1.3, hw * 1.3 + e, nxCircle(pf, NX_PUPIL))) * 0.95;
        rings = max(rings, (1.0 - smoothstep(hw * 1.2, hw * 1.2 + e, nxCircle(pf, NX_LIMB))) * 0.66);
        rings = max(rings, (1.0 - smoothstep(hw * 0.7, hw * 0.7 + e, nxCircle(pf, 0.34))) * 0.15);
        rings = max(rings, (1.0 - smoothstep(hw * 0.7, hw * 0.7 + e, nxCircle(pf, 0.48))) * 0.15);
        rings = max(rings, (1.0 - smoothstep(hw, hw + e, nxCircle(pf, NX_LIMB + 0.06))) * 0.5 * clamp(uP0.y, 0.0, 1.0));
        col = over(col, uC0.rgb, rings * online);
        vec3 nodeCol = mix(uC1.rgb, uC3.rgb, front.z);
        float nv = front.y * smoothstep(0.0, 0.2, z);
        col = over(col, nodeCol, nv);
        col.rgb += nodeCol * nv * 0.2;
    }

    // Край шара: тонкая окружность, ярче со стороны света.
    float limb = stroke((sqrt(rr) - 1.0) * NX_R, 0.6 * w);
    float lit = 0.10 + 0.45 * smoothstep(-0.2, 1.0, dot(normalize(d + vec2(1e-5)), normalize(vec2(-0.6, -0.8))));
    col = over(col, uC7.rgb, limb * lit);

    // Ядро в глубине шара: смещается иначе, чем поверхность, — отсюда глубина.
    float yaw2 = uGaze2.x * 0.62, pitch2 = uGaze2.y * 0.42;
    vec3 pole2 = vec3(sin(yaw2) * cos(pitch2), sin(pitch2), cos(yaw2) * cos(pitch2));
    vec2 core = c0 + NX_R * 0.76 * pole2.xy;
    float flash = uPulse > 0.82 ? (uPulse - 0.82) / 0.18 : 0.0;
    float coreSize = 0.034 * uPupil * (1.0 + 0.5 * flash);
    for (int i = 0; i < 8; i++) {                     // нити от ядра к кольцу зрачка
        vec3 nl = nxNode(0.0, float(i));
        vec3 nv = ax * nl.x + ay * nl.y + pole * nl.z;
        float sd = sdSegment(q, core, c0 + NX_R * nv.xy);
        col = over(col, mix(uC2.rgb, uC0.rgb, 0.55), (1.0 - smoothstep(0.5 * w, 1.6 * w, sd)) * 0.42);
    }
    float cd = length(q - core);
    col.rgb += uC2.rgb * exp(-cd / (0.10 * (1.0 + flash))) * (0.42 + 0.5 * flash + 0.3 * uWake);
    col.a = max(col.a, exp(-cd / 0.10) * 0.4);
    col = over(col, mix(uC2.rgb, vec3(1.0), 0.55), cover(cd - coreSize));

    // Событие: пакет идёт по сети от края радужки к ядру и подсвечивает её на пути.
    if (uPulse > 0.0005 && uPulse <= 0.82) {
        float t = uPulse / 0.82;
        vec2 from = c0 + NX_R * sin(NX_LIMB + 0.5) * normalize(uPulseDir + vec2(1e-5));
        vec2 pos = mix(from, core, t * t * (3.0 - 2.0 * t));
        float pd = length(q - pos);
        col.rgb += uC2.rgb * exp(-pd / 0.05) * 0.9;
        col = over(col, vec3(1.0, 0.95, 0.85), cover(pd - 0.022));
    }

    col *= open;

    // Растяжки от шара к уголкам глаза: держат шар и натягиваются при повороте.
    for (int i = 0; i < 3; i++) {
        float a = (float(i) - 1.0) * 0.55;
        vec3 l1 = vec3(sin(1.22) * cos(a), sin(1.22) * sin(a), cos(1.22));
        vec3 l2 = vec3(-l1.x, l1.y, l1.z);
        vec3 v1 = ax * l1.x + ay * l1.y + pole * l1.z, v2 = ax * l2.x + ay * l2.y + pole * l2.z;
        vec2 e1 = c0 + NX_R * v1.xy, e2 = c0 + NX_R * v2.xy;
        vec2 k1 = vec2(EYE_W, 0.0), k2 = vec2(-EYE_W, 0.0);
        if (uP0.x < 0.5) { k1 = mix(e1, k1, 0.55); k2 = mix(e2, k2, 0.55); }   // сети нет — растяжки оборваны
        float t1 = (1.0 - smoothstep(0.4 * w, 1.4 * w, sdSegment(q, e1, k1))) * (v1.z > 0.0 ? 0.42 : 0.14);
        float t2 = (1.0 - smoothstep(0.4 * w, 1.4 * w, sdSegment(q, e2, k2))) * (v2.z > 0.0 ? 0.42 : 0.14);
        // Нить от узла на ближней стороне видна целиком; от узла за шаром — только снаружи.
        float outside = smoothstep(0.98, 1.02, sqrt(rr));
        t1 *= v1.z > 0.0 ? 1.0 : outside;
        t2 *= v2.z > 0.0 ? 1.0 : outside;
        col = over(col, uC0.rgb, max(t1, t2) * open * online);
        col = over(col, uC1.rgb, max(cover(length(q - e1) - 0.02) * step(0.0, v1.z), cover(length(q - e2) - 0.02) * step(0.0, v2.z)) * open);
    }

    // Веки: две тонкие дуги с узлами в уголках; во сне остаётся одна линия и тёплая точка.
    float inside = cover(dShape - 2.0 * w);
    float lids = max(stroke(dTop, 0.55 * w), stroke(dBot, 0.55 * w)) * inside;
    col = over(col, uC5.rgb, lids * 0.55);
    float corner = cover(length(vec2(abs(q.x) - EYE_W, q.y)) - 0.03);
    col = over(col, uC1.rgb, corner);
    float closed = smoothstep(0.9, 1.0, uLidTop) * smoothstep(0.9, 1.0, uLidBot);
    float sd = length(q - vec2(0.0, 0.24));
    col.rgb += uC2.rgb * exp(-sd / 0.05) * 0.8 * closed;
    col = over(col, uC2.rgb, cover(sd - 0.026) * closed);

    // Рабочие столы: цепочка узлов под глазом, активный — янтарный.
    if (uP0.w > 0.5) {
        float n = min(uP0.w, 10.0), step_ = 0.17, y0 = 1.10;
        float fx = q.x / step_ + (n - 1.0) * 0.5;
        float idx = floor(fx + 0.5);
        if (idx >= 0.0 && idx <= n - 1.0) {
            vec2 pn = vec2((idx - (n - 1.0) * 0.5) * step_, y0);
            float isActive = abs(idx + 1.0 - uP0.z) < 0.5 ? 1.0 : 0.0;
            float dn = length(q - pn);
            col = over(col, mix(uC0.rgb, uC2.rgb, isActive), cover(dn - mix(0.016, 0.026, isActive)) * mix(0.55, 1.0, isActive));
            col.rgb += uC2.rgb * exp(-dn / 0.04) * 0.5 * isActive;
        }
        float chain = stroke(q.y - y0, 0.35 * w) * step(abs(q.x), (n - 1.0) * 0.5 * step_);
        col = over(col, uC0.rgb, chain * 0.22);
    }
    return col * mix(0.40, 1.0, clamp(uDim, 0.0, 1.0));
}
