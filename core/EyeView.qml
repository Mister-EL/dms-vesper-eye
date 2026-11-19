import QtQuick
import "Coverage.js" as Geo

// Отрисовка: один шейдер на образ. Все параметры — числа от движка; кадр рисуется,
// только когда хотя бы одно из них изменилось.
Item {
    id: root
    property var skin: null              // запись образа из SkinData
    property string variant: "dark"
    property var themeColors: null       // цвета темы оболочки по именам или null
    property real gazeX: 0
    property real gazeY: 0
    property real lagX: 0
    property real lagY: 0
    property real pupil: 1
    property real lidTop: 0
    property real lidBot: 0
    property real energy: 0
    property real wake: 0
    property real pulse: 0
    property real pulseX: 1
    property real pulseY: 0
    property real dim: 1
    property real time: 0
    // Сдвиг рисунка на несколько пикселей: защита OLED от выгорания.
    property real driftX: 0
    property real driftY: 0

    readonly property real unit: Geo.unitFor(width, height)
    readonly property var look: skin ? (skin.variants[variant] || skin.variants.dark) : null
    readonly property bool ready: fx.status === ShaderEffect.Compiled
    readonly property string shaderLog: fx.log
    Accessible.ignored: true

    function containsPoint(px, py) {
        return Geo.inLens((px - width / 2 - driftX) / unit, (py - height / 2 - driftY) / unit, 4 / unit);
    }
    function slot(i) {
        if (!look) return Qt.vector4d(0, 0, 0, 1);
        let value = look.colors[i];
        const name = (themeColors && skin.themeMap) ? skin.themeMap[i] : "";
        if (name && themeColors[name] !== undefined) value = themeColors[name];
        const c = Qt.color(value);
        return Qt.vector4d(c.r, c.g, c.b, c.a);
    }
    function param(key) {
        const p = look ? look[key] : null;
        return p ? Qt.vector4d(p[0], p[1], p[2], p[3]) : Qt.vector4d(0, 0, 0, 0);
    }

    ShaderEffect {
        id: fx
        x: root.driftX
        y: root.driftY
        width: root.width
        height: root.height
        visible: root.skin !== null
        blending: true
        property real uTime: root.time
        property vector2d uSize: Qt.vector2d(width, height)
        property real uUnit: root.unit
        property real uPupil: root.pupil
        property vector2d uGaze: Qt.vector2d(root.gazeX, root.gazeY)
        property vector2d uGaze2: Qt.vector2d(root.lagX, root.lagY)
        property real uLidTop: root.lidTop
        property real uLidBot: root.lidBot
        property real uEnergy: root.energy
        property real uWake: root.wake
        property real uPulse: root.pulse
        property real uDim: root.dim
        property vector2d uPulseDir: Qt.vector2d(root.pulseX, root.pulseY)
        property real uLight: root.variant === "light" ? 1 : 0
        property vector4d uC0: root.slot(0)
        property vector4d uC1: root.slot(1)
        property vector4d uC2: root.slot(2)
        property vector4d uC3: root.slot(3)
        property vector4d uC4: root.slot(4)
        property vector4d uC5: root.slot(5)
        property vector4d uC6: root.slot(6)
        property vector4d uC7: root.slot(7)
        property vector4d uP0: root.param("p0")
        property vector4d uP1: root.param("p1")
        fragmentShader: root.skin ? Qt.resolvedUrl("../shaders/" + root.skin.shader + ".frag.qsb") : ""
        onStatusChanged: {
            if (status === ShaderEffect.Error) console.warn("VesperEye: шейдер образа не собрался:", log);
            else if (status === ShaderEffect.Compiled) console.info("VesperEye: образ готов —", root.skin ? root.skin.shader : "");
        }
    }
}
