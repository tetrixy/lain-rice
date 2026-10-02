#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

log_step "Проверка окружения..."

# Проверка ОС
if ! grep -q "Arch Linux" /etc/os-release; then
    die "Этот рис предназначен только для Arch Linux."
fi
log_info "✅ Arch Linux обнаружен"

# Проверка X11 vs Wayland
if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    die "Обнаружен Wayland. Этот рис работает только на X11."
fi

if [[ -z "${DISPLAY:-}" ]]; then
    log_warn "Переменная DISPLAY пуста. Убедитесь, что вы не в графической сессии."
    log_warn "Если вы в TTY, установка продолжится, но X11 нужно будет запустить вручную."
else
    log_info "✅ X11 окружение обнаружено"
fi

# Проверка базовых инструментов
need_cmd "pacman"
need_cmd "git"
log_info "✅ Базовые инструменты доступны"