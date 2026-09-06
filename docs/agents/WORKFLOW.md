# Процесс работы ИИ-агента

## Вход в задачу

Прочитай корневой AGENTS, docs index, baseline и task-specific contracts. Проверь текущий HEAD, branch, рабочее дерево и существующие local AGENTS. Текущее поручение задаёт scope; прошлый roadmap не разрешает разработку всего продукта. Архитектурную документацию не путай с существующим API: найди symbols и реальные signatures через поиск.

Сформулируй в 3–5 предложениях: какой пользовательский результат нужен; текущий пробел; task ID и dependencies; затрагиваемые модули; какое evidence докажет результат. Если контекста хватает, продолжай без уточнения рутинных решений. Если gate технически не подтверждён, сначала проведи допустимую проверку, затем предложи конкретное решение с фактами.

## Границы типов задач

| Тип | Разрешённый результат | Чего не добавлять автоматически |
|---|---|---|
| Architecture/docs | Markdown specs, ADR, задачи, обзор исходников | Native shells, dependencies, tests/code, compiled artifacts |
| Domain/compiler | Pure models, normalization, compiler и relevant tests | Native privileges, UI redesign |
| Android runtime | Service/IPC/FD/permissions и contracts | Другие platform policy semantics |
| Linux runtime | Helper/worker/ownership/package integration | Root GUI, arbitrary commands |
| Product feature | Screen + use case + verified integration | Success mocks в production |
| Release | Reviewable artifacts/evidence в порученном scope | Публикация без поручения, новая лицензия по догадке |

## Рабочий цикл

1. Ограничить diff и назвать контракт до реализации. Изменение public DTO/semantics сопровождается документом и backward-compatibility решением.
2. Для существующего неправильного поведения подготовить минимальный воспроизводимый сценарий. Не переписывать все tests сразу.
3. Выполнить минимальный вертикальный срез. Удалить temporary fake wiring из production paths.
4. Запустить относящиеся к риску проверки. Flutter analyze/test сами по себе не подтверждают native/VPN integration.
5. Проверить error/cancel/retry/cleanup, redaction и schema versions. Сопоставить результат с acceptance ID.
6. Просмотреть final diff, убедиться в отсутствии посторонних изменений/секретов/непреднамеренной generated churn. Подготовить reviewable PR с problem→change→behavior→evidence.

## Review по зоне ответственности

Domain reviewer проверяет invariants и identity. Compiler reviewer проверяет semantic equivalence и capability gating. Platform reviewer — resource/privilege/FD ownership. Reliability reviewer — stale events, retries и rollback. Product reviewer — actual state, accessibility и misleading support claims. Это checklist одной задачи; отдельные агенты создаются только при явном поручении на delegation.

Если работа агентов отдельно разрешена, разбить по непересекающимся owned paths, согласовать DTO/version contract до edits, назначить одного integrator. Нельзя параллельно менять одну schema или state machine без общего owner. Передача агента не завершает integration acceptance.

## Definition of Ready

Задача имеет ID, goal/non-goals, dependencies, relevant spec, owned files, acceptance scenarios и доступный способ проверки. Если реального устройства нет, задача может закончиться draft implementation с not-run gate, но не claim production support. Unknowns перечисляются с конкретной проверкой, а не общим «потом протестировать».

## Передача контекста

В итоговом сообщении/PR: исходный commit; реализованные task IDs; изменённые contracts; tests с actual result; что не запускалось и почему; known gaps; exact next task. Для продолжения достаточно этой записи и docs index; не требовать чтения всех прежних чатов. Не записывать реальные tokens/UUID/password/server config в handoff.

## Обновление документации

Baseline append/update с новым checked commit только после чтения кода. Статус supported изменяется только с platform evidence. При новом ADR ссылки на superseded решение и затронутые contracts обязательны. Числовые budgets изменяются по измерению, а не для маскировки регрессии. Не копировать требования во множество файлов: index/AGENTS направляют к единому нормативному разделу.

## Пример корректного отчёта

«T06 plain/base64 subscription import: добавлены bounded parser и transactional reconcile; SUB-01/03 проходят в integration tests с mock HTTP; Android scheduled refresh не запускался, устройство недоступно. Native connection не менялся. Следующая задача — T06 JSON/YAML adapters». Это информативнее «подписки полностью готовы», когда часть сценариев не проверена.
