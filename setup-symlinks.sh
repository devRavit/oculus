#!/usr/bin/env bash
# setup-symlinks.sh
# WoW AddOns 디렉터리에 Oculus 모듈 심볼릭 링크를 일괄 설정합니다.
# Git Bash에서 실행: bash setup-symlinks.sh

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
ADDONS_DIR="/c/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns"

# 링크할 모듈 목록 (새 모듈 추가 시 여기에만 추가)
MODULES=(
    "Oculus"
    "Oculus_UnitFrames"
    "Oculus_RaidFrames"
    "Oculus_General"
)

echo "=== Oculus Symlink Setup ==="
echo "Repo   : $REPO_DIR"
echo "AddOns : $ADDONS_DIR"
echo ""

for MODULE in "${MODULES[@]}"; do
    SRC="$REPO_DIR/$MODULE"
    DST="$ADDONS_DIR/$MODULE"

    if [ ! -d "$SRC" ]; then
        echo "[SKIP] $MODULE — 소스 없음"
        continue
    fi

    # 기존 링크/디렉터리 제거 후 재생성
    if [ -e "$DST" ] || [ -L "$DST" ]; then
        rm -rf "$DST"
    fi

    ln -s "$SRC" "$DST"
    echo "[OK]   $MODULE"
done

echo ""
echo "완료. WoW를 재시작하거나 /reload 하세요."
