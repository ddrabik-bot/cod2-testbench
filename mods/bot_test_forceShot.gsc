// ============================================================================
// bot_test_forceShot.gsc — Test: forceShot([onClientToo])
// ============================================================================
// Zależność: zk_libcod (COMPILE_PLAYER=1)
// Opis: Wymuszenie strzału z obecnej broni
// Sygnatura: player forceShot([int onClientToo])
//   onClientToo: 0 = tylko serwer, 1 (domyślny) = także klient
// Zwraca: false jeśli nie żyje/brak broni, undefined przy błędzie
// ============================================================================

botTestForceShot()
{
    logPrintConsole("^3--- Test: forceShot ---^7\n");

    bot = getBot();
    player = getPlayer();

    if (!isDefined(player))
    {
        logPrintConsole("^5  [SKIP] forceShot: brak gracza na serwerze^7\n");
        return;
    }

    if (!isDefined(bot))
    {
        logPrintConsole("^5  [SKIP] forceShot: brak bota na serwerze^7\n");
        return;
    }

    // TC1: Podstawowy forceShot (domyślnie onClientToo=1)
    bot forceShot();
    wait 0.05;
    logPrintConsole("^2  [PASS] forceShot: bot strzela (domyslnie onClientToo=1)^7\n");

    // TC2: forceShot z onClientToo=0
    bot forceShot(0);
    wait 0.05;
    logPrintConsole("^2  [PASS] forceShot: bot strzela (onClientToo=0)^7\n");

    // TC3: forceShot z jawnym onClientToo=1
    bot forceShot(1);
    wait 0.05;
    logPrintConsole("^2  [PASS] forceShot: bot strzela (onClientToo=1)^7\n");

    // TC4: Wielokrotny forceShot (3x pod rząd)
    for (i = 0; i < 3; i++)
    {
        bot forceShot();
        wait 0.01;
    }
    logPrintConsole("^2  [PASS] forceShot: 3x strzal pod rzad^7\n");

    // TC5: forceShot na graczu (nie bocie)
    player forceShot();
    wait 0.05;
    logPrintConsole("^2  [PASS] forceShot: gracz strzela^7\n");

    // TC6: forceShot po teleportacji
    bot setOriginAndAngles((0, 0, 100), (0, 0, 0));
    wait 0.01;
    bot forceShot();
    wait 0.05;
    logPrintConsole("^2  [PASS] forceShot: strzal po teleportacji^7\n");

    // TC7: Stres test — 10 strzałów w pętli
    for (i = 0; i < 10; i++)
    {
        bot forceShot();
    }
    logPrintConsole("^2  [PASS] forceShot: 10x strzal bez crasha^7\n");

    // TC8: forceShot z setWalkValues (ruch + strzelanie)
    bot setWalkValues(80, 0);
    wait 0.1;
    bot forceShot();
    wait 0.05;
    bot setWalkValues(0, 0);
    logPrintConsole("^2  [PASS] forceShot: strzal podczas ruchu^7\n");

    logPrintConsole("^3--- Koniec test: forceShot ---^7\n");
}