# 05. DNS, TUN и сеть

DNS входит в первый working slice, не откладывается на финальную фазу. Это проект политики TrueTun; конкретные поля JSON выбираются по pinned core schema. [Документация DNS sing-box](https://sing-box.sagernet.org/configuration/dns/) служит справочником адаптера, не форматом domain storage.

## Resolver graph

Различать bootstrap resolver, direct resolver, proxy resolver и LAN/system resolver. DnsResolver содержит id, transport, endpoint, endpointBootstrapRef, egress(node/group/direct), timeout и TLS serverName. DNS rules выбирают resolver независимо от терминальных traffic routing rules; общий preset определяет согласованные defaults. Граф dependencies включает resolver endpoints, proxy endpoints, detours и rule-set assets. Цикл до start — DNS_DEPENDENCY_CYCLE.

Пример запрещённого цикла: proxy.example разрешается только через proxied DoH, чей outbound сначала должен подключиться к proxy.example. Допустимый bootstrap: resolve proxy hostname через явно выбранный underlying resolver → подключить proxy → использовать proxied resolver для пользовательских DNS запросов. Bootstrap запрос раскрывает имя proxy endpoint underlying resolver; это ограниченный явно документированный этап, не обещание «нулевых DNS утечек».

## Предлагаемый default v1

- TUN перехватывает обычные TCP/UDP DNS запросы приложений, вошедших в VPN, и направляет core DNS.
- User DNS по умолчанию через proxy resolver выбранного preset; local names через явно включённый LAN resolver policy.
- Bootstrap использует доступный системный underlying resolver; если его нет, понятная ошибка и настройка explicit resolver, не жёстко зашитый публичный DNS.
- Remote rule sets и subscription updates не требуются для восстановления last-known-good.
- FakeIP выключен; добавляется отдельно после проверки cache persistence, IPv6 и app compatibility.
- Sniffing используется лишь там, где пользователь включил соответствующую функцию; без MITM и без записи payload. Непрозрачный трафик остаётся unknown.

Обычный DNS interception не даёт контроля над любым приложением с собственным DoH/DoT; такой трафик следует IP/port/domain evidence маршрутизации. Приложения вне Android VPN filter используют системную сеть: TrueTun не управляет их DNS.

## IPv4/IPv6

Network policy: dualStack или blockIPv6ForCapturedTraffic. Default target — dualStack при подтверждённом dataplane. Если IPv6 TUN не поддержан, явная политика блокирует IPv6 captured apps средствами платформы; запрещён silent escape IPv6 в underlying сеть. Если такой block гарантировать нельзя — capability error для заявленного protected режима, UI объясняет ограничение.

Проверять отдельно endpoint resolution (A/AAAA), reachability сервера и внутренний egress proxy. Наличие IPv6 на устройстве не гарантирует AAAA endpoint. Happy Eyeballs только в supported adapter; не менять serverName/SNI при выборе IP. Для NAT64/DNS64 и IPv6-only сети обязательный device scenario перед объявлением поддержки.

## Изменение сети

Platform NetworkMonitor публикует NetworkEpoch + available/default transport facts. Supervisor debounce и пересборка bootstrap/platform portion; UI не пересоздаёт VPN в callback. Не фиксировать `wlp3s0`, interface index и DNS IP в saved preset. На Android protected sockets связываются с актуальной underlying Network в соответствии с core binding; на Linux worker detours/marks и helper routes защищают от self-capture.

Нет default interface: waitingForNetwork, без бесконечного падения на DNS. Captive portal: отдельная диагностика и действие открыть системную авторизацию; не отключать защиту и не переключать весь traffic в DIRECT автоматически. Если обход нужен пользователю, он задаёт явную temporary policy с видимым сроком.

## LAN и другие VPN

Доступ к RFC1918/ULA, `.local` и другим локальным именам — явный LAN preset. Не приравнивать все private destinations к безусловно доверенным. Пользователь может переопределить LAN rule через editor. Loopback control socket не выставляется в LAN.

Linux coexistence с NetworkManager, systemd-resolved, Docker bridge, ZeroTier и другим VPN проверяется до выпуска. Не перехватывать чужой route table и не flush firewall. Linux process routing — правило внутри TUN, не аналог Android native app exclusion. На Android одновременно активный другой VPN может отозвать TrueTun: показать VPN_REVOKED, не бороться автоматическими повторными permission prompts.

## Fetch routing

Subscription/ruleset fetch policy: direct, currentProxy, либо explicit user-selected fallback sequence. Default при подключении — currentProxy; до первого профиля — direct с TLS. Ошибка currentProxy не означает молчаливый direct fallback. Control-plane fetch из исключённого собственного Android package использует explicit local proxy channel/core HTTP client, если выбран currentProxy. Это также относится к health probes; обычный HTTP из UI может идти напрямую и не доказывает работу VPN.

## Приёмка

Packet captures для captured app: DNS/TCP/UDP проходят ожидаемым путём; bootstrap виден отдельно; нет незаявленного IPv6 escape; local resolver только по LAN policy. Повторить с blocked UDP/53, недоступным DoH, cached/offline rulesets, без default interface, при Wi-Fi→mobile, IPv6-only и после Stop. Политика DNS и activeRevision должны отображаться в diagnostics без токенов и полных пользовательских доменных журналов.
