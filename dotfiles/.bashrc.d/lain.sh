#!/usr/bin/env bash
# Приветствие Lain
if [[ -t 1 ]]; then
    echo -e "\033[0;36m"
    echo "  _      __    ___  "
    echo " | | /| / /__ / _ \ "
    echo " | |/ |/ / -_) ___/ "
    echo " |__/|__/\__/_/     "
    echo -e "\033[0;31m  WIRED CONNECTION ESTABLISHED\033[0m"
    echo ""
fi

# Алиасы
alias ss="maim -u | xclip -selection clipboard -t image/png && echo 'Скриншот в буфере'"
alias lock="betterlockscreen -l dim"