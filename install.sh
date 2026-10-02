#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/lib/common.sh"

LOG_FILE="$HOME/.lain-rice-install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

log_step "Запуск установки Lain Rice..."

# 1. Проверка окружения
source "$SCRIPT_DIR/scripts/detect_env.sh"

# 2. Определение железа [НОВОЕ]
source "$SCRIPT_DIR/scripts/hardware_detect.sh"

# 3. Установка драйверов [НОВОЕ]
source "$SCRIPT_DIR/scripts/drivers_install.sh"

# 4. Интерактивный выбор
echo -e "\n${COLOR_CYAN}--- Настройка окружения ---${COLOR_RESET}"
read -p "Выберите терминал (1: kitty, 2: alacritty) [1]: " TERM_CHOICE
TERM_CHOICE=${TERM_CHOICE:-1}

read -p "Установить Nerd Fonts? (y/n) [y]: " INSTALL_FONTS
INSTALL_FONTS=${INSTALL_FONTS:-y}

read -p "Включить автозапуск X через .bash_profile? (y/n) [y]: " AUTO_STARTX
AUTO_STARTX=${AUTO_STARTX:-y}

# 5. Бэкап
log_step "Создание резервных копий существующих конфигов..."
source "$SCRIPT_DIR/scripts/backup.sh"

# 6. Установка пакетов
log_step "Установка основных пакетов риса..."
if [[ "$INSTALL_FONTS" =~ ^[Yy]$ ]]; then
    cat "$SCRIPT_DIR/packages/pacman.txt" "$SCRIPT_DIR/packages/aur.txt" > /tmp/lain_all_packages.txt
else
    cat "$SCRIPT_DIR/packages/pacman.txt" > /tmp/lain_all_packages.txt
fi

# Проверка установленных пакетов для идемпотентности
PKGS_TO_INSTALL=""
while read -r pkg; do
    [[ -z "$pkg" || "$pkg" == \#* ]] && continue
    if ! pacman -Qi "$pkg" &> /dev/null; then
        PKGS_TO_INSTALL="$PKGS_TO_INSTALL $pkg"
    fi
done < /tmp/lain_all_packages.txt

if [[ -n "$PKGS_TO_INSTALL" ]]; then
    log_info "Установка: $PKGS_TO_INSTALL"
    sudo pacman -S --needed --noconfirm $PKGS_TO_INSTALL || die "Ошибка установки пакетов"
else
    log_info "Все пакеты уже установлены."
fi

# 7. Развёртывание dotfiles
log_step "Копирование конфигурационных файлов..."
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"

# Копируем структуру, пропуская ненужный терминал
find "$DOTFILES_DIR" -type f | while read -r file; do
    rel_path="${file#$DOTFILES_DIR/}"
    
    # Пропускаем alacritty, если выбран kitty, и наоборот
    if [[ "$TERM_CHOICE" == "1" && "$rel_path" == alacritty/* ]]; then continue; fi
    if [[ "$TERM_CHOICE" == "2" && "$rel_path" == kitty/* ]]; then continue; fi

    dest="$HOME/.$(dirname "$rel_path")"
    mkdir -p "$dest"
    
    # Для .bashrc.d создаём директорию, если её нет
    if [[ "$rel_path" == ".bashrc.d/"* ]]; then
        dest="$HOME/.bashrc.d"
        mkdir -p "$dest"
    fi

    backup_file "$HOME/.$rel_path"
    cp -f "$file" "$HOME/.$rel_path"
done

# 8. Пост-установка
source "$SCRIPT_DIR/scripts/post_install.sh"

# 9. Автозапуск X
if [[ "$AUTO_STARTX" =~ ^[Yy]$ ]]; then
    append_if_missing "$HOME/.bash_profile" '[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx'
fi

# 10. Финальные инструкции [НОВОЕ]
echo -e "\n${COLOR_CYAN}=== Установка завершена ===${COLOR_RESET}"
log_info "🎉 Lain Rice успешно установлен!"

# Проверяем, нужен ли перезапуск
CPU=$(grep "^CPU=" /tmp/lain-hardware-info | cut -d= -f2)
if [[ "$CPU" == "intel" || "$CPU" == "amd" ]]; then
    if pacman -Qi "${CPU}-ucode" &> /dev/null; then
        echo -e "\n${COLOR_YELLOW}⚠️ ВАЖНО: Был установлен микрокод процессора.${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Обновите загрузчик GRUB:${COLOR_RESET}"
        echo -e "  ${COLOR_CYAN}sudo grub-mkconfig -o /boot/grub/grub.cfg${COLOR_RESET}"
    fi
fi

GPU=$(grep "^GPU=" /tmp/lain-hardware-info | cut -d= -f2)
if [[ "$GPU" == "nvidia" ]]; then
    echo -e "\n${COLOR_YELLOW}⚠️ Для NVIDIA рекомендуется:${COLOR_RESET}"
    echo -e "  1. Перезагрузить систему для загрузки драйверов"
    echo -e "  2. Проверить работу: ${COLOR_CYAN}nvidia-smi${COLOR_RESET}"
fi

echo -e "\n${COLOR_GREEN}Следующие шаги:${COLOR_RESET}"
echo -e "  1. Сгенерируйте обои: ${COLOR_CYAN}~/.config/wallpapers/wallpaper-gen.sh${COLOR_RESET}"
echo -e "  2. Перезагрузитесь или выполните: ${COLOR_CYAN}startx${COLOR_RESET}"
echo -e "  3. Наслаждайтесь Wired! 🔌"