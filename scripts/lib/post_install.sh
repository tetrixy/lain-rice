#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

log_step "Обновление кэша шрифтов..."
fc-cache -fv > /dev/null 2>&1 || true

log_step "Обновление кэша иконок GTK..."
gtk-update-icon-cache -f -t /usr/share/icons/Papirus > /dev/null 2>&1 || true

if [[ -f "$HOME/.bashrc" ]]; then
    append_if_missing "$HOME/.bashrc" 'source "$HOME/.bashrc.d/lain.sh"'
fi

log_info "Пост-установочные задачи выполнены."