#!/usr/bin/env bash
# Генерирует случайный глитч-символ для polybar
GLITCH_CHARS=("█" "▓" "▒" "░" "◼" "◻" "▚" "▞")
RAND_CHAR=${GLITCH_CHARS[$RANDOM % ${#GLITCH_CHARS[@]}]}

# 20% шанс показать глитч, иначе показать "WIRED"
if (( RANDOM % 5 == 0 )); then
    echo "$RAND_CHAR"
else
    echo "ワイアード"
fi