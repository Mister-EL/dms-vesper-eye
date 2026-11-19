import QtQuick
import qs.Modules.Plugins

PluginSettings {
    pluginId: "vesperEye"
    ToggleSetting { settingKey: "followCursor"; label: qsTr("Следить за указателем"); defaultValue: true }
    ToggleSetting { settingKey: "lively"; label: qsTr("Редкие микродвижения и осмотры"); defaultValue: true }
    ToggleSetting { settingKey: "notifications"; label: qsTr("Взгляд на уведомления"); defaultValue: true }
    ToggleSetting { settingKey: "music"; label: qsTr("Реакция на музыку (выключена на батарее)"); defaultValue: false }
    ToggleSetting { settingKey: "followTheme"; label: qsTr("Цвета из темы DMS"); defaultValue: false }
    ToggleSetting { settingKey: "ecoMode"; label: qsTr("Экономичный режим"); defaultValue: true }
    ToggleSetting { settingKey: "reducedMotion"; label: qsTr("Уменьшить движение"); defaultValue: false }
}
