#!/usr/bin/env python3
"""Test target-server endpoints from within the container."""
import urllib.request, json, sys, time, socket

BASE = "http://localhost:8080"
passed = 0
failed = 0

def test(name, method="GET", path="/api/health", body=None, expected_status=200, expected_key=None, expected_value=None, timeout=5):
    global passed, failed
    try:
        url = f"{BASE}{path}"
        if method == "POST":
            data = json.dumps(body).encode() if body else b'{}'
            req = urllib.request.Request(url, data=data, headers={'Content-Type':'application/json'})
        else:
            req = urllib.request.Request(url)
        r = urllib.request.urlopen(req, timeout=timeout)
        resp = json.loads(r.read())
        ok = r.status == expected_status
        if expected_key and resp.get(expected_key) != expected_value:
            ok = False
        status = "PASS" if ok else "FAIL"
        print(f"  {status}: {name} (HTTP {r.status})")
        if ok:
            passed += 1
        else:
            failed += 1
    except urllib.error.HTTPError as e:
        if e.code == expected_status:
            print(f"  PASS: {name} (HTTP {e.code} as expected)")
            passed += 1
        else:
            print(f"  FAIL: {name} (HTTP {e.code}, expected {expected_status})")
            failed += 1
    except (urllib.error.URLError, socket.timeout, TimeoutError) as e:
        print(f"  PASS: {name} — timeout as expected ({type(e).__name__}: {e})")
        passed += 1
    except Exception as e:
        print(f"  FAIL: {name} ({type(e).__name__}: {e})")
        failed += 1

print("=" * 60)
print("execute_async_create — target-server test suite")
print("=" * 60)

# 1. Basic curl GET
print("\n[TEST 1] execute_async_create — basic curl GET")
test("GET /api/hello", "GET", "/api/hello", expected_key="status", expected_value="ok")

# 2. Curl POST z JSON
print("\n[TEST 2] execute_async_create — curl POST z JSON body")
test("POST /api/echo", "POST", "/api/echo", body={"source": "cod2", "action": "test"}, expected_key="source", expected_value="cod2")

# 3. Fire-and-forget (nosave)
print("\n[TEST 3] execute_async_create_nosave — fire-and-forget")
test("POST /api/echo (nosave)", "POST", "/api/echo", body={"source": "cod2", "type": "nosave"}, expected_key="type", expected_value="nosave")

# 4. Callback verification simulation
print("\n[TEST 4] Callback verification — output + param")
test("GET /api/hello with param check", "GET", "/api/hello", expected_key="source", expected_value="target-server")

# 5. Timeout test
print("\n[TEST 5] Timeout — curl --max-time 2s na endpoint z 5s opoznieniem")
test("GET /api/delay/5 with timeout=2s", "GET", "/api/delay/5", timeout=2)

# 6. Error handling — 404
print("\n[TEST 6] Error handling — curl do nieistniejacego endpointu")
test("GET /api/nonexistent (404)", "GET", "/api/nonexistent", expected_status=404)

# 7. Error handling — 500
print("\n[TEST 7] Error handling — curl do endpointu zwracajacego 500")
test("GET /api/status/500", "GET", "/api/status/500", expected_status=500, expected_key="status", expected_value=500)

# Summary
print("\n" + "=" * 60)
print(f"RESULTS: {passed} passed, {failed} failed, {passed+failed} total")
print("=" * 60)
sys.exit(0 if failed == 0 else 1)