# Маршрутизация: точная семантика TrueTun

Статус: нормативный проект v1. Этот документ заменяет прежнее упрощение «поля напрямую соответствуют sing-box». Упорядоченная модель вдохновлена Mihomo, но stored format — TrueTun.

## 1. Порядок и действия

Rules проверяются сверху вниз; первое совпавшее терминальное действие завершает выбор. Disabled rule не участвует. Final action — отдельное обязательное поле, применяется при отсутствии совпадений. Пустая обычная rule запрещена, даже disabled draft должна получить ошибку перед enable. Proxy target хранится как NodeId или GroupId; compiler создаёт tags из IDs и проверяет отсутствие коллизий. Direct — прямой outbound внутри VPN, Block — reject/drop в целевом backend. Вход в VPN определяет отдельный Android app filter.

Встроенные loop-prevention механизмы работают на уровне sockets/routes, а не скрытой пользовательской rule «всегда DIRECT на весь IP сервера». DNS interception и sniffing — compiler service actions; они должны отображаться отдельным служебным слоем в diagnostic preview. Пользовательский order не переставляется optimizer-ом.

## 2. Выражения

Внутренняя форма: Predicate(kind, values), All(children), Any(children), Not(child). Values в Predicate — OR. All — AND всех children; Any — OR; Not применяется ко всему подвыражению. Визуальный простой редактор строит All непустых категорий; advanced mode позволяет явные Any/Not. Не разрешать пустые All/Any, Not без child, неизвестные predicates. Proposed limits: depth 8, 256 predicate leaves на rule, 2 000 rules на policy; чрезмерное выражение отвергается, а не обрезается.

Точная формула простого примера: `(domain == a.example OR domain == b.example) AND (port == 443 OR port == 8443) AND network == tcp`.

| Domain совпал | Port совпал | TCP | Результат |
|---|---|---|---|
| Да | Да | Да | Совпадает |
| Да | Нет | Да | Не совпадает |
| Нет | Да | Да | Не совпадает |
| Да | Да | Нет | Не совпадает |

`domain` и `domainSuffix` — отдельные predicates. Если пользователь хочет «точный домен ИЛИ суффикс», UI создаёт Any явно. Миграция старой flat модели не должна угадывать намерение: текущие fixtures + preview и explicit semantics version.

В sing-box default rule некоторые destination-поля объединяются через OR; прямой flat map может расширить TrueTun All. Backend должен генерировать logical rule tree с изолированными predicates и терминальным action на наружном узле, либо доказанно эквивалентную форму. Rule-set также изолируется, чтобы особая merge-семантика ядра не изменила выражение. Точный JSON зависит от pinned schema и подтверждается core check и truth-table integration tests. [Источник: sing-box Route Rule](https://sing-box.sagernet.org/configuration/route/rule/).

## 3. Match context и неизвестные факты

FlowContext: source/destination IP, ports, transport network, originalDomain?, sniffedDomain?, detectedProtocol?, packageIdentity?, processIdentity?. Domain matching использует доступный originalDomain и только явно разрешённое evidence от sniffing. TLS encryption/ECH/DoH могут оставить поле unknown; не обещать узнать любой домен.

Reference evaluator возвращает true/false/unknown. Неизвестное поле и его отрицание не становятся совпадением; окончательное unknown пропускает rule. Backend с другой NOT-семантикой обязан сформировать existence guard либо отвергнуть такой matcher как UNSUPPORTED_CAPABILITY. Особенно важно для Not(package/process/protocol). Это gate T04; нельзя применять Not, превращающий отсутствие метаданных в широкое совпадение.

`NETWORK` — L4 TCP/UDP (прочее только capability); `PROTOCOL` — распознанный application protocol. IP rule не должна скрыто требовать remote DNS до bootstrap. Если evaluator не знает IP до resolution, preview помечает результат unknown, а не придумывает маршрут.

Domain suffix: canonical IDNA lowercase, убрать один trailing dot, совпадает сам suffix и поддомены по границе label; `notexample.com` не совпадает `example.com`. IP CIDR проверяется структурно и canonicalized; ranges — числовые 1..65535. Regex проверяется на синтаксис целевого engine, ограничение размера и затрат; Dart RegExp не является доказательством совместимости Go engine.

## 4. Scope и platform capability

Rule.scope = all/android/linux. Правило явно scoped к другой платформе сохраняется и показывается inactive с причиной. Правило scope=all с Android-only matcher на Linux — compile error, а не удаление predicate. Нельзя silently переводить packageName в processName. Unsupported enabled matcher внутри активного scope блокирует Apply. Package regex, process path lookup, ICMP и sniff protocols имеют собственные capabilities, не выводятся из версии OS.

## 5. Импорт Mihomo subset

| Вход | TrueTun | Ограничение |
|---|---|---|
| DOMAIN / DOMAIN-SUFFIX / DOMAIN-KEYWORD | Соответствующий Predicate | Canonicalize домен |
| IP-CIDR / IP-CIDR6 | destination CIDR | Сохранить no-resolve как семантический флаг; если backend не воспроизводит — importOnly |
| SRC-IP-CIDR | source CIDR | Проверить IPv4/IPv6 |
| DST-PORT / SRC-PORT | Port predicate | Проверить ranges |
| PROCESS-NAME / PROCESS-PATH | Linux scoped predicate | Не исполнять executable |
| RULE-SET | RuleSetId reference | Provider format и conversion должны быть поддержаны |
| MATCH | Final action | Только последний безусловный fallback; если после него rules, отчёт об unreachable, без тихого reorder |
| DIRECT / REJECT | Direct / Block | Различия reject/drop отображаются в report |
| Имя proxy/group | Stable ID lookup | Duplicate names требуют resolution |
| GEOIP / GEOSITE / логические расширения | ImportOnly до отдельного converter | Не скачивать случайную базу и не подменять semantics |

Parser не сводить к наивному split(',') для всех форматов: учитывать grammar конкретного subset. Разрешённый import report содержит source location, original text в protected draft, matched rule ID и unsupported meaning. Nodes-only import внешней конфигурации — default; import rules/groups — explicit preview. Inbounds, scripts, controller endpoints и native tun options не применяются из подписки.

## 6. Rule sets

RuleSet содержит стабильный ID, source kind(bundled/local/HTTPS), source format, rule semantics version, trust metadata, refresh policy, lastSuccess и immutable artifact versions. Compiler получает только локальный validated asset hash и type; HTTP при Connect не делает.

Update: bounded fetch → parse/convert в отдельном worker → проверить syntax/core compatibility → вычислить checksum → atomic rename content-addressed asset → DB CAS active version. Параллельный session pin удерживает старый asset. Невалидный update сохраняет last-known-good и показывает stale status. Checksum, вычисленный после загрузки, выявляет corruption, но не доказывает авторство; authenticity требует доверенного pinned hash/signature channel.

Обязательный ruleset отсутствует при offline first run — точная ошибка ASSET_MISSING, без пропуска block rule. Bundled local-network набор доступен offline. Remote update не должен автоматически менять active policy до Apply/явно выбранного auto-apply режима. Поддержка Mihomo YAML/MRS или sing-box SRS определяется format/version converter, а не расширением файла.

## 7. Диагностика и тесты

Preview показывает ordered rule IDs, final target и mapping generated rules → source rule. «Почему этот маршрут» может быть static explanation или runtime evidence; UI помечает источник. Если core не отдаёт matched rule, не изображать вычисленную догадку измеренным фактом.

Обязательны: truth tables All/Any/Not; AND domain+CIDR не превращается в OR; неизвестный package под Not; IPv6; suffix boundary; duplicate tags; missing target; scope mismatch; reorder меняет ожидаемый action; rule-set merge isolation; no-resolve; пустая группа; недоступные assets. Reference evaluator и backend проверяются на одинаковых flow fixtures.
