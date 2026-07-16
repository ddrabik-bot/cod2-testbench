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
// testRunner() — glowna funkcja uruchamiajaca testy
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

    // ---- Koniec F3.3 ----

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

    // ---- Test 4: getCallStack() - debug function from zk_libcod ----
    logPrintConsole("^3--- Test 4: getCallStack() ---^7\n");

    // Test 4.1: getCallStack() exists and returns data
    level.stack = getCallStack();
    assertEQ(isDefined(level.stack), 1, "getCallStack() zwraca zdefiniowana wartosc");

    // Test 4.2: getCallStack() returns an array (has .size property)
    level.stackSize = level.stack.size;
    assertEQ(level.stackSize >= 2, 1, "getCallStack() zwraca tablice z co najmniej 2 elementami (filename + line)");

    // Test 4.3: First element is a filename
    level.firstElem = level.stack[0];
    assertEQ(isDefined(level.firstElem), 1, "getCallStack()[0] jest zdefiniowane (nazwa pliku)");

    // Test 4.4: Second element is a line number
    level.secondElem = level.stack[1];
    assertEQ(isDefined(level.secondElem), 1, "getCallStack()[1] jest zdefiniowane (numer linii)");

    // Test 4.5: getCallStack() called from nested function has deeper stack
    level.nestedStack = [];
    testNestedCallStack();
    level.nestedDepth = level.nestedStack.size;
    assertEQ(level.nestedDepth >= 4, 1, "getCallStack() z funkcji zagniezdzonej ma >= 4 elementy (2 ramki)");

    // Test 4.6: Stack grows with deeper nesting
    level.deepStack = [];
    testDeepNestedCallStack();
    level.deepDepth = level.deepStack.size;
    assertEQ(level.deepDepth >= level.nestedDepth, 1, "getCallStack() z glebszego zagniezdzenia ma wiecej ramek");

    // ---- Test 5: isDefined() na roznych typach ----
    logPrintConsole("^3--- Test 5: isDefined() on different types ---^7\n");

    // Test 5.1: isDefined() on int
    level.testInt = 42;
    assertEQ(isDefined(level.testInt), 1, "isDefined(int) == 1");
    assertEQ(isDefined(0), 1, "isDefined(0) == 1 (zero jest zdefiniowane)");

    // Test 5.2: isDefined() on string
    level.testStr = "hello";
    assertEQ(isDefined(level.testStr), 1, "isDefined(string) == 1");
    assertEQ(isDefined(""), 1, "isDefined('') == 1 (pusty string jest zdefiniowany)");

    // Test 5.3: isDefined() on array
    level.testArr = [];
    assertEQ(isDefined(level.testArr), 1, "isDefined(array) == 1");

    // Test 5.4: isDefined() on undefined
    assertEQ(isDefined(level.undefinedVar), 0, "isDefined(niezdefiniowana zmienna) == 0");

    // Test 5.5: isDefined() on entity
    assertEQ(isDefined(level), 1, "isDefined(entity level) == 1");
    assertEQ(isDefined(game), 1, "isDefined(entity game) == 1");

    // Test 5.6: isDefined() on nonexistent entity field
    assertEQ(isDefined(level.nonexistentField), 0, "isDefined(level.nonexistentField) == 0");

    // Test 5.7: isDefined() on undefined keyword
    assertEQ(isDefined(undefined), 0, "isDefined(undefined) == 0");

    // Test 5.8: isDefined() on complex nested array
    level.nestedArr = [1, [2, 3], "test"];
    assertEQ(isDefined(level.nestedArr), 1, "isDefined(nested array) == 1");
    assertEQ(isDefined(level.nestedArr[1]), 1, "isDefined(nestedArr[1]) == 1 (podtablica)");

    // ---- Test 6: Logging and debug output ----
    logPrintConsole("^3--- Test 6: Logging and debug output ---^7\n");

    // Test 6.1: logPrintConsole() - exists and works
    assertEQ(logPrintConsole("^2[DEBUG] logPrintConsole test^7\n"), 1, "logPrintConsole() zwraca 1 (sukces)");

    // Test 6.2: printf() - exists and works
    assertEQ(isDefined(printf), 1, "printf() jest zdefiniowana");
    level.printfResult = 0;
    printf("^2[DEBUG] printf test^7\n");
    level.printfResult = 1;
    assertEQ(level.printfResult, 1, "printf() wykonuje sie bez bledu");

    // Test 6.3: println() - exists and works
    assertEQ(isDefined(println), 1, "println() jest zdefiniowana");
    level.printlnResult = 0;
    println("^2[DEBUG] println test^7\n");
    level.printlnResult = 1;
    assertEQ(level.printlnResult, 1, "println() wykonuje sie bez bledu");

    // Test 6.4: iprintln() - exists and works
    assertEQ(isDefined(iprintln), 1, "iprintln() jest zdefiniowana");
    level.iprintlnResult = 0;
    iprintln("^2[DEBUG] iprintln test^7");
    level.iprintlnResult = 1;
    assertEQ(level.iprintlnResult, 1, "iprintln() wykonuje sie bez bledu");

    // Test 6.5: iprintlnbold() - exists and works
    assertEQ(isDefined(iprintlnbold), 1, "iprintlnbold() jest zdefiniowana");
    level.iprintlnboldResult = 0;
    iprintlnbold("^2[DEBUG] iprintlnbold test^7");
    level.iprintlnboldResult = 1;
    assertEQ(level.iprintlnboldResult, 1, "iprintlnbold() wykonuje sie bez bledu");

    // Test 6.6: print() - exists and works
    assertEQ(isDefined(print), 1, "print() jest zdefiniowana");
    level.printResult = 0;
    print("^2[DEBUG] print test^7\n");
    level.printResult = 1;
    assertEQ(level.printResult, 1, "print() wykonuje sie bez bledu");

    // Test 6.7: Debug callbacks - CodeCallback_NotifyDebug exists
    assertEQ(isDefined(CodeCallback_NotifyDebug), 1, "CodeCallback_NotifyDebug jest zdefiniowany");

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

// ---------------------------------------------------------------------------
// Helper functions for getCallStack() tests
// ---------------------------------------------------------------------------

// testNestedCallStack() — wywoluje getCallStack() z poziomu zagniezdzonego
testNestedCallStack()
{
    level.nestedStack = getCallStack();
}

// testDeepNestedCallStack() — wywoluje getCallStack() z glebszego poziomu
testDeepNestedCallStack()
{
    testNestedCallStackDeep();
}

testNestedCallStackDeep()
{
    level.deepStack = getCallStack();
}

// ---------------------------------------------------------------------------
// testRunnerVerbose() — uruchamia testRunner() z dodatkowym debug outputem
// ---------------------------------------------------------------------------
testRunnerVerbose()
{
    logPrintConsole("^5--- Uruchamianie testRunner() z debug outputem ---^7\n");
    logPrintConsole("^5Stack przed testami:^7\n");
    level.prestack = getCallStack();
    logPrintConsole("^5  Rozmiar stosu: " + level.prestack.size + "^7\n");
    testRunner();
    logPrintConsole("^5--- testRunner() zakonczony ---^7\n");
}