# cod2-testbench

A reproducible test bench for Call of Duty 2 mod development with `zk_libcod`.
It separates repository-owned tests from proprietary CoD2 runtime files and
includes an HTTP fixture for `execute_async_create` curl tests.

## Repository layout and `zk_libcod`

`zk_libcod` is a Git submodule at `code/zk_libcod`, pinned to an exact commit so
local and CI checkouts use the same source revision. Its configured source is
the curated `master` branch of
[`ddrabik-bot/zk_libcod`](https://github.com/ddrabik-bot/zk_libcod).

The `branch = master` setting in `.gitmodules` is intentional. `master` is the
reviewed branch from which this repository may deliberately advance its pinned
gitlink. The fork's `dev` branch can be used for experiments, but it is not the
automatic source of test-bench updates. The submodule retains its own history
and licence; do not copy its source snapshots or build binaries here.

```bash
git clone --recurse-submodules https://github.com/ddrabik-bot/cod2-testbench.git
cd cod2-testbench

# For an existing clone:
git submodule update --init --recursive
```

To deliberately update the pinned revision: update and review
`ddrabik-bot/zk_libcod` on `master`, run
`git submodule update --remote code/zk_libcod`, inspect and test the changed
gitlink, then commit that gitlink. Do not copy submodule files or commit
`libcod2.so`.

## CoD2 runtime layout

- `code/zk_libcod/` — pinned source submodule.
- `code/bin/` — ignored local build output, except `.gitkeep`.
- `cod2server/main/` — base CoD2 `main` configuration from an authorized
  runtime artifact; no committed binaries or IWDs.
- `cod2server/testbench/` — `fs_game` directory for test-specific GSC scripts
  and configuration used with a real CoD2 server.
- `mods/` — host-side GSC fixtures retained for existing tests.
- `target-server/` — Python HTTP fixture introduced for F2.3; not a CoD2
  dedicated server.
- `tests/` and `scripts/` — host-side verification, reporting, and CI helpers.
- `results/` — generated test reports.
- `.github/workflows/` — GitHub Actions workflows.

The real CoD2 dedicated server is external to this repository. It uses a
licensed dedicated-server executable, game data and IWDs, plus this project's
`main` and `fs_game` configuration. Proprietary executables, game files, IWDs,
credentials, and restricted runtime assets are intentionally absent. Supply
them through an authorized local runtime, CI artifact, secret, or configuration
and never commit them to this repository.

## Python target-server fixture (F2.3)

`target-server` is a Python HTTP service for curl commands invoked by
`execute_async_create` and `execute_async_create_nosave`. It is a network
fixture only: it does not emulate, start, configure, or replace the real CoD2
server. Docker Compose places it on the project-specific
`cod2-testbench-net` bridge network. A CoD2 container reaches it at
`http://target-server:8080`; the host reaches it at `http://localhost:8091`.

| Method | Path | Description |
| --- | --- | --- |
| GET | `/api/health` | Health check. |
| GET | `/api/hello` | Returns `{"status":"ok","source":"target-server"}`. |
| POST | `/api/echo` | Returns the JSON body and request headers. |
| GET | `/api/delay/<N>` | Responds after `N` seconds for timeout tests. |
| GET | `/api/status/<N>` | Returns HTTP status `N` for error tests. |
| GET | `/api/headers` | Returns request headers as JSON. |

### Quick start

```bash
make build
make up
make ps
make test-curl
make test-timeout
make test-error
make test-all
make test-shell
make logs
make down
```

## `execute_async_create` examples

The following calls run on a real CoD2 server with `zk_libcod`. Use host port
`8091` from the host and internal port `8080` from containers on the project
network.

### Basic GET

```c
execute_async_create(
    "curl -s http://target-server:8080/api/hello",
    ::async_callback_basic, 1
);
```

```bash
curl -s http://localhost:8091/api/hello
```

### POST JSON

```c
execute_async_create(
    "curl -s -X POST -H 'Content-Type: application/json' \
        -d '{\"source\":\"cod2\",\"action\":\"test\"}' \
        http://target-server:8080/api/echo",
    ::async_callback_post, 2
);
```

### Fire-and-forget

```c
execute_async_create_nosave(
    "curl -s -X POST -H 'Content-Type: application/json' \
        -d '{\"source\":\"cod2\",\"type\":\"nosave\"}' \
        http://target-server:8080/api/echo"
);
```

This form starts the command and continues without a callback.
`execute_async_create` instead passes `callback(output, param)`:

```c
execute_async_create("echo 'callback_test_ok'", ::my_callback, 42);

my_callback(output, param) {
    // output == "callback_test_ok"
    // param == 42
}
```

### Timeout and error handling

When `--max-time` expires, curl exits with code `28`:

```c
execute_async_create(
    "curl -s --max-time 2 http://target-server:8080/api/delay/5",
    ::async_callback_timeout, 5
);
```

```c
execute_async_create(
    "curl -s --connect-timeout 3 http://nonexistent-host-99999:9999/api/test",
    ::async_callback_error, 6
);
```

## GSC and Python test suites

`tests/execute_async_test.gsc` provides six scenarios: basic GET, JSON POST,
fire-and-forget, callback verification, timeout handling, and unavailable-host
handling. To run it with a real server:

1. Copy `tests/execute_async_test.gsc` to the server's `raw/` directory.
2. Call `run_all_async_tests()` from `CodeCallback_StartGameType()`.
3. Ensure `execute_async_checkdone()` runs once per game frame.
4. Start the fixture with `make up`, then restart the CoD2 server.
5. Inspect fixture logs with `make logs` and CoD2 logs separately.

Requirements: `zk_libcod` built with `ENABLE_UNSAFE=1` in `config.hpp`, a
network path from CoD2 to `target-server`, and `execute_async_checkdone()` in
the game loop. Docker services should share a network; use host networking only
when explicitly required.

`tests/test_target_server.py` runs seven fixture endpoint tests inside the
container, covering GET, JSON POST, fire-and-forget behavior, callback
simulation, timeout, 404, and 500 responses:

```bash
docker exec cod2-testbench-target python3 /app/test_target_server.py
```

## HTML reports

The GSC framework writes `results/test_results.log` and
`results/test_report.html` after `testRunner()` runs. The HTML report contains
summary cards, a PASS/FAIL table, server uptime in milliseconds, and responsive
inline dark-theme styling.

```bash
# Generate from the default result log.
./tests/generate_html_report.sh

# Generate from a specific log.
./tests/generate_html_report.sh results/test_results.log
```

GitHub Actions generates the report when the helper exists and uploads
`results/` as the `test-results` artifact.

## Discord webhook notifications

After a GitHub Actions test run, the workflow can send a summary to Discord:

1. Create a webhook under Discord channel **Integrations** → **Webhooks**.
2. Add its URL as the Actions secret `DISCORD_WEBHOOK_URL` in **Settings** →
   **Secrets and variables** → **Actions** → **New repository secret**.

```bash
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..." \
  ./scripts/notify-discord.sh success "Local tests" "All tests passed"
```
