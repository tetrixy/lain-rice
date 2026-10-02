#!/usr/bin/env bash
QUOTES=(
    "Бог здесь. Я всегда рядом."
    "Present day. Present time. HAHAHAHA."
    "Ты не одинок в Wired."
    "Нет никакой границы между реальностью и сетью."
    "玲音 (Lain)"
)
echo "${QUOTES[$RANDOM % ${#QUOTES[@]}]}"