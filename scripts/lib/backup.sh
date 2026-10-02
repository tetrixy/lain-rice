#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

BACKUP_DIR="$HOME/.lain-rice-backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

for dir in i3 polybar picom rofi dunst kitty alacritty cava gtk-3.0 gtk-4.0; do
    if [[ -d "$HOME/.config/$dir" ]]; then
        cp -a "$HOME/.config/$dir" "$BACKUP_DIR/"
    fi
done

for file in .xinitrc .bash_profile; do
    if [[ -f "$HOME/$file" ]]; then
        cp -a "$HOME/$file" "$BACKUP_DIR/"
    fi
done

log_info "Бэкап создан в $BACKUP_DIR"