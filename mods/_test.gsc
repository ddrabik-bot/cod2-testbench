// ============================================================================
// _test.gsc — Test framework dla CoD2
// ============================================================================
// Zapewnia:
//   - testRunner()   — uruchamia wszystkie testy i generuje raport
//   - assertEQ()     — sprawdza czy actual == expected
//   - getBot()       — zwraca pierwszego bota na serwerze
//   - getPlayer()    — zwraca pierwszego nie-bota na serwerze
//
// Testy botów (F3.2):
//   - botTestSetOriginAndAngles()  — teleportacja bota
//   - botTestForceShot()           — wymuszenie strzału
//   - botTestSetWalkValues()       — ruch bota
//   - botTestMeleeWeapon()         — atak wręcz
//
// Uruchomienie: exec test.cfg w konsoli serwera
// Raport:        logPrintConsole + results/test_results.log
// ============================================================================

// ---------------------------------------------------------------------------
// testRunner() — główna funkcja uruchamiająca testy
// ---------------------------------------------------------------------------
testRunner()
{
    level.testPassed = 0;
    level.testFailed = 0;
    level.testResults = "";

    logPrintConsole("^2========================================^7\n");
    logPrintConsole("^2  Test Runner v1.0 — uruchomiono       ^7\n");
    logPrintConsole("^2========================================^7\n");

    // ---- Test 1: Basic math ----
    logPrintConsole("^3--- Test 1: Basic math ---^7\n");
    assertEQ(1 + 1, 2, "1 + 1 == 2");
    assertEQ(5 * 3, 15, "5 * 3 == 15");
    assertEQ(10 - 4, 6, "10 - 4 == 6");
    assertEQ(20 / 5, 4, "20 / 5 == 4");
    assertEQ(100 - 50 + 10, 60, "100 - 50 + 10 == 60");

    // ---- Test 2: String concatenation ----
    logPrintConsole("^3--- Test 2: String concatenation ---^7\n");
    level.strA = "Hello";
    level.strB = "World";
    level.strResult = level.strA + " " + level.strB;
    assertEQ(level.strResult, "Hello World", "Konkatencja: 'Hello' + ' ' + 'World'");

    level.strMulti = "Test" + "_" + "frame" + "_" + "v1";
    assertEQ(level.strMulti, "Test_frame_v1", "Konkatencja wielokrotna: Test_frame_v1");

    level.strEmpty = "" + "nonempty";
    assertEQ(level.strEmpty, "nonempty", "Konkatencja z pustym stringiem");

    // ---- Test 3: level.players ----
    logPrintConsole("^3--- Test 3: level.players ---^7\n");
    assertEQ(isDefined(level.players), 1, "level.players jest zdefiniowane");

    level.playerCount = level.players.size;
    assertEQ(level.playerCount >= 0, 1, "level.players.size >= 0");

    logPrintConsole("^4Aktualna liczba graczy: " + level.playerCount + "^7\n");

    // ---- F3.3: Failure Mode Tests ----
    logPrintConsole("^3--- F3.3: Failure Mode Tests ---^7\n");

    // Test: undefined variable access (LD_PRELOAD crash analog)
    logPrintConsole("^3--- Test 4: Undefined variable (crash test) ---^7\n");
    level.undefVar = undefined;
    assertEQ(isDefined(level.undefVar), 0, "Undefined variable isDefined == 0");

    // Test: division by zero
    logPrintConsole("^3--- Test 5: Division by zero ---^7\n");
    level.divResult = 10 / 0;
    assertEQ(isDefined(level.divResult), 1, "Division by zero nie crashuje (GSC safe)");

    // Test: empty string operations
    logPrintConsole("^3--- Test 6: Empty string operations ---^7\n");
    level.emptyStr = "";
    level.emptyConcat = level.emptyStr + level.emptyStr;
    assertEQ(level.emptyConcat, "", "Pusty string + pusty string == pusty string");
    assertEQ(level.emptyStr, "", "Pusty string == \"\"");
    assertEQ(strlen(level.emptyStr), 0, "strlen(pusty string) == 0");

    // Test: out of bounds array access
    logPrintConsole("^3--- Test 7: Array boundary test ---^7\n");
    level.testArray = [];
    level.testArray[0] = "first";
    level.testArray[1] = "second";
    level.outOfBounds = level.testArray[999];
    assertEQ(isDefined(level.outOfBounds), 0, "Array[999] (out of bounds) == undefined");

    // Test: invalid data handling
    logPrintConsole("^3--- Test 8: Invalid data handling ---^7\n");
    level.invalidNum = "abc" + 123;
    assertEQ(isDefined(level.invalidNum), 1, "String + number nie crashuje");
    level.mixedType = 1 + "test";
    assertEQ(isDefined(level.mixedType), 1, "Number + string nie crashuje");

    // Test: cykliczna zależność zmiennych
    logPrintConsole("^3--- Test 9: Self-reference ---^7\n");
    level.selfRef = level.selfRef;
    assertEQ(isDefined(level.selfRef), 0, "Self-referencja undefined (jeszcze nie zdefiniowana)");

    // ---- F3.2: Bot Function Tests ----
    logPrintConsole("^3--- F3.2: Bot Function Tests ---^7\n");

    // Wczytaj pliki testów botów
    // (muszą być załadowane przez exec przed wywołaniem testRunner)
    if (isDefined(botTestSetOriginAndAngles))
    {
        botTestSetOriginAndAngles();
    }
    else
    {
        logPrintConsole("^5  [SKIP] botTestSetOriginAndAngles — plik niezaladowany^7\n");
    }

    if (isDefined(botTestForceShot))
    {
        botTestForceShot();
    }
    else
    {
        logPrintConsole("^5  [SKIP] botTestForceShot — plik niezaladowany^7\n");
    }

    if (isDefined(botTestSetWalkValues))
    {
        botTestSetWalkValues();
    }
    else
    {
        logPrintConsole("^5  [SKIP] botTestSetWalkValues — plik niezaladowany^7\n");
    }

    if (isDefined(botTestMeleeWeapon))
    {
        botTestMeleeWeapon();
    }
    else
    {
        logPrintConsole("^5  [SKIP] botTestMeleeWeapon — plik niezaladowany^7\n");
    }

    // ---- Koniec F3.2 ----

    // Sprawdzenie czy kazdy element tablicy to entity
    if (level.playerCount > 0)
    {
        level.i = 0;
        while (level.i < level.playerCount)
        {
            level.player = level.players[level.i];
            assertEQ(isDefined(level.player), 1, "Gracz " + level.i + " jest zdefiniowany");
            level.i++;
        }
    }
    else
    {
        logPrintConsole("^3Brak graczy na serwerze — pomijam test entity per player^7\n");
    }

    // ---- Podsumowanie ----
    level.totalTests = level.testPassed + level.testFailed;
    logPrintConsole("^2========================================^7\n");
    logPrintConsole("^2  Podsumowanie testow                  ^7\n");
    logPrintConsole("^2========================================^7\n");
    logPrintConsole("^2  Total:  " + level.totalTests + "^7\n");
    logPrintConsole("^2  Passed: " + level.testPassed + "^7\n");

    if (level.testFailed > 0)
    {
        logPrintConsole("^1  Failed: " + level.testFailed + "^7\n");
    }
    else
    {
        logPrintConsole("^2  Failed: 0^7\n");
    }

    logPrintConsole("^2========================================^7\n");

    // ---- Zapis do pliku ----
    level.resultText = "=== Test Results ===\n";
    level.resultText = level.resultText + "Total:  " + level.totalTests + "\n";
    level.resultText = level.resultText + "Passed: " + level.testPassed + "\n";
    level.resultText = level.resultText + "Failed: " + level.testFailed + "\n";
    level.resultText = level.resultText + "\n--- Details ---\n";
    level.resultText = level.resultText + level.testResults;

    if (level.testFailed > 0)
    {
        logPrintConsole("^1========================================^7\n");
        logPrintConsole("^1  RESULT: FAIL                          ^7\n");
        logPrintConsole("^1========================================^7\n");
        level.resultText = level.resultText + "\nRESULT: FAIL";
    }
    else
    {
        logPrintConsole("^2========================================^7\n");
        logPrintConsole("^2  RESULT: PASS                          ^7\n");
        logPrintConsole("^2========================================^7\n");
        level.resultText = level.resultText + "\nRESULT: PASS";
    }

    writeFile("results/test_results.log", level.resultText);
    logPrintConsole("^4Raport zapisany do results/test_results.log^7\n");
}

// ---------------------------------------------------------------------------
// getBot() — zwraca pierwszego bota na serwerze lub undefined
// ---------------------------------------------------------------------------
getBot()
{
    for (i = 0; i < level.players.size; i++)
    {
        if (level.players[i] isBot())
        {
            return level.players[i];
        }
    }
    return undefined;
}

// ---------------------------------------------------------------------------
// getPlayer() — zwraca pierwszego nie-bota na serwerze lub undefined
// ---------------------------------------------------------------------------
getPlayer()
{
    for (i = 0; i < level.players.size; i++)
    {
        if (!level.players[i] isBot())
        {
            return level.players[i];
        }
    }
    return undefined;
}

// ---------------------------------------------------------------------------
// assertEQ(actual, expected, testName) — sprawdza czy actual == expected
// ---------------------------------------------------------------------------
assertEQ(actual, expected, testName)
{
    if (actual == expected)
    {
        level.testPassed++;
        level.testResults = level.testResults + "[PASS] " + testName + "\n";
        logPrintConsole("^2  [PASS] " + testName + "^7\n");
    }
    else
    {
        level.testFailed++;
        level.testResults = level.testResults + "[FAIL] " + testName + " (expected: " + expected + ", got: " + actual + ")\n";
        logPrintConsole("^1  [FAIL] " + testName + " ^7(expected: ^3" + expected + "^7, got: ^3" + actual + "^7)^7\n");
    }
}