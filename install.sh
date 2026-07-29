#!/usr/bin/env bash
#
# install.sh — установка плагинов российской экосистемы для Hermes Agent.
#
# Создаёт символические ссылки в ~/.hermes/plugins/ для каждого плагина
# из этого monorepo. Обновление плагинов — через `git pull` + `git submodule update --remote`.
#
# Использование:
#   ./install.sh          — установить все плагины
#   ./install.sh routerai — установить только RouterAI
#   ./install.sh max      — установить только MAX
#
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
PLUGINS_DIR="$HERMES_HOME/plugins"

# Цветной вывод
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Реестр плагинов: имя → (относительный путь в monorepo, целевой путь в ~/.hermes/plugins/)
declare -A PLUGINS=(
    ["routerai"]="model-providers/routerai:model-providers/routerai"
    ["max"]="platforms/max:platforms/max"
)

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
        # Уже симлинк — обновим
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

# Если передан аргумент — устанавливаем только указанный плагин
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
    # Устанавливаем все
    echo "Установка плагинов российской экосистемы для Hermes Agent"
    echo "HERMES_HOME: $HERMES_HOME"
    echo ""
    for name in "${!PLUGINS[@]}"; do
        install_plugin "$name" || true
    done
fi

echo ""
info "Готово! Перезапустите Hermes, чтобы плагины вступили в силу."