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
