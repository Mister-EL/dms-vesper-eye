import QtQuick

// Поведение: веки, зрачок, дремота и сон, реакции. Состояния сменяются по событиям и таймерам;
// постоянного кадрового цикла нет — анимация идёт только пока что-то меняется.
// Приоритет: приостановлен > уменьшенное движение > удержание > уведомление > внимание > покой.
Item {
    id: root
    property bool active: true
    property bool reducedMotion: false
    property bool eco: false
    property bool lively: true
    property bool tired: false           // батарея на исходе: веко тяжелеет
    property real restLid: 0.1           // насколько прикрыто верхнее веко в покое
    property int blinkClose: 95
    property int blinkHold: 30
    property int blinkOpen: 175
    property int drowsyAfter: 10000      // мс без движения до дремоты
    property int sleepAfter: 60000       // мс дремоты до сна

    property bool drowsy: false
    property bool asleep: false
    property bool held: false
    property bool reading: false
    property bool surprised: false

    property real idleLid: 0             // дремота: тяжёлое верхнее веко
    property real sleepLid: 0            // сон: оба века
    property real clickLid: 0
    property real blinkLid: 0
    property real surpriseOffset: 0
    property real pupilScale: 1
    property real wake: 0                // 1 → 0 при пробуждении
    property real pulse: 0               // 0 → 1 при событии, 0 — события нет
    property real pulseX: 1
    property real pulseY: 0
    property real dim: 1                 // яркость: во сне приглушается
    property double lastNotification: 0
    property double lastSurprise: 0
    property real notificationX: 1
    property real notificationY: -0.4

    readonly property real openness: Math.max(idleLid * 0.72, sleepLid, clickLid, blinkLid, tired ? 0.24 : 0)
    readonly property real lidTop: Math.max(0, Math.min(1, restLid + (1 - restLid) * openness - surpriseOffset))
    readonly property real lidBot: Math.max(sleepLid, clickLid, blinkLid * 0.9)
    readonly property string stateName: !active ? "suspended" : held ? "held" : reading ? "notification"
        : surprised ? "surprised" : asleep ? "asleep" : drowsy ? "drowsy" : "attentive"

    signal glance(real x, real y)        // посмотреть в сторону, доли от -1 до 1
    signal microGlance(real x, real y)
    signal resume()                      // вернуться к указателю

    function cancelBlink() { blink.stop(); doubleBlink.stop(); wakeBlink.stop(); blinkLid = 0; }
    function drowse() {
        if (!active || held || reading || drowsy) return;
        drowsy = true;
        idleTransition.to = 1; idleTransition.duration = 1100; idleTransition.restart();
        glance(0, 0);
        sleepTimeout.restart();
    }
    function fallAsleep() {
        if (!active || !drowsy || held || reading) return;
        asleep = true;
        sleepTransition.to = 1; sleepTransition.duration = 1600; sleepTransition.restart();
        dimTransition.to = 0.5; dimTransition.restart();
    }
    function activity() {
        if (!active) return;
        idleTimeout.restart(); sleepTimeout.stop();
        if (!drowsy && !asleep) return;
        const wasAsleep = asleep;
        drowsy = false; asleep = false;
        idleTransition.to = 0; idleTransition.duration = 420; idleTransition.restart();
        sleepTransition.to = 0; sleepTransition.duration = 380; sleepTransition.restart();
        dimTransition.to = 1; dimTransition.restart();
        resume();
        if (reducedMotion) return;
        if (wasAsleep) { wake = 1; wakeFade.restart(); }
        wakeBlink.restart();
    }
    // Глаз снова стал виден (ушли окна, сняли блокировку): открыться и найти указатель.
    function reveal() {
        if (!active) return;
        idleTimeout.restart();
        if (reducedMotion) return;
        wake = 1; wakeFade.restart();
        blinkNow(false);
    }
    function press() {
        if (!active) return;
        activity(); cancelBlink(); readSequence.stop(); reading = false;
        surpriseSequence.stop(); surprised = false; surpriseOffset = 0;
        held = true; clickTransition.to = 1; clickTransition.duration = 190; clickTransition.restart();
        pupilScale = 0.95;
    }
    function release() {
        if (!held) return;
        held = false; clickTransition.to = 0; clickTransition.duration = 210; clickTransition.restart();
        pupilScale = 1.02; pupilReset.restart(); activity(); resume();
    }
    function surprise() {
        if (!active || reducedMotion || Date.now() - lastSurprise < 2000) return;
        lastSurprise = Date.now(); activity(); cancelBlink(); held = false;
        clickTransition.stop(); clickLid = 0; readSequence.stop(); reading = false;
        surpriseSequence.restart();
    }
    function blinkNow(doubleOne) {
        if (!active || reducedMotion || held || reading || surprised || asleep) return;
        cancelBlink();
        if (doubleOne) doubleBlink.restart(); else blink.restart();
    }
    function notify(x, y) {
        if (!active || reducedMotion || held || Date.now() - lastNotification < 2500) return;
        lastNotification = Date.now(); activity(); cancelBlink();
        notificationX = x; notificationY = y;
        const n = Math.hypot(x, y) || 1;
        pulseX = x / n; pulseY = y / n; pulseRun.restart();
        readSequence.restart();
    }
    // Короткий взгляд в сторону без «чтения»: смена рабочего стола и тому подобное.
    function look(x, y) {
        if (!active || reducedMotion || held || reading || surprised || asleep) return;
        activity(); glance(x, y); lookReturn.restart();
    }
    function speed(value) {
        if (!active || held || drowsy || reading || surprised) return;
        pupilScale = 1 - 0.075 * Math.min(1, Math.max(0, value) / 1800);
        pupilReset.restart();
    }
    function stopAll() {
        cancelBlink(); idleTransition.stop(); sleepTransition.stop(); clickTransition.stop(); dimTransition.stop();
        readSequence.stop(); surpriseSequence.stop(); pulseRun.stop(); wakeFade.stop();
        idleTimeout.stop(); sleepTimeout.stop(); pupilReset.stop(); microReturn.stop(); patrolReturn.stop(); lookReturn.stop();
        held = false; reading = false; surprised = false;
        clickLid = 0; blinkLid = 0; surpriseOffset = 0; pupilScale = 1; wake = 0; pulse = 0;
        idleLid = drowsy ? 1 : 0; sleepLid = asleep ? 1 : 0; dim = asleep ? 0.5 : 1;
    }
    onActiveChanged: {
        if (!active) { stopAll(); return; }
        drowsy = false; asleep = false; idleLid = 0; sleepLid = 0; dim = 1; idleTimeout.restart();
    }
    onReducedMotionChanged: if (reducedMotion) stopAll()

    Behavior on pupilScale { enabled: root.active && !root.reducedMotion; NumberAnimation { duration: 220; easing.type: Easing.InOutCubic } }
    NumberAnimation { id: idleTransition; target: root; property: "idleLid"; easing.type: Easing.InOutSine
        onStarted: if (root.reducedMotion) { stop(); root.idleLid = root.drowsy ? 1 : 0; } }
    NumberAnimation { id: sleepTransition; target: root; property: "sleepLid"; easing.type: Easing.InOutSine
        onStarted: if (root.reducedMotion) { stop(); root.sleepLid = root.asleep ? 1 : 0; } }
    NumberAnimation { id: dimTransition; target: root; property: "dim"; duration: 900; easing.type: Easing.InOutSine
        onStarted: if (root.reducedMotion) { stop(); root.dim = root.asleep ? 0.5 : 1; } }
    NumberAnimation { id: clickTransition; target: root; property: "clickLid"; easing.type: Easing.OutCubic
        onStarted: if (root.reducedMotion) { stop(); root.clickLid = root.held ? 1 : 0; } }
    NumberAnimation { id: wakeFade; target: root; property: "wake"; to: 0; duration: 520; easing.type: Easing.OutCubic }
    SequentialAnimation {
        id: pulseRun
        NumberAnimation { target: root; property: "pulse"; from: 0.001; to: 1; duration: 1100; easing.type: Easing.InOutSine }
        ScriptAction { script: root.pulse = 0 }
    }
    Timer { id: idleTimeout; interval: root.drowsyAfter; running: root.active; onTriggered: root.drowse() }
    Timer { id: sleepTimeout; interval: root.sleepAfter; onTriggered: root.fallAsleep() }
    Timer { id: pupilReset; interval: 250; onTriggered: if (!root.held && !root.surprised) root.pupilScale = 1 }
    Timer {
        id: autoBlink
        interval: 5500; repeat: true; running: root.active && !root.drowsy && !root.reducedMotion
        onTriggered: { interval = 4000 + Math.floor(Math.random() * 5000); root.blinkNow(Math.random() < 0.2); }
    }
    SequentialAnimation {
        id: blink
        NumberAnimation { target: root; property: "blinkLid"; to: 1; duration: root.blinkClose; easing.type: Easing.OutCubic }
        PauseAnimation { duration: root.blinkHold }
        NumberAnimation { target: root; property: "blinkLid"; to: 0; duration: root.blinkOpen; easing.type: Easing.OutCubic }
    }
    SequentialAnimation {
        id: doubleBlink
        NumberAnimation { target: root; property: "blinkLid"; to: 1; duration: root.blinkClose; easing.type: Easing.OutCubic }
        PauseAnimation { duration: root.blinkHold }
        NumberAnimation { target: root; property: "blinkLid"; to: 0; duration: root.blinkOpen; easing.type: Easing.OutCubic }
        PauseAnimation { duration: 145 }
        NumberAnimation { target: root; property: "blinkLid"; to: 1; duration: root.blinkClose; easing.type: Easing.OutCubic }
        PauseAnimation { duration: root.blinkHold }
        NumberAnimation { target: root; property: "blinkLid"; to: 0; duration: root.blinkOpen; easing.type: Easing.OutCubic }
    }
    SequentialAnimation {
        id: wakeBlink
        PauseAnimation { duration: 420 }
        ScriptAction { script: if (root.active && !root.held && !root.reading) doubleBlink.restart() }
    }
    SequentialAnimation {
        id: surpriseSequence
        ScriptAction { script: { root.surprised = true; root.pupilScale = 1.3; } }
        NumberAnimation { target: root; property: "surpriseOffset"; to: 0.12; duration: 150; easing.type: Easing.OutCubic }
        PauseAnimation { duration: 400 }
        NumberAnimation { target: root; property: "surpriseOffset"; to: 0; duration: 350; easing.type: Easing.InOutCubic }
        ScriptAction { script: { root.surprised = false; root.pupilScale = 1; root.resume(); } }
    }
    SequentialAnimation {
        id: readSequence
        ScriptAction { script: { root.reading = true; root.glance(root.notificationX, root.notificationY); } }
        PauseAnimation { duration: 500 }
        ScriptAction { script: root.glance(root.notificationX * 0.78, root.notificationY) }
        PauseAnimation { duration: 600 }
        ScriptAction { script: root.glance(root.notificationX, root.notificationY + 0.05) }
        PauseAnimation { duration: 650 }
        ScriptAction { script: { root.reading = false; root.resume(); } }
    }
    Timer {
        interval: 4000; repeat: true; running: root.active && root.lively && !root.eco && !root.reducedMotion && !root.drowsy
        onTriggered: {
            interval = 2000 + Math.floor(Math.random() * 4000);
            if (root.held || root.reading || root.surprised || root.blinkLid > 0.01) return;
            root.microGlance((Math.random() - 0.5) * 0.14, (Math.random() - 0.5) * 0.08); microReturn.restart();
        }
    }
    Timer { id: microReturn; interval: 160; onTriggered: root.resume() }
    Timer {
        interval: 45000; repeat: true; running: root.active && root.drowsy && !root.asleep && root.lively && !root.eco && !root.reducedMotion
        onTriggered: {
            interval = 45000 + Math.floor(Math.random() * 30000);
            if (root.held || root.reading || root.blinkLid > 0.01) return;
            root.glance((Math.random() - 0.5) * 1.4, (Math.random() - 0.5) * 0.7); patrolReturn.restart();
        }
    }
    Timer { id: patrolReturn; interval: 1200; onTriggered: root.glance(0, 0) }
    Timer { id: lookReturn; interval: 700; onTriggered: root.resume() }
}
