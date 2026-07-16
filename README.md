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

- **8091** — target-server (HTTP test server, port already in use → change in docker-compose.yml)

## Tests

### 1. execute_async_create — basic curl GET

GSC call:
```c
execute_async_create(
    "curl -s http://target-server:8080/api/hello",
    ::async_callback_basic, 1
);
```

Shell equivalent:
```bash
curl -s http://localhost:8091/api/hello
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

No callback — just fires the curl and continues.

### 4. Callback verification

execute_async_create passes `callback(output, param)`:

```c
execute_async_create("echo 'callback_test_ok'", ::my_callback, 42);

my_callback(output, param) {
    // output == "callback_test_ok"
    // param == 42
}
```

### 5. Timeout test

Curl with `--max-time` limits execution time. When the endpoint is slower than the limit, curl exits with code 28:

```c
execute_async_create(
    "curl -s --max-time 2 http://target-server:8080/api/delay/5",
    ::async_callback_timeout, 5
);
```

### 6. Error handling

Curl to a nonexistent host or endpoint returns empty output or error message:

```c
execute_async_create(
    "curl -s --connect-timeout 3 http://nonexistent-host-99999:9999/api/test",
    ::async_callback_error, 6
);
```

## GSC Test Suite

The file `tests/execute_async_test.gsc` contains 6 test scenarios:

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
│   ├── _test.gsc            # Framework testowy z testRunner() + HTML report
│   └── test.cfg             # Konfiguracja do uruchomienia testow na serwerze CoD2
├── results/
│   ├── test_results.log     # Wyniki testow (plain text)
│   └── test_results.html    # Raport HTML z kolorowymi badge'ami PASS/FAIL/SKIP
├── scripts/
│   └── notify-discord.sh   # Powiadomienia Discord (F3.5)
└── README.md
```

## Raport HTML (F3.4)

Testy generuja kolorowy raport HTML zamiast tylko plain textu.

### GSC - `_test.gsc`

Po kazdym uruchomieniu `testRunner()` na serwerze CoD2, oprocz pliku
`results/test_results.log`, generowany jest rowniez `results/test_report.html`:

- Karty podsumowania: Razem, PASSED, FAILED, WYNIK (kolorowane)
- Tabela szczegolow: kazdy test jako wiersz z badge PASS (zielony) / FAIL (czerwony)
- Data: uptime serwera w ms
- Responsywne styled (dark theme, inline CSS)

### Shell - `tests/generate_html_report.sh`

Konwertuje dowolny plik `test_results.log` na `test_results.html`:

```bash
# Generowanie HTML z domyslnego pliku wynikowego
./tests/generate_html_report.sh

# Lub z konkretnego pliku log
./tests/generate_html_report.sh results/test_results.log
```

Raport HTML zawiera:
- **Kolorowe karty statystyk** - Razem, PASSED (zielony), FAILED (czerwony),
  SKIPPED (zloty), WYNIK
- **Tabele z badge'ami** - kazdy wpis [PASS]/[FAIL]/[SKIP] jako wiersz tabeli
- **Data i czas wykonania** - znacznik czasu UTC
- **Surowe logi** - oryginalny plik w `<pre>` na dole strony
- **Dark theme** - ciemna paleta #1a1a2e / #16213e / #0f3460 / #e94560

### CI - GitHub Actions

### `testRunner()`
Główna funkcja uruchamiająca wszystkie testy. Inicjalizuje liczniki,
wykonuje zestawy testów, wyświetla podsumowanie i zapisuje raport do pliku.

### `assertEQ(actual, expected, testName)`
Sprawdza czy `actual == expected`. W przypadku:
- **PASS** — zwiększa licznik `level.testPassed`, loguje `[PASS]`
- **FAIL** — zwiększa licznik `level.testFailed`, loguje `[FAIL]` z oczekiwaną
  i otrzymaną wartością

### Testy
1. **Basic math** — dodawanie, mnożenie, odejmowanie, dzielenie
2. **String concatenation** — łączenie stringów, pusty string
3. **level.players** — sprawdzenie istnienia tablicy graczy, liczby graczy

## Wynik

- Konsola: kolorowe logi z `^2` (PASS), `^1` (FAIL), `^3` (sekcje)
- Plik: `results/test_results.log` — podsumowanie + szczegóły

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

Powiadomienie zawiera: nazwę repozytorium, branch, commit (skrócony),
autora, link do runa, datę i podsumowanie z `results/test_results.log`.

### Użycie skryptu lokalnie

```bash
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..." \
  ./scripts/notify-discord.sh success "Testy lokalne" "Wszystkie testy przeszły"
```

### CI - GitHub Actions

W pipeline CI (`test.yml`) raport HTML jest automatycznie generowany i
dolaczany do artifactu `test-results`.
