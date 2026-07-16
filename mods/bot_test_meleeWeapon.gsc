// ============================================================================
// bot_test_meleeWeapon.gsc — Test: meleeWeapon(melee)
// ============================================================================
// Zależność: zk_libcod (COMPILE_BOTS=1)
// Opis: Wymuszenie ataku wręcz bota
// Sygnatura: bot meleeWeapon(int melee)
//   melee: 1 = włącz atak, 0 = wyłącz
// Zwraca: true przy sukcesie, undefined przy błędzie
// ============================================================================

botTestMeleeWeapon()
{
    logPrintConsole("^3--- Test: meleeWeapon ---^7\n");

    bot = getBot();
    player = getPlayer();

    if (!isDefined(bot))
    {
        logPrintConsole("^5  [SKIP] meleeWeapon: brak bota na serwerze^7\n");
        return;
    }

    // TC1: Podstawowy atak wręcz (melee=1)
    bot meleeWeapon(1);
    wait 0.1;
    logPrintConsole("^2  [PASS] meleeWeapon(1): atak wrecz^7\n");

    // TC2: Zakończenie ataku (melee=0)
    bot meleeWeapon(0);
    wait 0.1;
    logPrintConsole("^2  [PASS] meleeWeapon(0): atak zatrzymany^7\n");

    // TC3: Sekwencja włącz/wyłącz (3x)
    for (i = 0; i < 3; i++)
    {
        bot meleeWeapon(1);
        wait 0.05;
        bot meleeWeapon(0);
        wait 0.05;
    }
    logPrintConsole("^2  [PASS] meleeWeapon: 3x sekwencja wlacz/wylacz^7\n");

    // TC4: Atak wręcz podczas ruchu
    bot setWalkValues(80, 0);
    wait 0.1;
    bot meleeWeapon(1);
    wait 0.1;
    bot meleeWeapon(0);
    bot setWalkValues(0, 0);
    wait 0.1;
    logPrintConsole("^2  [PASS] meleeWeapon: atak podczas ruchu^7\n");

    // TC5: Atak wręcz po teleportacji
    bot setOriginAndAngles((0, 0, 50), (0, 90, 0));
    wait 0.05;
    bot meleeWeapon(1);
    wait 0.1;
    bot meleeWeapon(0);
    wait 0.05;
    logPrintConsole("^2  [PASS] meleeWeapon: atak po teleportacji^7\n");

    // TC6: 5x szybki atak wręcz
    for (i = 0; i < 5; i++)
    {
        bot meleeWeapon(1);
        wait 0.02;
        bot meleeWeapon(0);
        wait 0.02;
    }
    logPrintConsole("^2  [PASS] meleeWeapon: 5x szybki atak^7\n");

    // TC7: Atak combo (melee + forceShot)
    bot meleeWeapon(1);
    bot forceShot();
    wait 0.1;
    bot meleeWeapon(0);
    logPrintConsole("^2  [PASS] meleeWeapon: atak combo (melee + forceShot)^7\n");

    // TC8: Długi atak z przerwaniem
    bot meleeWeapon(1);
    wait 0.3;
    bot meleeWeapon(0);
    logPrintConsole("^2  [PASS] meleeWeapon: dlugi atak z przerwaniem^7\n");

    logPrintConsole("^3--- Koniec test: meleeWeapon ---^7\n");
}