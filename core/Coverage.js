.pragma library
// Геометрия глаза в «единицах» (1 = половина высоты раскрытия). Числа совпадают с shaders/src/common.glsl.
var EYE_W = 2.5;      // полуширина раскрытия
var BOX_W = 5.7;      // весь холст по ширине
var BOX_H = 2.7;      // и по высоте
var HU = 1.0;         // вершина верхней дуги
var HL = 0.88;        // вершина нижней дуги

// Точка (x, y) в единицах внутри линзы из двух дуг? pad расширяет линзу (для попадания мышью).
function inLens(x, y, pad) {
    pad = pad || 0;
    var ax = Math.abs(x);
    if (ax > EYE_W + pad) return false;
    var ru = (EYE_W * EYE_W + HU * HU) / (2 * HU), rl = (EYE_W * EYE_W + HL * HL) / (2 * HL);
    var cu = -HU + ru, cl = HL - rl;
    return Math.hypot(ax, y - cu) <= ru + pad && Math.hypot(ax, y - cl) <= rl + pad;
}

function unitFor(width, height) { return Math.min(height / BOX_H, width / BOX_W); }

// Форма глаза задаётся образом: { type: "lens" } (по умолчанию) или { type: "round", r, cy } — круг радиуса r
// с центром в (0, cy). Точка внутри формы?
function inside(shape, x, y, pad) {
    if (shape && shape.type === "round") { var r = shape.r + (pad || 0), dy = y - (shape.cy || 0); return x * x + dy * dy <= r * r; }
    if (shape && shape.w) {                               // линза своих размеров: { w, hu, hl }
        var p = pad || 0, ax = Math.abs(x), w = shape.w, hu = shape.hu, hl = shape.hl;
        if (ax > w + p) return false;
        var ru = (w * w + hu * hu) / (2 * hu), rl = (w * w + hl * hl) / (2 * hl);
        return Math.hypot(ax, y - (-hu + ru)) <= ru + p && Math.hypot(ax, y - (hl - rl)) <= rl + p;
    }
    return inLens(x, y, pad);
}
function scan(eye, rects, shape, each) {
    var unit = unitFor(eye.width, eye.height), cx = eye.x + eye.width / 2, cy = eye.y + eye.height / 2;
    var round = shape && shape.type === "round", hw = round ? shape.r : (shape && shape.w ? shape.w : EYE_W), hh = round ? shape.r : 1.0, oy = round ? (shape.cy || 0) : 0;
    for (var i = -10; i <= 10; i++) {
        for (var j = -6; j <= 6; j++) {
            var ux = i * hw / 10.4, uy = oy + j * hh / 6.2;
            if (!inside(shape, ux, uy, 0)) continue;
            var px = cx + ux * unit, py = cy + uy * unit, hidden = false;
            for (var k = 0; k < rects.length; k++) {
                var r = rects[k];
                if (px >= r.x && px <= r.x + r.width && py >= r.y && py <= r.y + r.height) { hidden = true; break; }
            }
            each(ux, uy, hidden);
        }
    }
}

// Какая доля глаза закрыта окнами, от 0 до 1. eye и окна — прямоугольники {x, y, width, height}
// в одних координатах. Проверяются точки по всей форме; окна могут закрывать её вместе.
function coverage(eye, rects, shape) {
    if (!rects || rects.length === 0) return 0;
    var total = 0, hidden = 0;
    scan(eye, rects, shape, function (x, y, h) { total++; if (h) hidden++; });
    return total ? hidden / total : 0;
}

// Видимая часть глаза: доля f от 0 до 1 и её середина (x, y) в единицах глаза.
// Нужна, чтобы зрачок переезжал туда, где его видно из-за окон.
function visible(eye, rects, shape) {
    if (!rects || rects.length === 0) return { f: 1, x: 0, y: 0 };
    var total = 0, seen = 0, sx = 0, sy = 0;
    scan(eye, rects, shape, function (x, y, h) { total++; if (!h) { seen++; sx += x; sy += y; } });
    return seen ? { f: seen / total, x: sx / seen, y: sy / seen } : { f: 0, x: 0, y: 0 };
}

// Глаз считается закрытым, когда видно меньше седьмой части: узкая щель между окнами не в счёт.
function covered(eye, rects, shape) { return coverage(eye, rects, shape) >= 0.85; }
