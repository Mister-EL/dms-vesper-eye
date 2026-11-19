import QtQuick
import qs.Modules.Plugins
import "skins/SkinData.js" as Skins

PluginSettings {
    pluginId: "vesperEye"
    SelectionSetting {
        settingKey: "skin"
        label: qsTr("Образ")
        description: qsTr("Внешний вид глаза")
        options: [{ "label": qsTr("По профилю оформления"), "value": "auto" }].concat(Skins.data.order.map(id => ({ "label": Skins.data.skins[id].title, "value": id })))
        defaultValue: "auto"
    }
    SelectionSetting {
        settingKey: "variant"
        label: qsTr("Вариант")
        description: qsTr("Тёмный или светлый; не у каждого образа есть оба")
        options: [{ "label": qsTr("По теме оболочки"), "value": "auto" }, { "label": qsTr("Тёмный"), "value": "dark" }, { "label": qsTr("Светлый"), "value": "light" }]
        defaultValue: "auto"
    }
    SelectionSetting {
        settingKey: "preset"
        label: qsTr("Характер")
        options: [{ "label": qsTr("Спокойный"), "value": "calm" }, { "label": qsTr("Живой: редкие осмотры и микродвижения"), "value": "lively" }, { "label": qsTr("Неподвижный"), "value": "still" }]
        defaultValue: "calm"
    }
    ToggleSetting { settingKey: "followTheme"; label: qsTr("Цвета из темы оболочки"); defaultValue: false }
    ToggleSetting { settingKey: "followCursor"; label: qsTr("Следить за указателем"); defaultValue: true }
    ToggleSetting { settingKey: "notifications"; label: qsTr("Взгляд на уведомления"); defaultValue: true }
    ToggleSetting { settingKey: "music"; label: qsTr("Реакция на музыку (выключена на батарее)"); defaultValue: false }
    ToggleSetting { settingKey: "ecoMode"; label: qsTr("Экономичный режим"); defaultValue: true }
    SelectionSetting {
        settingKey: "fpsCap"
        label: qsTr("Предел кадров при движении")
        options: [{ "label": "30", "value": "30" }, { "label": "60", "value": "60" }, { "label": qsTr("Как у экрана"), "value": "0" }]
        defaultValue: "60"
    }
}
