# Архитектура и границы совместимости

## Структура первого runtime-порта

```text
plugin.json
VesperEye.qml              # DMS DesktopPluginComponent adapter
Settings.qml
components/EyeRenderer.qml
components/GazeController.qml
components/BehaviorController.qml
components/CursorBackend.qml
helpers/cursor_poller.py   # read-only Unix socket, один helper на экземпляр
shaders/eye.frag
shaders/eye.frag.qsb
design/palette.json
```

Перечисленные runtime-файлы реализованы. Host-адаптеры уведомлений, темы, lock и CAVA находятся в VesperEye.qml. Подтверждённые сценарии и ограничения перечислены в VALIDATION.md.

DMS v1.6.0 содержит `DesktopPluginComponent` (qs.Modules.Plugins), instanceData/pluginData и wrapper-owned размер/позицию. Документированный пример задаёт type=desktop, capabilities, component, settings и requires_dms. Использовать фактический код release и examples: часть guide ещё описывает более простой plain Item. Не смешивать оба подхода без проверки.

## Что заменить в старом глазе

| Зависимость Noctalia | Направление замены |
|---|---|
| DraggableDesktopWidget | DMS wrapper + DesktopPluginComponent; не переносить старые position/resize handlers |
| Settings / Color | pluginData + отдельные palette tokens / DMS Theme adapter |
| NotificationService.activeList | Ограниченная подписка на допустимый DMS signal; не второе уведомляющее приложение |
| CavaService | Существующий spectrum backend DMS, если API подходит; иначе функция не включается до отдельной оценки |
| Quickshell.shellDir + абсолютный путь helper/shader | URL относительно плагина; валидация фактического plugin directory |
| screen.x/y/root position | Проверенная геометрия window/output и mapTo...; тест multi-monitor/fractional scale |
| 1067 строк смешанной логики | Компоненты по ответственности, приоритетная state machine |

## Обновления
DMS из upstream, Vesper Eye из этого репозитория. Ни копирования внутренних DMS Services, ни встроенного форка всей оболочки. Фиксировать проверенные release versions и plugin commit SHA. Если API не хватает — небольшой предложенный upstream fix или узкий optional adapter, а не тихое редактирование установленного пакета.

Никаких автоматических git pull/restart с работающим пользовательским рабочим столом. Обновления проверяются в candidate; включение расписаний/автообновлений — отдельное решение владельца. Ранее работающий пакет сохраняется до валидации нового.

## Источники
- https://github.com/AvengeMedia/DankMaterialShell/tree/v1.6.0/quickshell/PLUGINS/ExampleDesktopClock
- https://github.com/AvengeMedia/DankMaterialShell/blob/v1.6.0/quickshell/Modules/Plugins/DesktopPluginComponent.qml
- https://github.com/AvengeMedia/DankMaterialShell/blob/v1.6.0/quickshell/Modules/Plugins/DesktopPluginWrapper.qml
- https://danklinux.com/docs/dankmaterialshell/plugin-development/
- legacy/noctalia/SOURCE.json — исходные собственные доработки, upstream notices сохранены.
