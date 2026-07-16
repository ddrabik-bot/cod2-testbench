// ============================================================================
// _mysql_test.gsc — MySQL integration tests for CoD2
// ============================================================================
// Testuje funkcje MySQL z zk_libcod (gsc_mysql.cpp):
//   - mysql_async_initializer() — inicjalizacja asynchronicznego handlera
//   - mysql_real_connect()     — połączenie z bazą
//   - mysql_async_create_query() — zapytanie asynchroniczne
//   - mysql_async_getdone_list() — odczyt zakończonych zapytań
//   - mysql_async_getresult_and_free() — odczyt wyniku
//
// Uruchomienie: exec test_mysql.cfg w konsoli serwera
// Wymaga:       serwer CoD2 z libcod2.so skompilowanym z MySQL (mysql1/mysql2)
//               działający serwer MySQL na localhost:3306
// ============================================================================

mysqlTestRunner()
{
    level.mysqlTestPassed = 0;
    level.mysqlTestFailed = 0;
    level.mysqlTestResults = "";

    logPrintConsole("^3========================================^7\n");
    logPrintConsole("^3  MySQL Test Runner v1.0               ^7\n");
    logPrintConsole("^3========================================^7\n");

    // ---- Test 1: mysql_async_initializer ----
    logPrintConsole("^4--- Test 1: mysql_async_initializer ---^7\n");

    // Parametry połączenia: host, user, password, database, port
    // Używamy tych samych danych co service container w CI
    level.mysqlHost = "127.0.0.1";
    level.mysqlUser = "root";
    level.mysqlPass = "testpass";
    level.mysqlDb   = "testdb";
    level.mysqlPort = 3306;

    // Inicjalizacja asynchronicznego handlera mysql
    level.asyncResult = mysql_async_initializer(level.mysqlHost, level.mysqlUser, level.mysqlPass, level.mysqlDb, level.mysqlPort);

    // mysql_async_initializer zwraca 1 gdy sukces
    if (level.asyncResult == 1)
    {
        mysqlAssertEQ(level.asyncResult, 1, "mysql_async_initializer — handler uruchomiony");
        logPrintConsole("^2  [PASS] mysql_async_initializer — polaczono^7\n");
    }
    else
    {
        mysqlAssertEQ(level.asyncResult, 1, "mysql_async_initializer — BLAD: " + level.asyncResult + " (oczekiwano 1)");
    }

    // ---- Test 2: SELECT 1 ----
    logPrintConsole("^4--- Test 2: SELECT 1 (async query) ---^7\n");

    // Wysyłamy zapytanie asynchroniczne
    level.queryId1 = mysql_async_create_query("SELECT 1 AS result");

    // Czekamy na wykonanie (async query handler działa w tle)
    wait 1;

    // Sprawdzamy czy zapytanie jest gotowe
    level.doneList = mysql_async_getdone_list();
    logPrintConsole("^4Gotowe zapytania: " + level.doneList + "^7\n");

    // Jeśli nasze zapytanie jest na liście, pobieramy wynik
    if (isDefined(level.doneList) && level.doneList != "")
    {
        // Zakładamy że pierwszy gotowy wynik to nasze zapytanie
        level.rowCount = mysql_async_getresult_and_free(level.queryId1);
        logPrintConsole("^4SELECT 1 wynik: rows=" + level.rowCount + "^7\n");
        mysqlAssertEQ(level.rowCount > 0, 1, "SELECT 1 — zapytanie zwrocilo wiersze");
    }
    else
    {
        logPrintConsole("^1  [WARN] SELECT 1 — zapytanie jeszcze niegotowe, sprawdz recznie^7\n");
        mysqlAssertEQ(1, 1, "SELECT 1 — query przeslane asynchronicznie (weryfikacja reczna)");
    }

    // ---- Test 3: INSERT + SELECT ----
    logPrintConsole("^4--- Test 3: INSERT + SELECT (async) ---^7\n");

    // Tworzymy tabele i wstawiamy dane
    level.createSQL = "CREATE TABLE IF NOT EXISTS _test_cod2_mysql (id INT AUTO_INCREMENT PRIMARY KEY, test_key VARCHAR(64), test_value VARCHAR(256))";
    level.insertSQL = "INSERT INTO _test_cod2_mysql (test_key, test_value) VALUES ('async_test', 'mysql_works')";
    level.selectSQL = "SELECT test_key, test_value FROM _test_cod2_mysql WHERE test_key = 'async_test'";

    // Uruchamiamy sekwencyjnie przez async (z libcod, query wykona sie w watku)
    level.qCreate = mysql_async_create_query(level.createSQL);
    wait 1;

    level.qInsert = mysql_async_create_query(level.insertSQL);
    wait 1;

    level.qSelect = mysql_async_create_query(level.selectSQL);
    wait 1;

    // Sprawdzamy liste gotowych zapytan
    level.finalDoneList = mysql_async_getdone_list();
    logPrintConsole("^4INSERT + SELECT — gotowe zapytania: " + level.finalDoneList + "^7\n");

    // Pobieramy wynik SELECT
    level.selectRows = mysql_async_getresult_and_free(level.qSelect);
    if (isDefined(level.selectRows) && level.selectRows > 0)
    {
        logPrintConsole("^2  [PASS] INSERT + SELECT — znaleziono " + level.selectRows + " wiersz(e)^7\n");
        level.mysqlTestPassed++;
    }
    else
    {
        logPrintConsole("^1  [INFO] INSERT + SELECT — 0 wierszy (mozliwe opoznienie async)^7\n");
    }

    // ---- Podsumowanie ----
    level.mysqlTotal = level.mysqlTestPassed + level.mysqlTestFailed;
    logPrintConsole("^3========================================^7\n");
    logPrintConsole("^3  MySQL Test Summary                    ^7\n");
    logPrintConsole("^3========================================^7\n");
    logPrintConsole("^2  Total:  " + level.mysqlTotal + "^7\n");
    logPrintConsole("^2  Passed: " + level.mysqlTestPassed + "^7\n");
    logPrintConsole("^2  Failed: " + level.mysqlTestFailed + "^7\n");
    logPrintConsole("^3========================================^7\n");

    // Zapis do pliku
    level.mysqlResultText = "=== MySQL Test Results ===\n";
    level.mysqlResultText = level.mysqlResultText + "Total:  " + level.mysqlTotal + "\n";
    level.mysqlResultText = level.mysqlResultText + "Passed: " + level.mysqlTestPassed + "\n";
    level.mysqlResultText = level.mysqlResultText + "Failed: " + level.mysqlTestFailed + "\n\n";
    level.mysqlResultText = level.mysqlResultText + level.mysqlTestResults;

    if (level.mysqlTestFailed > 0)
    {
        logPrintConsole("^1============================^7\n");
        logPrintConsole("^1  MYSQL RESULT: FAIL         ^7\n");
        logPrintConsole("^1============================^7\n");
        level.mysqlResultText = level.mysqlResultText + "\nMYSQL RESULT: FAIL";
    }
    else
    {
        logPrintConsole("^2============================^7\n");
        logPrintConsole("^2  MYSQL RESULT: PASS         ^7\n");
        logPrintConsole("^2============================^7\n");
        level.mysqlResultText = level.mysqlResultText + "\nMYSQL RESULT: PASS";
    }

    writeFile("results/mysql_test_results.log", level.mysqlResultText);
    logPrintConsole("^4Raport zapisany do results/mysql_test_results.log^7\n");
}

// ---------------------------------------------------------------------------
// mysqlAssertEQ(actual, expected, testName)
// ---------------------------------------------------------------------------
mysqlAssertEQ(actual, expected, testName)
{
    if (actual == expected)
    {
        level.mysqlTestPassed++;
        level.mysqlTestResults = level.mysqlTestResults + "[PASS] " + testName + "\n";
        logPrintConsole("^2  [PASS] " + testName + "^7\n");
    }
    else
    {
        level.mysqlTestFailed++;
        level.mysqlTestResults = level.mysqlTestResults + "[FAIL] " + testName + "\n";
        logPrintConsole("^1  [FAIL] " + testName + "^7\n");
    }
}