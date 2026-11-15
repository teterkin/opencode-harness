# Project rules

<!-- Скелет. Оставь только то, что правда верно для этого проекта.
     Команда, которая не запускается, хуже отсутствующей строки. -->

## Commands

- test: `make test`
- lint: `make lint`
- typecheck: `make typecheck`
- build: `make build`
- run: `make run`

## Branches and commits

- Trunk: `main`.
- Work: `feat/<slug>`, `fix/<slug>`, `docs/<slug>`, `chore/<slug>`.
- Commit messages: `type: short imperative summary`.

## Project map

- `<path>` — что здесь лежит и зачем.
- `<path>` — неочевидный модуль: чем он отличается от соседнего.

## Domain invariants

- Инвариант, который не виден в коде, но который нельзя нарушать.
- Ещё один: что сломается, если его нарушить.

## Secrets

- Секреты живут в `<path>`, в репозиторий не попадают.
- `.env.example` обновляется при каждом новом ключе.

## Local notes

- Этот файл коммитится. Настройки конкретной машины — MCP-серверы, абсолютные
  пути, имена личных каталогов — живут в глобальном конфиге или в неотслеживаемой
  заметке, а не здесь.
