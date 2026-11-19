import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Позиция указателя в координатах рабочего стола. Wayland не сообщает её окну, над которым
// указателя нет, поэтому она запрашивается у Hyprland — прямо отсюда, без отдельного процесса.
// Частота подстраивается: пока указатель движется — часто, когда стоит — редко,
// когда глазу следить незачем (active = false) — никак.
Item {
    id: root
    property bool active: false
    property bool eco: false
    readonly property bool available: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== ""
    property real pointerX: 0
    property real pointerY: 0
    property bool valid: false
    property bool moving: false
    property double lastSample: 0
    signal moved(real x, real y, real speed)

    // Позицию можно подать и снаружи: когда указатель над самим глазом, её дают события окна.
    function feed(x, y) {
        const now = Date.now();
        if (valid && x === pointerX && y === pointerY) { lastSample = now; return; }
        const dt = Math.max(0.016, (now - lastSample) / 1000);
        const speed = valid ? Math.hypot(x - pointerX, y - pointerY) / dt : 0;
        if (!valid) console.info("VesperEye: позиция указателя получена");
        pointerX = x; pointerY = y; valid = true; lastSample = now;
        moving = true; settle.restart();
        moved(x, y, speed);
    }
    function poll() {
        if (sock.connected) { sock.connected = false; return; }   // прошлый ответ не пришёл: начать заново
        sock.connected = true;
    }
    onActiveChanged: if (active && available) poll()

    Timer {
        interval: root.moving ? (root.eco ? 50 : 33) : 250
        repeat: true
        running: root.active && root.available
        onTriggered: root.poll()
    }
    Timer { id: settle; interval: 750; onTriggered: root.moving = false }
    Socket {
        id: sock
        path: Hyprland.requestSocketPath
        // Hyprland отвечает одной строкой без перевода строки и закрывает соединение.
        parser: SplitParser {
            splitMarker: ""
            onRead: data => {
                sock.connected = false;
                try {
                    const o = JSON.parse(data);
                    if (typeof o.x === "number" && typeof o.y === "number" && isFinite(o.x) && isFinite(o.y)) root.feed(o.x, o.y);
                } catch (e) {}
            }
        }
        onConnectionStateChanged: if (connected) { write("j/cursorpos"); flush(); }
    }
}
