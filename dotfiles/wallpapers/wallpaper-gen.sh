#!/usr/bin/env bash
set -euo pipefail
# Генератор обоев в стиле Lain: сканлайны + шум
# Требует imagemagick

OUTPUT_DIR="$HOME/.wallpapers"
mkdir -p "$OUTPUT_DIR"
OUTPUT="$OUTPUT_DIR/lain_generated.png"

# Если есть базовое изображение, используем его, иначе создаём градиент
BASE_IMG="$1"
if [[ -n "$BASE_IMG" && -f "$BASE_IMG" ]]; then
    cp "$BASE_IMG" "$OUTPUT"
else
    # Создаём тёмный градиент
    convert -size 1920x1080 gradient:"#0a0a0a-#1a1a1a" "$OUTPUT"
fi

# Накладываем сканлайны и шум
convert "$OUTPUT" \
    \( -size 1920x1080 pattern:horizontal2 -fill "#000000" -colorize 80 \) \
    -compose Screen -composite \
    -noise 3 \
    -fill "rgba(139, 0, 0, 0.1)" -colorize 10 \
    "$OUTPUT"

echo "✅ Обои сгенерированы: $OUTPUT"
feh --no-fehbg --randomize --recursive "$OUTPUT_DIR"