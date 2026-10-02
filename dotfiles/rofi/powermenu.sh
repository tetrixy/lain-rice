#!/usr/bin/env bash
set -euo pipefail

OPTIONS="⏻ Выключить\n↻ Перезагрузить\n🔒 Заблокировать\n⏾ Спящий режим"
CHOSEN=$(echo -e "$OPTIONS" | rofi -dmenu -i -config ~/.config/rofi/lain.rasi -p "Питание")

case "$CHOSEN" in
    *"Выключить"*) systemctl poweroff ;;
    *"Перезагрузить"*) systemctl reboot ;;
    *"Заблокировать"*) betterlockscreen -l dim ;;
    *"Спящий режим"*) systemctl suspend ;;
    *) exit 0 ;;
esac