// ============================================================================
// _test.gsc — Test framework dla CoD2
// ============================================================================
// Zapewnia:
//   - testRunner()   — uruchamia wszystkie testy i generuje raport
//   - assertEQ()     — sprawdza czy actual == expected
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