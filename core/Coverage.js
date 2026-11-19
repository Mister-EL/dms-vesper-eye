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

// Какая доля глаза закрыта окнами, от 0 до 1. eye и окна — прямоугольники {x, y, width, height}
// в одних координатах. Проверяются точки по всей линзе; окна могут закрывать её вместе.
function coverage(eye, rects) {
    if (!rects || rects.length === 0) return 0;
    var unit = unitFor(eye.width, eye.height), cx = eye.x + eye.width / 2, cy = eye.y + eye.height / 2;
    var total = 0, hidden = 0;
    for (var i = -6; i <= 6; i++) {
        for (var j = -3; j <= 3; j++) {
            var ux = i * EYE_W / 6.2, uy = j * 0.28;
            if (!inLens(ux, uy, 0)) continue;
            total++;
            var px = cx + ux * unit, py = cy + uy * unit;
            for (var k = 0; k < rects.length; k++) {
                var r = rects[k];
                if (px >= r.x && px <= r.x + r.width && py >= r.y && py <= r.y + r.height) { hidden++; break; }
            }
        }
    }
    return total ? hidden / total : 0;
}

// Глаз считается закрытым, когда видно меньше седьмой части: узкая щель между окнами не в счёт.
function covered(eye, rects) { return coverage(eye, rects) >= 0.85; }
