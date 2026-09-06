# Готовые задания агентам

Эти шаблоны пользователь может дать следующему агенту. Они не запускают реализацию самостоятельно. Подставить актуальный HEAD и выбранный task scope; не требовать конкретный commit baseline после развития репозитория.

## A. Проверка осуществимости, документация

> Изучи AGENTS.md, docs/README.md и T00. Проверь выбранные кандидатные версии ядра по исходникам и официальным API. Подготовь compatibility report: exact build/source, Android mobile binding/protect/FD, Linux TUN ownership, routing logical semantics, XHTTP modes и ограничения. Изменяй только документацию. Раздели подтверждённые факты и то, что требует сборки/устройства. Не добавляй код приложения и не объявляй E2E support. Обнови ADR gates и предложи следующий ограниченный implementation task.

## B. Foundation

> Реализуй только T01 из docs/ROADMAP.md после проверки его gate. Сохрани Flutter UI основу. Введи IDs/domain ports и транзакционное storage v1 с encrypted secret references и CAS revisions. Native shells и dependencies — отдельный обозримый diff, pin toolchain. Не запускай VPN и не разрабатывай все страницы. Подтверди DAT-01 и отсутствие plaintext secrets, сообщи реальные команды и результаты.

## C. Компилятор маршрутизации

> Реализуй часть T04: AST, reference evaluator и compiler backend для domain/suffix/CIDR/port, All/Any/Not и final action. Следуй docs/ROUTING.md. Для Not над unknown metadata реализуй guard либо явный capability refusal. Не меняй native/runtime/UI. Проверь RTE-01..04 на pinned core, не только golden maps. Неподдерживаемые поля не удаляй. Если точный core отсутствует, укажи core-check gate как not-run.

## D. Android native

> Реализуй T03A в согласованных границах docs/architecture/06-android.md. Один supervisor, отдельный service process по принятому ADR, private IPC, protect callbacks и документированное FD ownership. Предусмотри permission denial/revoke, Stop во время Start, UI process death и empty include guard. Не добавляй экран рекомендаций. Приложи actual device/emulator evidence отдельно; не объявляй always-on/lockdown поддержку без проверки.

## E. Linux helper

> Реализуй T03L только после подтверждения T00 Linux binding gate. GUI остаётся непривилегированным. Helper валидирует typed plan, sender/Polkit и root-owned artifact; владеет ровно своими ресурсами. Запрети arbitrary executable/path/config/shell injection. Проверь LIN-01/02, crash journal и changed external DNS. Не заменяй TUN acceptance локальным SOCKS smoke test.

## F. Подписки

> Реализуй T06 только для plain/base64 share-link lists. Используй ImportDraft, limits, encrypted URL/headers, ETag/304, CAS update и stable node identity. Background partial/empty/invalid response сохраняет старый source. Refresh не переключает active snapshot. Покрой SUB-01..03 и IMP-04. JSON/YAML и новые protocols оставь последующим задачам.

## G. Android app lists и smart suggestions

> Реализуй T07 после native app filter. Обработай partial PackageManager visibility, missing apps, empty effective include, смену режима с preview, shared UID ограничения. Suggestions локальные, объяснимые, применяются только к draft после выбора. Не загружай installed-app inventory. Подтверди AND-01/03 и что advanced Block не обещается для bypass app.

## H. Проверка архитектурного соответствия

> Проведи read-only review последнего diff и затронутых contracts. Найди semantic drift, unsupported capability claims, lifecycle races, leaks/privilege mistakes и неработающие acceptance gates. Выдай findings с file/symbol, воспроизводимым сценарием, impact и минимальной рекомендацией. Не исправляй код автоматически и не расширяй scope. Отличай observed defect от hypothetical risk.

## I. Release readiness без публикации

> Проверь T12 для конкретного feature scope. Составь матрицу exact artifact builds, реально пройденных platform scenarios, migration/signing/packaging/notice gates и оставшихся blockers. Не публикуй release, не меняй проектную лицензию, не заявляй unsupported protocols. Дай конкретный следующий шаг для каждого blocker.
