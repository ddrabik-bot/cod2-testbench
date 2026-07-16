# cod2-testbench

Test bench for CoD2 (Call of Duty 2) development.

## Struktura projektu

```
cod2-testbench/
├── mods/
│   ├── _test.gsc                       — Framework testowy (testRunner + assertEQ)
│   ├── test.cfg                        — Konfiguracja uruchomieniowa testów
│   ├── bot_test_setOriginAndAngles.gsc — Testy teleportacji bota (F3.2)
│   ├── bot_test_forceShot.gsc          — Testy wymuszenia strzału (F3.2)
│   ├── bot_test_setWalkValues.gsc      — Testy ruchu bota (F3.2)
│   └── bot_test_meleeWeapon.gsc        — Testy ataku wręcz (F3.2)
├── results/
│   └── .gitkeep                        — Katalog wyników testów
├── scripts/
│   └── notify-discord.sh               — Wysyłka raportów testów na Discorda
├── tests/
│   ├── run_tests.sh                    — Shell runner testów
│   └── failure_mode_tests.sh           — Testy F3.3
├── docs/
│   └── bot-functions.md                — Dokumentacja API funkcji botów zk_libcod
├── Makefile                            — Komendy pomocnicze
└── README.md
```

## Uruchamianie testów

Na dedykowanym serwerze CoD2 z załadowanym zk_libcod:

```
exec test.cfg
```

Serwer załaduje `_test.gsc` i wszystkie pliki testów botów, wykona `testRunner()`,
a wyniki zostaną wypisane do konsoli i zapisane do `results/test_results.log`.

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
Funkcje pomocnicze zwracające pierwszego bota / gracza na serwerze.

## Testy

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

## Wymagania

- Serwer CoD2 z zainstalowanym [zk_libcod](https://github.com/ibuddieat/zk_libcod)
- Dla testów botów: `COMPILE_BOTS=1` i `COMPILE_PLAYER=1` w zk_libcod
- Do testów odporności: dostęp do shella (sh)

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

### Użycie skryptu lokalnie

```bash
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..." \
  ./scripts/notify-discord.sh success "Testy lokalne" "Wszystkie testy przeszły"
```