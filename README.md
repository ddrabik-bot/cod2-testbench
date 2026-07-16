# cod2-testbench

Test bench for CoD2 (Call of Duty 2) development.

## Struktura projektu

```
cod2-testbench/
├── mods/
│   ├── _test.gsc    — Framework testowy (testRunner + assertEQ)
│   └── test.cfg     — Konfiguracja uruchomieniowa testów
├── results/
│   └── .gitkeep     — Katalog wyników testów
├── scripts/
│   └── notify-discord.sh — Wysyłka raportów testów na Discorda
└── README.md
```

## Uruchamianie testów

Na dedykowanym serwerze CoD2 z załadowanym modem:

```
exec test.cfg
```

Serwer załaduje `_test.gsc`, wykona `testRunner()`, a wyniki zostaną
wypisane do konsoli i zapisane do `results/test_results.log`.

## Framework testowy

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
