import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import qs.Common
import qs.Services
import qs.Modules.Plugins
import "core"
import "core/Acts.js" as Acts
import "skins/SkinData.js" as Skins

// Vesper Eye: глаз на рабочем столе. Этот файл только связывает оболочку с движком из core/:
// настройки, положение на экране, уведомления, блокировку, пульт и команды.
DesktopPluginComponent {
    id: root
    property var screen: null
    readonly property real defaultWidth: 1220
    readonly property real defaultHeight: 578
    minWidth: 285
    minHeight: 135

    // Образ называет тема оформления полем "vesperEye" в своём файле:
    //   "skin": "keeper"  или  "skin": { "light": "<образ>", "dark": "<образ>" } — тогда кнопка режима оболочки меняет и рисунок, и характер;
    //   "variant" — принудительный вариант цветов; "wallpapers": { "light", "dark" } — обои по режиму.
    property var profileSkin: ""
    property string profileVariant: ""
    property var profileWallpapers: null
    readonly property string mode: Theme.isLightMode ? "light" : "dark"
    readonly property string skinId: {
        const asked = pluginData.skin ?? "auto";
        let want = asked;
        if (asked === "auto") want = typeof profileSkin === "string" ? profileSkin : (profileSkin ? (profileSkin[mode] || "") : "");
        return Skins.data.skins[want] ? want : Skins.data.order[0];
    }
    readonly property var skin: Skins.data.skins[skinId]
    readonly property string variant: {
        const asked = pluginData.variant ?? "auto";
        const want = asked === "auto" ? (profileVariant || mode) : asked;
        return skin.variants[want] ? want : Object.keys(skin.variants)[0];
    }
    function syncWallpaper() {
        if (!profileWallpapers) return;
        const want = Theme.isLightMode ? profileWallpapers.light : profileWallpapers.dark;
        if (want && SessionData.wallpaperPath !== want) SessionData.setWallpaper(want);
    }
    Connections { target: Theme; function onIsLightModeChanged() { root.syncWallpaper(); } }
    FileView {
        id: profileFile
        path: (SettingsData.currentThemeName === "custom" && SettingsData.customThemeFile) ? SettingsData.customThemeFile : ""
        blockLoading: false
        watchChanges: true
        printErrors: false
        function read() {
            let eye = {};
            try { eye = JSON.parse(profileFile.text()).vesperEye || {}; } catch (e) {}
            root.profileSkin = eye.skin || "";
            root.profileVariant = eye.variant || "";
            root.profileWallpapers = (eye.wallpapers && eye.wallpapers.light && eye.wallpapers.dark) ? eye.wallpapers : null;
            root.themeTitle = eye.title || "";
            root.syncWallpaper();
        }
        onLoaded: read()
        onFileChanged: reload()
        onLoadFailed: { root.profileSkin = ""; root.profileVariant = ""; root.profileWallpapers = null; }
    }
    property string themeTitle: ""
    readonly property bool reduced: (pluginData.reducedMotion ?? false) || SettingsData.animationSpeed === SettingsData.AnimationSpeed.None
    readonly property bool followCursor: pluginData.followCursor ?? true
    readonly property int fpsCap: parseInt(pluginData.fpsCap ?? "0") || 0      // 0 — как у экрана

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

    // Защита OLED: раз в три минуты рисунок смещается на пару пикселей.
    property int driftStep: 0
    readonly property var driftPath: [[0, 0], [3, 0], [3, 2], [0, 3], [-3, 2], [-3, 0], [0, -2], [2, -3]]
    Timer { interval: 180000; repeat: true; running: presence.awake; onTriggered: root.driftStep = (root.driftStep + 1) % root.driftPath.length }

    property var lastPopup: null
    readonly property alias life: life
    readonly property alias presence: presence
    readonly property alias view: view
    readonly property alias cursor: cursor

    Presence {
        id: presence
        hostVisible: root.hostVisible
        locked: root.locked
        screen: root.screen
        eyeRect: Qt.rect(root.origin.x, root.origin.y, root.width, root.height)
        eyeShape: root.skin.shape ?? null
        ecoSetting: root.pluginData.ecoMode ?? true
        onWorkspaceShift: direction => life.look(direction * 0.85, 0, 900)
    }
    CursorSource {
        id: cursor
        active: presence.tracking && root.followCursor && !hover.hovered
        eco: presence.eco
        onMoved: (x, y, speed) => life.cursorMoved()
    }
    HoverHandler {
        id: hover
        enabled: presence.awake && root.followCursor
        onPointChanged: if (hovered) cursor.feed(root.origin.x + point.position.x, root.origin.y + point.position.y)
    }
    Life {
        id: life
        active: presence.awake
        userIdle: presence.userIdle
        reducedMotion: root.reduced
        eco: presence.eco
        showEnabled: root.pluginData.selfPlay ?? true
        lowBattery: presence.lowBattery
        onBattery: presence.onBattery
        followCursor: root.followCursor
        hasTarget: cursor.valid
        targetDx: cursor.pointerX - (root.origin.x + root.width / 2)
        targetDy: cursor.pointerY - (root.origin.y + root.height / 2)
        hover: hover.hovered && view.containsPoint(hover.point.position.x, hover.point.position.y)
        unit: view.unit
        fpsCap: root.fpsCap
        restLid: root.skin.restLid ?? 0.22
        character: root.skin.character ?? ({})
        visFrac: presence.visFrac
        visX: presence.visX
        visY: presence.visY
    }
    // Сменился рисунок (другая тема или другой режим): глаз открывается заново, уже другим существом.
    onSkinIdChanged: { life.wakeNow(); life.reveal(); }
    EyeView {
        id: view
        anchors.fill: parent
        skin: root.skin
        variant: root.variant
        gazeX: life.gazeX
        gazeY: life.gazeY
        lagX: life.lagX
        lagY: life.lagY
        pupil: life.pupil
        lidTop: life.lidTop
        lidBot: life.lidBot
        wake: life.wake
        pulse: life.pulse
        dim: life.dim
        mood: life.mood
        face: life.face
        pose: life.pose
        time: life.clock
        bobX: life.bobX
        bobY: life.bobY
        driftX: root.driftPath[root.driftStep][0]
        driftY: root.driftPath[root.driftStep][1]
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
            life.notify(center ? 0 : left ? -0.8 : 0.8, bottom ? 0.45 : -0.45);
        }
    }
    // Новое окно на этом столе: взгляд в его сторону.
    Connections {
        target: Hyprland
        enabled: presence.awake
        function onRawEvent(event) {
            if (event.name !== "openwindow") return;
            openLook.restart();
        }
    }
    Timer {
        id: openLook
        interval: 350                      // геометрия нового окна приходит с опозданием
        onTriggered: {
            const top = Hyprland.activeToplevel, o = top ? top.lastIpcObject : null;
            if (!o || !o.at || !o.size) return;
            const dx = o.at[0] + o.size[0] / 2 - (root.origin.x + root.width / 2), dy = o.at[1] + o.size[1] / 2 - (root.origin.y + root.height / 2);
            const n = Math.hypot(dx, dy, 2.2 * view.unit);
            life.notify(dx / n, dy / n);
        }
    }

    // Удержание кнопки закрывает глаз, двойной щелчок удивляет, средняя кнопка открывает и закрывает пульт.
    Item {
        id: hitMask
        anchors.fill: parent
        function contains(p) { return view.containsPoint(p.x, p.y); }
    }
    MouseArea {
        anchors.fill: parent
        containmentMask: hitMask
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        preventStealing: false
        enabled: presence.awake
        onPressed: mouse => {
            if (mouse.button === Qt.MiddleButton) { root.pultOpen = !root.pultOpen; return; }
            if (mouse.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) { mouse.accepted = false; return; }
            life.press();
        }
        onReleased: life.release()
        onCanceled: life.release()
        onDoubleClicked: mouse => { if (mouse.button === Qt.LeftButton) life.surprise(); }
    }

    // Пульт проверки номеров. Открыт, пока включён в настройках; крестик прячет его до команды или средней кнопки.
    property bool pultOpen: pluginData.pult ?? false
    readonly property var actList: Acts.listFor(root.skin.character ? root.skin.character.acts : null, root.skin.character ? root.skin.character.names : null)
    LazyLoader {
        active: root.pultOpen && root.hostVisible
        Pult {
            screen: root.screen
            life: root.life
            acts: root.actList
            title: (root.themeTitle && root.themeTitle !== root.skin.title) ? root.themeTitle + " · " + root.skin.title : root.skin.title
            subtitle: (Theme.isLightMode ? "светлая версия" : "тёмная версия") + " · " + root.actList.length + " номеров"
            onCloseRequested: root.pultOpen = false
        }
    }
    // Команды: dms ipc call vesperEye play laugh | acts | pult | sleep | wake
    IpcHandler {
        target: "vesperEye"
        function play(name: string): string { return life.demo(name) ? "ok" : "нет такого номера; список: dms ipc call vesperEye acts"; }
        function acts(): string { return root.actList.map(a => a.id + " — " + a.name).join("\n"); }
        function pult(): string { root.pultOpen = !root.pultOpen; return root.pultOpen ? "пульт открыт" : "пульт закрыт"; }
        function sleep(): string { life.sleepNow(); return "ok"; }
        function wake(): string { life.wakeNow(); return "ok"; }
        function state(): string { return root.skinId + " " + root.variant + " " + (life.asleep ? "спит" : life.dozing ? "дремлет" : life.actName || "бодрствует") + " " + Math.round(life.energy * 100) + "%"; }
    }
}
