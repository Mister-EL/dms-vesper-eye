import QtQuick
import "Acts.js" as Acts

// Жизнь глаза: взгляд, веки, зрачок, мимика, скука и номера, которыми он себя занимает.
// Один кадровый цикл, который идёт, только пока глаз виден и не спит. Когда всё улеглось,
// значения перестают меняться и оболочка ничего не перерисовывает.
//
// Скука: пока человек ничего не делает, копится bored. Сначала глаз бодр и играет резвые номера,
// потом скучает, клюёт носом и через showSeconds засыпает. Любой ввод будит.
Item {
    id: root
    // --- входы ---
    property bool active: true            // глаз виден (не закрыт окнами, экран не заблокирован)
    property bool userIdle: false         // человек ничего не трогает
    property bool reducedMotion: false
    property bool eco: false              // без дыхания и подрагивания
    property bool showEnabled: true       // развлекать себя, пока человек бездействует
    property bool lowBattery: false       // батарея на исходе
    property bool forceTired: false       // то же, но по кнопке пульта
    readonly property bool tired: (lowBattery || forceTired) && !plain
    // Характер образа: tempo — темп номеров, omega — резвость взгляда (множители), lag — вялость слежения в секундах,
    // blink — [от, до] мс между морганиями, blinkKind — "lid" | "film" (третье веко) | "lazy", acts — веса номеров.
    // plain — простой глаз: только слежение, моргание и номера из acts; не реагирует на события и не засыпает,
    // а через dozeAfter секунд без человека прикрывает верхнее веко (drowsyLid — насколько). actGap — [от, до] мс между номерами.
    property var character: ({})
    function ch(key, fallback) { const v = character ? character[key] : undefined; return v === undefined ? fallback : v; }
    readonly property bool plain: !!ch("plain", false)
    property bool onBattery: false
    property bool followCursor: true
    property bool hasTarget: false        // позиция указателя известна
    property real targetDx: 0             // указатель относительно центра глаза, пиксели
    property real targetDy: 0
    property bool hover: false            // указатель над самим глазом
    property real unit: 100
    property int fpsCap: 60
    property real restLid: 0.22
    // Какая часть глаза видна из-за окон и где её середина (в единицах глаза).
    property real visFrac: 1
    property real visX: 0
    property real visY: 0

    // --- выходы ---
    property real gazeX: 0
    property real gazeY: 0
    property real lagX: 0
    property real lagY: 0
    property real lidTop: 1
    property real lidBot: 1
    property real pupil: 1
    property real wake: 0
    property real pulse: 0
    property real dim: 1
    property vector4d mood: Qt.vector4d(0, 0, 0, 0)     // тревога, усталость, закрутка, влага
    property vector4d face: Qt.vector4d(0, 0, 0, 0)     // перекос, улыбка, печаль
    property real bobX: 0                                // сдвиг всего глаза, в единицах
    property real bobY: 0
    property vector4d pose: Qt.vector4d(0, 0, 0, 0)     // жест придатков, «спрятался», третье веко, выпученность
    property real clock: 0                               // секунды, пока идут кадры: для покачивания листьев и шерсти
    readonly property bool asleep: bored >= showSeconds && !plain
    readonly property bool dozing: bored >= showSeconds && plain    // простой глаз не спит, а дремлет с прикрытым веком
    readonly property real energy: Math.min(tired ? 0.42 : 1, 1 - bored / showSeconds)
    readonly property string actName: _act
    // От батареи и без игры засыпает быстрее.
    readonly property real showBase: Math.max(10, ch("dozeAfter", 600))
    readonly property real showSeconds: Math.min(showBase, !showEnabled || reducedMotion ? 70 : tired ? 240 : onBattery ? 180 : 600)
    property real bored: 0
    property real timeScale: 1            // для тестов

    // --- внутреннее состояние (не свойства: меняется каждый кадр) ---
    property string _act: ""
    property var s: ({ gx: 0, gy: 0, vx: 0, vy: 0, px: 0, py: 0, lid: 1, lb: 1, pupil: 1, pupilLag: 1, alert: 0, sleep: 1, hold: 0, blink: 0, kick: 0,
        wake: 0, pulse: 0, fatigue: 0, skew: 0, smile: 0, sad: 0, tear: 0, pvx: 0, pvy: 0, lastDx: 0, lastDy: 0, lastPtr: 0, moved: 0,
        env: { t0: -1e12, peak: 0, hold: 0 }, glance: { x: 0, y: 0, until: 0 }, micro: { x: 0, y: 0, next: 0 }, hip: { t0: -1e12, amp: 0, next: 0 },
        blinkA: null, filmA: null, lastBlink: 0, nextBlink: 0, lastTx: 0, lastTy: 0, pupilKick: -1e12, held: false, wasBusy: true,
        steps: null, i: 0, t0: 0, dur: 0, cur: null, path: null, bob: null, toward: null, fast: false, nextAt: 1e15, hist: [], locked: false, last: 0, acc: 0 })

    property real testClock: -1           // тесты двигают время сами
    function now() { return testClock >= 0 ? testClock : Date.now(); }
    function toGaze(dx, dy) { const n = Math.hypot(dx, dy, 2.2 * unit); return [dx / n, dy / n]; }
    function flash(peak, hold) { s.env.t0 = now(); s.env.peak = peak; s.env.hold = hold; }
    function blink(kind) {
        const t = now();
        if (s.sleep > 0.3 || s.held || reducedMotion || (s.blinkA && t - s.blinkA.t0 < 400)) return;
        s.lastBlink = t;
        const style = ch("blinkKind", "lid");
        // Третье веко: обычное моргание — плёнка сбоку, веки при этом лишь прикрываются.
        if (style === "film" && (kind === "normal" || kind === "double")) { s.filmA = { t0: t, dur: 320 }; if (Math.random() < 0.75) return; }
        let b = kind === "slow" ? [150, 130, 330] : kind === "hard" ? [50, 110, 140] : [70, 45, 150];
        if (style === "lazy") b = [b[0] * 2.6, b[1] * 2.2, b[2] * 2.4];             // вялое моргание
        s.blinkA = { t0: t, close: b[0], hold: b[1], open: b[2], again: kind === "double" };
    }
    // --- номера ---
    function play(id, locked) {
        if (!Acts.ACTS[id]) return;
        _act = id; s.steps = Acts.ACTS[id].steps(); s.i = -1; s.cur = Acts.neutral(); s.path = null; s.toward = null; s.locked = !!locked;
        step(now());
    }
    function stop(t) {
        if (_act) { s.hist.push(_act); if (s.hist.length > 5) s.hist.shift(); }
        _act = ""; s.locked = false; s.bob = null;
        const gap = ch("actGap", null);
        s.nextAt = t + (gap ? Acts.R(gap[0], gap[1]) : Acts.R(1200, 2600) + (1 - energy) * Acts.R(2500, 6000));
    }
    function step(t) {
        const A = s.cur;
        if (s.path) { const p = s.path(1); A.x = p[0]; A.y = p[1]; }             // взгляд остаётся там, куда привёл путь
        for (const key of Acts.CHANNELS) if (typeof A[key] === "function") A[key] = A[key](1);
        if (++s.i >= s.steps.length) { stop(t); return; }
        const st = s.steps[s.i];
        s.t0 = t; s.dur = st.t * 1000 / (0.62 + 0.5 * Math.max(0.2, energy)) / ch("tempo", 1);   // сонный всё делает медленнее
        for (const key of ["x", "y", "om"].concat(Acts.CHANNELS)) if (st[key] !== undefined) A[key] = st[key];
        s.path = st.path || null; s.bob = st.bob || null;
        if (st.toward !== undefined) s.toward = st.toward; else if (st.x !== undefined || st.path) s.toward = null;
        s.fast = Acts.CHANNELS.some(key => typeof A[key] === "function");
        if (st.blink) blink(st.blink);
        if (st.burst) flash(st.burst, 0.25);
        if (st.pulse) s.pulse = 0.001;
        if (st.kick) s.kick = st.kick;
    }
    // --- события снаружи ---
    function wakeUp(deep) { if (plain) { blink("double"); return; } s.wake = deep ? 1 : 0.35; play(deep ? "wake" : "shake", true); }
    function activity() {                                      // человек что-то сделал
        if (bored > 0) { const deep = asleep, sleepy = energy < 0.45; bored = 0; if (active && !reducedMotion && (deep || sleepy)) wakeUp(deep); }
        if (_act && !s.locked) stop(now());
        kickLoop();
    }
    function cursorMoved() { s.moved = now(); activity(); }
    function look(x, y, ms) {                                  // короткий взгляд в сторону события
        if (!active || reducedMotion || plain) return;
        if (asleep) { bored = 0; wakeUp(true); }
        if (_act && !s.locked) stop(now());
        s.glance.x = x; s.glance.y = y; s.glance.until = now() + (ms || 1600); kickLoop();
    }
    function notify(x, y) { if (plain) return; look(x, y, 1700); s.pupilKick = now(); s.pulse = 0.001; }
    function press() { if (active && !asleep && !plain) { s.held = true; activity(); } }
    function release() { s.held = false; kickLoop(); }
    function surprise() { if (!active || reducedMotion || plain) return; s.wake = 0.7; s.pupilKick = now(); s.kick = 0.14; activity(); }
    function reveal() {                                        // глаз снова виден: открыться
        if (reducedMotion) { kickLoop(); return; }
        s.wake = 1; s.sleep = Math.max(s.sleep, 0.6); kickLoop();
    }
    function kickLoop() { quiet = false; }
    // Для пульта и команд: сыграть номер сейчас, усыпить, разбудить.
    function demo(id) { if (!Acts.ACTS[id]) return false; if (asleep) bored = showSeconds * 0.5; play(id, true); kickLoop(); return true; }
    function sleepNow() { if (_act) stop(now()); bored = showSeconds; kickLoop(); }
    function wakeNow() { if (bored > 0) { const deep = asleep; bored = 0; if (active && !reducedMotion) wakeUp(deep); } kickLoop(); }
    onActiveChanged: if (active) reveal()
    onUserIdleChanged: if (!userIdle) activity(); else { s.nextAt = now() + (plain ? Acts.R(3500, 8000) : 1400); kickLoop(); }
    onTiredChanged: if (tired && active) { flash(0.6, 0.7); kickLoop(); }
    onVisFracChanged: kickLoop()
    onTargetDxChanged: kickLoop()
    onTargetDyChanged: kickLoop()
    onHoverChanged: kickLoop()

    property bool quiet: false            // всё улеглось: кадры не нужны
    FrameAnimation { id: loop; running: root.active && !root.quiet; onTriggered: root.frame(frameTime) }
    // Во сне и в покое кадров нет; будит таймер моргания или событие.
    Timer { interval: 1000; repeat: true; running: root.active && root.quiet && !root.asleep; onTriggered: root.kickLoop() }

    function q(v, stepSize) { return Math.round(v / stepSize) * stepSize; }
    function frame(frameDt) {
        const t = now();
        // Предел кадров: шаг считается не чаще заданного.
        s.acc += Math.min(0.1, frameDt);
        const minStep = fpsCap > 0 ? 1 / fpsCap : 0;
        if (s.acc + 0.0005 < minStep) return;
        const dt = Math.min(0.05, s.acc); s.acc = 0;
        const k = tau => 1 - Math.exp(-dt / tau);
        const busy = !userIdle;
        // Скука копится, пока человек бездействует, — по часам, а не по кадрам: в покое кадров почти нет.
        const real = Math.min(2, Math.max(dt, (t - (s.last || t)) / 1000)); s.last = t;
        if (!busy) bored = Math.min(showSeconds, bored + real * timeScale);
        const E = energy, sleeping = asleep, drowsy = Acts.clamp((0.4 - E) / 0.4, 0, 1);
        if (sleeping && _act) stop(t);
        if (!busy && !sleeping && !_act && showEnabled && !reducedMotion && t > s.nextAt && t > s.glance.until) { const id = Acts.pick(E, s.hist, ch("acts", null)); if (id) play(id, false); }
        if (_act && t - s.t0 >= s.dur) step(t);
        const actP = _act ? Acts.clamp((t - s.t0) / s.dur, 0, 1) : 0;
        const av = key => { if (!_act) return 0; const v = s.cur[key]; return typeof v === "function" ? v(actP) : v; };

        // Скорость указателя: чтобы взгляд чуть опережал его.
        if (targetDx !== s.lastDx || targetDy !== s.lastDy) {
            const d = Math.max(0.008, (t - s.lastPtr) / 1000);
            s.pvx += ((targetDx - s.lastDx) / d - s.pvx) * 0.5; s.pvy += ((targetDy - s.lastDy) / d - s.pvy) * 0.5;
            s.lastDx = targetDx; s.lastDy = targetDy; s.lastPtr = t;
        }
        s.pvx *= Math.exp(-dt / 0.1); s.pvy *= Math.exp(-dt / 0.1);
        // Указатель опрашивается 20–30 раз в секунду: между отсчётами его позиция досчитывается плавно.
        if (s.sx === undefined) { s.sx = targetDx; s.sy = targetDy; }
        const lagTau = 0.045 + ch("lag", 0);
        s.sx += (targetDx - s.sx) * k(lagTau); s.sy += (targetDy - s.sy) * k(lagTau);

        // Куда смотреть: сон, событие, номер, указатель, покой.
        let tx = 0, ty = 0, om = 22, mode = "rest";
        if (sleeping) { ty = 0.15; mode = "sleep"; }
        else if (t < s.glance.until) { tx = s.glance.x; ty = s.glance.y; om = 30; mode = "glance"; }
        else if (_act) {
            om = s.cur.om; mode = "act";
            if (s.path) { const p = s.path(actP); tx = p[0]; ty = p[1]; }
            else if (s.toward !== null) { const g = hasTarget ? toGaze(s.sx, s.sy) : [0.6, 0.4]; tx = g[0] * s.toward; ty = g[1] * s.toward; }
            else { tx = s.cur.x; ty = s.cur.y; }
        } else if (busy && hasTarget && followCursor) { const g = toGaze(s.sx, s.sy); tx = g[0]; ty = g[1]; mode = "follow"; }
        else ty = 0.14 * drowsy;
        // Если часть глаза закрыта окном, зрачок переезжает туда, где его видно.
        const peek = Acts.clamp((0.92 - visFrac) / 0.45, 0, 1);
        if (peek > 0 && visFrac > 0) { tx += (Acts.clamp(visX / 1.10, -1, 1) - tx) * peek; ty += (Acts.clamp((visY + 0.05) / 0.26, -1, 1) - ty) * peek * 0.7; }
        // Большой перевод взгляда человек делает с морганием.
        if (!sleeping && mode !== "act" && Math.hypot(tx - s.lastTx, ty - s.lastTy) > 0.45 && t - s.lastBlink > 900) blink(tired ? "slow" : "normal");
        s.lastTx = tx; s.lastTy = ty;
        // Пока взгляд стоит, живой глаз чуть подрагивает.
        const lively = !eco && !reducedMotion && !plain;
        if (lively) {
            if (t > s.micro.next) { s.micro.x = (Math.random() - 0.5) * 0.04; s.micro.y = (Math.random() - 0.5) * 0.024; s.micro.next = t + 350 + Math.random() * 1300; }
            if (!sleeping && (mode === "rest" || mode === "glance" || (mode === "follow" && Math.hypot(s.pvx, s.pvy) < 40))) { tx += s.micro.x; ty += s.micro.y; }
        }
        om *= ch("omega", 1);
        if (reducedMotion) { s.gx = tx; s.gy = ty; s.vx = 0; s.vy = 0; s.px = tx; s.py = ty; }
        else {
            s.vx += (om * om * (tx - s.gx) - 2 * om * s.vx) * dt; s.vy += (om * om * (ty - s.gy) - 2 * om * s.vy) * dt;
            s.gx += s.vx * dt; s.gy += s.vy * dt; s.px += (s.gx - s.px) * k(0.09); s.py += (s.gy - s.py) * k(0.09);
        }
        // Вспышка лучей: вверх, держится, гаснет.
        const e = (t - s.env.t0) / 1000, V = s.env;
        const burst = e < 0 ? 0 : e < 0.12 ? V.peak * e / 0.12 : e < 0.12 + V.hold ? V.peak : V.peak * Math.max(0, 1 - (e - 0.12 - V.hold) / 0.5);
        s.alert += (burst - s.alert) * k(0.045);
        // Веки и мимика.
        const baseLid = tired ? 0.40 : restLid, baseLb = tired ? 0.04 : 0;
        const quick = !_act ? 0.13 : s.fast ? 0.03 : 0.075, shiver = av("shiver");
        const lidT = baseLid + ch("drowsyLid", 0.42) * drowsy * drowsy + av("lid") - (burst > 0.02 ? 0.1 : 0) + (mode === "rest" ? 0.04 : 0) - (hover && !plain ? 0.05 : 0);
        s.lid += (Acts.clamp(lidT, 0.02, 0.97) - s.lid) * k(quick); s.lb += (Math.max(baseLb, av("lb")) - s.lb) * k(quick);
        s.skew += (av("skew") - s.skew) * k(0.11); s.smile += (av("smile") - s.smile) * k(s.fast ? 0.05 : 0.12); s.sad += (av("sad") - s.sad) * k(0.2);
        const tr = av("tear"); s.tear = tr < s.tear && s.tear <= 0.15 ? s.tear + (tr - s.tear) * k(0.12) : tr;
        s.hold += ((s.held ? 1 : 0) - s.hold) * k(s.held ? 0.05 : 0.07);
        s.kick *= Math.exp(-dt / 0.13);
        // Моргание: по расписанию и по событиям.
        if (!sleeping && !_act && !reducedMotion && t > s.nextBlink) {
            if (s.nextBlink > 0) blink(tired || E < 0.4 ? "slow" : Math.random() < 0.18 ? "double" : "normal");
            const br = ch("blink", [2600, 6800]);
            s.nextBlink = t + br[0] + Math.random() * (br[1] - br[0]);
        }
        const B = s.blinkA;
        if (B) {
            const p = t - B.t0;
            s.blink = p < 0 ? 0 : p < B.close ? p / B.close : p < B.close + B.hold ? 1 : Math.max(0, 1 - (p - B.close - B.hold) / B.open);
            if (p >= B.close + B.hold + B.open) { s.blink = 0; s.kick = 0.04; s.blinkA = B.again ? { t0: t + 70, close: 70, hold: 40, open: 150 } : null; }
        }
        // Зрачок: сужается под указателем, изредка «вздыхает», у сонного шире.
        let hip = 0;
        if (lively) {
            if (t > s.hip.next) { s.hip.t0 = t; s.hip.amp = (Math.random() < 0.5 ? -1 : 1) * 0.04; s.hip.next = t + 3000 + Math.random() * 3500; }
            const hp = (t - s.hip.t0) / 700; hip = hp < 1 ? s.hip.amp * Math.sin(hp * Math.PI) : 0;
        }
        const pupilT = (tired ? 1.05 : 1) + 0.12 * drowsy + av("pupil") + (hover && !plain ? -0.12 : 0) + (t - s.pupilKick < 500 ? 0.1 : 0) + hip + Math.sin(t * 0.07) * 0.03 * shiver;
        s.pupil += (pupilT - s.pupil) * k(0.11); s.pupilLag += (s.pupil - s.pupilLag) * k(0.24);
        const twist = Acts.clamp(Acts.clamp((s.pupil - s.pupilLag) * 4, -0.5, 0.5) + av("twist"), -1, 1);
        s.sleep += ((sleeping ? 1 : 0) - s.sleep) * k(sleeping ? 0.9 : 0.12);
        const veins = Math.max(tired ? 0.9 : 0, av("veins")); s.fatigue += (veins - s.fatigue) * k(av("veins") ? 0.3 : tired ? 1.3 : 0.6);
        s.wake = Math.max(0, s.wake - dt * 1.8);
        if (s.pulse > 0) { s.pulse += dt / 1.0; if (s.pulse >= 1) s.pulse = 0; }
        let film = av("film");
        if (s.filmA) { const fp = (t - s.filmA.t0) / s.filmA.dur; if (fp >= 1) s.filmA = null; else film = Math.max(film, Math.sin(fp * Math.PI)); }
        const breath = lively && !sleeping ? Math.sin(t / 1000 * 1.35) * 0.012 : 0;
        const bob = _act && s.bob ? s.bob(actP) : [0, 0];

        // Выходы. Округляются до шага, который глаз уже не различает: без видимой перемены кадра нет.
        const closed = Math.max(s.blink, s.sleep, s.hold);
        const base = Acts.clamp(s.lid + breath - s.kick, 0, 1);
        const gq = 0.25 / Math.max(unit, 1);
        gazeX = q(s.gx, gq); gazeY = q(s.gy, gq); lagX = q(s.px, gq); lagY = q(s.py, gq);
        lidTop = q(Acts.clamp(base + (1 - base) * closed + Math.max(0, s.gy) * 0.16 - Math.max(0, -s.gy) * 0.03, 0, 1), 0.002);
        lidBot = q(Math.max(s.blink * 0.9, s.sleep, s.hold, s.lb), 0.002);
        pupil = q(s.pupil, 0.002); wake = q(s.wake, 0.01); pulse = q(s.pulse, 0.004); dim = q(1 - 0.35 * s.sleep, 0.01);
        mood = Qt.vector4d(q(s.alert, 0.01), q(s.fatigue, 0.01), q(twist, 0.01), q(s.tear, 0.005));
        face = Qt.vector4d(q(s.skew, 0.01), q(s.smile * (1 - closed), 0.01), q(s.sad, 0.01), 0);
        bobX = q(bob[0] + Math.sin(t * 0.061) * 0.008 * shiver, gq); bobY = q(bob[1] + Math.sin(t * 0.047) * 0.008 * shiver, gq);
        s.hide = (s.hide || 0) + (av("hide") - (s.hide || 0)) * k(0.10); s.bulge = (s.bulge || 0) + (av("bulge") - (s.bulge || 0)) * k(0.06);
        pose = Qt.vector4d(q(av("wave"), 0.01), q(s.hide, 0.01), q(film, 0.01), q(s.bulge, 0.01));
        if (_act || lively || s.filmA) clock = q((t % 3600000) / 1000, 1 / 60);

        // Покой: спит и веки сомкнуты, либо человек занят, указатель стоит и ничего не движется.
        const still = !s.filmA && (s.hide || 0) < 0.01 && (s.bulge || 0) < 0.01 && Math.abs(s.sx - targetDx) + Math.abs(s.sy - targetDy) < 0.5 && Math.abs(s.vx) + Math.abs(s.vy) < 0.002 && Math.abs(tx - s.gx) + Math.abs(ty - s.gy) < 0.002 && !s.blinkA && !_act
            && s.alert < 0.01 && s.wake <= 0 && s.pulse <= 0 && s.kick < 0.002 && Math.abs(s.hold - (s.held ? 1 : 0)) < 0.01
            && Math.abs(s.pupil - pupilT) < 0.001 && Math.abs(s.lid - Acts.clamp(lidT, 0.02, 0.97)) < 0.001 && Math.abs(s.lb - Math.max(baseLb, av("lb"))) < 0.001;
        quiet = sleeping ? s.sleep > 0.995 : (still && !lively && (busy || !showEnabled || reducedMotion || plain) && t >= s.glance.until && Math.abs(s.sleep) < 0.005);
    }
}
