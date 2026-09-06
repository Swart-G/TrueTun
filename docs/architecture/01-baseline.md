# 01. Состояние проекта и переход к целевой архитектуре

Проверено чтением исходников на `76e5c834e940072caf04591818e2440a7607cde3`, 2026-09-06. Flutter-тесты и соединение с сервером при подготовке документации не запускались. В этой редакции изменяются только Markdown-файлы.

## Инвентаризация

| Существующий путь | Реально есть | Чего это не доказывает |
|---|---|---|
| `lib/src/app.dart` | Material 3 shell, адаптивная навигация, заглушки экранов | Рабочее управление подключением |
| `lib/src/core/core_adapter.dart` | start/stop/validate, события, минимальные capabilities | Готовность TUN, reconcile, IPC, version negotiation |
| `lib/src/core/process_sing_box_adapter.dart` | Запуск executable из PATH, check, временный JSON, чтение логов | Production Linux TUN, устойчивость и безопасное хранение |
| `lib/src/profiles/proxy_node.dart` | Typed VLESS и enum других протоколов | Парсеры остальных протоколов, stable IDs, storage |
| `lib/src/profiles/vless_link_parser.dart` | VLESS-поля, TLS/Reality, transport, XHTTP mode | Без потерь для произвольной ссылки и совместимость серверов |
| `lib/src/profiles/profile_input_detector.dart` | Эвристика распознавания входа | HTTP-загрузка, YAML/JSON import, безопасный parser |
| `lib/src/core/sing_box_outbound_compiler.dart` | Преобразование VLESS в map, отказ для XHTTP | Полный валидный конфиг на выбранной сборке |
| `lib/src/routing/*` | Плоская модель matcher и компиляция полей | Заявленная AND-семантика на реальном ядре |
| `lib/src/apps/app_routing_policy.dart` | Include/exclude payload и локальные эвристики | Native фильтрация, перечисление приложений |
| `test/routing_compiler_test.dart` | 7 unit tests на detector/parser/maps/policy | Проверка ядром, TUN, сетевой или device E2E |
| `.github/workflows/ci.yml` | pub get, formatter, analyze, unit tests | Пин SDK/core, native builds, release gate |
| `tool/bootstrap.sh` | Генерация Flutter shells командой flutter create | Существующие `android/` и `linux/` в репозитории |

Нет persistence, state-management dependency, secret store, supervisor, Android service, Linux helper, полного DNS/compiler pipeline, подписок, реестра capabilities, нативных platform shells и проектного LICENSE. `pubspec.yaml` содержит Flutter и flutter_lints; версии новых библиотек ещё не утверждены.

## Выявленные риски, не исправленные кодом в этой задаче

1. `getCapabilities()` возвращает статический список независимо от состава binary. В production требуется build manifest + handshake + проверенные fixtures.
2. Process adapter считает `running` сразу после Process.start. Это означает только созданный процесс, не готовые маршруты/DNS.
3. stop ожидает exit без timeout; отсутствуют сериализация операций, session IDs, отбрасывание устаревших событий, гарантированное завершение streams.
4. Временный JSON содержит секреты; логи и ошибки пересылаются без redaction. Нужны права доступа, retention и crash cleanup.
5. AppRoutingPolicy умеет вернуть пустой include-list. Native слой обязан остановить применение до establish, иначе расширится VPN scope.
6. Domain app policy уже формирует native/core maps; будущая миграция должна вынести это в платформенный/compiler адаптер.
7. Плоский route compiler не гарантирует AND между разными категориями: в sing-box некоторые destination fields объединяются иначе. Нужны явные logical nodes.
8. Импорт `type=tcp&headerType=http` сейчас отображается на HTTP transport, а `spx` используется как запасной transport path. Сохранение исходной семантики не подтверждено; нужны отдельные representation и fixtures, а не предположение об эквивалентности.
9. Неизвестное `security` сейчас приводит к disabled TLS. Будущий importer обязан отвергать неизвестную security-семантику, а не понижать её.
10. Query multivalue, неизвестные поля, корректное однократное percent-decoding и многолинейный detector требуют тестов. Эвристика не является доказательством формата.
11. Прямые outbound tags в RouteAction нестабильны относительно обновления подписок; заменить ссылками на NodeId/GroupId.
12. Текущий CI форматирует код на runner вместо проверки неизменности; это записывается как будущая задача, workflow здесь не меняется.

## Путь миграции

Сначала добавить characterization tests существующего приемлемого поведения. Для потенциально неправильного поведения зафиксировать регрессионный сценарий с ожидаемой новой семантикой; не закреплять ошибку как контракт. Затем в отдельных задачах внедрить IDs и domain ports, перенести compiler/native serialization, создать session supervisor и соединить первый вертикальный срез.

Не перемещать все файлы одновременно. Старые публичные точки входа временно делегируют новым слоям; временный wrapper имеет задачу на удаление. Пока persistent database ещё нет, новая schema v1 не требует миграции из несуществующей БД, но импорт старых JSON/export при их появлении должен быть явно версионирован.
