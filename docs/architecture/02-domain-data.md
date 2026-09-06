# 02. Domain, данные и миграции

Статус: целевой контракт v1. Имена типов — спецификация, не добавленные Dart-классы. Времена persisted — UTC, таймеры и deadlines — monotonic clock. IDs — UUID, генерируемые приложением; display name и endpoint не являются ID.

## Сущности

| Сущность | Основные поля | Инварианты |
|---|---|---|
| ProfileSource | id, kind(manual/subscription/file), label, revision, createdAt | Источник владеет imported nodes, но не пользовательскими правилами |
| Subscription | sourceId, urlSecretRef, headersSecretRef, refreshPolicy, etag, lastModified, lastSuccess, status | URL целиком секретен; 304 не меняет nodes |
| ProxyNode | id, sourceId, protocol, endpoint, tls, transport, credentialRef, extensions, supportState | Port 1..65535; protocol-specific tagged union; неизвестное поле сохраняется без исполнения |
| NodeOverride | nodeId, userLabel, tags, enabled, preferred | Обновление источника не перезаписывает пользовательское |
| ProxyGroup | id, label, kind, members, selectedNodeId, healthPolicy | Ссылки только на существующие eligible members; нет циклов |
| RoutingPolicy | id, revision, orderedRuleIds, finalAction, platformScope | Есть finalAction; уникальные позиции и IDs |
| RoutingRule | id, label, enabled, scope, expression, action | Непустое ограниченное выражение; action=node/group/direct/block |
| RuleSet | id, source, format, checksum, trust, activeVersion, refreshPolicy | В snapshot фиксируется immutable version |
| AppAccessPolicy | id, mode, packageIdentities, revision | Нельзя получить пустой effective include при apply |
| AppSuggestion | identity, recommendation, reasonCode, evidence, confidence, providerVersion | Это предложение, не применённая политика |
| DnsPolicy | resolvers, orderedRules, bootstrap, finalResolver, ipv6Policy | Ссылки валидны; dependency graph ацикличен |
| ConnectionPreset | id, source/group selection, routingPolicyId, appPolicyId, dnsPolicyId, backendChannel | Один complete preset собирает snapshot |
| ConnectionSnapshot | snapshotId, desiredRevision, entityVersions, assetHashes, platformFacts, buildId | Immutable; полная ссылочная замкнутость |
| SessionRecord | sessionId, operationId, activeRevision, buildId, state, lastErrorCode | Не содержит raw конфиг/секреты |

TLS и transport — отдельные tagged unions, не набор несовместимых nullable полей. Domain различает TLS serverName, Reality spider path, transport path, host header и gRPC authority. Семантика неизвестного extension не угадывается. Невозможные сочетания дают structured diagnostics.

## Идентичность узлов и обновление

NodeId стабилен внутри source. Для первичного сопоставления использовать документированный provider ID, если он стабилен и уникален. Иначе canonical fingerprint по protocol/endpoint/security/transport и credential material, вычисленный локально HMAC с installation key; не label и не открытый SHA от секрета. Нормализовать host case/IDNA, defaults только когда их эквивалентность известна. Порядок query и label не влияют; неизвестные semantically significant extensions влияют. Ключ HMAC не экспортируется в диагностику.

Поворот credentials без provider ID может создать новый NodeId; не обещать автоматическую идентичность. Неоднозначное сопоставление не объединять по одному имени. Сохранить orphan/tombstone с предупреждением и дать remap. Удалённый узел, используемый active snapshot, сохраняется до освобождения session reference. Group на источник получает новый состав; ручной pinned member, исчезнувший из подписки, становится unavailable. Никакого fallback в DIRECT при пустой группе.

Duplicate nodes в разных источниках не объединяются автоматически: разная принадлежность и секреты. В одном источнике идентичные fingerprint можно свести с отображением количества дубликатов в preview.

## Хранение

Предложение: SQLite + Drift. Таблицы: profile_sources, subscriptions, nodes, node_overrides, groups, group_members, routing_policies, routing_rules, rule_sets, rule_set_versions, app_policies, app_policy_members, dns_policies, presets, revisions, session_records, settings, migration_history. Typed columns для IDs/status/revisions; versioned JSON payload допустим для protocol union/expression. Foreign keys включены; каскадное удаление не должно удалять пользовательский rule без explicit reconciliation.

Транзакция сохраняет целый logical change. Optimistic concurrency: write(expectedRevision) либо возвращает новую revision, либо REVISION_CONFLICT. При конфликте UI перечитывает данные и показывает diff; не перезаписывает чужое изменение last-write-wins. Snapshot читается одной read transaction; связанные assets пинятся до start.

Credential payload, raw share link, URL с токеном и authentication headers шифруются AEAD; key wrapping через Android Keystore или Linux Secret Service. Public endpoint metadata может оставаться в private SQLite: это не анонимные данные и не должно уходить в telemetry. Linux при недоступном keyring предлагает password-protected vault или memory-only session; silent plaintext fallback запрещён.

Secret store и SQLite не имеют общей ACID-транзакции. Протокол: создать pending encrypted secret → commit ссылку в SQLite → mark referenced. Recovery GC удаляет только неиспользуемые pending secrets после grace period и проверки live snapshots. Удаление: сначала tombstone references, затем после освобождения snapshots удалить secret. Прерывание посередине не оставляет broken committed reference.

## Версии и recovery

Разделять app release version, database schemaVersion, payloadVersion, IPC apiVersion, config schema family и core build ID. Ни одна не подменяет другую. Unknown enum сохраняется как unsupported opaque entry и не компилируется. Unknown major DB schema: открытие только read-only/export если формат безопасно читаем; не выполнять destructive downgrade.

Миграция: exclusive migration lock → проверка свободного места → согласованный backup средствами SQLite → transaction migration → foreign-key/integrity checks → commit. При fail сохранить старую БД/backup, не очищать данные. Для будущих real schemas тестировать N-1 → N, прерывание и повреждённый payload. Первый v1 создаётся заново, не имитировать существующую базу.

Runtime JSON материализуется только перед validate/start в защищённой runtime directory или native memory. Last-known-good хранится как encrypted snapshot/capsule с refs/assets, не как plaintext JSON в preferences. Старый core build должен сохраняться для rollback только если его целостность подтверждена и он не отозван.

## Export/import

TrueTun export имеет formatVersion и не содержит platform ephemeral paths, FD, PID, socket names. По умолчанию без секретов: placeholders и отчёт, какие данные нужны для подключения. Полный export — отдельное явно выбранное действие с шифрованием и предупреждением в UI. При переносе Android package identities и Linux process identities сохраняют scope и становятся inactive на другой платформе с заметной диагностикой. Runtime snapshots не являются переносимыми profiles.
