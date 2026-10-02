#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/scripts/lib/common.sh"

log_warn "Начало удаления Lain Rice..."
read -p "Это восстановит последние бэкапы и удалит созданные файлы. Продолжить? (y/N): " CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || die "Отменено."

LATEST_BACKUP=$(ls -td "$HOME/.lain-rice-backup/"* 2>/dev/null | head -n 1)

if [[ -n "$LATEST_BACKUP" ]]; then
    log_step "Восстановление из $LATEST_BACKUP..."
    for dir in i3 polybar picom rofi dunst kitty alacritty cava gtk-3.0 gtk-4.0; do
        if [[ -d "$LATEST_BACKUP/$dir" ]]; then
            rm -rf "$HOME/.config/$dir"
            cp -a "$LATEST_BACKUP/$dir" "$HOME/.config/"
        fi
    done
else
    log_warn "Бэкапы не найдены. Удаление конфигов без восстановления."
    safe_rmdir "$HOME/.config/i3"
    safe_rmdir "$HOME/.config/polybar"
    safe_rmdir "$HOME/.config/picom"
    safe_rmdir "$HOME/.config/rofi"
    safe_rmdir "$HOME/.config/dunst"
    safe_rmdir "$HOME/.config/kitty"
fi

# Очистка специфичных файлов
rm -f "$HOME/.xinitrc"
rm -f "$HOME/.bashrc.d/lain.sh"

log_info "Удаление завершено. Рекомендуется перезагрузиться."