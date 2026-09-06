import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import qs.Common
import qs.Services
import qs.Modules.Plugins
import "components"

DesktopPluginComponent {
    id: root
    property var screen: null
    readonly property real defaultWidth: 1000
    readonly property real defaultHeight: 526
    minWidth: 240
    minHeight: 126
    readonly property bool reduced: (pluginData.reducedMotion ?? false) || SettingsData.animationSpeed === SettingsData.AnimationSpeed.None
    readonly property bool eco: (pluginData.ecoMode ?? true) || UPower.onBattery
    readonly property bool hostActive: visible && (Window.window?.visible ?? false) && !SessionService.locked && !SessionService.lockedHint
    readonly property bool motionActive: hostActive && cursor.screenAwake
    readonly property bool audioWanted: motionActive && !reduced && !eco && (pluginData.music ?? false) && (MprisController.activePlayer?.isPlaying ?? false)
    property bool audioRegistered: false
    property real amplitude: 0
    property real cursorX: 0
    property real cursorY: 0
    property bool hasCursor: false
    property var lastPopup: null
    readonly property alias behavior: behavior
    readonly property alias gaze: gaze
    readonly property alias renderer: renderer
    readonly property alias cursorBackend: cursor

    readonly property point globalCenter: {
        const host = root.QsWindow.window;
        if (!host) return Qt.point(width / 2, height / 2);
        const point = root.mapToItem(root.QsWindow.contentItem, width / 2, height / 2);
        const margins = host.WlrLayershell.margins;
        return Qt.point((screen?.x ?? 0) + margins.left + point.x, (screen?.y ?? 0) + margins.top + point.y);
    }
    onGlobalCenterChanged: cursorPoint()
    function cursorPoint() {
        if (!(pluginData.followCursor ?? true) || !hasCursor || behavior.held || behavior.reading || behavior.idle || behavior.surprised) return;
        const center = root.globalCenter;
        gaze.point(cursorX - center.x, cursorY - center.y);
    }
    function updateAudio() {
        if (audioWanted === audioRegistered) return;
        CavaService.refCount = Math.max(0, CavaService.refCount + (audioWanted ? 1 : -1));
        audioRegistered = audioWanted;
        if (!audioWanted) amplitude = 0;
    }
    onAudioWantedChanged: updateAudio()
    Component.onCompleted: updateAudio()
    Component.onDestruction: if (audioRegistered) CavaService.refCount = Math.max(0, CavaService.refCount - 1)

    CursorBackend {
        id: cursor
        active: root.hostActive
        followCursor: root.pluginData.followCursor ?? true
        eco: root.eco
        screenName: root.screen?.name ?? ""
        onMoved: (x, y, speed) => {
            root.cursorX = x; root.cursorY = y; root.hasCursor = true;
            behavior.activity(); behavior.speed(speed); root.cursorPoint();
        }
    }
    GazeController {
        id: gaze
        active: root.motionActive
        reducedMotion: root.reduced
        eco: root.eco
        limit: renderer.logicalHeight * 0.1056
    }
    BehaviorController {
        id: behavior
        active: root.motionActive
        reducedMotion: root.reduced
        eco: root.eco
        lively: root.pluginData.lively ?? true
        onGlance: (x, y) => gaze.point(x * gaze.limit, y * gaze.limit)
        onMicroGlance: (x, y) => gaze.point(gaze.targetX + x * gaze.limit, gaze.targetY + y * gaze.limit)
        onResumeCursor: { if (idle) gaze.point(0, 0); else root.cursorPoint(); }
    }
    EyeRenderer {
        id: renderer
        anchors.fill: parent
        irisX: gaze.irisX; irisY: gaze.irisY
        pupilX: gaze.pupilX; pupilY: gaze.pupilY
        pupilScale: behavior.pupilScale
        musicAmplitude: root.amplitude
        topLid: behavior.topLid
        bottomLid: behavior.bottomLid
        accent: (root.pluginData.followTheme ?? false) ? Theme.secondary : "#C6A36D"
        lidTone: (root.pluginData.followTheme ?? false) ? Theme.surface : "#17121A"
        irisTone: (root.pluginData.followTheme ?? false) ? Theme.primary : "#75263D"
    }
    Connections {
        target: CavaService
        enabled: root.audioWanted
        function onValuesChanged() {
            const values = CavaService.values;
            const average = values.reduce((a, b) => a + (b || 0), 0) / Math.max(1, values.length) / 100;
            root.amplitude += (Math.max(0, Math.min(1, average)) - root.amplitude) * 0.3;
        }
    }
    Connections {
        target: NotificationService
        function onPopupsChanged() {
            const popups = NotificationService.popups;
            const popup = popups.length ? popups[popups.length - 1] : null;
            if (!popup || popup === root.lastPopup) return;
            root.lastPopup = popup;
            if (!(root.pluginData.notifications ?? true) || SessionData.doNotDisturb) return;
            const pos = SettingsData.notificationPopupPosition;
            const left = pos === SettingsData.Position.Left || pos === SettingsData.Position.Bottom;
            const center = pos === -1 || pos === SettingsData.Position.TopCenter || pos === SettingsData.Position.BottomCenter;
            const bottom = pos === SettingsData.Position.Bottom || pos === SettingsData.Position.Right || pos === SettingsData.Position.BottomCenter;
            behavior.notify(center ? 0 : left ? -1 : 1, bottom ? 0.45 : -0.45);
        }
    }
    Item {
        id: hitMask
        anchors.fill: parent
        function contains(p) { return renderer.containsPoint(p.x, p.y); }
    }
    MouseArea {
        anchors.fill: parent
        containmentMask: hitMask
        acceptedButtons: Qt.LeftButton
        preventStealing: false
        enabled: root.motionActive
        onPressed: mouse => {
            if (mouse.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) { mouse.accepted = false; return; }
            behavior.press();
        }
        onReleased: behavior.release()
        onCanceled: behavior.release()
        onDoubleClicked: behavior.surprise()
    }
}
