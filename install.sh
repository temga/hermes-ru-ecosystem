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

# ── Реестр плагинов ───────────────────────────────────────────────────
# Формат: "repo_name"
#   repo_name — аргумент для `hermes plugins install temga/<repo_name> --enable`
declare -A PLUGINS=(
    ["routerai"]="hermes-routerai-plugin"
    ["neuraldeep"]="hermes-neuraldeep-chat"
    ["max"]="max-hermes-plugin"
    ["routerai-imagen"]="hermes-plugin-routerai-imagegen"
)

# ── Установка через hermes plugins install ────────────────────────────
install_plugin() {
    local name="$1"
    local repo="${PLUGINS[$name]}"

    if ! command -v hermes &>/dev/null; then
        error "hermes не найден в PATH. Установите Hermes Agent: https://github.com/NousResearch/hermes-agent"
        return 1
    fi

    hermes plugins install "temga/$repo" --enable
    info "Установлен: $name (temga/$repo)"
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
info "Готово! Перезапустите Hermes, чтобы плагины вступили в силу."
