import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property bool active: true
    property bool eco: false
    property bool followCursor: true
    property string screenName: ""
    property bool screenAwake: true
    property int failures: 0
    property bool retryReady: true
    property bool reconfiguring: false
    readonly property bool available: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== ""
    readonly property bool running: stream.running
    signal moved(real x, real y, real speed)
    function retry() { failures = 0; retryReady = true; }
    onActiveChanged: if (active) retry()
    function reconfigure() {
        if (!stream.running) return;
        reconfiguring = true; optionsTimer.restart();
    }
    onEcoChanged: reconfigure()
    onFollowCursorChanged: reconfigure()
    Process {
        id: stream
        running: root.active && root.available && root.screenName !== "" && root.retryReady && !root.reconfiguring && root.failures < 3
        command: ["python3", decodeURIComponent(Qt.resolvedUrl("../helpers/cursor_poller.py").toString().replace(/^file:\/\//, "")), "--screen", root.screenName].concat(root.eco ? ["--eco"] : []).concat(root.followCursor ? [] : ["--no-cursor"])
        stdout: SplitParser {
            onRead: line => {
                try {
                    const data = JSON.parse(line);
                    if (typeof data.awake === "boolean") root.screenAwake = data.awake;
                    if (typeof data.x === "number" && typeof data.y === "number") root.moved(data.x, data.y, data.speed || 0);
                } catch (_) {}
            }
        }
        onExited: (code, status) => {
            if (!root.active || root.reconfiguring) return;
            root.failures += 1; root.retryReady = false;
            if (root.failures < 3) retryTimer.restart();
        }
    }
    Timer { id: optionsTimer; interval: 100; onTriggered: { root.retry(); root.reconfiguring = false; } }
    Timer { id: retryTimer; interval: 3000 * Math.max(1, root.failures); onTriggered: if (root.active) root.retryReady = true }
}
