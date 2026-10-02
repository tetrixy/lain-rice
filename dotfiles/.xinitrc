#!/usr/bin/env bash
set -euo pipefail

# Загрузка раскладки и настроек курсора
setxkbmap -layout us,ru -option grp:alt_shift_toggle,caps:escape
xsetroot -cursor_name left_ptr

# Отключаем системный динамик (бипер)
xset b off

# Запуск i3
exec i3