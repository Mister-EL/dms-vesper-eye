import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import "Coverage.js" as Geo

// Присутствие: решает, сколько глазу можно тратить.
//   awake    — глаз виден: можно моргать и реагировать;
//   tracking — к тому же человек за компьютером: можно следить за указателем.
// Когда глаз закрыт окнами, заблокирован экран или человек отошёл, всё останавливается.
Item {
    id: root
    property bool hostVisible: true
    property bool locked: false
    property var screen: null
    property rect eyeRect: Qt.rect(0, 0, 0, 0)     // глаз в координатах рабочего стола
    property bool ecoSetting: true

    readonly property bool hypr: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== ""
    readonly property bool onBattery: UPower.onBattery
    readonly property bool lowBattery: onBattery && UPower.displayDevice !== null && UPower.displayDevice.ready
                                       && UPower.displayDevice.percentage > 0 && UPower.displayDevice.percentage < 0.15
    readonly property bool userIdle: idle.isIdle
    property bool covered: false
    property bool windowsAround: false
    property real coverage: 0
    readonly property bool awake: hostVisible && !locked && !covered
    readonly property bool tracking: awake && !userIdle
    readonly property bool eco: ecoSetting || onBattery
    signal workspaceShift(int direction)           // -1 или 1: рабочий стол сменился влево или вправо

    property int _workspaceId: -1

    // Три секунды без ввода — человек не смотрит на указатель; ингибиторы (видео) не учитываются.
    IdleMonitor { id: idle; enabled: root.hostVisible && !root.locked; timeout: 3; respectInhibitors: false }

    function windowsOn(workspace, rects) {
        if (!workspace) return false;
        if (workspace.hasFullscreen) return true;
        const list = workspace.toplevels ? workspace.toplevels.values : [];
        for (let i = 0; i < list.length; i++) {
            const o = list[i].lastIpcObject;
            if (!o || o.hidden === true || o.mapped === false || !o.at || !o.size) continue;
            rects.push({ x: o.at[0], y: o.at[1], width: o.size[0], height: o.size[1] });
        }
        return false;
    }
    // Глаз считается закрытым, если окна активного рабочего стола закрывают его почти целиком.
    // Сведения о геометрии окон могут запаздывать, поэтому любая неясность трактуется как «виден».
    function recompute() {
        if (!hypr || !screen || eyeRect.width <= 0) { covered = false; windowsAround = false; coverage = 0; return; }
        const monitor = Hyprland.monitorFor(screen);
        if (!monitor) { covered = false; windowsAround = false; coverage = 0; return; }
        const rects = [];
        let full = windowsOn(monitor.activeWorkspace, rects);
        const special = monitor.lastIpcObject && monitor.lastIpcObject.specialWorkspace ? monitor.lastIpcObject.specialWorkspace.name : "";
        if (special) {
            const all = Hyprland.workspaces.values;
            for (let i = 0; i < all.length; i++) if (all[i].name === special) full = windowsOn(all[i], rects) || full;
        }
        windowsAround = rects.length > 0;
        coverage = full ? 1 : Geo.coverage(eyeRect, rects);
        covered = coverage >= 0.85;
    }
    function refresh() {
        if (!hypr) return;
        Hyprland.refreshMonitors(); Hyprland.refreshWorkspaces(); Hyprland.refreshToplevels();
        early.restart(); late.restart();
    }
    onScreenChanged: refresh()
    onEyeRectChanged: debounce.restart()
    onHostVisibleChanged: if (hostVisible) refresh()
    Component.onCompleted: refresh()

    Timer { id: debounce; interval: 120; onTriggered: root.refresh() }
    Timer { id: early; interval: 150; onTriggered: root.recompute() }
    Timer { id: late; interval: 600; onTriggered: root.recompute() }
    // Перетаскивание и изменение размера окна событий не дают: пока рядом есть окна, изредка сверяемся.
    Timer { interval: 4000; repeat: true; running: root.hypr && root.hostVisible && !root.locked && root.windowsAround && !root.userIdle; onTriggered: root.refresh() }

    Connections {
        target: Hyprland
        enabled: root.hypr && root.hostVisible
        function onRawEvent(event) {
            const n = event.name;
            if (n === "workspacev2") {
                const id = parseInt(String(event.data).split(",")[0]);
                if (!isNaN(id)) {
                    if (root._workspaceId > 0 && id > 0 && id !== root._workspaceId) root.workspaceShift(id > root._workspaceId ? 1 : -1);
                    root._workspaceId = id;
                }
            }
            if (n === "openwindow" || n === "closewindow" || n === "movewindowv2" || n === "workspacev2" || n === "focusedmonv2"
                    || n === "changefloatingmode" || n === "fullscreen" || n === "activespecialv2" || n === "moveworkspacev2" || n === "pin")
                debounce.restart();
        }
    }
}
