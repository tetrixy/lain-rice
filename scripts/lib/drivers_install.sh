#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

HW_INFO_FILE="/tmp/lain-hardware-info"

if [[ ! -f "$HW_INFO_FILE" ]]; then
    die "Файл $HW_INFO_FILE не найден. Сначала запустите hardware_detect.sh"
fi

log_step "Установка драйверов на основе обнаруженного железа..."

# Читаем информацию о железе
GPU=$(grep "^GPU=" "$HW_INFO_FILE" | cut -d= -f2)
CPU=$(grep "^CPU=" "$HW_INFO_FILE" | cut -d= -f2)
AUDIO=$(grep "^AUDIO=" "$HW_INFO_FILE" | cut -d= -f2)
TOUCHPAD=$(grep "^TOUCHPAD=" "$HW_INFO_FILE" | cut -d= -f2)

PACKAGES_TO_INSTALL=()

# 1. Драйверы видеокарты
log_step "Установка драйверов видеокарты..."
case "$GPU" in
    nvidia)
        log_info "🎮 Установка драйверов NVIDIA..."
        PACKAGES_TO_INSTALL+=(
            "nvidia-dkms"
            "nvidia-utils"
            "nvidia-settings"
            "lib32-nvidia-utils"
            "libva-mesa-driver"  # Для VA-API
            "mesa-utils"
        )
        # Создаём конфиг X11 для NVIDIA
        mkdir -p "$HOME/.config/X11"
        cat > "$HOME/.config/X11/20-nvidia.conf" << 'EOF'
Section "Device"
    Identifier "NVIDIA Card"
    Driver "nvidia"
    Option "TripleBuffer" "true"
    Option "AllowEmptyInitialConfiguration"
EndSection
EOF
        log_info "✅ Конфиг X11 для NVIDIA создан"
        ;;
    amd)
        log_info "🎮 Установка драйверов AMD..."
        PACKAGES_TO_INSTALL+=(
            "xf86-video-amdgpu"
            "vulkan-radeon"
            "lib32-vulkan-radeon"
            "libva-mesa-driver"
            "mesa-utils"
        )
        ;;
    intel)
        log_info "🎮 Установка драйверов Intel..."
        PACKAGES_TO_INSTALL+=(
            "xf86-video-intel"
            "vulkan-intel"
            "lib32-vulkan-intel"
            "intel-media-driver"  # Для VA-API
            "mesa-utils"
        )
        ;;
    *)
        log_warn "⚠️ Неизвестная видеокарта, пропускаем установку GPU-драйверов"
        ;;
esac

# 2. Микрокод процессора
log_step "Установка микрокода процессора..."
case "$CPU" in
    intel)
        if ! pacman -Qi intel-ucode &> /dev/null; then
            PACKAGES_TO_INSTALL+=("intel-ucode")
            log_info "🔲 Микрокод Intel будет установлен"
            log_warn "⚠️ После установки обновите GRUB: sudo grub-mkconfig -o /boot/grub/grub.cfg"
        else
            log_info "✅ Микрокод Intel уже установлен"
        fi
        ;;
    amd)
        if ! pacman -Qi amd-ucode &> /dev/null; then
            PACKAGES_TO_INSTALL+=("amd-ucode")
            log_info "🔲 Микрокод AMD будет установлен"
            log_warn "⚠️ После установки обновите GRUB: sudo grub-mkconfig -o /boot/grub/grub.cfg"
        else
            log_info "✅ Микрокод AMD уже установлен"
        fi
        ;;
esac

# 3. Аудио
log_step "Настройка аудио..."
if [[ "$AUDIO" == "none" ]]; then
    read -p "Аудио-сервер не обнаружен. Установить PipeWire? (рекомендуется) [Y/n]: " INSTALL_AUDIO
    INSTALL_AUDIO=${INSTALL_AUDIO:-y}
    
    if [[ "$INSTALL_AUDIO" =~ ^[Yy]$ ]]; then
        PACKAGES_TO_INSTALL+=(
            "pipewire"
            "pipewire-alsa"
            "pipewire-pulse"
            "pipewire-jack"
            "wireplumber"
            "lib32-pipewire"
            "lib32-pipewire-jack"
        )
        log_info "🔊 PipeWire будет установлен"
    fi
else
    log_info "✅ Аудио-сервер уже установлен: $AUDIO"
fi

# 4. Тачпад
if [[ "$TOUCHPAD" == "present" ]]; then
    log_step "Установка драйверов тачпада..."
    if ! pacman -Qi xf86-input-libinput &> /dev/null; then
        PACKAGES_TO_INSTALL+=("xf86-input-libinput")
        log_info "🖱️ Драйвер тачпада будет установлен"
    else
        log_info "✅ Драйвер тачпада уже установлен"
    fi
fi

# 5. Базовые утилиты для работы с железом
log_step "Добавление базовых утилит..."
PACKAGES_TO_INSTALL+=(
    "lshw"           # Информация о железе
    "pciutils"       # lspci
    "usbutils"       # lsusb
    "dmidecode"      # Информация о BIOS/UEFI
    "acpi"           # Информация о батарее
    "powertop"       # Мониторинг энергопотребления
)

# 6. Установка пакетов
if [[ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]]; then
    log_step "Установка драйверов и утилит..."
    log_info "Пакеты для установки: ${PACKAGES_TO_INSTALL[*]}"
    
    # Проверяем, какие пакеты уже установлены
    FINAL_PACKAGES=()
    for pkg in "${PACKAGES_TO_INSTALL[@]}"; do
        if ! pacman -Qi "$pkg" &> /dev/null; then
            FINAL_PACKAGES+=("$pkg")
        fi
    done
    
    if [[ ${#FINAL_PACKAGES[@]} -gt 0 ]]; then
        sudo pacman -S --needed --noconfirm "${FINAL_PACKAGES[@]}" || die "Ошибка установки пакетов"
        log_info "✅ Драйверы установлены"
    else
        log_info "✅ Все необходимые драйверы уже установлены"
    fi
else
    log_info "✅ Никаких дополнительных драйверов не требуется"
fi

# 7. Специфичные настройки для picom
log_step "Настройка picom для вашего GPU..."
PICOM_CONF="$HOME/.config/picom/picom.conf"
if [[ -f "$PICOM_CONF" ]]; then
    case "$GPU" in
        nvidia)
            # Для NVIDIA лучше использовать backend glx
            sed -i 's/^backend = .*/backend = "glx";/' "$PICOM_CONF"
            log_info "🎮 Picom настроен для NVIDIA (backend: glx)"
            ;;
        amd|intel)
            # Для AMD/Intel можно использовать glx или xrender
            sed -i 's/^backend = .*/backend = "glx";/' "$PICOM_CONF"
            log_info "🎮 Picom настроен для $GPU (backend: glx)"
            ;;
    esac
fi

log_info "✅ Установка драйверов завершена"