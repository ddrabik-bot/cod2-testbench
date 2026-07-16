# cod2-testbench

Test bench dla serwera Call of Duty 2 z zk_libcod (libcod2).

## Struktura

```
code/bin/          - Binarki serwera (cod2_lnxded + libcod2.so)
mods/              - Miejsce na mody
scripts/           - Skrypty pomocnicze
  setup.sh         - Pobiera i konfiguruje binarki
.github/workflows/ - CI
  test.yml         - Workflow: uruchamia serwer przez LD_PRELOAD i weryfikuje
test.cfg           - Konfiguracja serwera testowego
```

## CI Workflow

Workflow GitHub Actions:
1. Pobiera `cod2_lnxded` v1.3 z mirroru opferlamm-clan
2. Pobiera `libcod2.so` (zk_libcod v15.0) z GitHub Releases
3. Uruchamia serwer: `LD_PRELOAD=./code/bin/libcod2.so ./code/bin/cod2_lnxded +exec test.cfg`
4. Czeka 5s na rozruch
5. Weryfikuje: serwer nie crashuje

## Lokalne uruchomienie

```bash
# Pobierz binarki
bash scripts/setup.sh

# Uruchom serwer
cd code/bin
LD_PRELOAD=./libcod2.so ./cod2_lnxded +set sv_maxclients 16 +set sv_rcon_password test123 +set fs_game mods +exec ../../test.cfg
```

## Zależności

- `libc6:i386`, `libstdc++5:i386`, `zlib1g:i386`, `libmysqlclient21:i386` (32-bit libs dla CoD2)
- `curl` (do pobierania binarow)

## Źródła

- CoD2 Linux Server v1.3: opferlamm-clan.de
- zk_libcod v15.0: https://github.com/ibuddieat/zk_libcod