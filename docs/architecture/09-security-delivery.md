# 09. Безопасность, диагностика и поставка

## Модель доверия

| Вход/граница | Риск | Обязательный контроль |
|---|---|---|
| Subscription/share link/YAML | Credentials disclosure, resource exhaustion, config injection | Bounded parser, typed normalization, no native passthrough |
| Remote rule set | Подмена routing/blocking, corrupt binary | Trust metadata, format validation, last-known-good, preview/version pin |
| UI→privileged helper | Локальное повышение прав | Sender authentication, Polkit, allowlisted schema, fixed binary |
| Runtime logs/errors | UUID/password/token exposure | Redact before fan-out, bounded storage, safe error codes |
| Core/update artifact | Supply-chain compromise, incompatible schema | Source commit + hash + trusted delivery + build evidence |
| Package inventory | Privacy disclosure | Local-only processing, optional generic hint DB |
| Persisted secrets | Theft from backup/temp/database | AEAD/key wrapping, private paths, encrypted backup |

Нельзя считать данные trusted потому, что они пришли из личной подписки. Не исполнять скрипты и template code. Не помещать remote strings в shell или privileged filesystem path. Domain extension maps никогда не проходят напрямую в core config.

## Runtime secrets

Android app-private storage и Linux XDG data/runtime paths с mode 0700 для directories, 0600 для sensitive files. Использовать безопасное создание файлов, не follow symlinks, не помещать credentials в CLI args/environment. JSON после validate удаляется в finally, crash cleanup выполняется при следующем reconcile. Нельзя обещать физическое secure erase на flash; минимизировать время и объём plaintext.

Default logs: timestamp, operation/session ID, stage, error code, safe counters. UUID, passwords, private keys, subscription URL/query/header tokens, userinfo, raw config и raw share links редактируются. Имена nodes могут содержать URL/секрет: они тоже недоверенный текст. Redaction структурная по полям плюс defensive raw-line sanitizer; неизвестная строка с высоким риском не экспортируется целиком.

Предлагаемый retention: memory ring 2 MiB, file diagnostics opt-in до 10 MiB/3 files, max age 7 days; crash bundles выключены до согласованного redaction. User can clear. Установленные apps, посещённые домены и IP history по умолчанию не сохраняются. Aggregate traffic counters — локально и с документированным reset.

## Diagnostic bundle

Default export: app/core/helper version+hash, platform capability facts, redacted lifecycle timeline, validation error codes, anonymous entity mapping, asset versions и test summary. Исключить raw SQLite, credentials, URLs, memory dump, packet payload и полный app inventory. Перед выдачей bundle повторно проверить seeded secret patterns. Полный конфиг с секретами — отдельное явно выбранное действие экспорта профиля, не checkbox по умолчанию в diagnostics.

Core crash не инициирует автоматическую загрузку bundle. Никакая telemetry network отправка не появляется транзитивно из «умных подсказок». Возможная будущая telemetry требует отдельного opt-in design.

## Build manifest

Каждый runtime artifact описывается buildId, upstream repository/commit/tag, patches, toolchain, build flags, OS/ABI, hash, signature provenance, config schema family, supported feature tuples, license notices и regression evidence IDs. Binary по PATH допускается только development mode с явным unknown support state.

Manifest hash не заменяет trusted delivery: если binary и hash загружены с одного подменённого канала, authenticity не доказана. Release pipeline pin-ит dependencies/CI actions, формирует SBOM и provenance, хранит ключи signing вне repository. APK signing key не генерируется заново при каждом build. Номер package versionCode нужен платформе даже если пользовательские релизы называются без semver; схема релизов утверждается отдельно.

## CI по мере реализации

1. Docs-only: relative links, Markdown fences, scope diff. Не требовать native device tests для Markdown.
2. Domain/compiler: non-mutating format check, analyze, unit/property/contract tests, generated-code consistency.
3. Native changes: Android build/lint/native unit; Linux helper build/static checks; pinned core check fixtures.
4. Network release gate: controlled test servers, physical Android и Linux VM/host, packet capture evidence, fault injection.
5. Release: подписанные artifacts, ABI matrix, migration fixtures, license inventory, clean-install/upgrade/uninstall, documented known limitations.

Build/check команды будущих компонентов должны появиться в repo только при их реализации; не выдавать предложенные команды за уже рабочие. Текущий CI описан в baseline и не меняется этим docs PR.

## Performance budgets как измеряемые цели

Первый baseline измерить в T09 на указанном устройстве. Предлагаемые цели: UI не блокируется parser/compiler >16 ms на frame (тяжёлую работу выносить в isolate), import 1 000 nodes ≤2 s на reference device, local ready ≤5 s после уже выданного consent и доступной сети, stop ≤7 s, 100 циклов без роста FD/process count. Throughput оценивать относительно того же core на той же сети: overhead goal ≤10%; отдельно memory/CPU idle и screen-off battery over 8 h. Это цели, не подтверждённые характеристики; если недостижимы, публиковать измерение и ADR, а не подгонять тест.
