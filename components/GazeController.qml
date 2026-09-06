import QtQuick

Item {
    id: root
    property bool active: true
    property bool reducedMotion: false
    property bool eco: false
    property real limit: 40
    property real targetX: 0
    property real targetY: 0
    property real irisX: 0
    property real irisY: 0
    property real pupilX: 0
    property real pupilY: 0
    property double lastStep: 0
    readonly property bool moving: Math.abs(targetX - irisX) + Math.abs(targetY - irisY) > 0.025
                                    || Math.abs(targetX * 0.08 - pupilX) + Math.abs(targetY * 0.08 - pupilY) > 0.015

    function point(dx, dy) {
        const dist = Math.hypot(dx, dy);
        const f = dist > limit ? limit / dist : 1;
        targetX = dx * f;
        targetY = dy * f;
        if (reducedMotion) snap();
    }
    function snap() {
        irisX = targetX; irisY = targetY;
        pupilX = targetX * 0.08; pupilY = targetY * 0.08;
    }
    function approach(value, target, a) {
        return Math.abs(value - target) < 0.01 ? target : value + (target - value) * a;
    }
    onActiveChanged: if (!active) { lastStep = 0; targetX = 0; targetY = 0; snap(); }
    onReducedMotionChanged: if (reducedMotion) snap()
    Timer {
        interval: root.eco ? 33 : 16
        repeat: true
        running: root.active && !root.reducedMotion && root.moving
        onRunningChanged: root.lastStep = 0
        onTriggered: {
            const now = Date.now();
            const dt = root.lastStep ? Math.min(80, now - root.lastStep) : interval;
            root.lastStep = now;
            const a = 1 - Math.exp(-dt / 80), b = 1 - Math.exp(-dt / 115);
            root.irisX = root.approach(root.irisX, root.targetX, a);
            root.irisY = root.approach(root.irisY, root.targetY, a);
            root.pupilX = root.approach(root.pupilX, root.targetX * 0.08, b);
            root.pupilY = root.approach(root.pupilY, root.targetY * 0.08, b);
        }
    }
}
