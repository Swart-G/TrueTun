# Выбор ядра и данные о лицензиях

Этот документ задаёт инженерный release gate, а не выбирает лицензию TrueTun. В проверенном baseline проектного LICENSE нет. Архитектурный adapter не устраняет автоматически обязательства зависимости.

## Проверенные источники, 2026-09-06

- В [LICENSE sing-box](https://github.com/SagerNet/sing-box/blob/testing/LICENSE) указана GPL версии 3 или позднее и дополнительное условие об имени/ассоциации. Проверенный blob: `175f35038fd936eb50439a4eb12d64501feb830c`. Это default testing branch, не выбранный production pin.
- [LICENSE.md hiddify-core](https://github.com/hiddify/hiddify-core/blob/main/LICENSE.md) содержит GPLv3 и вводный список дополнительных условий, включая non-commercial, attribution и ограничения для forks. Проверенный blob: `529ef62e2ad38525704f9aa506cc985a32897162`. Здесь не делается вывод о юридической совместимости или применимости сочетания этих условий.

## Решение для проектирования

Собственные UI/domain/import/routing компоненты TrueTun; upstream sing-box как кандидат baseline; Hiddify application code не копируется. Extended fork оценивается независимо. Перед подключением конкретного binary/library агент фиксирует exact commit, LICENSE/NOTICE и transitives. License другого репозитория или его другой ветки не считается достаточным доказательством для выбранного artifact.

## Gate до binary release

Владелец проекта выбирает лицензию TrueTun на основе точного dependency inventory. Отдельно проверить Android native linking, Linux worker/library/process model, notices, source distribution requirements и branding. Не утверждать, что запуск через process делает copyleft неприменимым. При неопределённости нужны дополнительная проверка условий/квалифицированная оценка; не подменять её уверенным заключением агента.

Artifact inventory: component, source URL/commit, license files hashes, integration model, modifications, required notices/source materials и ответственный за проверку. Сборочные инструкции и соответствующие исходники для выпуска должны быть воспроизводимо связаны с build ID. Менять лицензию или объявлять совместимость всех будущих forks в рамках обычной implementation задачи нельзя.
