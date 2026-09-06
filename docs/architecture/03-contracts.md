# 03. Контракты сервисов и IPC

Статус: проект API v1; это не существующие signatures. Все публичные операции имеют operationId, deadline и typed Result; domain не получает Throwable/stderr как пользовательскую ошибку. Отсутствующее optional field отличается от explicit null/reset.

## Application ports

| Port / операция | Вход | Результат и побочные эффекты |
|---|---|---|
| ImportService.inspect | InputHandle, ImportOptions, limits | ImportDraft(nodes, diagnostics, ignoredSections, requiredCapabilities); ничего не сохраняет |
| ImportService.commit | draftId/hash, expectedRevision, acceptedWarnings | Новая source revision; одна транзакция, draft имеет expiry |
| SubscriptionService.refresh | sourceId, routePolicy, expectedRevision | unchanged / updated(diff) / failed; active runtime не переключает |
| RoutingService.save | policyDraft, expectedRevision | desired revision или diagnostic paths |
| AppPolicyService.preview | mode, identities, installedSnapshot | effective packages, missing apps, added/removed, errors |
| SuggestionService.suggest | installedSnapshot, localPreset, manualDecisions | Deterministic proposals, ни сети, ни apply |
| SnapshotAssembler.assemble | presetId, expectedRevision, PlatformFacts, BuildManifest | Immutable замкнутый snapshot, resolved secret handles и pinned asset refs |
| ConfigCompiler.compile | snapshot, CapabilityReport | CompiledPlan либо diagnostics; без I/O, clock/random/HTTP |
| ConnectionService.apply | planId, expectedActiveRevision | operation handle; commit только supervisor |
| ConnectionService.stop | reason, operationId | Идемпотентное прекращение desiredConnected и runtime |
| ConnectionService.observe | afterSequence | Snapshot + ordered events; при gap resync |
| DiagnosticsService.export | explicit scope, redaction policy | Проверенный redacted bundle, bounded size |

Plan assembly разрешает secret handles через dedicated runtime materializer. Компилятор работает с secret placeholders; validate/start получают материализованную копию внутри trusted boundary. Не передавать secret store interface внутрь pure compiler.

## DTO

**CapabilityReport:** buildId, sourceCommit, configSchema, platform, abi, protocol/transport combinations, features, limits, evidenceRevision. Комбинация включает TLS/Reality/flow/UDP, а не просто protocol name. Состояние: unavailable, importOnly, experimental, supported; unknown всегда fail-closed при connect. Возможности = пересечение build manifest, runtime handshake и platform adapter; marketed supported дополнительно требует test evidence.

**PlatformFacts:** OS/API/ABI, permissionState, networkEpoch, defaultInterface identity, IPv4/IPv6 reachability evidence, VPN lockdown facts, package inventory revision. Не сохранять Android network handle или Linux ifindex навсегда: это факты текущего окружения.

**CompiledPlan:** planId, snapshotHash, desiredRevision, buildId, platform, configSchemaVersion, configTemplate, secretBindings, assetHashes, networkIntent, appFilter, requiredPrivileges, routeRuleMap, restartKind, diagnostics. planId/operationId генерируются за пределами compiler. Hash относится к canonical semantic input с secret version IDs, не к credentials; не публикуется как fingerprint сервера.

**ValidationReport:** accepted, errors[], warnings[], testedBuildId, validatedPlanHash, expiresAt/networkEpoch. Формат ошибок: code, severity, fieldPath, entityId, safeMessageKey, safeArgs, retryable, suggestedAction. Unsafe core output сначала redaction, потом private diagnostic attachment.

## Runtime control boundary

| Метод | Контракт |
|---|---|
| negotiate(clientApiMajor, minor) | Совпадающий major обязателен; capabilities для optional fields; несовместимость блокирует start |
| inspect() | Возвращает фактическое состояние, session/activeRevision, resource ownership; работает после UI restart |
| validate(plan) | Schema и core check в непривилегированном контексте без изменения системной сети; bounded timeout |
| prepare(plan, expectedActiveRevision) | Проверяет assets/permissions/environment, выдаёт краткоживущий ticket; не меняет active routes |
| commit(ticket, operationId) | Проверяет неизменность hash/build/owner, сериализует stop/start; события отражают результат |
| stop(operationId, reason) | Снимает desiredConnected, отменяет retries, освобождает свои ресурсы |
| subscribe(afterSequence) | Stream lifecycle и bounded diagnostic events |
| selectMember(groupId, nodeId, expectedActiveRevision) | Только если capability dynamicSelect; иначе RESTART_REQUIRED, а не скрытый reconnect |

Android: Flutter ↔ Pigeon bridge в UI process ↔ private AIDL/Binder service в `:vpn` process ↔ native core. Linux: Flutter client ↔ system D-Bus helper с аутентифицированным sender ↔ managed core worker. FD никогда не передаётся как обычное межпроцессное integer поле.

Ticket привязан к authenticated caller, плану и expiry (предлагается 60 s). Авторизация не кешируется произвольно между пользователями; prepare не равен разрешению привилегий для любого commit. Повторный operationId с тем же payload возвращает прежний результат/handle, с другим payload — IDEMPOTENCY_CONFLICT. Хранить последние 128 operation results или 10 минут; после перезапуска сначала inspect/resync, не предполагать вечную дедупликацию.

## События и порядок

Envelope: apiVersion, runtimeInstanceId, sessionId?, operationId?, sequence, monotonicTimestamp, eventType, payload. Sequence монотонен внутри runtime instance, отсчёт новый при restart. События StateChanged, PlanApplied, HealthChanged, TrafficSample, RedactedLog, OperationFailed. Последний authoritative snapshot включает sequence; клиент подписывается после него или повторяет inspect при gap. Устаревшие session events не меняют новое состояние.

Lifecycle events не терять; при переполнении медленному клиенту выдать ResyncRequired и snapshot. Логи bounded: 2 000 записей / 2 MiB, configurable; drop count виден. TrafficSample максимум 1 Hz при открытом экране, throttled в фоне. Нельзя заблокировать packet loop медленным listener.

## Ошибки

| Code | Значение | Автоматическое действие |
|---|---|---|
| INPUT_INVALID / INPUT_LIMIT | Некорректный/слишком большой input | Нет retry |
| UNSUPPORTED_CAPABILITY | Узел/правило нельзя исполнить на build | Сохранить importOnly, не ослаблять конфиг |
| REFERENCE_MISSING / GROUP_EMPTY | Несуществующая цель | Блокировать apply |
| APP_INCLUDE_EMPTY | Нет установленных приложений в include | Блокировать establish |
| PERMISSION_DENIED / VPN_REVOKED | Отказ/отзыв доступа | Не перезапрашивать циклом |
| CORE_INVALID_CONFIG | Check отклонил | Сохранить active plan |
| NETWORK_UNAVAILABLE | Нет underlying сети | Ждать network event с cancellation |
| DNS_BOOTSTRAP_FAILED | Невозможно разрешить endpoint | Retry bounded согласно network policy |
| CORE_START_TIMEOUT / CORE_CRASHED | Runtime не готов/упал | Recovery по lifecycle |
| REVISION_CONFLICT / STALE_PLAN | Изменились данные/среда | Пересобрать/показать diff |
| RESOURCE_CONFLICT | TUN/route/port принадлежит другому | Не удалять чужой ресурс |
| ROLLBACK_FAILED | Старый план тоже не стартовал | Явный failed и выбранная failure policy |
| SECRET_UNAVAILABLE | Key store locked/missing | Запрос unlock через UX, без plaintext fallback |

Предлагаемые limits: validate 10 s, start readiness 20 s, stop grace 5 s + terminate 2 s, network debounce 750 ms. Это параметры v1 для измерения в T00/T09, а не фактические показатели приложения. Cancellation кооперативна до commit; после commit новый Stop ставится в serialized supervisor и побеждает auto-reconnect.
