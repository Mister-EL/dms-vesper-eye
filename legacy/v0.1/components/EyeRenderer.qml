import QtQuick

Item {
    id: root
    property real irisX: 0
    property real irisY: 0
    property real pupilX: 0
    property real pupilY: 0
    property real pupilScale: 1
    property real musicAmplitude: 0
    property real topLid: 0
    property real bottomLid: 0
    property color accent: "#C6A36D"
    property color lidTone: "#17121A"
    property color irisTone: "#75263D"
    readonly property real logicalHeight: Math.min(height, width / 1.9)
    readonly property real radius: logicalHeight * 0.2706
    readonly property real visibleEyeHeight: logicalHeight * 0.44
    Accessible.ignored: true

    function vector(c) { const value = Qt.color(c); return Qt.vector4d(value.r, value.g, value.b, value.a); }
    function containsPoint(px, py) {
        const nx = Math.abs(px - width / 2) / Math.max(1, width * 0.496);
        return nx <= 1 && Math.abs(py - height / 2) <= logicalHeight * 0.22 * Math.pow(Math.max(0, 1 - nx * nx), 1.08) + 3;
    }
    ShaderEffect {
        id: eye
        anchors.centerIn: parent
        width: root.width
        height: Math.ceil(root.visibleEyeHeight + 8)
        property vector2d itemSize: Qt.vector2d(width, height)
        property real logicalEyeHeight: root.logicalHeight
        property vector2d irisOffset: Qt.vector2d(root.irisX, root.irisY)
        property vector2d pupilOffset: Qt.vector2d(root.pupilX, root.pupilY)
        property real irisRadius: root.radius * (1 + root.musicAmplitude * 0.06)
        property real pupilRadius: root.radius * 0.66 * root.pupilScale
        property real topLidProgress: Math.max(0, Math.min(1, root.topLid))
        property real bottomLidProgress: Math.max(0, Math.min(1, root.bottomLid))
        property real outlineWidth: Math.max(1, root.width / 800)
        property vector4d scleraColor: root.vector("#C3B4A4")
        property vector4d irisInnerColor: root.vector(Qt.lighter(root.irisTone, 1.45))
        property vector4d irisMiddleColor: root.vector(root.irisTone)
        property vector4d irisOuterColor: root.vector(Qt.darker(root.irisTone, 1.7))
        property vector4d pupilColor: root.vector("#08070B")
        property vector4d accentColor: root.vector(root.accent)
        property vector4d highlightColor: Qt.vector4d(0.965, 0.91, 0.87, 0.65)
        property vector4d lidColor: root.vector(root.lidTone)
        fragmentShader: Qt.resolvedUrl("../shaders/eye.frag.qsb")
        blending: true
    }
}
