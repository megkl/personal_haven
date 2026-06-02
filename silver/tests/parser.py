#!/usr/bin/env python3
"""
parser.py — converts `flutter test --reporter json` stdout to Silver format.

Flutter JSON test protocol emits one JSON object per line.
  testStart  -> records test id -> name
  testDone   -> result: "success" | "failure" | "error"

Output: JSON array of {"name": str, "status": "pass" | "fail"}
"""
import json
import sys


def parse(raw: str) -> list:
    tests = {}   # id -> name
    results = {} # id -> "pass" | "fail"

    for line in raw.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue

        event = obj.get("type") or obj.get("event", "")

        if event == "testStart":
            test = obj.get("test", {})
            tid = test.get("id")
            name = test.get("name", "").strip()
            # Skip hidden root/loader entries (no dots in name = framework noise)
            if tid is not None and name and "loading " not in name:
                tests[tid] = name

        elif event == "testDone":
            tid = obj.get("testID")
            result = obj.get("result", "failure")
            hidden = obj.get("hidden", False)
            if tid is not None and not hidden:
                results[tid] = "pass" if result == "success" else "fail"

        elif event == "error":
            tid = obj.get("testID")
            if tid is not None:
                results[tid] = "fail"

    output = []
    for tid, name in tests.items():
        status = results.get(tid, "fail")
        output.append({"name": name, "status": status})

    return output


if __name__ == "__main__":
    raw = sys.stdin.read()
    print(json.dumps(parse(raw), indent=2))
