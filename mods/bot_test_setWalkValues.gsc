// ============================================================================
// bot_test_setWalkValues.gsc — Test: setWalkValues(forwardMove, rightMove)
// ============================================================================
// Zależność: zk_libcod (COMPILE_BOTS=1)
// Opis: Ustawienie wartości ruchu bota
// Sygnatura: bot setWalkValues(int forwardMove, int rightMove)
//   forwardMove: 127 = przód, -127 = tył, 0 = stop
//   rightMove:   127 = prawo, -127 = lewo, 0 = stop
// Zwraca: true przy sukcesie, undefined przy błędzie
// ============================================================================

botTestSetWalkValues()
{
    logPrintConsole("^3--- Test: setWalkValues ---^7\n");

    bot = getBot();

    if (!isDefined(bot))
    {
        logPrintConsole("^5  [SKIP] setWalkValues: brak bota na serwerze^7\n");
        return;
    }

    // TC1: Ruch do przodu (full speed)
    bot setWalkValues(127, 0);
    wait 0.15;
    vel = bot.velocity;
    speed = length(vel);
    logPrintConsole("^5  [INFO] setWalkValues(127,0): speed=" + speed + "^7\n");
    assertEQ(speed > 0, 1, "setWalkValues: ruch do przodu (speed=" + speed + ")");
    bot setWalkValues(0, 0);
    wait 0.1;

    // TC2: Ruch do tyłu
    bot setWalkValues(-127, 0);
    wait 0.15;
    vel = bot.velocity;
    speed = length(vel);
    logPrintConsole("^5  [INFO] setWalkValues(-127,0): speed=" + speed + "^7\n");
    assertEQ(speed > 0, 1, "setWalkValues: ruch do tylu (speed=" + speed + ")");
    bot setWalkValues(0, 0);
    wait 0.1;

    // TC3: Ruch w prawo
    bot setWalkValues(0, 127);
    wait 0.15;
    vel = bot.velocity;
    speed = length(vel);
    logPrintConsole("^5  [INFO] setWalkValues(0,127): speed=" + speed + "^7\n");
    assertEQ(speed > 0, 1, "setWalkValues: ruch w prawo (speed=" + speed + ")");
    bot setWalkValues(0, 0);
    wait 0.1;

    // TC4: Ruch w lewo
    bot setWalkValues(0, -127);
    wait 0.15;
    vel = bot.velocity;
    speed = length(vel);
    logPrintConsole("^5  [INFO] setWalkValues(0,-127): speed=" + speed + "^7\n");
    assertEQ(speed > 0, 1, "setWalkValues: ruch w lewo (speed=" + speed + ")");
    bot setWalkValues(0, 0);
    wait 0.1;

    // TC5: Ruch po skosie (przód + prawo)
    bot setWalkValues(127, 127);
    wait 0.15;
    vel = bot.velocity;
    speed = length(vel);
    logPrintConsole("^5  [INFO] setWalkValues(127,127): speed=" + speed + "^7\n");
    assertEQ(speed > 0, 1, "setWalkValues: ruch po skosie (speed=" + speed + ")");
    bot setWalkValues(0, 0);
    wait 0.1;

    // TC6: Zatrzymanie po ruchu
    bot setWalkValues(127, 0);
    wait 0.15;
    bot setWalkValues(0, 0);
    wait 0.2;
    vel = bot.velocity;
    speed = length(vel);
    logPrintConsole("^5  [INFO] setWalkValues(0,0) stop: speed=" + speed + "^7\n");
    assertEQ(speed < 20, 1, "setWalkValues: zatrzymanie (speed=" + speed + ")");

    // TC7: Ruch z małą prędkością
    bot setWalkValues(30, 0);
    wait 0.15;
    vel = bot.velocity;
    speed = length(vel);
    logPrintConsole("^5  [INFO] setWalkValues(30,0): speed=" + speed + "^7\n");
    assertEQ(speed > 0, 1, "setWalkValues: mala predkosc (fw=30, speed=" + speed + ")");
    bot setWalkValues(0, 0);
    wait 0.1;

    // TC8: Szybka zmiana kierunków (slalom)
    directions = ((127, 0), (0, 127), (-127, 0), (0, -127));
    for (i = 0; i < 4; i++)
    {
        bot setWalkValues(directions[i][0], directions[i][1]);
        wait 0.1;
    }
    bot setWalkValues(0, 0);
    logPrintConsole("^2  [PASS] setWalkValues: 4 kierunki bez crasha^7\n");

    logPrintConsole("^3--- Koniec test: setWalkValues ---^7\n");
}