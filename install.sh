#!/usr/bin/env bash
#
# install.sh — установка плагинов российской экосистемы для Hermes Agent.
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
#   ./install.sh routerai     — установить только RouterAI
#   ./install.sh max          — установить только MAX
#
set -euo pipefail

REPO_URL="https://github.com/temga/hermes-ru-ecosystem.git"
TARBALL_URL="https://github.com/temga/hermes-ru-ecosystem/archive/refs/heads/main.tar.gz"
CLONE_DIR="${HERMES_RU_ECOSYSTEM_DIR:-$HOME/.hermes/hermes-ru-ecosystem}"

# URL tarball-ов отдельных плагинов (для режима без git)
declare -A PLUGIN_TARBALLS=(
    ["routerai"]="https://github.com/temga/hermes-routerai-plugin/archive/refs/heads/main.tar.gz"
    ["max"]="https://github.com/temga/max-hermes-plugin/archive/refs/heads/main.tar.gz"
)
# Имя папки внутри tarball (GitHub: <repo>-main/)
declare -A PLUGIN_TARBALL_DIRS=(
    ["routerai"]="hermes-routerai-plugin-main"
    ["max"]="max-hermes-plugin-main"
)

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
PLUGINS_DIR="$HERMES_HOME/plugins"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

# ── Реестр плагинов ───────────────────────────────────────────────────
declare -A PLUGINS=(
    ["routerai"]="model-providers/routerai:model-providers/routerai"
    ["max"]="platforms/max:platforms/max"
)

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
        # Git нет — скачиваем tarball основного репо + отдельные tarball'ы плагинов
        info "Git не найден — скачиваю tarball..."
        if [[ -d "$CLONE_DIR" ]]; then
            rm -rf "$CLONE_DIR"
        fi
        mkdir -p "$CLONE_DIR"

        # Основной репо (install.sh, README, .env.example)
        tmp_tar="$(mktemp)"
        tmp_extract="$(mktemp -d)"
        curl -fsSL "$TARBALL_URL" -o "$tmp_tar"
        tar -xzf "$tmp_tar" -C "$tmp_extract"
        cp -r "$tmp_extract"/hermes-ru-ecosystem-main/* "$CLONE_DIR/"
        cp -r "$tmp_extract"/hermes-ru-ecosystem-main/.* "$CLONE_DIR/" 2>/dev/null || true
        rm -rf "$tmp_extract" "$tmp_tar"

        # Отдельные плагины (сабмодули не входят в tarball основного репо)
        for pname in "${!PLUGIN_TARBALLS[@]}"; do
            local entry="${PLUGINS[$pname]}"
            local src_rel="${entry%%:*}"
            local dst_dir="$CLONE_DIR/$src_rel"
            mkdir -p "$dst_dir"
            tmp_tar="$(mktemp)"
            tmp_extract="$(mktemp -d)"
            curl -fsSL "${PLUGIN_TARBALLS[$pname]}" -o "$tmp_tar"
            tar -xzf "$tmp_tar" -C "$tmp_extract"
            cp -r "$tmp_extract"/"${PLUGIN_TARBALL_DIRS[$pname]}"/* "$dst_dir/"
            cp -r "$tmp_extract"/"${PLUGIN_TARBALL_DIRS[$pname]}"/.* "$dst_dir/" 2>/dev/null || true
            rm -rf "$tmp_extract" "$tmp_tar"
            info "Скачан плагин: $pname"
        done

        cd "$CLONE_DIR"
        SCRIPT_DIR="$CLONE_DIR"
        info "Распаковано: $CLONE_DIR"
        warn "Git не установлен — обновляйте через повторный запуск скрипта."
    fi
fi

# ── Установка плагинов ────────────────────────────────────────────────
install_plugin() {
    local name="$1"
    local entry="${PLUGINS[$name]}"
    local src_rel="${entry%%:*}"
    local dst_rel="${entry##*:}"

    local src="$SCRIPT_DIR/$src_rel"
    local dst="$PLUGINS_DIR/$dst_rel"

    if [[ ! -d "$src" ]]; then
        error "Плагин '$name' не найден: $src"
        return 1
    fi

    mkdir -p "$(dirname "$dst")"

    if [[ -L "$dst" ]]; then
        rm "$dst"
        ln -s "$src" "$dst"
        info "Обновлён симлинк: $dst → $src"
    elif [[ -d "$dst" ]]; then
        warn "Директория уже существует (не симлинк): $dst"
        warn "Удалите её вручную: rm -rf \"$dst\""
        return 1
    else
        ln -s "$src" "$dst"
        info "Установлен: $dst → $src"
    fi
}

# ── Установка ─────────────────────────────────────────────────────────
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
