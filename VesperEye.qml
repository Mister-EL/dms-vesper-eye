import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Modules.Plugins
import "core"
import "skins/SkinData.js" as Skins

// Vesper Eye: глаз на рабочем столе. Этот файл только связывает оболочку с движком из core/:
// настройки, положение на экране, уведомления, музыка, блокировка.
DesktopPluginComponent {
    id: root
    property var screen: null
    readonly property real defaultWidth: 1140
    readonly property real defaultHeight: 540
    minWidth: 285
    minHeight: 135

    // Настройки экземпляра.
    readonly property string skinId: (pluginData.skin && Skins.data.skins[pluginData.skin]) ? pluginData.skin : Skins.data.order[0]
    readonly property var skin: Skins.data.skins[skinId]
    readonly property string variant: {
        const asked = pluginData.variant ?? "auto";
        const want = asked === "auto" ? (Theme.isLightMode ? "light" : "dark") : asked;
        return skin.variants[want] ? want : "dark";
    }
    readonly property string preset: pluginData.preset ?? "calm"          // calm | lively | still
    readonly property bool reduced: preset === "still" || (pluginData.reducedMotion ?? false)
                                    || SettingsData.animationSpeed === SettingsData.AnimationSpeed.None
    readonly property bool followCursor: pluginData.followCursor ?? true
    readonly property int fpsCap: parseInt(pluginData.fpsCap ?? "60") || 0
    readonly property var themeColors: (pluginData.followTheme ?? false) ? ({
        "primary": Theme.primary, "secondary": Theme.secondary, "tertiary": Theme.tertiary, "surface": Theme.surface,
        "surfaceText": Theme.surfaceText, "background": Theme.background, "outline": Theme.outline
    }) : null

    // Состояние хоста.
    readonly property bool hostVisible: visible && (Window.window?.visible ?? false)
    readonly property bool locked: SessionService.locked || SessionService.lockedHint
    // Левый верхний угол виджета в координатах рабочего стола: окно слоя знает только свои отступы.
    readonly property point origin: {
        const host = root.QsWindow.window;
        if (!host) return Qt.point(0, 0);
        const p = root.mapToItem(root.QsWindow.contentItem, 0, 0);
        const m = host.WlrLayershell.margins;
        return Qt.point((screen?.x ?? 0) + m.left + p.x, (screen?.y ?? 0) + m.top + p.y);
    }
    readonly property bool near: cursor.valid && presence.tracking && Math.hypot(gaze.targetDx, gaze.targetDy) < 1.1 * view.unit
    property real nearness: near ? 1 : 0
    Behavior on nearness { NumberAnimation { duration: 260; easing.type: Easing.InOutSine } }

    // Музыка: общий анализатор оболочки, только по желанию и только пока что-то играет.
    readonly property bool audioWanted: presence.tracking && !reduced && !presence.eco && (pluginData.music ?? false)
                                        && (MprisController.activePlayer?.isPlaying ?? false)
    property bool audioRegistered: false
    property real amplitude: 0
    function updateAudio() {
        if (audioWanted === audioRegistered) return;
        CavaService.refCount = Math.max(0, CavaService.refCount + (audioWanted ? 1 : -1));
        audioRegistered = audioWanted;
        if (!audioWanted) amplitude = 0;
    }
    onAudioWantedChanged: updateAudio()
    Component.onCompleted: updateAudio()
    Component.onDestruction: if (audioRegistered) CavaService.refCount = Math.max(0, CavaService.refCount - 1)

    // Защита OLED: раз в три минуты рисунок смещается на пару пикселей.
    property int driftStep: 0
    readonly property var driftPath: [[0, 0], [3, 0], [3, 2], [0, 3], [-3, 2], [-3, 0], [0, -2], [2, -3]]
    Timer { interval: 180000; repeat: true; running: presence.awake; onTriggered: root.driftStep = (root.driftStep + 1) % root.driftPath.length }

    property var lastPopup: null
    readonly property alias behavior: behavior
    readonly property alias gaze: gaze
    readonly property alias presence: presence
    readonly property alias view: view
    readonly property alias cursor: cursor

    Presence {
        id: presence
        hostVisible: root.hostVisible
        locked: root.locked
        screen: root.screen
        eyeRect: Qt.rect(root.origin.x, root.origin.y, root.width, root.height)
        ecoSetting: root.pluginData.ecoMode ?? true
        onAwakeChanged: if (awake) behavior.reveal()
        onUserIdleChanged: if (!userIdle) behavior.activity()
        onWorkspaceShift: direction => behavior.look(direction * 0.85, 0)
    }
    CursorSource {
        id: cursor
        active: presence.tracking && root.followCursor && !hover.hovered
        eco: presence.eco
        onMoved: (x, y, speed) => { behavior.activity(); behavior.speed(speed); }
    }
    HoverHandler {
        id: hover
        enabled: presence.awake && root.followCursor
        onPointChanged: if (hovered) cursor.feed(root.origin.x + point.position.x, root.origin.y + point.position.y)
    }
    Gaze {
        id: gaze
        active: presence.awake
        reducedMotion: root.reduced
        unit: view.unit
        omega: root.skin.motion?.omega ?? 20
        fpsCap: root.fpsCap
        hasTarget: cursor.valid && root.followCursor && !behavior.drowsy
        targetDx: cursor.pointerX - (root.origin.x + root.width / 2)
        targetDy: cursor.pointerY - (root.origin.y + root.height / 2)
    }
    Manner {
        id: behavior
        active: presence.awake
        reducedMotion: root.reduced
        eco: presence.eco
        lively: root.preset === "lively"
        tired: presence.lowBattery
        restLid: root.skin.restLid ?? 0
        blinkClose: root.skin.motion?.blinkClose ?? 95
        blinkHold: root.skin.motion?.blinkHold ?? 30
        blinkOpen: root.skin.motion?.blinkOpen ?? 175
        onGlance: (x, y) => { gaze.glanceX = x; gaze.glanceY = y; gaze.glancing = true; }
        onMicroGlance: (x, y) => { gaze.glanceX = gaze.gazeX + x; gaze.glanceY = gaze.gazeY + y; gaze.glancing = true; }
        onResume: gaze.glancing = false
    }
    EyeView {
        id: view
        anchors.fill: parent
        skin: root.skin
        variant: root.variant
        themeColors: root.themeColors
        gazeX: gaze.gazeX
        gazeY: gaze.gazeY
        lagX: gaze.lagX
        lagY: gaze.lagY
        // Зрачок уже в светлой теме, расширяется от музыки и сужается, когда указатель совсем рядом.
        pupil: behavior.pupilScale * (root.variant === "light" ? 0.9 : 1) * (1 + root.amplitude * 0.05) * (1 - 0.06 * root.nearness)
        // Верхнее веко следует за взглядом: вниз — опускается, вверх — чуть приподнимается.
        lidTop: Math.max(0, Math.min(1, behavior.lidTop + Math.max(0, gaze.gazeY) * 0.16 - Math.max(0, -gaze.gazeY) * 0.03))
        lidBot: behavior.lidBot
        energy: root.amplitude
        wake: behavior.wake
        pulse: behavior.pulse
        pulseX: behavior.pulseX
        pulseY: behavior.pulseY
        dim: behavior.dim
        driftX: root.driftPath[root.driftStep][0]
        driftY: root.driftPath[root.driftStep][1]
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
    // Уведомление: взгляд в ту сторону, где оно всплыло. Текст не читается.
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

    // Удержание кнопки закрывает глаз, двойной щелчок удивляет. Попадание считается по форме глаза.
    Item {
        id: hitMask
        anchors.fill: parent
        function contains(p) { return view.containsPoint(p.x, p.y); }
    }
    MouseArea {
        anchors.fill: parent
        containmentMask: hitMask
        acceptedButtons: Qt.LeftButton
        preventStealing: false
        enabled: presence.awake
        onPressed: mouse => {
            if (mouse.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) { mouse.accepted = false; return; }
            behavior.press();
        }
        onReleased: behavior.release()
        onCanceled: behavior.release()
        onDoubleClicked: behavior.surprise()
    }
}
