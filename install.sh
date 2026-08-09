#!/usr/bin/env bash
#
# install.sh — установка плагинов российской экосистемы для Hermes Agent.
#
# Все плагины устанавливаются единым способом — через встроенный менеджер
# плагинов Hermes:
#
#   hermes plugins install temga/<repo> --enable
#
# Поддерживает два режима:
#   1. Локальный:  ./install.sh          (из клонированного репозитория)
#   2. One-liner:  curl -fsSL <url> | bash
#
# В режиме one-liner скрипт сам клонирует репозиторий с сабмодулями
# в ~/.hermes/hermes-ru-ecosystem и продолжает установку оттуда.
#
# Использование:
#   ./install.sh              — установить все плагины
#   ./install.sh routerai     — установить только RouterAI (model-provider)
#   ./install.sh neuraldeep   — установить только NeuralDeep (model-provider)
#   ./install.sh max          — установить только MAX (platform)
#   ./install.sh routerai-imagen — установить только RouterAI Image Gen (backend)
#   ./install.sh neuraldeep-search — установить только NeuralDeep Search (backend)
#
set -euo pipefail

REPO_URL="https://github.com/temga/hermes-ru-ecosystem.git"
TARBALL_URL="https://github.com/temga/hermes-ru-ecosystem/archive/refs/heads/main.tar.gz"
CLONE_DIR="${HERMES_RU_ECOSYSTEM_DIR:-$HOME/.hermes/hermes-ru-ecosystem}"

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

# ── Self-bootstrap: если скрипт запущен через curl | bash ─────────────
# Детект: нет .git рядом → скрипт скачан, а не клонирован
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -d "$SCRIPT_DIR/.git" ]]; then
    if command -v git &>/dev/null; then
        # Git есть — клонируем с сабмодулями
        info "Клонирую репозиторий с сабмодулями..."
        if [[ -d "$CLONE_DIR/.git" ]]; then
            info "Обновляю существующий клон: $CLONE_DIR"
            cd "$CLONE_DIR"
            git pull --ff-only
            git submodule update --remote
        else
            rm -rf "$CLONE_DIR"
            git clone --recursive "$REPO_URL" "$CLONE_DIR"
        fi
        cd "$CLONE_DIR"
        SCRIPT_DIR="$CLONE_DIR"
        info "Клон готов: $CLONE_DIR"
    else
        # Git нет — скачиваем tarball основного репо
        info "Git не найден — скачиваю tarball..."
        if [[ -d "$CLONE_DIR" ]]; then
            rm -rf "$CLONE_DIR"
        fi
        mkdir -p "$CLONE_DIR"

        tmp_tar="$(mktemp)"
        tmp_extract="$(mktemp -d)"
        curl -fsSL "$TARBALL_URL" -o "$tmp_tar"
        tar -xzf "$tmp_tar" -C "$tmp_extract"
        cp -r "$tmp_extract"/hermes-ru-ecosystem-main/* "$CLONE_DIR/"
        cp -r "$tmp_extract"/hermes-ru-ecosystem-main/.* "$CLONE_DIR/" 2>/dev/null || true
        rm -rf "$tmp_extract" "$tmp_tar"

        cd "$CLONE_DIR"
        SCRIPT_DIR="$CLONE_DIR"
        info "Распаковано: $CLONE_DIR"
        warn "Git не установлен — плагины будут установлены через hermes plugins install."
    fi
fi

# ── Установка Hermes Agent (если не установлен) ──────────────────────
ensure_hermes() {
    # 1. Уже в PATH?
    if command -v hermes &>/dev/null; then
        info "Hermes Agent найден в PATH."
        return 0
    fi

    # 2. Установлен, но ~/.local/bin не в PATH?
    if [[ -x "$HOME/.local/bin/hermes" ]]; then
        info "Hermes Agent найден в ~/.local/bin — добавляю в PATH."
        export PATH="$HOME/.local/bin:$PATH"
        return 0
    fi

    # 3. Не установлен — клонируем с GitHub и запускаем setup-hermes.sh
    warn "Hermes Agent не найден. Устанавливаю из GitHub..."

    local HERMES_REPO="https://github.com/NousResearch/hermes-agent.git"
    local HERMES_SRC="$HERMES_HOME/hermes-agent"

    if [[ -d "$HERMES_SRC/.git" ]]; then
        info "Обновляю существующий клон Hermes: $HERMES_SRC"
        cd "$HERMES_SRC"
        git pull --ff-only
    else
        info "Клонирую Hermes Agent → $HERMES_SRC"
        git clone --depth 1 "$HERMES_REPO" "$HERMES_SRC"
        cd "$HERMES_SRC"
    fi

    # setup-hermes.sh интерактивный — отказываемся от ripgrep и setup wizard
    info "Запускаю setup-hermes.sh (неинтерактивный режим)..."
    printf 'n\n\n' | bash setup-hermes.sh

    # Проверяем результат
    if [[ -x "$HOME/.local/bin/hermes" ]]; then
        export PATH="$HOME/.local/bin:$PATH"
        info "Hermes Agent установлен."
    else
        error "Установка Hermes не удалась. См. вывод выше."
        error "Установите вручную: https://github.com/NousResearch/hermes-agent"
        return 1
    fi
}

ensure_hermes

# ── Реестр плагинов ───────────────────────────────────────────────────
# Формат: "repo_name"
#   repo_name — аргумент для `hermes plugins install temga/<repo_name> --enable`
declare -A PLUGINS=(
    ["routerai"]="hermes-routerai-plugin"
    ["neuraldeep"]="hermes-neuraldeep-chat"
    ["max"]="max-hermes-plugin"
    ["routerai-imagen"]="hermes-plugin-routerai-imagegen"
    ["neuraldeep-search"]="hermes-plugin-neuraldeep-search"
)

# Model-provider плагины требуют дополнительного шага после install.
# `hermes plugins install` клонирует репозиторий плоско в
# ~/.hermes/plugins/<manifest_name>/, но Provider Registry сканирует только
# ~/.hermes/plugins/model-providers/<name>/. Симлинк устраняет разрыв.
# Формат: [short_name]="manifest_name" (manifest_name — поле name из plugin.yaml)
declare -A MODEL_PROVIDERS=(
    ["routerai"]="routerai-provider"
    ["neuraldeep"]="neuraldeep-provider"
)

# ── Симлинк для model-provider плагинов ──────────────────────────────
link_model_provider() {
    local name="$1"       # short name (routerai, neuraldeep)
    local manifest="$2"   # manifest name from plugin.yaml (routerai-provider, …)

    local plugins_dir="$HERMES_HOME/plugins"
    local target="$plugins_dir/$manifest"
    local link="$plugins_dir/model-providers/$name"

    if [[ ! -d "$target" ]]; then
        warn "Каталог $target не найден — пропускаю симлинк для $name"
        return 0
    fi

    mkdir -p "$plugins_dir/model-providers"
    rm -f "$link"
    ln -s "$target" "$link"
    info "Симлинк: model-providers/$name → $manifest"
}

# ── Установка через hermes plugins install ────────────────────────────
install_plugin() {
    local name="$1"
    local repo="${PLUGINS[$name]}"

    if ! command -v hermes &>/dev/null; then
        error "hermes недоступен. ensure_hermes() должен был это обработать."
        return 1
    fi

    hermes plugins install "temga/$repo" --enable
    info "Установлен: $name (temga/$repo)"

    # Model-provider плагины: создаём симлинк в model-providers/
    if [[ -n "${MODEL_PROVIDERS[$name]+isset}" ]]; then
        link_model_provider "$name" "${MODEL_PROVIDERS[$name]}"
    fi
}

if [[ $# -gt 0 ]]; then
    for name in "$@"; do
        if [[ -z "${PLUGINS[$name]+isset}" ]]; then
            error "Неизвестный плагин: $name"
            echo "Доступные: ${!PLUGINS[*]}"
            exit 1
        fi
        install_plugin "$name"
    done
else
    echo "Установка плагинов российской экосистемы для Hermes Agent"
    echo "HERMES_HOME: $HERMES_HOME"
    echo ""
    for name in "${!PLUGINS[@]}"; do
        install_plugin "$name" || true
    done
fi

echo ""
info "Плагины установлены. Перезапустите Hermes, чтобы они вступили в силу."

# ── Настройка (если Hermes только что установлен) ────────────────────
# hermes setup читает requires_env из plugin.yaml установленных плагинов
# и запрашивает нужные API-ключи. Запускаем только после установки плагинов.
if [[ -t 0 ]]; then
    echo ""
    read -p "Запустить мастер настройки (hermes setup)? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        hermes setup
    else
        info "Настройте Hermes позже командой: hermes setup"
    fi
else
    # curl | bash — нет терминала, инструктируем пользователя
    info "Для настройки API-ключей выполните: hermes setup"
fi
