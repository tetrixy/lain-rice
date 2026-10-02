#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

log_step "Определение аппаратного обеспечения..."

# Создаём файл с информацией о железе
HW_INFO_FILE="/tmp/lain-hardware-info"
cat /dev/null > "$HW_INFO_FILE"

# 1. Определение видеокарты
log_step "Определение видеокарты..."
if lspci | grep -i "vga\|3d\|display" | grep -qi "nvidia"; then
    echo "GPU=nvidia" >> "$HW_INFO_FILE"
    log_info "🎮 Обнаружена видеокарта NVIDIA"
    lspci | grep -i "vga\|3d\|display" | grep -i "nvidia" >> "$HW_INFO_FILE"
elif lspci | grep -i "vga\|3d\|display" | grep -qi "amd\|radeon"; then
    echo "GPU=amd" >> "$HW_INFO_FILE"
    log_info "🎮 Обнаружена видеокарта AMD"
    lspci | grep -i "vga\|3d\|display" | grep -i "amd\|radeon" >> "$HW_INFO_FILE"
elif lspci | grep -i "vga\|3d\|display" | grep -qi "intel"; then
    echo "GPU=intel" >> "$HW_INFO_FILE"
    log_info "🎮 Обнаружена интегрированная графика Intel"
    lspci | grep -i "vga\|3d\|display" | grep -i "intel" >> "$HW_INFO_FILE"
else
    echo "GPU=unknown" >> "$HW_INFO_FILE"
    log_warn "⚠️ Не удалось определить видеокарту"
fi

# 2. Определение процессора и микрокода
log_step "Определение процессора..."
CPU_VENDOR=$(grep -m1 "vendor_id" /proc/cpuinfo | awk '{print $3}')
if [[ "$CPU_VENDOR" == "GenuineIntel" ]]; then
    echo "CPU=intel" >> "$HW_INFO_FILE"
    log_info "🔲 Процессор Intel"
elif [[ "$CPU_VENDOR" == "AuthenticAMD" ]]; then
    echo "CPU=amd" >> "$HW_INFO_FILE"
    log_info "🔲 Процессор AMD"
else
    echo "CPU=unknown" >> "$HW_INFO_FILE"
    log_warn "⚠️ Неизвестный процессор: $CPU_VENDOR"
fi

# 3. Определение Wi-Fi адаптера
log_step "Определение сетевого оборудования..."
if lspci | grep -qi "network\|ethernet\|wireless"; then
    echo "NETWORK=present" >> "$HW_INFO_FILE"
    log_info "📶 Сетевой адаптер обнаружен"
    lspci | grep -i "network\|ethernet\|wireless" >> "$HW_INFO_FILE"
else
    echo "NETWORK=none" >> "$HW_INFO_FILE"
    log_warn "⚠️ Сетевой адаптер не обнаружен (или только USB)"
fi

# 4. Определение аудио
log_step "Определение аудио..."
if pacman -Qq | grep -q "^pipewire$"; then
    echo "AUDIO=pipewire" >> "$HW_INFO_FILE"
    log_info "🔊 PipeWire уже установлен"
elif pacman -Qq | grep -q "^pulseaudio$"; then
    echo "AUDIO=pulseaudio" >> "$HW_INFO_FILE"
    log_info "🔊 PulseAudio уже установлен"
else
    echo "AUDIO=none" >> "$HW_INFO_FILE"
    log_warn "⚠️ Аудио-сервер не обнаружен"
fi

# 5. Определение тачпада (для ноутбуков)
log_step "Определение тачпада..."
if libinput list-devices 2>/dev/null | grep -qi "touchpad"; then
    echo "TOUCHPAD=present" >> "$HW_INFO_FILE"
    log_info "🖱️ Тачпад обнаружен"
else
    echo "TOUCHPAD=none" >> "$HW_INFO_FILE"
    log_info "🖱️ Тачпад не обнаружен (десктоп?)"
fi

# 6. Определение разрешения экрана
log_step "Определение разрешения экрана..."
if command -v xrandr &> /dev/null && [[ -n "${DISPLAY:-}" ]]; then
    RESOLUTION=$(xrandr | grep -E "^\S+\s+connected" -A1 | grep -oP '\d+x\d+' | head -1)
    if [[ -n "$RESOLUTION" ]]; then
        echo "RESOLUTION=$RESOLUTION" >> "$HW_INFO_FILE"
        log_info "🖥️ Разрешение: $RESOLUTION"
    else
        echo "RESOLUTION=unknown" >> "$HW_INFO_FILE"
        log_warn "⚠️ Не удалось определить разрешение"
    fi
else
    echo "RESOLUTION=unknown" >> "$HW_INFO_FILE"
    log_warn "⚠️ X11 не запущен, разрешение не определено"
fi

log_info "✅ Информация о железе сохранена в $HW_INFO_FILE"