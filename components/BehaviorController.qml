import QtQuick

Item {
    id: root
    property bool active: true
    property bool reducedMotion: false
    property bool eco: false
    property bool lively: true
    property bool idle: false
    property bool held: false
    property bool reading: false
    property bool surprised: false
    property real idleLid: 0
    property real clickLid: 0
    property real blinkLid: 0
    property real pupilScale: 1
    property real surpriseOffset: 0
    property double lastNotification: 0
    property double lastSurprise: 0
    property real notificationX: 1
    property real notificationY: -0.4
    readonly property real topLid: Math.max(0, Math.max(idleLid, clickLid, blinkLid) - surpriseOffset)
    readonly property real bottomLid: Math.max(clickLid, blinkLid)
    readonly property string stateName: !active ? "suspended" : held ? "held" : reading ? "notification" : surprised ? "surprised" : idle ? "drowsy" : "attentive"
    signal glance(real x, real y)
    signal resumeCursor()
    signal microGlance(real x, real y)

    function cancelBlink() { blink.stop(); doubleBlink.stop(); wakeBlink.stop(); blinkLid = 0; }
    function idleNow() {
        if (!active || held || reading) return;
        idle = true;
        idleTransition.to = 1; idleTransition.duration = 1100; idleTransition.restart();
        glance(0, 0);
    }
    function activity() {
        if (!active) return;
        idleTimeout.restart();
        if (!idle) return;
        idle = false;
        idleTransition.to = 0; idleTransition.duration = 420; idleTransition.restart();
        if (!reducedMotion) wakeBlink.restart();
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
        pupilScale = 1.02; pupilReset.restart(); activity(); resumeCursor();
    }
    function surprise() {
        if (!active || reducedMotion || Date.now() - lastSurprise < 2000) return;
        lastSurprise = Date.now(); activity(); cancelBlink(); held = false;
        clickTransition.stop(); clickLid = 0; readSequence.stop(); reading = false;
        surpriseSequence.restart();
    }
    function blinkNow(doubleOne) {
        if (!active || reducedMotion || held || reading || surprised) return;
        cancelBlink();
        if (doubleOne) doubleBlink.restart(); else blink.restart();
    }
    function notify(x, y) {
        if (!active || reducedMotion || held || Date.now() - lastNotification < 2500) return;
        lastNotification = Date.now(); activity(); cancelBlink();
        notificationX = x; notificationY = y; readSequence.restart();
    }
    function speed(value) {
        if (!active || held || idle || reading || surprised) return;
        pupilScale = 1 - 0.075 * Math.min(1, Math.max(0, value) / 1800);
        pupilReset.restart();
    }
    function stopAll() {
        cancelBlink(); idleTransition.stop(); clickTransition.stop(); readSequence.stop(); surpriseSequence.stop();
        idleTimeout.stop(); pupilReset.stop(); microReturn.stop(); patrolReturn.stop();
        held = false; reading = false; surprised = false;
        clickLid = 0; blinkLid = 0; surpriseOffset = 0; pupilScale = 1; idleLid = idle ? 1 : 0;
    }
    onActiveChanged: { if (!active) stopAll(); else { idle = false; idleLid = 0; idleTimeout.restart(); } }
    onReducedMotionChanged: if (reducedMotion) stopAll()
    Behavior on pupilScale { enabled: root.active && !root.reducedMotion; NumberAnimation { duration: 220; easing.type: Easing.InOutCubic } }
    NumberAnimation { id: idleTransition; target: root; property: "idleLid"; duration: 1100; easing.type: Easing.InOutSine; onStarted: if (root.reducedMotion) { stop(); root.idleLid = root.idle ? 1 : 0; } }
    NumberAnimation { id: clickTransition; target: root; property: "clickLid"; duration: 190; easing.type: Easing.OutCubic; onStarted: if (root.reducedMotion) { stop(); root.clickLid = root.held ? 1 : 0; } }
    Timer { id: idleTimeout; interval: 10000; running: root.active; onTriggered: root.idleNow() }
    Timer { id: pupilReset; interval: 250; onTriggered: if (!root.held && !root.surprised) root.pupilScale = 1 }
    Timer {
        id: autoBlink
        interval: 5500; repeat: true; running: root.active && !root.idle && !root.reducedMotion
        onTriggered: { interval = 4000 + Math.floor(Math.random() * 5000); root.blinkNow(Math.random() < 0.2); }
    }
    SequentialAnimation {
        id: blink
        NumberAnimation { target: root; property: "blinkLid"; to: 1; duration: 95; easing.type: Easing.OutCubic }
        PauseAnimation { duration: 30 }
        NumberAnimation { target: root; property: "blinkLid"; to: 0; duration: 175; easing.type: Easing.OutCubic }
    }
    SequentialAnimation {
        id: doubleBlink
        NumberAnimation { target: root; property: "blinkLid"; to: 1; duration: 95; easing.type: Easing.OutCubic }
        PauseAnimation { duration: 30 }
        NumberAnimation { target: root; property: "blinkLid"; to: 0; duration: 175; easing.type: Easing.OutCubic }
        PauseAnimation { duration: 145 }
        NumberAnimation { target: root; property: "blinkLid"; to: 1; duration: 90; easing.type: Easing.OutCubic }
        PauseAnimation { duration: 20 }
        NumberAnimation { target: root; property: "blinkLid"; to: 0; duration: 175; easing.type: Easing.OutCubic }
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
        ScriptAction { script: { root.surprised = false; root.pupilScale = 1; root.resumeCursor(); } }
    }
    SequentialAnimation {
        id: readSequence
        ScriptAction { script: { root.reading = true; root.glance(root.notificationX, root.notificationY); } }
        PauseAnimation { duration: 500 }
        ScriptAction { script: root.glance(root.notificationX * 0.78, root.notificationY) }
        PauseAnimation { duration: 600 }
        ScriptAction { script: root.glance(root.notificationX, root.notificationY + 0.05) }
        PauseAnimation { duration: 650 }
        ScriptAction { script: { root.reading = false; root.resumeCursor(); } }
    }
    Timer {
        interval: 4000; repeat: true; running: root.active && root.lively && !root.eco && !root.reducedMotion && !root.idle
        onTriggered: {
            interval = 2000 + Math.floor(Math.random() * 4000);
            if (root.held || root.reading || root.surprised || root.blinkLid > 0.01) return;
            root.microGlance((Math.random() - 0.5) * 0.14, (Math.random() - 0.5) * 0.08); microReturn.restart();
        }
    }
    Timer { id: microReturn; interval: 160; onTriggered: root.resumeCursor() }
    Timer {
        interval: 45000; repeat: true; running: root.active && root.idle && root.lively && !root.eco && !root.reducedMotion
        onTriggered: {
            interval = 45000 + Math.floor(Math.random() * 30000);
            if (root.held || root.reading || root.blinkLid > 0.01) return;
            root.glance((Math.random() - 0.5) * 1.4, (Math.random() - 0.5) * 0.7); patrolReturn.restart();
        }
    }
    Timer { id: patrolReturn; interval: 1200; onTriggered: root.glance(0, 0) }
}
