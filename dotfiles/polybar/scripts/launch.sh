#!/usr/bin/env bash
set -euo pipefail

# Убиваем старые инстанции polybar
killall -q polybar

# Ждём завершения
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Запускаем polybar для каждого монитора
for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m polybar --reload main &
done

echo "Polybar запущен"