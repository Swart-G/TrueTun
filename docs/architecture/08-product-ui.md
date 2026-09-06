# 08. Продукт, UI и proxy groups

Сохранить текущую Flutter/Material 3 основу; качественный adaptive UI строится вокруг сетевого состояния. UI не раскрывает implementation details вроде Binder/FD и compiler tags обычному пользователю.

## Экраны

| Раздел | Основные действия | Обязательные состояния |
|---|---|---|
| Главная | Connect/Stop, выбор preset/group, быстрый переход к причине | Нет профиля, importOnly, permission required, preparing, connected, degraded, reconnecting, failed, pending changes |
| Профили | Paste/file/share input, preview, rename/delete, subscriptions refresh | Loading, partial/unsupported import, auth expired, stale source, empty result |
| Узлы и группы | Выбор узла, manual test, group members | Не проверен, testing, healthy, failed, unavailable, no eligible member |
| Маршрутизация | Create/edit/reorder/disable/duplicate/search, final action, Apply | Invalid expression, incompatible scope, missing target, active vs saved |
| Приложения | Mode, search, selected filter, system apps, suggestions preview | Partial inventory, missing app, empty include, conflicting advanced rule |
| Диагностика | State timeline, redacted logs, safe export, health details | Dropped logs, unavailable runtime evidence, export review |
| Настройки | DNS preset, LAN, IPv6, background behavior, backend info | Не поддерживается этой сборкой, restart required |

Android bottom navigation для основных разделов, второстепенные через меню; Linux navigation rail/sidebar и keyboard shortcuts. Layout по доступной ширине, а не жёсткой проверке платформы. Narrow width 360 dp и wide desktop проверяются отдельно; safe areas/status bar учитываются. Пользовательский текст/scale 200% не обрезает Connect/error actions.

## Presentation state

View model подписана на authoritative snapshot и repository read models. Локальный editor draft хранится отдельно от applied policy. Pending Apply показывает, что поменяется и потребуется ли reconnect. Save не должен мигать Connected→Disconnected. Operations имеют progress/cancel и исключают double tap; UI command debounce не заменяет supervisor serialization.

Ошибки локализуются по safeMessageKey; technical details раскрываются отдельно. Не показывать raw stderr вместо объяснения. Connect disabled для importOnly снабжается причиной и доступным действием выбрать поддерживаемый backend/узел. Системное разрешение не запрашивается при каждом открытии страницы.

## Группы и health

Group kinds v1: manual selector; P1: latency-based и fallback. Members могут быть explicit NodeIds или source selector с понятными filters. В первом MVP не поддерживать nested groups; при расширении граф обязан оставаться ацикличным. Пустая группа — GROUP_EMPTY, не DIRECT. Каждая routing group выбирает свой member; global home selection не перезаписывает все группы.

Manual selection стабилен до выбора пользователя/удаления узла. Auto strategy имеет единственного owner: core-native verified URL-test либо application scheduler через dynamicSelect, но не оба одновременно. Fallback выбирает первый здоровый по сохранённому порядку; url-test — минимальную подтверждённую latency с hysteresis. Proposal: switch только после 3 failures current или устойчивого выигрыша минимум 20% и 30 ms на 3 probes; min dwell 60 s. Это начальные параметры, не SLA.

Latency — отдельный результат DNS/connect/TLS/HTTP timing, не ICMP ping к серверу. Test запрос должен идти через конкретный tested node, даже если own Android package исключён. Captive portal/HTTP 200 interception не равно healthy; использовать ожидаемый status/body и HTTPS validation. Один endpoint может быть недоступен сам по себе: хранить reason, не считать все nodes неисправными по одному внешнему outage.

Probe budget proposal: foreground test-all max concurrency 3, timeout 5 s/node, cancel; auto probes 60 s active, 5 min background, suspend/defer при battery saver/metered по setting. Не тратить трафик всего subscription на каждом render. Health не переписывает node credentials и subscription data.

## Smart list interaction

Показывать причину предложения рядом с приложением. Actions «Применить выбранные предложения» и «Отменить» работают с draft/revision; никакой автоматической массовой коррекции после обновления hint базы. Нейтральные предложения не меняют список. Include/exclude подписывать словами, а не цветом checkboxes. При переходе режима показывать effective access до/после и поведение новых установленных apps.

## Доступность и качество

Русский/английский на первом рабочем milestone; strings вне widgets. Screen readers получают actual connection state, кнопки semantic labels. Цвет не единственный статус, focus order и keyboard navigation обязательны; reorder доступен кнопками помимо drag. Секреты скрыты, reveal/copy — явное действие с ограниченным exposure. Diagnostic config preview всегда redacted default.

Приёмка: widget tests ключевых state transitions + visual/manual checks narrow/wide/light/dark/large text. UI shell или screenshot не является доказательством рабочего VPN; runtime errors воспроизводятся и отображаются в том же UI.
