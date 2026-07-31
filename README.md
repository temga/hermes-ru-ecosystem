# Плагины российской экосистемы для Hermes Agent

[![GitHub](https://img.shields.io/badge/GitHub-temga%2Fhermes--ru--ecosystem-blue)](https://github.com/temga/hermes-ru-ecosystem)

Набор плагинов для [Hermes Agent](https://github.com/NousResearch/hermes-agent), обеспечивающих работу с российскими сервисами: API-провайдеры, мессенджеры и генерация изображений.

## Состав

| Плагин | Тип | Репозиторий |
|---|---|---|
| **RouterAI** | model-provider | [temga/hermes-routerai-plugin](https://github.com/temga/hermes-routerai-plugin) |
| **NeuralDeep** | model-provider | [temga/hermes-neuraldeep-chat](https://github.com/temga/hermes-neuraldeep-chat) |
| **MAX Messenger** | platform | [temga/max-hermes-plugin](https://github.com/temga/max-hermes-plugin) |
| **RouterAI Image Gen** | backend (image generation) | [temga/hermes-plugin-routerai-imagegen](https://github.com/temga/hermes-plugin-routerai-imagegen) |

Все плагины устанавливаются единым способом — через встроенный менеджер плагинов Hermes:

    hermes plugins install temga/<repo> --enable

## Установка

### Вариант 1: One-liner (рекомендуется)

    curl -fsSL https://raw.githubusercontent.com/temga/hermes-ru-ecosystem/main/install.sh | bash

Скрипт клонирует репозиторий с сабмодулями в `~/.hermes/hermes-ru-ecosystem` и устанавливает все плагины через `hermes plugins install`. Если `git` не установлен — скачивает tarball-архив с GitHub.

### Вариант 2: Вручную

    git clone --recursive https://github.com/temga/hermes-ru-ecosystem.git
    cd hermes-ru-ecosystem
    ./install.sh

### Установка отдельных плагинов

    ./install.sh routerai
    ./install.sh neuraldeep
    ./install.sh max
    ./install.sh routerai-imagen

### Установка напрямую (без install.sh)

    hermes plugins install temga/hermes-routerai-plugin --enable
    hermes plugins install temga/hermes-neuraldeep-chat --enable
    hermes plugins install temga/max-hermes-plugin --enable
    hermes plugins install temga/hermes-plugin-routerai-imagegen --enable

### Как это работает

Все плагины регистрируются через систему плагинов Hermes (`hermes plugins install temga/<repo> --enable`). Hermes сам клонирует репозиторий, устанавливает зависимости и регистрирует плагин. После установки плагин обнаруживается автоматически — никаких ручных symlink или `pip install` не требуется.

## Настройка

Hermes хранит секреты в `~/.hermes/.env`, а не через `export`. Можно также использовать `hermes setup` — мастер настройки запросит ключи автоматически (благодаря `requires_env` в `plugin.yaml`).

### RouterAI (model-provider)

Добавьте в `~/.hermes/.env`:

    ROUTERAI_API_KEY=ваш-api-ключ

Выбор провайдера в Hermes:

    hermes model

Выберите `routerai` из списка.

### NeuralDeep (model-provider)

Добавьте в `~/.hermes/.env`:

    NEURALDEEP_API_KEY=ваш-api-ключ

Выбор провайдера в Hermes:

    hermes model

Выберите `neuraldeep` из списка. Модели: `gpt-oss-120b`, `qwen3.6-35b-a3b`, `gemma-4-31b`.

### MAX Messenger (platform)

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

### RouterAI Image Gen (backend)

Использует тот же `ROUTERAI_API_KEY`, что и model-provider. Настройка в `~/.hermes/config.yaml`:

```yaml
image_gen:
  provider: routerai
  model: openai/gpt-image-2
```

Или через CLI:

    hermes config set image_gen.provider routerai
    hermes config set image_gen.model openai/gpt-image-2

Поддерживаемые модели: GPT Image, Flux, Seedream, Gemini, Krea, Recraft и др. (38+ моделей). Полный список — в [README плагина](backends/routerai-imagegen/README.md).

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
├── install.sh                              # скрипт установки
├── README.md
├── .env.example
├── model-providers/
│   ├── routerai/                           # git submodule → hermes-routerai-plugin
│   │   ├── __init__.py                     # register_provider(ProviderProfile(...))
│   │   ├── plugin.yaml
│   │   └── README.md
│   └── neuraldeep/                         # git submodule → hermes-neuraldeep-chat
│       ├── __init__.py                     # register_provider(ProviderProfile(...))
│       ├── plugin.yaml
│       └── README.md
├── platforms/
│   └── max/                                # git submodule → max-hermes-plugin
│       ├── __init__.py                     # from .adapter import register
│       ├── adapter.py                      # register(ctx) → ctx.register_platform(...)
│       ├── plugin.yaml
│       ├── pyproject.toml
│       └── README.md
└── backends/
    └── routerai-imagegen/                  # git submodule → hermes-plugin-routerai-imagegen
        ├── __init__.py                     # register(ctx) → ctx.register_image_gen_provider(...)
        ├── plugin.yaml
        └── README.md
```

## Известные особенности

### EXPENSIVE MODEL WARNING (RouterAI)

RouterAI отдаёт цены в рублях через `/models` API. Hermes предполагает доллары, поэтому при выборе некоторых моделей может появляться предупреждение о дорогой модели. Реальная цена в долларах ниже порогов. Просто подтвердите выбор («Switch anyway»). Подробности — в [README RouterAI](model-providers/routerai/README.md).

## Лицензия

MIT
