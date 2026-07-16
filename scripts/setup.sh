#!/bin/bash
# setup.sh - Pobiera binarki CoD2 i libcod2 do testow CI
# Uzycie: bash setup.sh [katalog_docelowy]

set -euo pipefail

TARGET_DIR="${1:-./code/bin}"
mkdir -p "$TARGET_DIR"

echo "=== Pobieranie CoD2 Linux Dedicated Server v1.3 ==="
curl -sL -o /tmp/cod2-lnxded-1.3.tar \
  "https://www.opferlamm-clan.de/tl_files/special/patches/cod2-lnxded-1.3-06232006.tar"

echo "=== Wypakowywanie ==="
tar -xf /tmp/cod2-lnxded-1.3.tar -C /tmp/
# Archiwum zawiera:
#   cod2_lnxded
#   Readme_Cod2_LinuxServer_Readme.txt (lub podobny plik)
#   main/ - katalog z plikami .iwd

# Kopiujemy binarke
cp /tmp/cod2_lnxded "$TARGET_DIR/"
chmod +x "$TARGET_DIR/cod2_lnxded"

echo "=== Pobieranie libcod2.so (zk_libcod v15.0) ==="
curl -sL -o "$TARGET_DIR/libcod2.so" \
  "https://github.com/ibuddieat/zk_libcod/releases/download/v15.0/libcod2.so"
chmod +x "$TARGET_DIR/libcod2.so"

echo "=== Weryfikacja ==="
ls -la "$TARGET_DIR/"
file "$TARGET_DIR/cod2_lnxded"
file "$TARGET_DIR/libcod2.so"

echo "=== Gotowe ==="