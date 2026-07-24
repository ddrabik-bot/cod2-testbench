/**
 * execute_async_test.gsc — Test execute_async_create with curl
 *
 * PURPOSE: Test asynchronous shell-command execution through
 * execute_async_create / execute_async_create_nosave z zk_libcod.
 *
 * REQUIREMENTS:
 * - zk_libcod z ENABLE_UNSAFE=1 (config.hpp)
 * - execute_async_checkdone() called every frame
 * - target-server running (docker compose up -d)
 *
 * SCENARIOS:
 *   1. execute_async_create — basic curl GET
 *   2. execute_async_create — curl POST with a JSON body
 *   3. execute_async_create_nosave — fire-and-forget
 *   4. Callback verification — output and callback parameter
 *   5. Timeout — curl --max-time against a delayed endpoint
 *   6. Error handling — curl to a nonexistent host
 */

test_results = [];

/* ── 1. Basic curl GET ── */
test_basic_get() {
    iprintln("^2[TEST 1] execute_async_create -- basic curl GET");
    execute_async_create("curl -s http://target-server:8080/api/hello", ::async_callback_basic, 1);
}

async_callback_basic(output, param) {
    if (output == "{}") {
        iprintln("^2[TEST 1] PASS -- curl GET returned expected JSON");
        test_results[param] = "PASS";
    } else {
        iprintln("^1[TEST 1] FAIL -- unexpected output: " + output);
        test_results[param] = "FAIL";
    }
}

/* ── 2. Curl POST z JSON ── */
test_post_json() {
    iprintln("^2[TEST 2] execute_async_create -- curl POST with a JSON body");
    execute_async_create(
        "curl -s -X POST -H 'Content-Type: application/json' \
            -d '{\"source\":\"cod2\",\"action\":\"test\"}' \
            http://target-server:8080/api/echo",
        ::async_callback_post, 2);
}

async_callback_post(output, param) {
    if (isDefined(output) && output != "") {
        iprintln("^2[TEST 2] PASS -- POST returned: " + output);
        test_results[param] = "PASS";
    } else {
        iprintln("^1[TEST 2] FAIL -- empty response");
        test_results[param] = "FAIL";
    }
}

/* ── 3. Fire-and-forget (nosave) ── */
test_fire_and_forget() {
    iprintln("^2[TEST 3] execute_async_create_nosave -- fire-and-forget");
    execute_async_create_nosave(
        "curl -s -X POST -H 'Content-Type: application/json' \
            -d '{\"source\":\"cod2\",\"type\":\"nosave\"}' \
            http://target-server:8080/api/echo");
    test_results[3] = "PASS (no crash)";
    iprintln("^2[TEST 3] PASS -- execute_async_create_nosave executed");
}

/* ── 4. Callback verification ── */
test_callback_verification() {
    iprintln("^2[TEST 4] Callback verification -- parameter and output");
    execute_async_create("echo 'callback_test_ok'", ::async_callback_verify, 42);
}

async_callback_verify(output, param) {
    if (output == "callback_test_ok" && param == 42) {
        iprintln("^2[TEST 4] PASS -- callback(output=" + output + ", param=" + param + ")");
        test_results[4] = "PASS";
    } else {
        iprintln("^1[TEST 4] FAIL -- output=" + output + " param=" + param);
        test_results[4] = "FAIL";
    }
}

/* ── 5. Timeout test ── */
test_timeout() {
    iprintln("^2[TEST 5] Timeout -- curl --max-time 2s against endpoint delayed by 5s");
    execute_async_create(
        "curl -s --max-time 2 http://target-server:8080/api/delay/5",
        ::async_callback_timeout, 5);
}

async_callback_timeout(output, param) {
    if (output == "" || strContains(output, "timed out") || strContains(output, "curl: (28)")) {
        iprintln("^2[TEST 5] PASS -- curl timeout detected (output: '" + output + "')");
        test_results[5] = "PASS";
    } else {
        iprintln("^1[TEST 5] FAIL -- unexpected output: " + output);
        test_results[5] = "FAIL";
    }
}

/* ── 6. Error handling ── */
test_error_handling() {
    iprintln("^2[TEST 6] Error handling -- curl to a nonexistent host");
    execute_async_create(
        "curl -s --connect-timeout 3 http://nonexistent-host-99999:9999/api/test",
        ::async_callback_error, 6);
}

async_callback_error(output, param) {
    if (output == "" || strContains(output, "Could not resolve") || strContains(output, "Connection refused")) {
        iprintln("^2[TEST 6] PASS -- curl error correctly captured");
        test_results[6] = "PASS";
    } else {
        iprintln("^1[TEST 6] FAIL -- unexpected output: " + output);
        test_results[6] = "FAIL";
    }
}

/* ── Test runner ── */
run_all_async_tests() {
    iprintln("^3=== execute_async_create test suite ===");
    iprintln("^3Version: 1.0.0");
    test_basic_get();
    test_post_json();
    test_fire_and_forget();
    test_callback_verification();
    test_timeout();
    test_error_handling();
    iprintln("^3=== All tests dispatched. Waiting for async callbacks... ===");
}

print_test_summary() {
    iprintln("^3=== execute_async_create test results ===");
    for (i = 1; i <= 6; i++) {
        if (isDefined(test_results[i])) {
            iprintln("  Test " + i + ": " + test_results[i]);
        } else {
            iprintln("  Test " + i + ": ^1PENDING (no callback yet)");
        }
    }
    iprintln("^3==================================");
}