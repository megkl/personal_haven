#!/usr/bin/env bash
# Silver harness entrypoint — do NOT modify per task.
set -euo pipefail

TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$TASK_DIR/config.json"
LOG_DIR="/logs/verifier"
mkdir -p "$LOG_DIR"

# 1. Apply test patch
TEST_PATCH="$(python3 - <<'PYEOF'
import json, sys
d = json.load(open("'"$CONFIG"'"))
print(d.get("test_patch", ""))
PYEOF
)"

if [ -n "$TEST_PATCH" ]; then
    echo "[harness] Applying test_patch..."
    printf '%s' "$TEST_PATCH" | git apply --whitespace=nowarn - || {
        echo "[harness] ERROR: test_patch failed to apply" >&2
        echo "0" > "$LOG_DIR/reward.txt"
        exit 1
    }
fi

# 2. Run suite and parse
echo "[harness] Running tests..."
RAW="$(bash "$TASK_DIR/run_script.sh" 2>&1)" || true
PARSED="$(echo "$RAW" | python3 "$TASK_DIR/parser.py")"
echo "[harness] Parsed:"
echo "$PARSED"

# 3. Check each required test
REWARD=1

check_list() {
    local label="$1"
    local key="$2"
    local names
    names="$(python3 - <<PYEOF
import json
d = json.load(open("$CONFIG"))
for n in d.get("$key", []):
    print(n)
PYEOF
)"
    while IFS= read -r name; do
        [ -z "$name" ] && continue
        status="$(echo "$PARSED" | python3 - "$name" <<'PYEOF'
import json, sys
results = json.load(sys.stdin)
name = sys.argv[1]
m = next((r for r in results if r["name"] == name), None)
print(m["status"] if m else "missing")
PYEOF
)"
        if [ "$status" = "pass" ]; then
            echo "[harness] PASS [$label]: $name"
        else
            echo "[harness] FAIL [$label]: $name  (status=$status)"
            REWARD=0
        fi
    done <<< "$names"
}

check_list "fail_to_pass" "fail_to_pass"
check_list "pass_to_pass" "pass_to_pass"

echo "$REWARD" > "$LOG_DIR/reward.txt"
echo "[harness] reward=$REWARD"
