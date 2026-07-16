# Dokumentacja API funkcji botów z zk_libcod

## 1. setOriginAndAngles(origin, angles)

**Źródło:** `gsc_player.cpp` (linia 3186)

**Sygnatura GSC:** 
```c
player setOriginAndAngles((vector)origin, (vector)angles)
```

**Parametry:**
- `origin` (vector) — pozycja docelowa (x, y, z)
- `angles` (vector) — kąty widzenia (pitch, yaw, roll)

**Opis:**
Teleportuje gracza/bota do podanej pozycji i ustawia kąt patrzenia. Funkcja zawiera zaawansowaną logikę:
1. Zatrzymuje używanie MG (turret), jeśli gracz na nich siedzi
2. Odlinkowuje encję z BSP (SV_UnlinkEntity)
3. Czyści flagi (zachowuje ducked/prone)
4. Ustawia bit teleportu (EF_TELEPORT_BIT) — klient nie lerpuje
5. Zeruje prędkość i jumpTime
6. Kopiuje origin do ps.origin i G_SetOrigin
7. Ustawia kąt widzenia przez SetClientViewAngle
8. Wykonuje pmove (zerowy ruch) dla synchronizacji errordecay
9. Relinkuje encję do świata
10. Wywołuje ClientEndFrame (fix dla spectatorów)

**Zwraca:** brak (void) w przypadku sukcesu, undefined przy błędzie

**Warunki błędu:**
- `id >= MAX_CLIENTS` → error, push undefined
- Brak parametrów lub zły typ → error, push undefined

**Testy:**
- TC1: Teleportacja bota do znanej pozycji
- TC2: Teleportacja z obrotem o 180 stopni
- TC3: Zerowa prędkość po teleportacji
- TC4: Teleportacja w powietrzu (wysokie Z)
- TC5: Kąt patrzenia w górę (pitch=-90)
- TC6: Teleportacja gracza (nie bota)
- TC7: Brak parametrów (nie crashuje)

---

## 2. forceShot([onClientToo])

**Źródło:** `gsc_player.cpp` (linia 759)

**Sygnatura GSC:**
```c
player forceShot([int onClientToo])
```

**Parametry:**
- `onClientToo` (int, opcjonalny) — domyślnie 1:
  - 0 = strzał tylko na serwerze
  - 1 = strzał + event EV_FIRE_WEAPON na kliencie

**Opis:**
Wymusza oddanie strzału z obecnej broni. Wywołuje `FireWeaponAntiLag` z odpowiednim timestampem (w zależności od dvara `g_antilag`). Jeśli `onClientToo=1`, dodaje także event `EV_FIRE_WEAPON` dla klienta.

**Zwraca:**
- `undefined` — jeśli entity nie jest graczem lub złe parametry
- `false` — jeśli gracz nie żyje (`!G_IsPlaying`) lub nie ma broni (`weapon < 1`)
- brak jawnej wartości zwrotnej w przypadku sukcesu

**Warunki błędu:**
- `id >= MAX_CLIENTS` → error, push undefined
- Parametr nie-integer → error, push undefined
- Gracz nie żyje → push false
- Brak broni → push false

**Testy:**
- TC1: forceShot na bocie (domyślnie onClientToo=1)
- TC2: forceShot z onClientToo=0
- TC3: forceShot z onClientToo=1
- TC4: Wielokrotny forceShot (3x)
- TC5: forceShot na graczu
- TC6: forceShot po teleportacji
- TC7: 10x forceShot w pętli (stres test)
- TC8: Zły typ parametru (nie crashuje)

---

## 3. setWalkValues(forwardMove, rightMove)

**Źródło:** `gsc_bots.cpp` (linia ~15)

**Sygnatura GSC:**
```c
bot setWalkValues(int forwardMove, int rightMove)
```

**Parametry:**
- `forwardMove` (int) — wartość ruchu do przodu/tyłu
  - > 0 = do przodu
  - < 0 = do tyłu
  - Max prędkość: 127 lub 128
- `rightMove` (int) — wartość ruchu w bok
  - > 0 = w prawo
  - < 0 = w lewo

**Opis:**
Ustawia wartości `botForwardMove` i `botRightMove` w `customPlayerState[id]`. Te wartości są używane podczas procesowania ruchu bota przez serwer.

**Zwraca:** `true` (qtrue) w przypadku sukcesu, `undefined` przy błędzie

**Warunki błędu:**
- `id >= MAX_CLIENTS` → error, push undefined
- `client->netchan.remoteAddress.type != NA_BOT` → error, push undefined
- Brak parametrów lub zły typ → error, push undefined

**Testy:**
- TC1: Ruch do przodu (fw=127, rg=0)
- TC2: Ruch do tyłu (fw=-127, rg=0)
- TC3: Ruch w prawo (fw=0, rg=127)
- TC4: Ruch w lewo (fw=0, rg=-127)
- TC5: Ruch po skosie (fw=127, rg=127)
- TC6: Zatrzymanie (fw=0, rg=0)
- TC7: Mała prędkość (fw=30, rg=0)
- TC8: Próba na graczu (nie crashuje)

---

## 4. meleeWeapon(melee)

**Źródło:** `gsc_bots.cpp` (linia ~115)

**Sygnatura GSC:**
```c
bot meleeWeapon(int melee)
```

**Parametry:**
- `melee` (int) — flaga ataku wręcz:
  - 1 = włącz atak wręcz (ustawia bit KEY_MASK_MELEE)
  - 0 = wyłącz atak wręcz (usuwa bit KEY_MASK_MELEE)

**Opis:**
Ustawia lub usuwa bit `KEY_MASK_MELEE` w `customPlayerState[id].botButtons`. Gdy bit jest ustawiony, serwer CoD2 wykonuje atak wręcz w następnej klatce fizyki.

**Zwraca:** `true` (qtrue) w przypadku sukcesu, `undefined` przy błędzie

**Warunki błędu:**
- `id >= MAX_CLIENTS` → error, push undefined
- `client->netchan.remoteAddress.type != NA_BOT` → error, push undefined
- Brak parametrów lub zły typ → error, push undefined

**Testy:**
- TC1: Podstawowy atak wręcz (melee=1)
- TC2: Zakończenie ataku (melee=0)
- TC3: Sekwencja włącz/wyłącz (3x)
- TC4: Atak podczas ruchu
- TC5: Atak po teleportacji
- TC6: 5x szybki atak
- TC7: Próba na graczu (nie crashuje)
- TC8: Atak combo (melee + forceShot)

---

## Funkcje pomocnicze (z test_runner.gsc)

| Funkcja | Opis |
|---------|------|
| `get_bot()` | Zwraca pierwszego bota na serwerze lub `undefined` |
| `get_player()` | Zwraca pierwszego nie-bota na serwerze lub `undefined` |
| `assert_eq(expected, actual, name)` | Sprawdza równość wartości |
| `assert_true(condition, name)` | Sprawdza warunek |
| `assert_false(condition, name)` | Sprawdza negację warunku |
| `skip_test(name)` | Oznacza test jako pominięty |

## Uwagi

1. Funkcje botów (`setWalkValues`, `meleeWeapon`, `fireWeapon`, itd.) wymagają `COMPILE_BOTS=1` w zk_libcod
2. `setOriginAndAngles` i `forceShot` są funkcjami gracza (player), nie wymagają `COMPILE_BOTS`
3. Wszystkie funkcje walidują: `id >= MAX_CLIENTS` → error
4. Funkcje botów dodatkowo walidują: `NA_BOT`
5. W przypadku błędu parametrów, funkcje zwracają `undefined` i logują error — **nie crashują serwera**