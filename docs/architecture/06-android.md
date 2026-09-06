# 06. Android runtime и приложения

Цель: Android GUI/Activity может быть уничтожен, а уже разрешённый VPN продолжает работать под управлением native service. Предложение — Kotlin VpnService в отдельном `:vpn` process; Flutter через Pigeon UI bridge и private Binder/AIDL. Это изолирует native crash от UI process, но требует реального IPC; MethodChannel сам по себе не межпроцессный транспорт.

## Lifecycle и FD

UI вызывает системный VPN consent flow; service имеет необходимый manifest/service permission и foreground notification. Точные foreground service type/permissions и API-level restrictions проверить по выбранным min/target SDK в T00, не копировать устаревший manifest. Consent denial/revoke — terminal user decision без reconnect loop.

Service владеет original ParcelFileDescriptor TUN. Если native binding требует detached/duplicated FD, соглашение фиксируется отдельно: кто закрывает original, кто duplicate, когда transfer считается совершённым. Default proposal: service держит original до stop, core получает duplicate и закрывает его при shutdown. Если binding требует иное — ADR до реализации. Raw integer FD нельзя передать из UI process как валидный FD; использовать native descriptor mechanism внутри service.

До protect/bind required sockets исходящие соединения не создаются. Не исключать проблему loops только удалением собственного package: native binding должен поддержать protect callbacks для всех core outbound sockets. Service применяет immutable app filter до establish, сообщает local readiness и active revision, хранит recovery capsule в app-private encrypted storage. При shutdown закрывает core, FD и callbacks один раз; notification отражает настоящий state.

## Native app filter

Android разрешает либо allowed, либо disallowed list; изменение требует нового VPN establishment. Пустой allowed list означает все приложения. Lockdown может лишить исключённые приложения сети вместо обычного bypass. [Источник: Android VPN guide](https://developer.android.com/develop/connectivity/vpn).

| Режим TrueTun | Effective native policy | Предварительная проверка |
|---|---|---|
| Все, кроме выбранных | addDisallowedApplication для selected + own package | Пересечь с установленными; собственный package определяется runtime |
| Только выбранные | addAllowedApplication для selected без own package | Effective set обязан быть непустым |

Имена UI лучше «В VPN: все, кроме выбранных» и «В VPN: только выбранные», потому что внутри VPN rule может отправить приложение DIRECT. Own-package bypass остаётся системным инвариантом этого проекта; его explicit proxy fetch реализуется отдельно. Не добавлять одновременно core package filter и Builder filter с различающейся семантикой. Если core platform callback сам создаёт Builder, единственный authority остаётся этот callback с TrueTun normalized policy.

После remove/install package inventory invalidates. Исчезнувшие выбранные identities сохраняются как missing в policy, но не передаются Builder. Если vanished последний include member, новая сессия не запускается, старая не расширяется. При изменении установленных приложений во время prepare повторить effective-set validation непосредственно перед establish. Для одного missing package не превращать весь режим в default all.

## Package identity и видимость

Identity = Android user/profile scope + packageName; UID — runtime derived fact, не permanent key. PackageManager visibility ограничена ОС; `QUERY_ALL_PACKAGES` и требования канала распространения — gate отдельно, не предполагать полный inventory. Launcher apps — полезный default view, но не полный список. UI показывает partial visibility, missing и system apps по запросу. Icons lazy cache с ключом package/version/user, без больших bitmap в bulk Binder response.

Shared UID, work profiles, cloned apps и delegated system traffic требуют явного ограничения UX: app label не всегда даёт изолированный сетевой субъект. Scope work profile не менять без соответствующего доступного API. Если несколько packages разделяют UID, показать связанную группу и проверить actual filter behavior на устройстве. Не утверждать точное per-package isolation по одному списку PackageManager.

## Advanced package routing

После попадания в VPN package matcher выбирает node/group/direct/block. Availability зависит от native core ability находить owner соединения. Если binding не предоставляет package metadata, advanced package rules недоступны, но native whitelist/blacklist могут работать. Правило Block для bypass app не работает: editor заранее показывает конфликт доступа, а не обещает блокировку.

## Умный выбор

Цель v1 — локальные предложения, а не ML или remote inference. Источники: пользовательские решения, выбранный региональный preset, versioned curated package hints, доступная category. Приоритет: explicit user choice > explicit preset confirmation > curated suggestion > category heuristic > neutral. Browser/social не обязаны нуждаться в VPN; system/banking не обязаны всегда идти напрямую.

Suggestion: action(include/bypass/neutral), reasonCode, readable evidence, confidenceLabel, providerVersion. Числовая confidence — heuristic score, не измеренная вероятность. Не выводить «95% надёжность» из текущих констант. Список installed apps и user decisions не загружается. Обновление общей базы подсказок опционально, versioned и не содержит inventory в request.

Preview показывает added/removed, источники причин и mode conversion. Apply suggestions изменяет draft, затем пользователь применяет policy. Undo возвращает предыдущую revision, если нет intervening edits; иначе предлагает diff. При переключении include↔exclude нельзя просто сохранить ту же checked list: UI предлагает сохранить effective scope для текущего inventory или начать выбор заново. Для новых apps семантика modes различается и показывается заранее.

## Always-on, background и power

MVP не заявляет reboot/always-on до проверки recovery capsule и secret availability до unlock. По умолчанию ключи доступны после unlock; do not weaken key protection ради раннего auto-start. Если always-on не поддержан, manifest/UX отражает это. Disconnect из notification идёт в тот же supervisor. Перезапуск UI делает inspect и subscribe, не connect.

Не держать бессрочный wake lock без измерений. Health checks ограничиваются по battery/metered state и не порождают постоянный wakeup. Notification, quick tile и system VPN settings должны сходиться к одному desired intent.

## Device acceptance

Физическое устройство обязательно: consent deny/allow/revoke; UI process kill; отдельный service crash; screen off/Doze; Wi-Fi/mobile handover; install/uninstall выбранного app; пустой include; shared UID fixture где доступно; lockdown и bypass; native FD leak на 100 start/stop; app inventory privacy. Emulator-only результат маркируется отдельно. Exact SDK/ABI matrix фиксируется T00.
