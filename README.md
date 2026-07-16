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

## Python Test Suite

The file `tests/test_target_server.py` contains 7 automated tests that verify the target-server
endpoints from within the container (simulating what execute_async_create does with curl):

```bash
# Run inside target-server container
docker exec cod2-testbench-target python3 /app/test_target_server.py
```

### Test Results (all PASS)

```
============================================================
execute_async_create — target-server test suite
============================================================

[TEST 1] execute_async_create — basic curl GET
  PASS: GET /api/hello (HTTP 200)

[TEST 2] execute_async_create — curl POST z JSON body
  PASS: POST /api/echo (HTTP 200)

[TEST 3] execute_async_create_nosave — fire-and-forget
  PASS: POST /api/echo (nosave) (HTTP 200)

[TEST 4] Callback verification — output + param
  PASS: GET /api/hello with param check (HTTP 200)

[TEST 5] Timeout — curl --max-time 2s na endpoint z 5s opoznieniem
  PASS: GET /api/delay/5 with timeout=2s — timeout as expected

[TEST 6] Error handling — curl do nieistniejacego endpointu
  PASS: GET /api/nonexistent (404) (HTTP 404 as expected)

[TEST 7] Error handling — curl do endpointu zwracajacego 500
  PASS: GET /api/status/500 (HTTP 500 as expected)

============================================================
RESULTS: 7 passed, 0 failed, 7 total
============================================================
```

## Project Structure

```
cod2-testbench/
├── docker-compose.yml       # Docker compose z target-server
├── Makefile                 # Komendy: up, down, test-*, test-shell
├── README.md                # Ten plik
├── target-server/
│   ├── Dockerfile           # Python 3.13-alpine
│   └── server.py            # HTTP test server
├── tests/
│   ├── execute_async_test.gsc   # GSC test suite dla execute_async_create (F2.3)
│   └── test_target_server.py    # Python test suite (F2.3)
├── mods/
│   ├── _test.gsc            # Framework testowy
│   └── test.cfg             # Konfiguracja testow
├── results/
│   ├── test_results.log     # Wyniki testow (plain text)
│   └── test_results.html    # Raport HTML
├── scripts/
│   └── notify-discord.sh   # Powiadomienia Discord
└── .github/workflows/
    └── test.yml             # CI pipeline
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

### CI - GitHub Actions

W pipeline CI (`test.yml`) raport HTML jest automatycznie generowany i
dolaczany do artifactu `test-results`.

## Discord Webhook (F3.5)

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

### Użycie skryptu lokalnie

```bash
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..." \
  ./scripts/notify-discord.sh success "Testy lokalne" "Wszystkie testy przeszły"
```