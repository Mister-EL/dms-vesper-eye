import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common

// Пульт: кнопки номеров и состояний текущего образа, чтобы проверять их на живом рабочем столе.
// Отдельное окно слоя в правом нижнем углу; цвета берёт у темы оболочки.
PanelWindow {
    id: win
    property var life: null
    property var acts: []                 // [{ id, name }]
    property string title: ""
    property string subtitle: ""
    signal closeRequested()

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "vesper-eye:pult"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { right: true; bottom: true }
    margins { right: 20; bottom: 20 }
    implicitWidth: 600
    implicitHeight: body.implicitHeight + 28
    color: "transparent"

    readonly property color cBg: Theme.surfaceContainer
    readonly property color cText: Theme.surfaceText
    readonly property color cMuted: Theme.surfaceVariantText
    readonly property color cLine: Theme.outline
    readonly property color cAccent: Theme.primary
    readonly property color cOnAccent: Theme.primaryText
    readonly property real rad: Math.min(Theme.cornerRadius, 16)

    component Chip: Rectangle {
        id: chip
        property string text: ""
        property bool on: false
        signal clicked()
        implicitWidth: label.implicitWidth + 22
        implicitHeight: 30
        radius: Math.min(win.rad, 15)
        color: on ? win.cAccent : (area.containsMouse ? Qt.rgba(win.cText.r, win.cText.g, win.cText.b, 0.12) : "transparent")
        border.width: 1
        border.color: on ? win.cAccent : win.cLine
        Text { id: label; anchors.centerIn: parent; text: chip.text; color: chip.on ? win.cOnAccent : win.cText; font.pixelSize: 13; font.family: Theme.fontFamily }
        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: chip.clicked() }
    }

    Rectangle {
        anchors.fill: parent
        radius: win.rad
        color: win.cBg
        border.width: 1
        border.color: win.cLine

        Column {
            id: body
            x: 14; y: 14
            width: parent.width - 28
            spacing: 10

            Item {
                width: parent.width; height: 34
                Column {
                    Text { text: win.title; color: win.cText; font.pixelSize: 15; font.bold: true; font.family: Theme.fontFamily }
                    Text { text: win.subtitle; color: win.cMuted; font.pixelSize: 12; font.family: Theme.fontFamily }
                }
                Chip { anchors.right: parent.right; text: "×"; onClicked: win.closeRequested() }
            }
            // Бодрость: полная полоса — только проснулся, пустая — спит.
            Item {
                width: parent.width; height: 20
                Rectangle { y: 7; width: parent.width; height: 6; radius: 3; color: Qt.rgba(win.cText.r, win.cText.g, win.cText.b, 0.14) }
                Rectangle { y: 7; width: parent.width * Math.max(0, win.life ? win.life.energy : 0); height: 6; radius: 3; color: win.cAccent; Behavior on width { NumberAnimation { duration: 300 } } }
            }
            Text {
                width: parent.width
                color: win.cMuted; font.pixelSize: 12; font.family: Theme.fontFamily
                text: !win.life ? "" : win.life.asleep ? "спит" : win.life.actName ? "играет номер" : win.life.userIdle ? "скучает, бодрость " + Math.round(win.life.energy * 100) + " %" : "следит за вами, бодрость " + Math.round(win.life.energy * 100) + " %"
            }
            Flow {
                width: parent.width; spacing: 6
                Repeater {
                    model: win.acts
                    Chip { required property var modelData; text: modelData.name; on: win.life && win.life.actName === modelData.id; onClicked: win.life.demo(modelData.id) }
                }
            }
            Rectangle { width: parent.width; height: 1; color: win.cLine; opacity: 0.6 }
            Flow {
                width: parent.width; spacing: 6
                Chip { text: "Усыпить"; onClicked: win.life.sleepNow() }
                Chip { text: "Разбудить"; onClicked: win.life.wakeNow() }
                Chip { text: "Низкий заряд"; on: win.life && win.life.forceTired; onClicked: win.life.forceTired = !win.life.forceTired }
                Chip { text: "Уведомление"; onClicked: win.life.notify(0.8, -0.45) }
                Chip { text: "Скука ×20"; on: win.life && win.life.timeScale > 1; onClicked: win.life.timeScale = win.life.timeScale > 1 ? 1 : 20 }
            }
        }
    }
}
