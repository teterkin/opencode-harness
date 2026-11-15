# Changelog

Формат — [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/),
версии — [SemVer](https://semver.org/lang/ru/).

## [Unreleased]

## [2.0.1] — 2026-11-15

### Fixed

- `install.sh` больше не перезаписывает `AGENTS.md` целиком: правила харнесса
  живут между маркерами `<!-- harness:begin -->` и `<!-- harness:end -->`,
  пользовательский текст вне них сохраняется. Файл без маркеров (установка
  2.0.0) мигрирует в один блок без дублирования правил.
- `uninstall.sh` вырезает из `AGENTS.md` только блок харнесса и удаляет файл,
  только если в нём ничего не осталось.

## [2.0.0] — 2026-11-15

Переход на opencode 2.x. Несовместимо с 1.x: минимальная версия — 2.3.0,
правила прав переписаны на формат v2.

### Added

- `tests/doctor.sh` — сверяет запущенную версию opencode с пином
  `opencode.version` и ищет рядом более новый бинарь. Коды выхода: `0` —
  совпадает, `1` — ниже минимума, `2` — дрейф с прогоном самотестов.
- `tests/doctor.bats.sh` — симуляции версий, путей и старого формата вывода.
- `tests/version.bats.sh` — `VERSION` = верх `CHANGELOG.md` = тег; режим
  `--tag` требует существующий аннотированный тег.
- `tests/docs.bats.sh` — docs-baseline, порядок секций README, шаблоны.
- `VERSION` и `opencode.version` — версия харнесса и пин инструмента.
- `commands/release.md` — `/release`: `VERSION`, `CHANGELOG`, README, проверки,
  тег.
- `skills/project-kit/SKILL.md` — docs-baseline, каркас проектного `AGENTS.md`,
  ветки и версии.
- `templates/AGENTS.md`, `templates/PRD.md` — скелеты для нового проекта.
- `docs/prd/2.0.md`, `docs/workflow.md`, `TODO.md`.
- `install.sh` пишет манифест `harness-installed.txt`; `uninstall.sh` сносит по
  манифесту, с fallback на список файлов 1.0.0.
- `AGENTS.md`: правила про авто `git init`, ветки `feat/` `fix/` `docs/`
  `chore/`, SemVer, docs-baseline, обязательный каркас проектного `AGENTS.md`,
  язык общения, `doctor` и MCP-серверы: выключены глобально, включаются
  проектным `opencode.jsonc`.

### Changed

- `tests/verify.sh` читает эффективное состояние через HTTP API opencode
  (`/api/agent`, `/api/command`, `/api/skill`), а не через `opencode debug
  agent` и `opencode debug skill`, которых в 2.x нет.
- `permissions` вместо deprecated `permission`: упорядоченный ruleset
  `{action, resource, effect}`, действие `shell` вместо `bash`.
- `reviewer` ходит в `opencode/deepseek-v4-pro#high` с потолком `steps: 20`.
- Скиллы `tdd-workflow` (исходное состояние, проверка чувствительности, strict
  `xfail`) и `prd-authoring` (источники и допущения, `docs/prd/<slug>.md`).
- README перестроен: описание, установка, использование, архитектура, версии.

### Removed

- Поддержка opencode 1.x.

## [1.0.0] — 2026-11-15

Первый зафиксированный релиз: правила, агенты, команды, скиллы и установщик.

### Added

- `AGENTS.md` — семь правил, которые попадают в контекст каждой сессии: TDD
  без production-кода до падающего теста, PRD перед нетривиальной задачей, план
  до правок, атомарные диффы, реальные проверки, git только по явной просьбе,
  проверка git-репозитория на старте задачи и пиннинг зависимостей.
- `agents/implementer.md` — агент по умолчанию: TDD-цикл, реальные проверки,
  запрет на переписывание истории на уровне permissions.
- `agents/plan.md` — планировщик с `edit: deny`, только PRD или план.
- `agents/reviewer.md` — субагент-ревьюер на чтение, `edit: deny`.
- `commands/prd.md`, `commands/tdd.md`, `commands/review.md` — точки входа
  `/prd`, `/tdd`, `/review`.
- `skills/tdd-workflow/SKILL.md`, `skills/prd-authoring/SKILL.md` — процедуры,
  которые подгружаются по смыслу запроса.
- `install.sh` — установка в `~/.config/opencode` с бэкапом, проверкой
  `opencode` и `python3` до первой записи, наложением `opencode.json` поверх
  существующего конфига и идемпотентностью.
- `uninstall.sh` — снос файлов харнесса без потери провайдера и остального
  конфига.
- `tests/install.bats.sh` — 45 проверок установки, сноса, сохранения секретов,
  идемпотентности и отказов на битом входе.
- `tests/verify.sh` — проверка, что установленная конфигурация подхватилась.
- `LICENSE` — MIT.

### Compatibility

- Проверено на opencode 1.18.34 (Homebrew), `python3` 3.12, macOS 15.7.9
  arm64.

### Known limitations

- `tests/verify.sh` опирается на `opencode debug config` и
  `opencode debug agent`, которых нет в opencode 2.x, поэтому на 2.x он
  красный. Исправляется в 2.0.0.
- README и правила — инструкции для модели, а не enforcement. Реально
  блокируют только permissions.
- `default_agent: implementer` действует глобально, скрипты с явным `build`
  его не подхватывают.
- `uninstall.sh` содержит захардкоженные списки агентов, команд и скиллов:
  новый скилл придётся добавлять в двух местах.
