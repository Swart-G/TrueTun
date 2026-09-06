# Импорт, подписки и поддержка протоколов

Успех parser, core check и работающее соединение — три разных доказательства. В baseline реализован только начальный VLESS parser/compiler; перечисление схем в detector или enum не означает поддержку протокола.

## 1. Capability matrix

| Приоритет | Семейство | Baseline репозитория | Условие подключения |
|---|---|---|---|
| P0 | VLESS TCP + TLS/Reality | Parser и outbound map | Exact build, flow/fingerprint validation, Android/Linux E2E |
| P0 | VLESS WS/gRPC/HTTPUpgrade | Поля парсятся и компилируются | Проверенные server fixtures каждой комбинации |
| P0 discovery / P1 integration | VLESS XHTTP | Частичное сохранение import, compiler отклоняет | Отдельный backend, mode/options и upload/download E2E |
| P1 | Trojan, Shadowsocks, VMess | Только protocol enums/detection | Tagged models, parsers, full fixtures |
| P1 | Hysteria2, TUIC | Только enum/detection | QUIC/UDP build capability и network tests |
| P2 | SSH, WireGuard | Только enum/detection | Актуальная модель core и platform integration |
| P2 | HTTP/SOCKS proxy inputs | Частичная scheme detection | Различать proxy URL и subscription URL, UI choice при неоднозначности |
| P2/P3 | AnyTLS, Naive, Amnezia variants | Нет реализации | Отдельные parser/build/platform/license gates |

Каждая строка разворачивается в tuple protocol+transport+security+flow+UDP+platform+ABI+build. SupportState: unsupported, importOnly, experimental, supported. `supported` требует acceptance из verification; latest upstream docs не подтверждают shipped binary. WireGuard и AmneziaWG — разные возможности, конвертация WG не означает AWG. VLESS XHTTP import не подменяется TCP/WS. Список transport options сверяется с [upstream V2Ray transport](https://sing-box.sagernet.org/configuration/shared/v2ray-transport/), но pin решает применимость.

## 2. Input pipeline

InputHandle = pasted text / shared intent / local file / remote source; clipboard не читается периодически без действия пользователя. Детектор выдаёт candidates с confidence, затем настоящий parser подтверждает формат. Порядок: bounded size → текстовая кодировка → явный структурированный формат/многострочный список → одиночный URI → bounded base64 decode и повторная проверка. Не считать любую длинную base64 строку подпиской.

Proposal limits v1: 10 MiB downloaded/decompressed body, 10 000 nodes, 64 KiB на URI, YAML/JSON depth 32, максимум один base64 unwrap, 5 redirects, connect timeout 10 s и total fetch 30 s. Limiter считает decompressed bytes и parse memory, а не только Content-Length. XML/entity/script/custom YAML tag execution не допускается; YAML alias expansion ограничивается. Превышение — INPUT_LIMIT с unchanged existing source.

ImportDraft содержит valid nodes, unsupported preserved nodes, errors(source location), warnings, duplicates, ignoredSections и required capabilities. Сохранение partial manual import возможно после preview. Фоновое refresh при parse errors не заменяет source по умолчанию; пользователь может явно принять partial update. Нулевой результат обновления не удаляет предыдущие узлы автоматически. Unsupported-but-preserved nodes не являются parse error, но preview показывает невозможность Connect.

## 3. VLESS требования

Проверять URI host/IPv6 brackets/port, credential syntax, duplicated query keys, supported security enum, TLS/Reality requirements, flow/transport compatibility. Неизвестный security блокирует подключение. UUID строгой baseline формы сохраняется пока выбранная спецификация не докажет другой допустимый формат; не ослаблять parser по догадке.

Decode percent-encoding ровно один раз по компонентам URI. Различать `%2F` в path, `%25` и уже decoded fragment; не double-decode display name. Query multi-values сохраняются; конфликт `sni` и `serverName` не разрешается случайным порядком map. Реальные aliases нормализуются только при доказанной эквивалентности. `spx` не транспортный path, TCP HTTP header camouflage не автоматически HTTP transport.

TLS enabled/serverName/ALPN/insecure/fingerprint и Reality publicKey/shortId сохраняются структурно. Insecure из ссылки требует заметного warning и explicit acceptance; не менять его молча ни в одну сторону. Unknown extensions хранятся bounded вместе с source format; не вставляются raw в generated config. Credential rotation и normalization учитывают stable identity правила из data spec.

## 4. Подписки

Source хранит encrypted URL/headers, расписание, fetch route policy, ETag/Last-Modified и display metadata. HTTP client проверяет TLS; custom CA только через явное user setting и отдельный gate. Redirect на другой origin не получает Authorization/Cookie/custom secret headers исходного origin. HTTPS→HTTP downgrade запрещён default. URL/headers не логируются. Private/local URL допускается как явный пользовательский source; redirects к loopback/link-local/private destinations требуют отдельного подтверждения назначения либо блокируются, чтобы внешняя подписка не исследовала локальные сервисы.

Refresh: fetch → 304 unchanged или parse candidate → normalize → reconcile IDs/overrides/groups → validate references → CAS transaction → notify diff. 401/403 означает auth required, не aggressive retry; 429 учитывает Retry-After; 5xx/timeout exponential bounded backoff с jitter. Defaults: auto refresh 12 h, min interval 15 min, per-source concurrency 1, global concurrency 2. Это проектные настройки, менять после измерений, не обещать exact timer в Android background.

Metadata traffic/expiry из subscription headers считается внешним утверждением. Проверять единицы, переполнение/отрицательные числа/дату; показывать unknown при некорректном значении. Не путать billed traffic с локальными счётчиками TrueTun.

Отключение refresh не удаляет nodes. Редактирование subscription URL создаёт новую fetch generation; запоздавший response старого URL не коммитится. Отмена не оставляет half source. Background update не вызывает скрытый reconnect.

## 5. JSON/YAML конфиги

Default import — только nodes. Groups/rules импортируются отдельным preview с semantic mapping report. Не применять из внешнего файла inbounds, listen addresses, external controller, local paths, tun flags, scripts, arbitrary download sources или runtime cache paths. Full native config passthrough исключён из v1: он ломает единый policy/compiler authority.

sing-box schema version и Mihomo dialect — явные inputs parser adapters. Provider references требуют bounded graph и cycle detection; автоматический обход произвольных nested URLs выключен. Файлы rule-provider не считать profile subscription. Неподдерживаемый набор сохраняется как protected source attachment/importOnly с объяснением, не «успешно подключён».

## 6. Протокол расширения

Для нового протокола агент добавляет: domain tagged variant; parser с real sanitized fixtures; importer report; serializer persistence version; capability tuple; backend compiler; core-check fixture; E2E server harness; UI readable fields; redaction cases; support matrix evidence. Новая строка enum без этого не завершённая задача.

XHTTP сначала отдельный T00 compatibility investigation: определить exact source/build, лицензии, mobile/library API, поддерживаемые modes и extra fields. Если подходящий backend не подтверждён, сохранять importOnly с точной причиной; не делать скрытое многоядерное сцепление. Выбор extended core применяется ко всей сессии v1.
