import QtQuick

// Взгляд. Пружина без перерегулирования, шаг — по времени кадра, поэтому траектория
// одинакова на 60 и на 120 Гц. Наружу значения уходят, только когда изменение
// заметно глазу (четверть пикселя): пока его нет, кадр не запрашивается.
Item {
    id: root
    property bool active: true
    property bool reducedMotion: false
    property real unit: 100          // пикселей в единице глаза
    property real omega: 20          // жёсткость пружины, 1/с
    property int fpsCap: 60          // 0 — без ограничения

    // Цель: вектор от центра глаза до указателя, в пикселях.
    property real targetDx: 0
    property real targetDy: 0
    property bool hasTarget: false
    // Временный взгляд в сторону (уведомление, осмотр), от -1 до 1.
    property bool glancing: false
    property real glanceX: 0
    property real glanceY: 0

    // Результат, от -1 до 1.
    property real gazeX: 0
    property real gazeY: 0
    property real lagX: 0
    property real lagY: 0
    readonly property bool moving: anim.running
    readonly property real quantum: 0.25 / Math.max(1, unit)
    property int frames: 0           // счётчик опубликованных кадров (для проверок)

    property real _gx: 0
    property real _gy: 0
    property real _vx: 0
    property real _vy: 0
    property real _lx: 0
    property real _ly: 0
    property real _acc: 0

    function goal() {
        if (glancing) return Qt.point(glanceX, glanceY);
        if (!hasTarget) return Qt.point(0, 0);
        // Указатель лежит на плоскости перед глазом: чем он дальше, тем меньше добавляет к повороту.
        const z = 2.2 * unit, n = Math.hypot(targetDx, targetDy, z);
        return Qt.point(targetDx / n, targetDy / n);
    }
    function publish(force) {
        const q = quantum;
        if (!force && Math.abs(_gx - gazeX) < q && Math.abs(_gy - gazeY) < q && Math.abs(_lx - lagX) < q && Math.abs(_ly - lagY) < q) return;
        gazeX = _gx; gazeY = _gy; lagX = _lx; lagY = _ly; frames += 1;
    }
    function snap() {
        const g = goal();
        _gx = _lx = g.x; _gy = _ly = g.y; _vx = _vy = 0; _acc = 0;
        anim.stop(); publish(true);
    }
    function kick() {
        if (!active) return;
        if (reducedMotion) { snap(); return; }
        const g = goal();
        if (Math.abs(g.x - _gx) + Math.abs(g.y - _gy) > quantum * 0.5 && !anim.running) { _acc = 0; anim.start(); }
    }
    function step(dt) {
        _acc += Math.min(0.1, Math.max(0.0005, dt));
        if (fpsCap > 0 && _acc < 1 / fpsCap - 0.0015) return;
        const h = _acc; _acc = 0;
        const g = goal();
        let w = omega;
        if (Math.hypot(g.x - _gx, g.y - _gy) > 0.25) w *= 1.6;   // дальний перевод взгляда — скачком
        const e = Math.exp(-w * h);
        let d = _gx - g.x, t = (_vx + w * d) * h;
        _gx = g.x + (d + t) * e; _vx = (_vx - w * t) * e;
        d = _gy - g.y; t = (_vy + w * d) * h;
        _gy = g.y + (d + t) * e; _vy = (_vy - w * t) * e;
        const b = 1 - Math.exp(-h / 0.09);
        _lx += (_gx - _lx) * b; _ly += (_gy - _ly) * b;
        const q = quantum;
        if (Math.abs(g.x - _gx) + Math.abs(g.y - _gy) < q * 0.5 && Math.abs(_vx) + Math.abs(_vy) < q * 4
                && Math.abs(_lx - _gx) + Math.abs(_ly - _gy) < q) {
            _gx = _lx = g.x; _gy = _ly = g.y; _vx = _vy = 0;
            anim.stop(); publish(true);
            return;
        }
        publish(false);
    }

    onTargetDxChanged: kick()
    onTargetDyChanged: kick()
    onHasTargetChanged: kick()
    onGlancingChanged: kick()
    onGlanceXChanged: kick()
    onGlanceYChanged: kick()
    onUnitChanged: kick()
    onReducedMotionChanged: if (reducedMotion) snap()
    onActiveChanged: { if (active) kick(); else anim.stop(); }

    FrameAnimation {
        id: anim
        running: false
        onTriggered: root.step(frameTime)
    }
}
