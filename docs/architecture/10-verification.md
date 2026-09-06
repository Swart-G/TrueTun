# 10. Проверки и критерии готовности

Наличие тестового файла не равно успешному тесту. Каждое свидетельство фиксирует commit, точный core/helper build, OS/API/ABI, scenario ID, command, actual result и redacted evidence. «Не запускалось» допустимо; «поддерживается» без проверки недопустимо.

## Пирамида проверок

| Уровень | Что проверяет | Чего не подтверждает |
|---|---|---|
| Pure unit/property | IDs, validation, graph, AST evaluator, normalization, serialization | Реальные поля ядра |
| Compiler contract/golden | Детерминизм plan и mapping source rules | Runtime semantics сам по себе |
| Exact core check | JSON/schema/build compatibility | Сервер доступен, TUN/DNS работает |
| Native/IPC tests | FD lifecycle, serialization, ownership, cancellation | Физическую сеть устройства |
| Controlled network E2E | DNS/TCP/UDP/IPv6 и выбранный egress | Работу любой сети и сайта |
| Device fault/soak | Process death, handover, permission, cleanup | Все OEM устройства |
| Widget/manual UX | Реальные состояния и доступность | Надёжность соединения |

Test doubles: FakeClock, FakeNetworkMonitor, FakeCoreRuntime, in-memory repositories, fake secret store, seeded parser fixtures. Инъекция failure на каждом шаге prepare/commit/cleanup. Fake runtime не должен становиться default production adapter.

## Acceptance scenarios

| ID | Сценарий | Ожидаемый результат |
|---|---|---|
| IMP-01 | VLESS Reality TCP, valid fixture | Сохранённые поля, core check и E2E соответствуют fixture |
| IMP-02 | Unknown security, duplicate conflicting query, malformed encoding | Safe diagnostic, нет TLS downgrade |
| IMP-03 | XHTTP на baseline без capability | ImportOnly, Connect disabled, mode сохранён |
| IMP-04 | YAML alias bomb, oversized gzip/base64, recursive provider | Bounded failure без memory exhaustion |
| SUB-01 | 304, 401, 429, timeout, invalid/empty/partial response | Старые nodes и active session сохранены |
| SUB-02 | Rename, reorder, credential rotation, vanished selected node | Stable IDs по policy, overrides сохранены, no silent direct |
| SUB-03 | URL edited пока refresh идёт | Response старой generation не коммитится |
| RTE-01 | Domain+CIDR+port, All/Any/Not truth tables | Reference и backend совпадают |
| RTE-02 | Unknown package под Not, platform mismatch | Guard/reject, не широкий match |
| RTE-03 | Domain suffix boundary, IPv6 CIDR, no-resolve | Документированная семантика |
| RTE-04 | Missing target/ruleset, empty group, cyclic graph | Apply заблокирован до смены сети |
| RTE-05 | Reorder conflicting direct/block rules | Реальный egress соответствует первому match |
| DNS-01 | Proxy hostname через bootstrap, proxied user DNS | Нет dependency cycle; paths соответствуют policy |
| DNS-02 | UDP/53 blocked, DoH unavailable, no default interface | Bounded recovery и точная причина |
| DNS-03 | IPv6/IPv4-only/NAT64, local names, custom app DoH | Нет незаявленного IPv6 escape; ограничения видимы |
| SES-01 | Double Connect, Stop во время check/start, late Ready | Одна generation, Stop побеждает retry |
| SES-02 | Bad candidate, rollback success/fail | Old active сохраняется до commit, затем точный outcome |
| SES-03 | Core/UI/helper death, full disk, locked secrets | Recovery без ложного Connected и утечки temp secrets |
| AND-01 | Include/exclude, empty include, last app uninstalled | Никакого расширения scope до all |
| AND-02 | Revoke, lockdown, Doze, handover, UI kill | Документированное service поведение |
| AND-03 | Shared UID/work profile/partial inventory | Верные ограничения и identity |
| LIN-01 | Denied/spoofed IPC, arbitrary executable/config/path | Helper отклоняет до privilege/network mutation |
| LIN-02 | Crash journal и changed external DNS/routes | Cleanup только собственных ресурсов |
| LIN-03 | Docker/ZeroTier/NetworkManager/suspend | Нет удаления чужой сети |
| SEC-01 | Seed secrets во всех error/log/export paths | Ни один sentinel не найден в output |
| DAT-01 | CAS conflict, secret write interruption, migration fail | Нет broken reference и потери committed data |
| UX-01 | Narrow/wide, dark/light, RU/EN, 200% text, keyboard | Все важные действия доступны |
| PERF-01 | 100 cycles, 30 min bidirectional transfer, 8 h idle | Нет monotonic resource leak; измеренные бюджеты |

## Network harness

Тестовые серверы принадлежат разработчику/CI и имеют одноразовые credentials. Fixtures в repository используют `.example`/`.invalid` и synthetic secrets. Для Reality нужен согласованный рабочий server setup с exact versions; фиктивный public key из unit test не годится для E2E. Генерация сервера/keys — будущая задача, сейчас стенд не создаётся.

Capture точки: client underlying interface, TUN где доступен, server ingress/egress. Test destination возвращает идентифицируемый response; проверять egress identity, а не только status 200. Для UDP — echo/controlled datagrams с loss counters, для больших transfer — bidirectional stream, для DNS — controlled resolver logs. Health endpoint outage проверять отдельно от proxy failure.

Android тестовый traffic должен исходить из included test app; собственный excluded UI HTTP request не считается dataplane test. Для bypass и DIRECT использовать две разные traffic paths и проверять соответствующее ожидание. Linux process tests запускают controlled child executable; permissions/metadata availability записываются.

## Матрица выпуска

T00 фиксирует min SDK и current supported Android SDK плюс ABI; physical arm64 обязателен. Linux Fedora x86_64 primary, Ubuntu x86_64 secondary; aarch64 отдельный gate. Не писать «все Android/Linux» по одному emulator и одному GitHub runner. Extended build имеет отдельный набор результатов.

## Definition of Done

Задача завершена, когда поведение соответствует спецификации, relevant scenarios реально пройдены, документация/ADR/schema обновлены, secret scan чист, diff ограничен scope, нет незаявленного fallback и отчёт воспроизводим. При внешнем blocker коммит может быть полезным draft, но milestone остаётся incomplete. UI placeholders и success returned by fake adapter не закрывают сетевые задачи.

Для этого документационного изменения достаточно целостности ссылок/разметки, согласованности контрактов и подтверждения, что исполняемые файлы не изменились. Flutter/native/network tests здесь не требуются и не запускались.
