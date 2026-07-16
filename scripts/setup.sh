#!/bin/bash
# setup.sh - Pobiera binarki CoD2, libcod2 i pliki gry do testow CI
# Uzycie: bash setup.sh [katalog_docelowy]

set -euo pipefail

TARGET_DIR="${1:-./code/bin}"
mkdir -p "$TARGET_DIR"

echo "=== Pobieranie CoD2 Linux Dedicated Server v1.3 ==="
curl -sL -o /tmp/cod2-lnxded-1.3.tar \
  "https://www.opferlamm-clan.de/tl_files/special/patches/cod2-lnxded-1.3-06232006.tar"

echo "=== Wypakowywanie ==="
EXTRACT_DIR="/tmp/cod2-extract"
rm -rf "$EXTRACT_DIR"
mkdir -p "$EXTRACT_DIR"
tar -xf /tmp/cod2-lnxded-1.3.tar -C "$EXTRACT_DIR"
# Archiwum zawiera:
#   cod2_lnxded
#   Readme_Cod2_LinuxServer_Readme.txt
#   main/ - katalog z plikami .iwd

# Kopiujemy binarke
cp "$EXTRACT_DIR"/cod2_lnxded "$TARGET_DIR/"
chmod +x "$TARGET_DIR/cod2_lnxded"

# Kopiujemy katalog main/ (pliki .iwd) - wymagane do map
if [ -d "$EXTRACT_DIR/main" ]; then
  echo "=== Kopiowanie main/ (pliki gry) ==="
  cp -r "$EXTRACT_DIR/main" "$TARGET_DIR/"
  ls -la "$TARGET_DIR/main/"
fi

echo "=== Pobieranie libcod2.so (zk_libcod v15.0) ==="
curl -sL -o "$TARGET_DIR/libcod2.so" \
  "https://github.com/ibuddieat/zk_libcod/releases/download/v15.0/libcod2.so"
chmod +x "$TARGET_DIR/libcod2.so"

echo "=== Weryfikacja ==="
ls -la "$TARGET_DIR/"
ls -la "$TARGET_DIR/main/" 2>/dev/null || echo "UWAGA: brak main/"

echo "=== Gotowe ==="