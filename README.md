# Плагины российской экосистемы для Hermes Agent

[![GitHub](https://img.shields.io/badge/GitHub-temga%2Fhermes--ru--ecosystem-blue)](https://github.com/temga/hermes-ru-ecosystem)

Набор плагинов для [Hermes Agent](https://github.com/NousResearch/hermes-agent), обеспечивающих работу с российскими сервисами: API-провайдеры и мессенджеры.

## Состав

| Плагин | Тип | Описание | Репозиторий |
|---|---|---|---|
| **RouterAI** | model-provider | OpenAI-совместимый API-агрегатор (GPT, Claude, Gemini и др.). Оплата в рублях, без VPN. | [temga/hermes-routerai-plugin](https://github.com/temga/hermes-routerai-plugin) |
| **MAX Messenger** | platform | Адаптер для Max Messenger (max.ru). Webhook-режим, голосовые, файлы, inline-клавиатуры. | [temga/max-hermes-plugin](https://github.com/temga/max-hermes-plugin) |

## Установка

### 1. Клонирование

    git clone --recursive https://github.com/temga/hermes-ru-ecosystem.git
    cd hermes-ru-ecosystem

### 2. Установка плагинов

    ./install.sh

Скрипт создаёт символические ссылки в `~/.hermes/plugins/` для каждого плагина.

Можно установить отдельные плагины:

    ./install.sh routerai
    ./install.sh max

### 3. Настройка

#### RouterAI

    export ROUTERAI_API_KEY="ваш-api-ключ"

Выбор провайдера в Hermes:

    hermes model

Выберите `routerai` из списка.

#### MAX Messenger

Зависимости:

    pip install maxapi

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

Переменные окружения:

    MAX_BOT_TOKEN=токен_бота
    MAX_WEBHOOK_URL=https://ваш-домен/max/webhook
    MAX_WEBHOOK_SECRET=секрет_5_256_символов

Подробности — в [README MAX-плагина](platforms/max/README.md).

## Обновление

    cd hermes-ru-ecosystem
    git pull
    git submodule update --remote

Симлинки автоматически указывают на обновлённые файлы.

## Структура

```
hermes-ru-ecosystem/
├── install.sh                          # скрипт установки (симлинки)
├── README.md
├── model-providers/
│   └── routerai/                       # git submodule → hermes-routerai-plugin
│       ├── __init__.py
│       ├── plugin.yaml
│       └── README.md
└── platforms/
    └── max/                            # git submodule → max-hermes-plugin
        ├── __init__.py
        ├── adapter.py
        ├── plugin.yaml
        ├── pyproject.toml
        └── README.md
```

## Известные особенности

### EXPENSIVE MODEL WARNING (RouterAI)

RouterAI отдаёт цены в рублях через `/models` API. Hermes предполагает доллары, поэтому при выборе некоторых моделей может появляться предупреждение о дорогой модели. Реальная цена в долларах ниже порогов. Просто подтвердите выбор («Switch anyway»). Подробности — в [README RouterAI](model-providers/routerai/README.md).

## Как это работает

`install.sh` создаёт символические ссылки:

- `~/.hermes/plugins/model-providers/routerai → ./model-providers/routerai`
- `~/.hermes/plugins/platforms/max → ./platforms/max`

Hermes обнаруживает плагины через сканирование директорий `~/.hermes/plugins/`. Симлинки работают как обычные директории, поэтому отдельная настройка не требуется.

## Лицензия

MIT
