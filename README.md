# cod2-testbench

Test bench for CoD2 mod development with zk_libcod.

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

### 1. execute_async_create — basic curl GET

GSC call:
```c
execute_async_create(
    "curl -s http://target-server:8080/api/hello",
    ::async_callback_basic, 1
);
```

### 2. execute_async_create — curl POST z JSON

GSC call:
```c
execute_async_create(
    "curl -s -X POST -H 'Content-Type: application/json' \
        -d '{\"source\":\"cod2\",\"action\":\"test\"}' \
        http://target-server:8080/api/echo",
    ::async_callback_post, 2
);
```

### 3. execute_async_create_nosave — fire-and-forget

```c
execute_async_create_nosave(
    "curl -s -X POST -H 'Content-Type: application/json' \
        -d '{\"source\":\"cod2\",\"type\":\"nosave\"}' \
        http://target-server:8080/api/echo"
);
```

### 4. Callback verification

```c
execute_async_create("echo 'callback_test_ok'", ::my_callback, 42);

my_callback(output, param) {
    // output == "callback_test_ok"
    // param == 42
}
```

### 5. Timeout test

```c
execute_async_create(
    "curl -s --max-time 2 http://target-server:8080/api/delay/5",
    ::async_callback_timeout, 5
);
```

### 6. Error handling

```c
execute_async_create(
    "curl -s --connect-timeout 3 http://nonexistent-host-99999:9999/api/test",
    ::async_callback_error, 6
);
```

## GSC Test Suite

The file `tests/execute_async_test.gsc` contains 6 test scenarios (F2.x):

1. `test_basic_get()` — basic curl GET
2. `test_post_json()` — curl POST z JSON
3. `test_fire_and_forget()` — nosave call
4. `test_callback_verification()` — callback param weryfikacja
5. `test_timeout()` — timeout test z --max-time
6. `test_error_handling()` — error handling dla nieistniejacego hosta

Aby uruchomic testy w CoD2 server:

1. Skopiuj `tests/execute_async_test.gsc` do katalogu `raw/` serwera
2. Dodaj call do `run_all_async_tests()` w `CodeCallback_StartGameType()`
3. Upewnij sie, ze `execute_async_checkdone()` jest wywolywane co klatke
4. Uruchom target-server: `make up`
5. Restart serwera CoD2
6. Sprawdz logi: `make logs`

### Wymagania

- zk_libcod z `ENABLE_UNSAFE=1` (config.hpp)
- Siec Docker: target-server w tej samej sieci co serwer CoD2 (lub przez `--network host`)
- `execute_async_checkdone()` w petli gry

## Project Structure

```
cod2-testbench/
├── docker-compose.yml       # Docker compose z target-server
├── Makefile                 # Komendy: up, down, test-*, test-shell
├── README.md                # Ten plik
├── target-server/
│   ├── Dockerfile           # Python 3.13-alpine
│   └── server.py            # HTTP test server
├── mods/
│   ├── _test.gsc            # Framework testowy (testRunner + assertEQ)
│   ├── test.cfg             # Konfiguracja do uruchomienia testow na serwerze CoD2
│   ├── bot_test_setOriginAndAngles.gsc — Testy teleportacji bota (F3.2)
│   ├── bot_test_forceShot.gsc          — Testy wymuszenia strzału (F3.2)
│   ├── bot_test_setWalkValues.gsc      — Testy ruchu bota (F3.2)
│   └── bot_test_meleeWeapon.gsc        — Testy ataku wręcz (F3.2)
├── results/
│   ├── test_results.log     # Wyniki testow (plain text)
│   └── test_results.html    # Raport HTML z kolorowymi badge'ami PASS/FAIL/SKIP
├── scripts/
│   └── notify-discord.sh   # Powiadomienia Discord (F3.5)
├── tests/
│   ├── run_tests.sh                    # Shell runner testów
│   ├── failure_mode_tests.sh           # Testy F3.3
│   ├── generate_html_report.sh         # Generator HTML (F3.4)
│   └── execute_async_test.gsc          # Testy execute_async (F2.x)
├── docs/
│   └── bot-functions.md                # Dokumentacja API funkcji botów zk_libcod (F3.2)
└── .github/workflows/
    └── test.yml            # GitHub Actions pipeline
```

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

## Testy

### F2.x — execute_async tests
- `execute_async_create` — basic curl GET, POST z JSON, callback verification
- `execute_async_create_nosave` — fire-and-forget
- Timeout, error handling

### F3.1 — Podstawowe testy
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

### F3.4 — Raport HTML
- GSC generuje `results/test_results.html` z kolorowymi badge'ami PASS/FAIL/SKIP
- Shell script `tests/generate_html_report.sh` konwertuje dowolny log na HTML
- Dark theme, responsywne style, inline CSS

### F3.5 — Discord Webhook
- Powiadomienia na Discorda z podsumowaniem wyników testów
- Kolorowe karty: zielony (PASS), czerwony (FAIL), żółty (SKIP)

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
   - Ustawienia kanału → Integracje → Webhooki → Nowy webhook
   - Skopiuj URL webhooka

2. Dodaj secret do repozytorium:

   **Przez GitHub UI:**
   - Settings → Secrets and variables → Actions → New repository secret
   - Name: `DISCORD_WEBHOOK_URL`
   - Value: URL webhooka z Discorda

   **Przez API:**
   ```bash
   python3 scripts/set_discord_secret.py 'https://discord.com/api/webhooks/...'
   ```

### Format powiadomień

| Status    | Kolor  | Emoji |
|-----------|--------|-------|
| Success   | 🟢     | ✅    |
| Failure   | 🔴     | ❌    |
| Cancelled | 🟡     | ⚠️    |

### Użycie skryptu lokalnie

```bash
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..." \
  ./scripts/notify-discord.sh success "Testy lokalne" "Wszystkie testy przeszły"
```

### CI - GitHub Actions

W pipeline CI (`test.yml`) raport HTML jest automatycznie generowany i
dolaczany do artifactu `test-results`.