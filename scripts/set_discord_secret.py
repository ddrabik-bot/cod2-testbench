#!/usr/bin/env python3
"""Create/update DISCORD_WEBHOOK_URL secret in ddrabik-bot/cod2-testbench."""
import json
import base64
import os
import sys
import urllib.request

from nacl import public as nacl_public

TOKEN = ""
with open("/opt/data/profiles/dev/.env") as f:
    for line in f:
        if line.startswith("GITHUB_TOKEN"):
            TOKEN = line.split("=", 1)[1].strip()
            break
if not TOKEN:
    print("ERROR: GITHUB_TOKEN not set")
    sys.exit(1)

OWNER = "ddrabik-bot"
REPO = "cod2-testbench"
SECRET_NAME = "DISCORD_WEBHOOK_URL"

# Public key
with open("/tmp/cod2_pubkey.json") as f:
    pub_data = json.load(f)
    key_id = pub_data["key_id"]
    pubkey_b64 = pub_data["key"]

pubkey = base64.b64decode(pubkey_b64)
pubkey_obj = nacl_public.PublicKey(pubkey)

# Encrypt the value (sealed box)
value = sys.argv[1] if len(sys.argv) > 1 else "SET_YOUR_DISCORD_WEBHOOK_URL_HERE"
sealed_box = nacl_public.SealedBox(pubkey_obj)
encrypted = sealed_box.encrypt(value.encode("utf-8"))
encrypted_b64 = base64.b64encode(encrypted).decode("utf-8")

# API call
payload = json.dumps({"encrypted_value": encrypted_b64, "key_id": key_id}).encode("utf-8")
req = urllib.request.Request(
    f"https://api.github.com/repos/{OWNER}/{REPO}/actions/secrets/{SECRET_NAME}",
    data=payload,
    headers={
        "Authorization": f"Bearer {TOKEN}",
        "Accept": "application/vnd.github+json",
        "Content-Type": "application/json",
    },
    method="PUT",
)
try:
    with urllib.request.urlopen(req) as resp:
        http_code = resp.status
        print(f"Secret {SECRET_NAME}: HTTP {http_code}")
        if http_code == 201:
            print(f"  ✅ Secret '{SECRET_NAME}' created")
        elif http_code == 204:
            print(f"  ✅ Secret '{SECRET_NAME}' updated")
except urllib.error.HTTPError as e:
    print(f"  ❌ HTTP {e.code}: {e.read().decode('utf-8')[:200]}")
    sys.exit(1)