#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/scripts/lib/common.sh"

echo "Выберите акцентный цвет:"
echo "1) Красный (Lain Blood #8b0000)"
echo "2) Циан (Wired Cyan #7fd4d4)"
echo "3) Монохром (Dusty White #dcdcdc)"
read -p "Ваш выбор [1]: " CHOICE
CHOICE=${CHOICE:-1}

case $CHOICE in
    1) ACCENT="#8b0000" ;;
    2) ACCENT="#7fd4d4" ;;
    3) ACCENT="#dcdcdc" ;;
    *) die "Неверный выбор" ;;
esac

log_step "Применение акцента $ACCENT..."

# Обновляем polybar
sed -i "s/^accent = .*/accent = $ACCENT/" "$HOME/.config/polybar/config.ini"
# Обновляем rofi
sed -i "s/^  foreground: .*/  foreground: $ACCENT;/" "$HOME/.config/rofi/lain.rasi"
# Обновляем kitty
sed -i "s/^color_1 .*/color_1 $ACCENT/" "$HOME/.config/kitty/kitty.conf"

log_info "Тема обновлена. Перезапустите polybar (Mod+Shift+R) и kitty."