# 11. Архитектурные решения и открытые gates

ADR фиксирует контекст, выбранное направление, альтернативу и последствия. «Принято» ниже означает проектное решение; не утверждает наличие реализации. Изменять решение можно с объяснением и обновлением связанных контрактов, а не обходом документации.

## Реестр ADR

| ID / статус | Решение и причина | Альтернатива и последствия |
|---|---|---|
| ADR-001 принято | Flutter modular monolith, pure domain и ports | Два native UI дублируют продуктовую логику; packages выделять по реальной нужде |
| ADR-002 принято | Exact pinned sing-box baseline, отдельные extended manifests | Hiddify fork целиком дал бы больше features, но увеличил coupling и dependency gates |
| ADR-003 принято | Capability по combination/build/platform + test evidence | Статический protocol enum ложно обещает поддержку |
| ADR-004 принято | Normalized domain storage, stable IDs, typed unions | Native config как БД ломает migrations и перенос backend |
| ADR-005 принято | Immutable snapshot и validate-before-break controlled restart | Hot reload/dual TUN не обещаны, TCP flows могут оборваться |
| ADR-006 принято | Supervisor — единственный runtime authority | UI-controlled VPN не переживает Activity/process lifecycle |
| ADR-007 принято | Android native app scope отдельно от rules | Include/exclude core map сам по себе не даёт системной VPN гарантии |
| ADR-008 принято | Explicit routing AST, unknown не превращается в широкое Not-match | Flat map проще, но может менять смысл AND/OR; unsupported negative guards блокируются |
| ADR-009 предложено | Android service в отдельном process, private Binder, Pigeon facade | In-process native проще, но native crash уронит UI; отдельный process требует IPC/recovery работы |
| ADR-010 предложено | Linux helper owns TUN/routes, unprivileged worker через FD integration | Core-owned auto_route допустим только отдельным проверенным ADR; UI root исключён |
| ADR-011 предложено | Riverpod + Drift + Pigeon, versions at T01 | Альтернативы допустимы при сохранении ports/transactions/API, без преждевременного dependency zoo |
| ADR-012 принято | DNS входит в первый E2E, bootstrap graph explicit | Поздний DNS этап скрывает фундаментальные routing failures |
| ADR-013 принято | Локальные объяснимые рекомендации, preview/apply | Remote inventory/ML не нужны для первой полезной функции |
| ADR-014 принято | Restore-system-network default, block-on-failure отдельный verified режим | Фальшивый kill switch опаснее явного режима без него |
| ADR-015 принято | Один backend на всю session v1 | Несколько ядер/цепочки осложняют DNS, groups, privilege и recovery |
| ADR-016 принято | Docs-only пакет не реализует компоненты | Следующий агент начинает только явно порученный milestone |

## Открытые вопросы с владельцами

| Gate | Кто решает | До какого этапа | Доказательство / действие при провале |
|---|---|---|---|
| Exact core stable version, flags, schema | Core integration | T01 | Manifest + check fixtures; не выпускать unknown capabilities |
| Android mobile API, protect/FD ownership, process bridge | Android integration | T03A | Compiled native spike, descriptor tests; уточнить ADR-009 |
| Linux FD/platform binding feasibility | Linux integration | T03L | Managed worker smoke test; иначе ADR alternative, production TUN blocked |
| Logical rules/Not unknown semantics | Compiler owner | T04 | Truth tables на exact core; guard или unsupported |
| XHTTP backend/modes/mobile support | Core integration | T10 | Отдельный compatibility report; до успеха importOnly |
| min/target SDK, FGS и package visibility | Android owner | T01/T03A | Сверка актуальной Android API/docs и build, store channel policy отдельно |
| Linux resolver backends и Polkit actions | Linux owner | T03L | Fedora/Ubuntu integration evidence |
| Project license + exact dependency distribution | Project owner | Первый binary release | Recorded decision и inventory; не выбирать за владельца |
| Stable dependency pins / state libraries | App foundation | T01 | Build/analyze обеих платформ, lockfiles |
| Performance/health retry budgets | Reliability owner | T09 | Measured baseline, ADR при корректировке |

Эти роли может выполнять один агент последовательно; реестр не поручает создавать субагентов. Gates — технические условия, не автоматическое требование спрашивать разрешение на каждый шаг.

## Источники и границы проверки

- [Baseline TrueTun](https://github.com/Swart-G/TrueTun/tree/76e5c834e940072caf04591818e2440a7607cde3) — источник текущего состояния.
- [Route Rule](https://sing-box.sagernet.org/configuration/route/rule/) — основание учитывать grouped-field и logical semantics.
- [TUN](https://sing-box.sagernet.org/configuration/inbound/tun/) и [DNS](https://sing-box.sagernet.org/configuration/dns/) — справочники compiler adapter; новые поля страницы могут отсутствовать в pinned release.
- [Android VpnService.Builder](https://developer.android.com/reference/android/net/VpnService.Builder) — API reference платформенного фильтра.
- [Polkit manual](https://polkit.pages.freedesktop.org/polkit/polkit.8.html) — разделение privileged mechanism и авторизации; D-Bus/helper topology здесь является собственным проектным решением TrueTun.
- Лицензионные файлы и наблюдения перечислены в [LICENSING](../LICENSING.md).

Проверка upstream страниц не включала сборку ядра/устройство. Дата страницы не заменяет git pin. Все численные budgets, DTO и module layout — проект TrueTun, не цитата или обещание upstream.

## Шаблон нового ADR

ID; дата; статус; проблема; ограничения пользователя; рассмотренные варианты; решение; последствия для API/storage/platform/test; gate и измеримое evidence; migration/backout plan; ссылки на затронутые документы. Superseded ADR остаётся с ссылкой на замену, чтобы следующий агент понимал причины.
