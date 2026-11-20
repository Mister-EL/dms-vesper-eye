import QtQuick
import qs.Modules.Plugins
import "skins/SkinData.js" as Skins

PluginSettings {
    pluginId: "vesperEye"
    SelectionSetting {
        settingKey: "skin"
        label: qsTr("Образ")
        description: qsTr("«По теме оформления» — образ называет файл темы оболочки; если там его нет, берётся первый из списка")
        options: [{ "label": qsTr("По теме оформления"), "value": "auto" }].concat(Skins.data.order.map(id => ({ "label": Skins.data.skins[id].title, "value": id })))
        defaultValue: "auto"
    }
    SelectionSetting {
        settingKey: "variant"
        label: qsTr("Вариант")
        description: qsTr("Светлая или тёмная версия рисунка")
        options: [{ "label": qsTr("По теме оформления"), "value": "auto" }, { "label": qsTr("Светлая"), "value": "light" }, { "label": qsTr("Тёмная"), "value": "dark" }]
        defaultValue: "auto"
    }
    ToggleSetting { settingKey: "pult"; label: qsTr("Пульт проверки номеров"); description: qsTr("Окно с кнопками в углу экрана; ещё открывается средней кнопкой по глазу"); defaultValue: false }
    ToggleSetting { settingKey: "selfPlay"; label: qsTr("Развлекать себя, пока вы ничего не делаете"); description: qsTr("Десять минут от сети, три от батареи; потом засыпает. Архивные глаза только посматривают по сторонам и дремлют"); defaultValue: true }
    ToggleSetting { settingKey: "followCursor"; label: qsTr("Следить за указателем"); defaultValue: true }
    ToggleSetting { settingKey: "notifications"; label: qsTr("Взгляд на уведомления"); defaultValue: true }
    ToggleSetting { settingKey: "ecoMode"; label: qsTr("Экономичный режим"); description: qsTr("Без дыхания и мелких подрагиваний, когда взгляд стоит"); defaultValue: true }
    SelectionSetting {
        settingKey: "fpsCap"
        label: qsTr("Предел кадров")
        options: [{ "label": "30", "value": "30" }, { "label": "60", "value": "60" }, { "label": qsTr("Как у экрана"), "value": "0" }]
        defaultValue: "0"
    }
}
