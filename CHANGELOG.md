# Changelog

Формат — [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/),
версии — [SemVer](https://semver.org/lang/ru/).

## [Unreleased]

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
