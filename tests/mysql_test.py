#!/usr/bin/env python3
"""
MySQL Integration Tests for cod2-testbench.

Tests MySQL connectivity using the service container:
  1. mysql_async_initializer — connection pool / async initialisation pattern
  2. SELECT 1 — basic connectivity
  3. INSERT + SELECT — data round-trip

Usage:
  python3 tests/mysql_test.py [--host HOST] [--port PORT] [--user USER] [--password PASS] [--database DB]

Environment variables (overridden by CLI args):
  MYSQL_HOST      (default: 127.0.0.1)
  MYSQL_PORT      (default: 3306)
  MYSQL_USER      (default: root)
  MYSQL_PASSWORD  (default: testpass)
  MYSQL_DATABASE  (default: testdb)
"""

import os
import sys
import time
import argparse

# Results accumulator
PASSED = 0
FAILED = 0
SKIPPED = 0


def report(result, test_name, detail=""):
    """Report a test result in the same format as run_tests.sh."""
    global PASSED, FAILED, SKIPPED
    if result == "PASS":
        PASSED += 1
        print(f"[PASS] {test_name}")
    elif result == "FAIL":
        FAILED += 1
        print(f"[FAIL] {test_name} — {detail}")
    elif result == "SKIP":
        SKIPPED += 1
        print(f"[SKIP] {test_name} — {detail}")


def wait_for_mysql(conn_func, max_retries=10, delay=2):
    """Wait for MySQL to become available."""
    for attempt in range(1, max_retries + 1):
        try:
            conn = conn_func()
            conn.close()
            return True
        except Exception as e:
            print(f"  Waiting for MySQL (attempt {attempt}/{max_retries}): {e}")
            time.sleep(delay)
    return False


def test_connection(db):
    """Test 1: mysql_async_initializer — verify connection pool readiness."""
    try:
        cursor = db.cursor()
        cursor.execute("SELECT CONNECTION_ID() AS cid")
        row = cursor.fetchone()
        cid = row[0]
        cursor.close()
        report("PASS", f"mysql_async_initializer — connected (connection_id={cid})")
        return True
    except Exception as e:
        report("FAIL", "mysql_async_initializer — can't connect", str(e))
        return False


def test_select_1(db):
    """Test 2: SELECT 1 — basic query execution."""
    try:
        cursor = db.cursor()
        cursor.execute("SELECT 1 AS result")
        row = cursor.fetchone()
        cursor.close()

        if row and row[0] == 1:
            report("PASS", "SELECT 1 — basic connectivity")
            return True
        else:
            report("FAIL", "SELECT 1 — unexpected result", f"got {row}")
            return False
    except Exception as e:
        report("FAIL", "SELECT 1 — query failed", str(e))
        return False


def test_insert_select(db):
    """Test 3: INSERT + SELECT — data round-trip with test data."""
    test_data = [
        ("cod2_test_1", "async_initializer", "test_value_a"),
        ("cod2_test_2", "mysql_binding", "test_value_b"),
        ("cod2_test_3", "connection_pool", "test_value_c"),
    ]

    try:
        cursor = db.cursor()

        # Create temporary table
        cursor.execute("""
            CREATE TEMPORARY TABLE IF NOT EXISTS _test_mysql (
                id INT AUTO_INCREMENT PRIMARY KEY,
                test_key VARCHAR(64) NOT NULL,
                test_group VARCHAR(64) NOT NULL,
                test_value VARCHAR(256) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # INSERT multiple rows
        cursor.executemany(
            "INSERT INTO _test_mysql (test_key, test_group, test_value) VALUES (%s, %s, %s)",
            test_data
        )
        db.commit()
        inserted = cursor.rowcount
        if inserted != len(test_data):
            report("FAIL", "INSERT + SELECT — row count mismatch",
                   f"expected {len(test_data)}, got {inserted}")
            cursor.close()
            return False
        report("PASS", f"INSERT + SELECT — inserted {inserted} rows")

        # SELECT back
        cursor.execute("SELECT test_key, test_group, test_value FROM _test_mysql ORDER BY id")
        rows = cursor.fetchall()

        if len(rows) != len(test_data):
            report("FAIL", "INSERT + SELECT — readback row count",
                   f"expected {len(test_data)}, got {len(rows)}")
            cursor.close()
            return False

        all_ok = True
        for i, (key, group, value) in enumerate(rows):
            expected = test_data[i]
            if key != expected[0] or group != expected[1] or value != expected[2]:
                report("FAIL", f"INSERT + SELECT — row {i} mismatch",
                       f"expected {expected}, got ({key},{group},{value})")
                all_ok = False

        if all_ok:
            report("PASS", f"INSERT + SELECT — all {len(rows)} rows verified by SELECT")

        # Clean up
        cursor.execute("DROP TEMPORARY TABLE IF EXISTS _test_mysql")
        cursor.close()
        return all_ok

    except Exception as e:
        report("FAIL", "INSERT + SELECT — query error", str(e))
        return False


def test_async_pattern(db):
    """
    Test 4: mysql_async_initializer pattern — simulate the async query model
    from zk_libcod's gsc_mysql.cpp in Python.

    The GSC mysql_async_initializer creates a background thread that polls for
    queued queries. Here we test the pattern by:
      - Opening multiple connections (simulating a pool)
      - Running concurrent queries
      - Checking results asynchronously
    """
    try:
        import threading
        import queue

        results_queue = queue.Queue()

        def async_query(conn_params, query, qid):
            """Simulate an async query execution."""
            import pymysql
            try:
                c = pymysql.connect(**conn_params)
                cur = c.cursor()
                cur.execute(query)
                rows = cur.fetchall()
                cur.close()
                c.close()
                results_queue.put((qid, rows, None))
            except Exception as e:
                results_queue.put((qid, None, str(e)))

        conn_params = {
            "host": db.host,
            "port": db.port if hasattr(db, 'port') else 3306,
            "user": db.user,
            "password": db.password,
            "database": db.db if hasattr(db, 'db') else db.database,
        }

        # Spawn 3 parallel "async" queries
        queries = [
            (1, "SELECT 'async_test_1' AS val"),
            (2, "SELECT 'async_test_2' AS val"),
            (3, "SELECT 42 AS val"),
        ]

        threads = []
        for qid, q in queries:
            t = threading.Thread(target=async_query, args=(conn_params, q, qid))
            t.start()
            threads.append(t)

        for t in threads:
            t.join(timeout=10)

        results = []
        while not results_queue.empty():
            results.append(results_queue.get_nowait())

        if len(results) != len(queries):
            report("FAIL", "async_initializer pattern — incomplete results",
                   f"got {len(results)}/{len(queries)}")
            return False

        all_ok = True
        for qid, rows, err in results:
            if err:
                report("FAIL", f"async_initializer pattern — query {qid} error", err)
                all_ok = False
            else:
                report("PASS", f"async_initializer pattern — query {qid} returned {len(rows)} row(s)")

        return all_ok

    except ImportError:
        report("SKIP", "async_initializer pattern — threading/queue not available")
        return True  # skip is not a failure
    except Exception as e:
        report("FAIL", "async_initializer pattern — error", str(e))
        return False


def main():
    parser = argparse.ArgumentParser(description="MySQL Integration Tests")
    parser.add_argument("--host", default=os.environ.get("MYSQL_HOST", "127.0.0.1"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("MYSQL_PORT", 3306)))
    parser.add_argument("--user", default=os.environ.get("MYSQL_USER", "root"))
    parser.add_argument("--password", default=os.environ.get("MYSQL_PASSWORD", "testpass"))
    parser.add_argument("--database", default=os.environ.get("MYSQL_DATABASE", "testdb"))
    args = parser.parse_args()

    # Import pymysql
    try:
        import pymysql
    except ImportError:
        print("[SKIP] MySQL tests — pymysql not installed")
        print()
        print("MySQL Results: 0 passed, 0 failed, 1 skipped")
        return 0

    print("=" * 50)
    print("  MySQL Integration Tests")
    print("=" * 50)
    print(f"  Host:     {args.host}")
    print(f"  Port:     {args.port}")
    print(f"  User:     {args.user}")
    print(f"  Database: {args.database}")
    print("=" * 50)

    # Wait for MySQL to be ready
    print("\n[*] Waiting for MySQL...")
    def try_connect():
        return pymysql.connect(
            host=args.host,
            port=args.port,
            user=args.user,
            password=args.password,
            database=args.database,
            connect_timeout=5
        )

    if not wait_for_mysql(try_connect):
        print("[FAIL] MySQL not available after retries")
        global FAILED
        FAILED += 1
        print(f"\nMySQL Results: {PASSED} passed, {FAILED} failed, {SKIPPED} skipped")
        return 1

    print("[*] MySQL ready, starting tests...\n")

    # Run tests
    db = try_connect()

    test_connection(db)
    test_select_1(db)
    test_insert_select(db)
    test_async_pattern(db)

    db.close()

    # Summary
    total = PASSED + FAILED + SKIPPED
    print(f"\n{'=' * 50}")
    print(f"  MySQL Results: {PASSED} passed, {FAILED} failed, {SKIPPED} skipped")
    print(f"{'=' * 50}")

    return 1 if FAILED > 0 else 0


if __name__ == "__main__":
    sys.exit(main())