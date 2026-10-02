#!/usr/bin/env bash
set -euo pipefail

# Цвета для вывода
readonly COLOR_RESET="\033[0m"
readonly COLOR_GREEN="\033[0;32m"
readonly COLOR_YELLOW="\033[0;33m"
readonly COLOR_RED="\033[0;31m"
readonly COLOR_CYAN="\033[0;36m"

log_info()  { echo -e "${COLOR_GREEN}[✅]${COLOR_RESET} $1"; }
log_warn()  { echo -e "${COLOR_YELLOW}[⚠️]${COLOR_RESET} $1"; }
log_error() { echo -e "${COLOR_RED}[❌]${COLOR_RESET} $1"; }
log_step()  { echo -e "${COLOR_CYAN}[🔧]${COLOR_RESET} $1"; }

die() {
    log_error "$1"
    exit 1
}

need_cmd() {
    if ! command -v "$1" &> /dev/null; then
        die "Требуется команда '$1', но она не найдена."
    fi
}

# Идемпотентный бэкап файла
backup_file() {
    local src="$1"
    local backup_dir="$HOME/.lain-rice-backup/$(date +%Y%m%d_%H%M%S)"
    
    if [[ -e "$src" ]]; then
        mkdir -p "$backup_dir"
        cp -a "$src" "$backup_dir/"
        log_warn "Создан бэкап: $backup_dir/$(basename "$src")"
    fi
}

# Добавление строки в файл, если её там ещё нет
append_if_missing() {
    local file="$1"
    local line="$2"
    if ! grep -qF "$line" "$file" 2>/dev/null; then
        echo "$line" >> "$file"
        log_info "Добавлено в $(basename "$file"): $line"
    fi
}

# Безопасная проверка пути перед удалением
safe_rmdir() {
    local dir="$1"
    if [[ -d "$dir" && "$dir" == "$HOME/"* && "$dir" != "$HOME" ]]; then
        rm -rf "$dir"
        log_info "Удалено: $dir"
    else
        log_warn "Пропуск опасного пути: $dir"
    fi
}