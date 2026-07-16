// ============================================================================
// bot_test_setOriginAndAngles.gsc — Test: setOriginAndAngles(origin, angles)
// ============================================================================
// Zależność: zk_libcod (COMPILE_PLAYER=1)
// Funkcja: Teleportacja gracza/bota do podanej pozycji z kątem widzenia
// Sygnatura: player setOriginAndAngles((vector)origin, (vector)angles)
// Zwraca: undefined przy błędzie, void przy sukcesie
// ============================================================================

botTestSetOriginAndAngles()
{
    logPrintConsole("^3--- Test: setOriginAndAngles ---^7\n");

    bot = getBot();
    player = getPlayer();

    if (!isDefined(bot))
    {
        logPrintConsole("^5  [SKIP] Brak bota na serwerze^7\n");
        return;
    }

    // TC1: Teleportacja bota do znanej pozycji
    test_origin = (-100, 500, 50);
    test_angles = (0, 180, 0);
    bot setOriginAndAngles(test_origin, test_angles);
    wait 0.05;

    current_origin = bot.origin;
    dist = distance(current_origin, test_origin);
    assertEQ(dist < 10, 1, "setOriginAndAngles: teleportacja bota (dist=" + dist + ")");

    // TC2: Kąt patrzenia po teleportacji (yaw=180)
    bot_angles = bot.angles;
    yaw_diff = abs(bot_angles[1] - 180) % 360;
    if (yaw_diff > 180)
        yaw_diff = 360 - yaw_diff;
    assertEQ(yaw_diff < 10, 1, "setOriginAndAngles: yaw=180 (diff=" + yaw_diff + ")");

    // TC3: Zerowa prędkość po teleportacji
    vel = bot.velocity;
    speed = length(vel);
    assertEQ(speed < 1, 1, "setOriginAndAngles: zerowa predkosc (speed=" + speed + ")");

    // TC4: Teleportacja w powietrzu (wysokie Z)
    bot setOriginAndAngles((-100, 500, 500), (0, 0, 0));
    wait 0.05;
    dist = distance(bot.origin, (-100, 500, 500));
    assertEQ(dist < 15, 1, "setOriginAndAngles: teleportacja w powietrzu (dist=" + dist + ")");

    // TC5: Kąt patrzenia w górę (pitch=-90)
    bot setOriginAndAngles((-100, 500, 50), (-90, 0, 0));
    wait 0.05;
    pitch_diff = abs(bot.angles[0] - (-90)) % 360;
    if (pitch_diff > 180)
        pitch_diff = 360 - pitch_diff;
    assertEQ(pitch_diff < 15, 1, "setOriginAndAngles: pitch=-90 (diff=" + pitch_diff + ")");

    // TC6: Teleportacja gracza (nie bota)
    if (isDefined(player))
    {
        player_origin = player.origin;
        new_origin = (player_origin[0] + 50, player_origin[1], player_origin[2]);
        player setOriginAndAngles(new_origin, (0, 90, 0));
        wait 0.05;
        dist = distance(player.origin, new_origin);
        assertEQ(dist < 10, 1, "setOriginAndAngles: teleportacja gracza (dist=" + dist + ")");
    }
    else
    {
        logPrintConsole("^5  [SKIP] setOriginAndAngles: brak gracza^7\n");
    }

    // TC7: Seria teleportacji (stres test)
    for (i = 0; i < 5; i++)
    {
        bot setOriginAndAngles((i * 50, i * 50, 50), (0, i * 72, 0));
        wait 0.02;
    }
    logPrintConsole("^2  [PASS] setOriginAndAngles: 5x teleportacja bez crasha^7\n");

    logPrintConsole("^3--- Koniec test: setOriginAndAngles ---^7\n");
}