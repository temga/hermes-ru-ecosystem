# Плагины российской экосистемы для Hermes Agent

[![GitHub](https://img.shields.io/badge/GitHub-temga%2Fhermes--ru--ecosystem-blue)](https://github.com/temga/hermes-ru-ecosystem)

Набор плагинов для [Hermes Agent](https://github.com/NousResearch/hermes-agent), обеспечивающих работу с российскими сервисами: API-провайдеры и мессенджеры.

## Состав

| Плагин | Тип | Способ установки | Репозиторий |
|---|---|---|---|
| **RouterAI** | model-provider | symlink (Hermes не поддерживает entry-points для model-providers) | [temga/hermes-routerai-plugin](https://github.com/temga/hermes-routerai-plugin) |
| **MAX Messenger** | platform | pip install (entry-points, proper way) | [temga/max-hermes-plugin](https://github.com/temga/max-hermes-plugin) |

## Установка

### Вариант 1: One-liner (рекомендуется)

    curl -fsSL https://raw.githubusercontent.com/temga/hermes-ru-ecosystem/main/install.sh | bash

Скрипт сам клонирует репозиторий с сабмодулями в `~/.hermes/hermes-ru-ecosystem` и устанавливает плагины. Если `git` не установлен — скачивает tarball-архивы с GitHub.

### Вариант 2: Вручную

    git clone --recursive https://github.com/temga/hermes-ru-ecosystem.git
    cd hermes-ru-ecosystem
    ./install.sh

### Установка отдельных плагинов

    ./install.sh routerai
    ./install.sh max

### Как это работает

Способ установки зависит от типа плагина:

- **RouterAI (model-provider)** — Hermes обнаруживает model-providers только сканированием директории `~/.hermes/plugins/model-providers/`. Entry-points не поддерживаются. Скрипт создаёт symlink: `~/.hermes/plugins/model-providers/routerai → ./model-providers/routerai`.

- **MAX (platform)** — Hermes поддерживает entry-points через группу `hermes_agent.plugins`. Плагин устанавливается через `pip install -e` (editable-режим из клона) или `pip install` (из tarball). После установки Hermes автоматически находит плагин через `importlib.metadata`.

## Настройка

Hermes хранит секреты в `~/.hermes/.env`, а не через `export`. Можно также использовать `hermes setup` — мастер настройки запросит ключи автоматически (благодаря `requires_env` в `plugin.yaml`).

### RouterAI

Добавьте в `~/.hermes/.env`:

    ROUTERAI_API_KEY=ваш-api-ключ

Выбор провайдера в Hermes:

    hermes model

Выберите `routerai` из списка.

### MAX Messenger

Добавьте в `~/.hermes/.env`:

    MAX_BOT_TOKEN=токен_бота
    MAX_WEBHOOK_URL=https://ваш-домен/max/webhook
    MAX_WEBHOOK_SECRET=секрет_5_256_символов

Конфигурация `~/.hermes/config.yaml`:

```yaml
plugins:
  enabled:
    - max

gateway:
  platforms:
    max:
      enabled: true
      extra:
        burst_merge_seconds: 2.0
        busy_text_mode: queue
        busy_text_debounce_seconds: 1.5
        webhook_host: "0.0.0.0"
        webhook_port: 8088
        webhook_path: "/max/webhook"
```

Подробности — в [README MAX-плагина](platforms/max/README.md).

## Обновление

### Если установлен через git

    cd ~/.hermes/hermes-ru-ecosystem
    git pull
    git submodule update --remote
    ./install.sh

### Если установлен через one-liner

Просто запустите ту же команду снова:

    curl -fsSL https://raw.githubusercontent.com/temga/hermes-ru-ecosystem/main/install.sh | bash

## Структура

```
hermes-ru-ecosystem/
├── install.sh                          # скрипт установки
├── README.md
├── model-providers/
│   └── routerai/                       # git submodule → hermes-routerai-plugin
│       ├── __init__.py                 # register_provider(ProviderProfile(...))
│       ├── plugin.yaml
│       └── README.md
└── platforms/
    └── max/                            # git submodule → max-hermes-plugin
        ├── __init__.py                 # from .adapter import register
        ├── adapter.py                  # register(ctx) → ctx.register_platform(...)
        ├── plugin.yaml
        ├── pyproject.toml              # entry-points: hermes_agent.plugins
        └── README.md
```

## Известные особенности

### EXPENSIVE MODEL WARNING (RouterAI)

RouterAI отдаёт цены в рублях через `/models` API. Hermes предполагает доллары, поэтому при выборе некоторых моделей может появляться предупреждение о дорогой модели. Реальная цена в долларах ниже порогов. Просто подтвердите выбор («Switch anyway»). Подробности — в [README RouterAI](model-providers/routerai/README.md).

## Лицензия

MIT