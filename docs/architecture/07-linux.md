# 07. Linux: runtime, права и упаковка

Цель: GUI обычного пользователя, отдельный проверяемый privileged helper, изолированный процесс ядра. Текущий Dart ProcessSingBoxAdapter остаётся development adapter; его PATH lookup и временные конфиги не являются production contract.

## Процессы и IPC

Предлагается Go helper под system service, system D-Bus API с проверкой authenticated sender UID/session и Polkit actions. Один активный VPN owner на машину в v1: второй пользователь получает RESOURCE_CONFLICT и не может stop чужую сессию. После рестарта UI владелец reconnects к helper и inspect; после logout по default disconnect, режим сохранения после logout — отдельная опция вне MVP.

Helper принимает typed NetworkIntent и ограниченный CompiledPlan, но не shell string, путь к executable, environment overrides или произвольный upstream JSON. Клиент считается недоверенным даже при локальном UID. Helper повторно валидирует весь план, ограничивает разрешённые inbounds/outbounds/options и материализует core config в собственной runtime directory. Protocol credentials нужны worker, но не пишутся в D-Bus logs или process args.

Авторизация по отдельным действиям connect/apply; inspect/stop доступны только owner/admin согласно policy. Polkit decision привязывается к реальному sender, не UID из payload. Структура actions/policy подлежит проверке на Fedora и Ubuntu; не выдавать общий passwordless root для GUI.

## Единственный владелец TUN и маршрутов

**Предпочтительный production вариант:** helper создаёт TUN, адреса, принадлежащие TrueTun routes/rules, DNS state и передаёт FD worker через Unix ancillary FD passing. Core worker работает непривилегированно и использует platform binding; auto_route/auto_redirect в core выключены, чтобы не было двух авторов системной сети. Это требует доказать support выбранной сборки/library в T00; stock CLI не считается умеющим принимать любой унаследованный FD.

Если FD integration не поддерживается, gate не пройден. Допустимая альтернатива отдельным ADR: managed core worker с минимальными проверенными Linux capabilities и ownership его auto-route ресурсов, строгим helper-generated config и отдельной cleanup моделью. Нельзя незаметно запустить GUI/core с unrestricted sudo. До решения production TUN отмечен blocked; непривилегированный mixed proxy может служить только dev smoke test, не MVP TUN acceptance.

## Resource journal

Session journal: owner UID, sessionId, worker handle/start time, TUN identity, allocated addresses, route table/rule priorities, firewall handles если нужны, DNS previous/applied values, build hash. Journal записывается до мутации с pending/applied marker. Ресурсы получают собственный namespace/prefix и collision check; не занимать заранее чужую table ID.

Start: verify artifact → authorize → validate plan → allocate own resources → worker handshake → publish ready. Stop: отменить retries → stop worker с deadline → удалить только свои routes/rules/TUN → compare-and-restore DNS → clear journal. Если внешний network manager уже изменил DNS, не восстанавливать устаревший global snapshot поверх него; удалять собственную per-link настройку через выбранный backend.

Crash recovery сверяет journal с фактическими ownership attributes, не удаляет interface только по совпавшему имени. PID может переиспользоваться. Никогда не выполнять global `ip route flush`, `nft flush ruleset`, `iptables -F`, не перезаписывать `/etc/resolv.conf` без владельца и backup semantics. Stale state cleanup также проходит tests.

## DNS adapters и окружающая сеть

Detect backend: systemd-resolved per-link integration либо NetworkManager supported configuration. Отсутствие поддержанного backend — явное ограничение, не shell patch resolver file. Resolver engine selection pin и tests T05. TUN routing должен сохранять доступ worker к proxy endpoint через underlying path без слишком широкого bypass всего пользовательского трафика к этому IP.

Проверять домашние LAN, Docker/Podman bridges, ZeroTier, suspend/resume и другой VPN. Наличие чужого VPN может быть supported coexistence или понятным conflict, но не повод удалить чужие маршруты. IPv6 и DNS включаются в тот же NetworkIntent, не отдельными ad hoc shell scripts.

## Приложения Linux

Desktop entry — UI label/icon, process identity — name/path и optional UID scope. Не выполнять `Exec` для определения приложения; разбирать desktop metadata безопасно. Shell wrappers, Electron children, Flatpak/Snap, containers и renamed binaries могут нарушать сопоставление. Показывать canonical executable и confidence/limitations, давать manual matcher.

Linux app rule применяется после входа в TUN; v1 не обещает native per-app bypass эквивалентный Android. Exact process lookup capability проверяется с выбранным core и permissions. Если lookup unavailable, rule не деградирует в wildcard.

## Дистрибуция

Primary target: Fedora x86_64; secondary Ubuntu x86_64; aarch64 после отдельного build/device gate. Это proposed matrix по приоритетам проекта, не существующие builds. Предпочтительно RPM/DEB для установки helper/service/policy и обновления coordinated components. AppImage может предоставлять GUI, но не должен притворяться, что privileged helper установлен; Flatpak distribution отдельно требует portal/host strategy.

Binary path берётся из install manifest, никогда из PATH в production. Root-owned files не writable обычным пользователем; helper проверяет hash/build compatibility. GUI/helper/core обновляются совместимым набором; major IPC mismatch блокирует start. Автообновление и silent daemon replacement вне MVP. Uninstall корректно stop и удалить только package-owned resources; пользовательские данные удалять отдельно по запросу.

## Приёмка

Connect/Stop без root GUI; Polkit deny; spoofed sender/extra config keys; binary/path/symlink substitution; helper/worker crash; stale journal; resource conflict; user logout; DNS modified externally; suspend/resume; NetworkManager restart; 100 cycles; Docker/ZeroTier coexistence; IPv6 capture. Отчёт содержит distro/kernel/helper/core build и до/после diff системных ресурсов.
