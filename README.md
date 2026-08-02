<p align="center">
  <img src="assets/banner.webp" alt="Hermes RU Ecosystem" width="100%">
</p>

# Плагины российской экосистемы для Hermes Agent

[![GitHub](https://img.shields.io/badge/GitHub-temga%2Fhermes--ru--ecosystem-blue)](https://github.com/temga/hermes-ru-ecosystem)

> #### Геометрия сильнее декорации
>
> [Hermes Agent](https://github.com/NousResearch/hermes-agent) — открытый AI-агент от Nous Research. Мощный, расширяемый, с поддержкой десятков платформ. Но он спроектирован в мире, где OpenAI, Anthropic и Telegram работают из коробки.
>
> В 1920-е годы Россию отрезали от Европы — но Малевич, Татлин, Лисицкий и Родченко не остановились. Они построили авангард — язык, который Европа потом учила. Изоляция стала материалом, а не приговором.
>
> Сегодня ограничений снова много, но останавливаться никто не собирается. Этот репозиторий — набор плагинов для Hermes Agent: провайдеры моделей, мессенджеры, генерация изображений. Открытый код, MIT.

## Состав

| Плагин | Тип | Репозиторий |
|---|---|---|
| **RouterAI** | model-provider | [temga/hermes-routerai-plugin](https://github.com/temga/hermes-routerai-plugin) |
| **NeuralDeep** | model-provider | [temga/hermes-neuraldeep-chat](https://github.com/temga/hermes-neuraldeep-chat) |
| **MAX Messenger** | platform | [temga/max-hermes-plugin](https://github.com/temga/max-hermes-plugin) |
| **RouterAI Image Gen** | backend (image generation) | [temga/hermes-plugin-routerai-imagegen](https://github.com/temga/hermes-plugin-routerai-imagegen) |

## Быстрый старт

Одна команда установит и Hermes Agent, и все плагины:

```
curl -fsSL https://raw.githubusercontent.com/temga/hermes-ru-ecosystem/main/install.sh | bash
```

Если Hermes уже установлен — установятся только плагины.

## Установка

### Вариант 1: One-liner (рекомендуется)

```
curl -fsSL https://raw.githubusercontent.com/temga/hermes-ru-ecosystem/main/install.sh | bash
```

Скрипт клонирует репозиторий с сабмодулями в `~/.hermes/hermes-ru-ecosystem`, при необходимости устанавливает Hermes Agent из GitHub, а затем устанавливает все плагины через `hermes plugins install`. Если `git` не установлен — скачивает tarball-архив.

### Вариант 2: Вручную

```
git clone --recursive https://github.com/temga/hermes-ru-ecosystem.git
cd hermes-ru-ecosystem
./install.sh
```

### Установка отдельных плагинов

```
./install.sh routerai
./install.sh neuraldeep
./install.sh max
./install.sh routerai-imagen
```

## Настройка

Hermes хранит секреты в `~/.hermes/.env`. После установки запустите `hermes setup` — мастер настройки запросит нужные API-ключи автоматически.

Подробная настройка каждого плагина — в его собственном README:

| Плагин | README |
|---|---|
| RouterAI | [model-providers/routerai/README.md](model-providers/routerai/README.md) |
| NeuralDeep | [model-providers/neuraldeep/README.md](model-providers/neuraldeep/README.md) |
| MAX Messenger | [platforms/max/README.md](platforms/max/README.md) |
| RouterAI Image Gen | [backends/routerai-imagegen/README.md](backends/routerai-imagegen/README.md) |

## Обновление

### Если установлен через git

```
cd ~/.hermes/hermes-ru-ecosystem
git pull
git submodule update --remote
./install.sh
```

### Если установлен через one-liner

Просто запустите ту же команду снова:

```
curl -fsSL https://raw.githubusercontent.com/temga/hermes-ru-ecosystem/main/install.sh | bash
```

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

## Лицензия

MIT
