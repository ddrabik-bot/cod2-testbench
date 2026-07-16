# cod2-testbench

Test bench for CoD2 mod development with zk_libcod.

## Struktura projektu

```
cod2-testbench/
├── docker-compose.yml       # Docker compose z target-server
├── Makefile                 # Komendy: up, down, test-*, test-shell
├── README.md                # Ten plik
├── target-server/
│   ├── Dockerfile           # Python 3.13-alpine
│   └── server.py            # HTTP test server
├── code/bin/
│   ├── cod2_lnxded          # CoD2 Linux Dedicated Server v1.3
│   └── libcod2.so           # zk_libcod v15.0
├── main/
│   └── iw_15.iwd            # Game data files (wymagane do map)
├── mods/
│   ├── _test.gsc            # Framework testowy (testRunner + assertEQ + getBot/getPlayer)
│   ├── test.cfg             # Konfiguracja uruchomieniowa testów
│   ├── bot_test_setOriginAndAngles.gsc — Testy teleportacji bota (F3.2)
│   ├── bot_test_forceShot.gsc          — Testy wymuszenia strzału (F3.2)
│   ├── bot_test_setWalkValues.gsc      — Testy ruchu bota (F3.2)
│   └── bot_test_meleeWeapon.gsc        — Testy ataku wręcz (F3.2)
├── results/
│   ├── test_results.log     # Wyniki testow (plain text)
│   └── test_results.html    # Raport HTML z kolorowymi badge'ami PASS/FAIL/SKIP
├── scripts/
│   ├── setup.sh             # Pobiera i konfiguruje binarki CoD2
│   └── notify-discord.sh    # Powiadomienia Discord (F3.5)
├── tests/
│   ├── run_tests.sh                    # Shell runner testów
│   ├── failure_mode_tests.sh           # Testy F3.3
│   ├── generate_html_report.sh         # Generator HTML (F3.4)
│   └── execute_async_test.gsc          # Testy execute_async (F2.x)
├── docs/
│   └── bot-functions.md                # Dokumentacja API funkcji botów zk_libcod (F3.2)
├── test.cfg                 # Konfiguracja serwera testowego
└── .github/workflows/
    └── test.yml            # GitHub Actions pipeline
```

## CI Workflow

Workflow GitHub Actions zawiera 3 joby:

1. **test** — uruchamia testy GSC (MySQL, test runner, HTML report, Discord webhook)
2. **build-zk-libcod** — buduje zk_libcod z source (F1.2)
3. **start-server** — uruchamia serwer CoD2 z LD_PRELOAD i weryfikuje czy nie crashuje (F1.3)

### start-server job:

1. Pobiera `cod2_lnxded` v1.3 z mirroru opferlamm-clan
2. Pobiera `libcod2.so` (zk_libcod v15.0) z GitHub Releases
3. Kopiuje `main/` z plikami .iwd (wymagane do map)
4. Uruchamia serwer: `LD_PRELOAD=./libcod2.so ./cod2_lnxded +exec ../../test.cfg`
5. Czeka 5s na rozruch
6. Weryfikuje: serwer nie crashuje

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

## Target Server

An HTTP test server that provides endpoints for testing `execute_async_create` / `execute_async_create_nosave` curl calls.

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/health` | Health check |
| GET | `/api/hello` | Returns `{"status":"ok","source":"target-server"}` |
| POST | `/api/echo` | Echoes JSON body + headers back |
| GET | `/api/delay/<N>` | Responds after N seconds (for timeout tests) |
| GET | `/api/status/<N>` | Returns HTTP status N (for error tests) |
| GET | `/api/headers` | Returns request headers as JSON |

### Quick Start

```bash
make build
make up
make ps

# Run curl tests
make test-curl
make test-timeout
make test-error
make test-all

# Run shell-level simulation of execute_async_create
make test-shell

# View logs
make logs

# Stop
make down
```

## Ports

- **8091** — target-server (HTTP test server)

## Tests

### F2.x — execute_async curl tests

1. **execute_async_create — basic curl GET**
   ```c
   execute_async_create(
       "curl -s http://target-server:8080/api/hello",
       ::async_callback_basic, 1
   );
   ```

2. **execute_async_create — curl POST z JSON**
   ```c
   execute_async_create(
       "curl -s -X POST -H 'Content-Type: application/json' \
           -d '{\"source\":\"cod2\",\"action\":\"test\"}' \
           http://target-server:8080/api/echo",
       ::async_callback_post, 2
   );
   ```

3. **execute_async_create_nosave — fire-and-forget**
   ```c
   execute_async_create_nosave(
       "curl -s -X POST -H 'Content-Type: application/json' \
           -d '{\"source\":\"cod2\",\"type\":\"nosave\"}' \
           http://target-server:8080/api/echo"
   );
   ```

4. **Callback verification**
   ```c
   execute_async_create("echo 'callback_test_ok'", ::my_callback, 42);
   ```

5. **Timeout test**
   ```c
   execute_async_create(
       "curl -s --max-time 2 http://target-server:8080/api/delay/5",
       ::async_callback_timeout, 5
   );
   ```

6. **Error handling**
   ```c
   execute_async_create(
       "curl -s --connect-timeout 3 http://nonexistent-host-99999:9999/api/test",
       ::async_callback_error, 6
   );
   ```

### F3.1 — Podstawowe testy GSC
1. **Basic math** — dodawanie, mnożenie, odejmowanie, dzielenie
2. **String concatenation** — łączenie stringów, pusty string
3. **level.players** — sprawdzenie istnienia tablicy graczy, liczby graczy

### F3.2 — Testy funkcji botów z zk_libcod
4. **setOriginAndAngles** — teleportacja bota do pozycji z kątem widzenia
5. **forceShot** — wymuszenie strzału z obecnej broni
6. **setWalkValues** — ustawienie ruchu bota (przód/tył/bok/skos)
7. **meleeWeapon** — atak wręcz bota

### F3.3 — Testy odporności (failure mode)
8. **Crash przy braku LD_PRELOAD** — symulacja braku biblioteki
9. **Puste argumenty** — obsługa pustych stringów i plików
10. **Timeout przy execute_async** — timeout dla długich/zapętlonych procesów
11. **Nieprawidłowe dane w MySQL** — obsługa braku klienta MySQL

## Framework testowy

### `testRunner()`
Główna funkcja uruchamiająca wszystkie testy. Inicjalizuje liczniki,
wykonuje zestawy testów, wyświetla podsumowanie i zapisuje raport do pliku.

### `assertEQ(actual, expected, testName)`
Sprawdza czy `actual == expected`. W przypadku:
- **PASS** — zwiększa licznik `level.testPassed`, loguje `[PASS]`
- **FAIL** — zwiększa licznik `level.testFailed`, loguje `[FAIL]` z oczekiwaną
  i otrzymaną wartością

### `getBot()` / `getPlayer()`
Funkcje pomocnicze zwracające pierwszego bota / gracza na serwerze (F3.2).

### `generateHtmlReport()`
Generuje kolorowy raport HTML z wynikami testów (F3.4).

## Wymagania

- Serwer CoD2 z zainstalowanym [zk_libcod](https://github.com/ibuddieat/zk_libcod)
- Dla testów botów: `COMPILE_BOTS=1` i `COMPILE_PLAYER=1` w zk_libcod
- Do testów odporności: dostęp do shella (sh)
- Dla execute_async: `ENABLE_UNSAFE=1` w config.hpp

## Wynik

- Konsola: kolorowe logi z `^2` (PASS), `^1` (FAIL), `^3` (sekcje)
- Plik: `results/test_results.log` — podsumowanie + szczegóły
- HTML: `results/test_results.html` — raport z badge'ami

## Discord Webhook

Po każdym uruchomieniu GitHub Actions test suite wysyła powiadomienie na
Discorda z podsumowaniem wyników.

### Konfiguracja

1. Utwórz webhook na serwerze Discord:
2. Dodaj secret do repozytorium: `DISCORD_WEBHOOK_URL`

### Format powiadomień

| Status    | Kolor  | Emoji |
|-----------|--------|-------|
| Success   | 🟢     | ✅    |
| Failure   | 🔴     | ❌    |
| Cancelled | 🟡     | ⚠️    |

## Źródła

- CoD2 Linux Server v1.3: opferlamm-clan.de
- zk_libcod v15.0: https://github.com/ibuddieat/zk_libcod