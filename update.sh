#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/scripts/lib/common.sh"

log_step "Обновление репозитория..."
git pull origin main || die "Ошибка git pull"

log_step "Повторный запуск установщика (идемпотентно)..."
exec ./install.sh