.PHONY: up down restart logs build ps test-shell test-curl test-timeout test-error test-all clean

# Docker compose
up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart

logs:
	docker compose logs -f

build:
	docker compose build

ps:
	docker compose ps

# Tests

## Test basic curl GET to target-server
test-curl:
	@echo "=== Test: curl GET /api/hello ==="
	curl -s http://localhost:8091/api/hello | python3 -m json.tool
	@echo ""
	@echo "=== Test: curl POST /api/echo ==="
	curl -s -X POST -H 'Content-Type: application/json' \
		-d '{"source":"cod2","action":"test"}' \
		http://localhost:8091/api/echo | python3 -m json.tool

## Test timeout (--max-time 2s on endpoint with 5s delay)
test-timeout:
	@echo "=== Test: timeout (curl --max-time 2s on /api/delay/5) ==="
	time curl -s --max-time 2 http://localhost:8091/api/delay/5; \
	if [ $$? -eq 28 ]; then echo "PASS: curl returned exit code 28 (timeout)"; else echo "FAIL: unexpected exit code"; fi

## Test error handling (bad endpoint)
test-error:
	@echo "=== Test: error handling (404) ==="
	curl -s -w "\nHTTP_CODE: %{http_code}\n" http://localhost:8091/api/nonexistent
	@echo ""
	@echo "=== Test: error handling (connection refused) ==="
	curl -s --connect-timeout 3 http://localhost:18999/ 2>&1 || true

## Run all curl tests
test-all: test-curl test-timeout test-error
	@echo "=== All curl tests completed ==="

## Shell-level simulation of execute_async_create pattern
test-shell:
	@echo "=== Shell-level simulation of execute_async_create ==="
	@echo ""
	@echo "--- Test 1: Basic GET (execute_async_create equivalent) ---"
	OUTPUT=$$(curl -s http://localhost:8091/api/hello); \
	echo "Output: $$OUTPUT"; \
	if [ "$$OUTPUT" = '{"status": "ok", "source": "target-server"}' ]; then \
		echo "PASS: GET returned expected JSON"; \
	else \
		echo "FAIL: unexpected output"; \
	fi
	@echo ""
	@echo "--- Test 2: POST with JSON (callback simulation) ---"
	OUTPUT=$$(curl -s -X POST -H 'Content-Type: application/json' \
		-d '{"source":"cod2","action":"test"}' \
		http://localhost:8091/api/echo); \
	echo "Output: $$OUTPUT"; \
	SOURCE=$$(echo "$$OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('source',''))"); \
	if [ "$$SOURCE" = "cod2" ]; then \
		echo "PASS: POST echo returned correct source"; \
	else \
		echo "FAIL: unexpected source"; \
	fi
	@echo ""
	@echo "--- Test 3: Fire-and-forget (nosave equivalent) ---"
	curl -s -X POST -H 'Content-Type: application/json' \
		-d '{"source":"cod2","type":"nosave"}' \
		http://localhost:8091/api/echo > /dev/null 2>&1; \
	echo "PASS: fire-and-forget curl executed (exit code: $$?)"
	@echo ""
	@echo "--- Test 4: Callback verification (param + output) ---"
	OUTPUT="callback_test_ok"; \
	PARAM=42; \
	if [ "$$OUTPUT" = "callback_test_ok" ] && [ "$$PARAM" = "42" ]; then \
		echo "PASS: callback(output=$$OUTPUT, param=$$PARAM)"; \
	else \
		echo "FAIL: callback"; \
	fi
	@echo ""
	@echo "--- Test 5: Timeout (curl --max-time 2s on 5s delay) ---"
	time curl -s --max-time 2 http://localhost:8091/api/delay/5 > /dev/null 2>&1; \
	EXIT_CODE=$$?; \
	if [ "$$EXIT_CODE" = "28" ]; then \
		echo "PASS: curl timed out (exit 28)"; \
	else \
		echo "FAIL: curl returned $$EXIT_CODE (expected 28)"; \
	fi
	@echo ""
	@echo "--- Test 6: Error handling (nonexistent host) ---"
	curl -s --connect-timeout 3 http://nonexistent-host-99999:9999/ > /dev/null 2>&1; \
	EXIT_CODE=$$?; \
	if [ "$$EXIT_CODE" != "0" ]; then \
		echo "PASS: curl failed with exit code $$EXIT_CODE (expected non-zero)"; \
	else \
		echo "FAIL: curl succeeded (expected failure)"; \
	fi
	@echo ""
	@echo "=== Shell-level simulation complete ==="

# Cleanup
clean:
	docker compose down -v
	docker rmi cod2-testbench-target 2>/dev/null || true