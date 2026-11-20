.pragma library
// Номера, которыми глаз занимает себя, пока человек ничего не делает, и разовые реакции.
// Этот же набор играет живая страница design/keeper: менять здесь и там вместе.
//
// Шаг: t — длительность в секундах; x, y — куда смотреть (от -1 до 1); path — путь взгляда по доле шага;
// toward — доля пути до курсора. Каналы lid, lb (веки), pupil, skew (перекос века), smile, sad (веко домиком),
// twist (закрутка лучей), tear (влага), veins (сосуды), shiver (дрожь) — добавки к покою: число держится
// до конца номера, функция от доли шага играется один раз. bob — сдвиг всего глаза по доле шага;
// blink, burst, pulse, kick — разовые. om — резвость взгляда.
// wave — жест придатков (листья, уши, шерсть), hide — закрыться ими, film — третье веко, bulge — глаз выпучен:
// что именно они значат, решает рисунок образа.
// e — при какой бодрости номер уместен (1 — только проснулся, 0 — засыпает); w — вес при выборе.
var TAU = Math.PI * 2;
var CHANNELS = ["lid", "lb", "pupil", "skew", "smile", "sad", "twist", "tear", "veins", "shiver", "wave", "hide", "film", "bulge"];
function clamp(v, a, b) { return Math.min(b, Math.max(a, v)); }
function R(a, b) { return a + Math.random() * (b - a); }
function sgn() { return Math.random() < 0.5 ? -1 : 1; }
function neutral() { return { x: 0, y: 0, lid: 0, lb: 0, pupil: 0, skew: 0, smile: 0, sad: 0, twist: 0, tear: 0, veins: 0, shiver: 0, wave: 0, hide: 0, film: 0, bulge: 0, om: 22 }; }

var ACTS = {
  laugh: { name: 'Смеётся', e: [0.35, 1], w: 3, steps: () => [
    { t: 0.3, x: 0, y: -0.05, lid: -0.1, pupil: 0.15, om: 26 },
    { t: 2.2, smile: 1, wave: p => Math.sin(p * 10 * Math.PI), lid: p => 0.1 + 0.06 * Math.sin(p * 10 * Math.PI), pupil: 0.1, y: -0.12, bob: p => [0, -0.035 * Math.abs(Math.sin(p * 10 * Math.PI)) * (1 - 0.3 * p)] },
    { t: 0.5, smile: 0.7, wave: 0, lid: 0.06, tear: p => 0.1 * p },
    { t: 0.8, smile: p => 0.7 * (1 - p), lid: p => 0.06 + 0.05 * Math.abs(Math.sin(p * 4 * Math.PI)), tear: 0.1, bob: p => [0, -0.02 * Math.abs(Math.sin(p * 4 * Math.PI)) * (1 - p)] },
    { t: 0.4, smile: 0, lid: 0, tear: 0, pupil: 0, y: 0, blink: 'normal' }] },
  surprise: { name: 'Удивляется', e: [0.3, 1], w: 2.5, steps: () => { const d = sgn(), x = 0.7 * d, y = R(-0.3, 0.2); return [
    { t: 0.5, x, y, om: 24 }, { t: 0.45, x: -0.2 * d, y: 0.05, om: 20 },
    { t: 0.12, x, y, om: 46, lid: -0.26, pupil: 0.3, bulge: 1, pulse: true, kick: 0.1 }, { t: 0.9 }, { t: 0.3, blink: 'double', bulge: 0 },
    { t: 0.7, lid: 0.18, lb: 0.22, pupil: -0.22, twist: p => 0.5 * Math.sin(p * Math.PI) }, { t: 0.5, lid: -0.2, lb: 0, pupil: 0.25 },
    { t: 0.6, x: 0, y: 0, lid: 0, pupil: 0, om: 20 }]; } },
  fear: { name: 'Пугается', e: [0.35, 1], w: 2, steps: () => { const d = sgn(); return [
    { t: 0.12, lid: -0.26, pupil: -0.34, burst: 0.75, x: 0, y: 0, om: 44, pulse: true }, { t: 0.9, shiver: 1 },
    { t: 0.28, x: -0.75 * d, y: 0.05, shiver: 0.6 }, { t: 0.28, x: 0.75 * d, y: 0.05 }, { t: 0.3, x: 0, y: -0.45 },
    { t: 0.7, lid: 0.97, lb: 0.6, shiver: 0.4, hide: 1, x: 0, y: 0.1 },
    { t: 0.7, lid: 0.7, lb: 0.5, shiver: 0, hide: 0.55, x: -0.5 * d, y: 0, pupil: -0.2, om: 10 }, { t: 0.6, x: 0.5 * d },
    { t: 0.8, lid: 0.05, lb: 0, hide: 0, x: 0, y: 0, pupil: 0, om: 18 }, { t: 0.4, lid: 0, blink: 'slow' }]; } },
  angry: { name: 'Злится', e: [0.4, 1], w: 2, steps: () => [
    { t: 0.5, x: 0, y: 0, lid: 0.06, pupil: -0.1, om: 30 },
    { t: 0.25, lid: 0.3, lb: 0.34, pupil: -0.32, veins: 1 },
    { t: 1.8, shiver: p => 0.4 + 0.6 * p, lid: p => 0.3 + 0.04 * p, lb: p => 0.34 + 0.06 * p },
    { t: 0.16, burst: 0.55, blink: 'hard', shiver: 0 },
    { t: 0.9, x: 0.6 * sgn(), y: -0.25, lid: 0.16, lb: 0.1, pupil: -0.1, veins: 0.5, om: 16 },
    { t: 0.6, x: 0, y: 0, lid: 0, lb: 0, pupil: 0, veins: 0 }] },
  sad: { name: 'Грустит', e: [0.08, 0.7], w: 2.5, steps: () => { const d = sgn(); return [
    { t: 0.6, x: 0, y: 0, lid: -0.03, om: 14 },
    { t: 1.5, x: 0.28 * d, y: 0.6, sad: 1, lid: 0.12, lb: 0.08, pupil: 0.22, om: 4.5, bob: p => [0, 0.035 * p] },
    { t: 1.7, lb: p => 0.1 + 0.035 * Math.sin(p * 22 * Math.PI) * Math.sin(p * Math.PI), bob: p => [0, 0.035 - 0.014 * Math.max(0, Math.sin(p * 4 * Math.PI)) ** 6] },
    { t: 0.5, blink: 'slow', lb: 0.1, bob: () => [0, 0.035] },
    { t: 1.5, x: 0, y: -0.28, lid: -0.04, lb: 0.14, pupil: 0.34, om: 6, bob: p => [0, 0.035 - 0.02 * p] },
    { t: 0.9, x: -0.3 * d, y: 0.45, lid: 0.16, pupil: 0.2, om: 5, bob: p => [0, 0.015 + 0.03 * Math.sin(p * Math.PI)] },
    { t: 0.4, blink: 'slow', bob: () => [0, 0.015] },
    { t: 0.9, x: 0, y: 0, sad: 0, lid: 0, lb: 0, pupil: 0, om: 12, bob: p => [0, 0.015 * (1 - p)] }]; } },
  disgust: { name: 'Брезгует', e: [0.25, 0.9], w: 2, steps: () => { const d = sgn(); return [
    { t: 0.5, x: 0.45 * d, y: 0.5, om: 22 }, { t: 0.35, lid: 0.06, pupil: -0.1 },
    { t: 0.3, lid: 0.34, lb: 0.5, skew: -0.7 * d, pupil: -0.25, x: -0.35 * d, y: -0.1, om: 30 }, { t: 0.5, shiver: 0.8 },
    { t: 0.9, shiver: 0, x: -0.7 * d, y: -0.3, om: 9 }, { t: 0.3, blink: 'slow' },
    { t: 0.6, x: 0, y: 0, lid: 0, lb: 0, skew: 0, pupil: 0, om: 18 }]; } },
  fly: { name: 'Муха', g: true, e: [0.5, 1], w: 3, steps: () => { const a = R(0, 6), b = R(0, 6), c = R(0, 6), hx = R(-0.3, 0.3), hy = R(-0.1, 0.2); return [
    { t: 2.6, path: p => [0.8 * Math.sin(7 * p + a) * Math.cos(3 * p + b), 0.5 * Math.sin(9 * p + c)], om: 36, lid: -0.08, pupil: -0.1 },
    { t: 0.9, path: p => [hx + 0.07 * Math.cos(26 * p), hy + 0.05 * Math.sin(26 * p)], om: 40, lid: 0.14, lb: 0.26, pupil: -0.22 },
    { t: 0.16, blink: 'hard', burst: 0.3, bob: p => [0, 0.03 * Math.sin(p * Math.PI)] },
    { t: 1.1, smile: 0.9, lid: 0.05, lb: 0, pupil: 0.1, x: 0, y: 0, om: 20 }, { t: 0.3, smile: 0, lid: 0, pupil: 0 }]; } },
  hunt: { name: 'Охота на курсор', e: [0.45, 1], w: 2.5, steps: () => [
    { t: 0.6, lid: 0.25, lb: 0.28, pupil: -0.15, toward: 0.3, om: 12 }, { t: 0.7, toward: 0.6 }, { t: 0.6, toward: 0.85 },
    { t: 0.5, bob: p => [0.02 * Math.sin(p * 8 * Math.PI), 0] },
    { t: 0.16, toward: 1, lid: -0.22, lb: 0, pupil: 0.3, om: 46, burst: 0.3, pulse: true }, { t: 0.9 },
    { t: 0.7, x: 0, y: 0, lid: 0.05, pupil: 0, skew: 0.3, om: 16 }, { t: 0.3, skew: 0, lid: 0 }] },
  contest: { name: 'Гляделки', e: [0.3, 1], w: 2, steps: () => [
    { t: 0.5, x: 0, y: 0, lid: 0.06, om: 26 }, { t: 2.4, lid: 0.1, pupil: -0.18, tear: p => 0.1 * p },
    { t: 1.0, shiver: p => 0.3 + 0.7 * p, lb: 0.12 }, { t: 0.16, blink: 'hard', shiver: 0, tear: 0 },
    { t: 0.9, x: 0.55 * sgn(), y: 0.3, skew: 0.4, lid: 0.16, lb: 0, pupil: 0, om: 14 }, { t: 0.4, x: 0, y: 0, skew: 0, lid: 0 }] },
  spin: { name: 'Вращает зрачком', e: [0.55, 1], w: 2, steps: () => { const d = sgn(); return [
    { t: 2.2, path: p => { const a = p * p * 3 * TAU * d; return [0.6 * Math.cos(a), 0.48 * Math.sin(a)]; }, om: 40, lid: -0.1 },
    { t: 1.6, path: p => { const a = p * 3 * TAU * d, k = 0.2 * (1 - p); return [k * Math.cos(a), k * Math.sin(a)]; }, twist: p => Math.sin(p * 3 * TAU) * (1 - p), lid: p => 0.1 + 0.07 * Math.sin(p * 9 * Math.PI) * (1 - p), om: 26 },
    { t: 0.35, blink: 'double', x: 0, y: 0, twist: 0, lid: 0 }, { t: 0.5, bob: p => [0.025 * Math.sin(p * 4 * Math.PI) * (1 - p), 0] }]; } },
  roll: { name: 'Закатывает глаза', e: [0.25, 1], w: 2, steps: () => { const d = sgn(); return [
    { t: 0.5, x: 0, y: 0, lid: 0.14, lb: 0.1, pupil: -0.08, om: 24 }, { t: 0.3, x: -0.55 * d, y: 0.1, om: 22 },
    { t: 1.3, path: p => [-0.6 * d * Math.cos(Math.PI * p), 0.1 - 0.9 * Math.sin(Math.PI * p)], lid: -0.16, lb: 0, om: 30 },
    { t: 0.6, lid: 0.1 }, { t: 0.5, x: 0, y: 0, lid: 0, pupil: 0, blink: 'slow' }]; } },
  suspect: { name: 'Подозревает', e: [0.2, 0.9], w: 2, steps: () => { const d = sgn(); return [
    { t: 0.5, lid: 0.26, lb: 0.32, pupil: -0.12, x: 0, y: 0 }, { t: 1.5, x: -0.78 * d, y: 0.05, om: 7, skew: -0.6 * d }, { t: 0.8 },
    { t: 0.14, x: 0.78 * d, y: 0.05, om: 46, skew: 0.5 * d, lid: 0.1, lb: 0.1, pupil: 0, pulse: true }, { t: 0.9 },
    { t: 0.6, x: 0, y: 0, skew: 0, lid: 0, lb: 0, om: 18 }]; } },
  around: { name: 'Осматривается', e: [0.3, 1], w: 2.5, steps: () => { const s = [], pts = [[-0.85, -0.45], [0.85, -0.4], [0.8, 0.45], [-0.8, 0.4], [0, -0.6]].sort(() => Math.random() - 0.5).slice(0, 3);
    pts.forEach((q, i) => s.push({ t: 0.35, x: q[0], y: q[1], om: 28, lid: -0.04, lb: 0, pupil: 0.05 }, i === 1 ? { t: 1.0, lid: 0.2, lb: 0.25, pupil: -0.2 } : { t: R(0.4, 0.7) }));
    s.push({ t: 0.5, x: 0, y: 0, lid: 0, lb: 0, pupil: 0, blink: 'normal' }); return s; } },
  dream: { name: 'Задумался', e: [0.12, 0.7], w: 2.5, steps: () => [
    { t: 5.5, path: p => [0.55 * Math.sin(TAU * p), -0.3 + 0.22 * Math.sin(2 * TAU * p)], om: 6, lid: 0.14, pupil: 0.16 },
    { t: 0.9, x: 0, y: -0.1, smile: 0.5, lid: 0.1 }, { t: 0.4, smile: 0, lid: 0, pupil: 0, y: 0, blink: 'double' }] },
  yawn: { name: 'Зевает', g: true, e: [0.05, 0.55], w: 3, steps: () => [
    { t: 0.9, lid: -0.12, pupil: 0.15, x: 0, y: -0.15, om: 8, bob: p => [0, -0.03 * p] },
    { t: 1.0, lid: 0.74, lb: 0.6, om: 6, tear: p => 0.1 * p, bob: () => [0, -0.03] }, { t: 1.1, bob: p => [0, -0.03 * (1 - p)] },
    { t: 0.9, lid: 0.1, lb: 0, tear: p => 0.1 * (1 - p) }, { t: 0.3, blink: 'double', tear: 0 }, { t: 0.6 }] },
  nod: { name: 'Клюёт носом', e: [0, 0.35], w: 4, steps: () => [
    { t: 2.4, lid: 0.62, y: 0.3, x: 0, om: 4, pupil: 0.2, bob: p => [0, 0.06 * p * p] }, { t: 0.8, lid: 0.74, bob: p => [0, 0.06 + 0.02 * p] },
    { t: 0.12, lid: -0.2, burst: 0.4, pupil: -0.25, om: 42, y: -0.1, bob: p => [0, 0.08 * (1 - p)] },
    { t: 0.3, x: -0.5 }, { t: 0.3, x: 0.5 }, { t: 0.9, x: 0, y: 0, lid: 0.05, pupil: 0, om: 14 }] },
  shake: { name: 'Встряхивается', e: [0, 0.4], w: 2, steps: () => [
    { t: 0.7, lid: -0.1, path: p => [0.25 * Math.sin(p * 6 * Math.PI) * (1 - p), 0], bob: p => [0.05 * Math.sin(p * 6 * Math.PI) * (1 - p), 0], om: 40 },
    { t: 0.3, blink: 'double', x: 0, y: 0 }, { t: 0.7, lid: -0.06, pupil: -0.05 }] },
  // --- номера с характером: играют только там, где образ их назвал ---
  sun: { name: 'Греется на солнце', e: [0.2, 1], w: 0, steps: () => [
    { t: 0.9, x: 0.25, y: -0.7, lid: -0.05, pupil: -0.12, om: 8 }, { t: 0.5, lid: 0.3, lb: 0.2 },
    { t: 3.2, smile: 1, lid: 0.9, lb: 0.5, wave: p => 0.5 + 0.5 * Math.sin(p * 4 * Math.PI), bob: p => [0.03 * Math.sin(p * 4 * Math.PI), -0.02] },
    { t: 0.6, smile: 0.4, lid: 0.1, lb: 0, wave: 0 }, { t: 0.5, smile: 0, lid: 0, pupil: 0, x: 0, y: 0, blink: 'normal' }] },
  hello: { name: 'Машет', e: [0.4, 1], w: 0, steps: () => [
    { t: 0.4, x: 0, y: 0, lid: -0.1, pupil: 0.12, om: 26 },
    { t: 1.8, smile: 0.7, wave: p => Math.sin(p * 9 * Math.PI) * (1 - 0.3 * p), bob: p => [0, -0.02 * Math.abs(Math.sin(p * 9 * Math.PI))] },
    { t: 0.5, smile: 0, wave: 0, lid: 0, pupil: 0, blink: 'normal' }] },
  drift: { name: 'Зрачок уплыл', e: [0, 1], w: 0, steps: () => { const d = sgn(); return [
    { t: 0.6, x: 0, y: 0, om: 10 }, { t: 2.6, path: p => [0.75 * d * p * p, 0.35 * p], om: 3, lid: 0.08, pupil: 0.1 }, { t: 0.9 },
    { t: 0.14, x: 0, y: 0, om: 46, bulge: 0.6, blink: 'hard' }, { t: 0.8, bulge: 0, lid: 0, pupil: 0 }]; } },
  twitch: { name: 'Дёргается', e: [0, 1], w: 0, steps: () => [
    { t: 0.5, x: 0, y: 0 }, { t: 0.9, shiver: 0.9, lid: p => 0.1 + 0.25 * Math.abs(Math.sin(p * 7 * Math.PI)), wave: p => Math.sin(p * 14 * Math.PI) },
    { t: 0.5, shiver: 0, lid: 0, wave: 0 }, { t: 0.5, shiver: 0.7, lid: p => 0.3 * Math.abs(Math.sin(p * 5 * Math.PI)), wave: p => Math.sin(p * 10 * Math.PI) }, { t: 0.5, shiver: 0, lid: 0, wave: 0 }] },
  brains: { name: 'Тянется к курсору', e: [0.1, 1], w: 0, steps: () => [
    { t: 1.6, toward: 0.5, om: 3, lid: 0.1, pupil: 0.15 }, { t: 1.6, toward: 0.9, bulge: 0.5, om: 3 },
    { t: 1.4, toward: 1, bulge: 1, pupil: 0.3, lid: -0.1, bob: p => [0, 0.015 * Math.sin(p * 6 * Math.PI)] },
    { t: 0.9, bulge: 0, x: 0, y: 0.1, lid: 0.2, pupil: 0, om: 6 }, { t: 0.5, lid: 0 }] },
  popeye: { name: 'Глаз выпучился', e: [0.2, 1], w: 0, steps: () => [
    { t: 0.5, x: 0, y: 0, lid: 0.15 }, { t: 0.18, bulge: 1, lid: -0.3, pupil: -0.3, om: 40, pulse: true }, { t: 1.2, shiver: 0.3 },
    { t: 0.9, bulge: 0, shiver: 0, lid: 0.1, pupil: 0 }, { t: 0.4, lid: 0, blink: 'slow' }] },
  slowblink: { name: 'Медленно жмурится', e: [0.1, 1], w: 0, steps: () => [
    { t: 0.6, x: 0, y: 0, om: 8, pupil: 0.15 }, { t: 1.1, lid: 0.95, lb: 0.4, smile: 0.5, om: 6 }, { t: 0.9 },
    { t: 1.0, lid: 0.12, lb: 0, smile: 0.3 }, { t: 0.6, smile: 0, lid: 0, pupil: 0 }] },
  stargaze: { name: 'Смотрит вдаль', e: [0.1, 0.8], w: 0, steps: () => { const d = sgn(); return [
    { t: 1.4, x: 0.45 * d, y: -0.6, om: 4, lid: -0.06, pupil: 0.35 }, { t: 3.0, twist: p => 0.6 * Math.sin(p * Math.PI), wave: p => 0.4 * Math.sin(p * 2 * Math.PI) },
    { t: 0.5, film: p => Math.sin(p * Math.PI) }, { t: 0.9, x: 0, y: 0, lid: 0, pupil: 0, twist: 0, wave: 0, film: 0, om: 8 }]; } },
  bristle: { name: 'Шерсть дыбом', e: [0.4, 1], w: 0, steps: () => { const d = sgn(); return [
    { t: 0.12, lid: -0.2, pupil: -0.4, burst: 0.9, x: 0.6 * d, y: 0, om: 44 }, { t: 1.3, shiver: 0.5 },
    { t: 0.9, shiver: 0, x: 0, y: 0, lid: 0, pupil: 0.1, om: 12 }, { t: 0.5, pupil: 0, film: p => Math.sin(p * Math.PI) }, { t: 0.2, film: 0 }]; } },
  sweep: { name: 'Смотрит по сторонам', e: [0, 1], w: 0, steps: () => { const d = sgn(), a = R(0.55, 1), b = R(0.3, 0.6), y = R(-0.5, 0.5); return [
    { t: R(0.9, 1.4), x: a * d, y: y * a, om: 5 }, { t: R(0.25, 0.5) },
    { t: R(0.85, 1.4), x: -b * d, y: -y * b, om: 5 }, { t: R(0.22, 0.48) },
    { t: R(1.1, 1.7), x: 0, y: 0, om: 4.5 }]; } },
  wake: { name: 'Просыпается', hidden: true, steps: () => [{ t: 0.25, lid: -0.2, pupil: -0.2, x: 0, y: 0, om: 40 }, { t: 0.32, x: -0.6, y: 0.04 }, { t: 0.32, x: 0.6, y: 0.04 }, { t: 0.3, x: 0, y: 0, lid: 0, pupil: 0, blink: 'normal' }] },
};

// Выбор следующего номера по бодрости e; skip — недавно сыгранные; weights — веса из характера образа
// (номер без веса не играется). Без характера играются номера с собственным весом.
function weightOf(id, weights) { return weights ? (weights[id] || 0) : ACTS[id].w; }
function pick(e, skip, weights) {
    function fits(no) {
        var out = [];
        for (var id in ACTS) { var a = ACTS[id]; if (!a.hidden && weightOf(id, weights) > 0 && no.indexOf(id) < 0 && e >= a.e[0] && e <= a.e[1]) out.push(id); }
        return out;
    }
    var pool = fits(skip);
    if (!pool.length) pool = fits(skip.slice(-1));
    if (!pool.length) pool = fits([]);                    // у образа всего один номер: пусть повторяется
    if (!pool.length) return "";
    var total = 0, i;
    for (i = 0; i < pool.length; i++) total += weightOf(pool[i], weights);
    var r = Math.random() * total;
    for (i = 0; i < pool.length; i++) { r -= weightOf(pool[i], weights); if (r <= 0) return pool[i]; }
    return pool[pool.length - 1];
}
// Список номеров образа для пульта: [{ id, name }].
function listFor(weights, names) {
    var out = [];
    for (var id in ACTS) if (!ACTS[id].hidden && weightOf(id, weights) > 0) out.push({ id: id, name: (names && names[id]) || ACTS[id].name });
    return out;
}
