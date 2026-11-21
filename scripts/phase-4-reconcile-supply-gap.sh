#!/usr/bin/env bash

# Deliberately avoid "set -e": failures must not terminate an
# interactive parent shell. This script is intended to run as a child process.
set -u
set -o pipefail

main() {
    if [[ -z "${VC_RPC_URL:-}" ]]; then
        echo "ERROR: VC_RPC_URL is not available."
        return 1
    fi

    for cmd in curl jq python3; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "ERROR: Required command not found: $cmd"
            return 1
        fi
    done

    local USDR="0x0000000000000000000000000000000000000400"
    local TRANSFER="0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
    local OUT="evidence/phase-4-one-pass-audit"

    mkdir -p "$OUT" || {
        echo "ERROR: Could not create evidence directory."
        return 1
    }

    # Three non-overlapping ranges, each no larger than 100,000 blocks.
    local RANGES=(
        "11147588 11247587"
        "11247588 11347587"
        "11347588 11362693"
    )

    local PART=1
    local START END FROM_HEX TO_HEX PAYLOAD HTTP CURL_STATUS FILE

    echo "Starting USDr supply-gap reconciliation."
    echo "Target chain: Rayls (72957)"
    echo "Block range: 11147588–11362693"
    echo

    for RANGE in "${RANGES[@]}"; do
        read -r START END <<< "$RANGE"

        FROM_HEX=$(printf '0x%x' "$START")
        TO_HEX=$(printf '0x%x' "$END")
        FILE="$OUT/supply-gap-transfer-part-${PART}.json"

        echo "Request $PART: blocks $START–$END"

        PAYLOAD=$(jq -n \
            --arg address "$USDR" \
            --arg transfer "$TRANSFER" \
            --arg from "$FROM_HEX" \
            --arg to "$TO_HEX" \
            '{
                jsonrpc: "2.0",
                id: 1,
                method: "eth_getLogs",
                params: [{
                    address: $address,
                    fromBlock: $from,
                    toBlock: $to,
                    topics: [$transfer]
                }]
            }')

        HTTP=$(curl -sS \
            --connect-timeout 10 \
            --max-time 90 \
            -o "$FILE" \
            -w '%{http_code}' \
            -H "Content-Type: application/json" \
            --data "$PAYLOAD" \
            "$VC_RPC_URL")
        CURL_STATUS=$?

        if [[ "$CURL_STATUS" -ne 0 ]]; then
            echo "ERROR: Network/request failure on part $PART."
            echo "curl exit code: $CURL_STATUS"
            echo "Any response received is preserved at: $FILE"
            return 1
        fi

        if [[ "$HTTP" != "200" ]]; then
            echo "ERROR: HTTP status $HTTP on part $PART."
            cat "$FILE"
            return 1
        fi

        if ! jq -e \
            '((has("error") | not) and (.result | type == "array"))' \
            "$FILE" >/dev/null; then
            echo "ERROR: RPC returned an error or invalid response."
            jq . "$FILE" 2>/dev/null || cat "$FILE"
            return 1
        fi

        echo "  HTTP $HTTP; logs retrieved: $(jq '.result | length' "$FILE")"
        PART=$((PART + 1))
    done

    echo
    echo "Combining the three successful responses..."

    if ! jq -s '[.[] | .result[]]' \
        "$OUT/supply-gap-transfer-part-1.json" \
        "$OUT/supply-gap-transfer-part-2.json" \
        "$OUT/supply-gap-transfer-part-3.json" \
        > "$OUT/supply-gap-transfer-logs.json"; then
        echo "ERROR: Could not combine RPC responses."
        return 1
    fi

    echo "Combined logs: $(jq 'length' "$OUT/supply-gap-transfer-logs.json")"

    python3 - "$OUT/supply-gap-transfer-logs.json" <<'PY'
import json
import sys
from decimal import Decimal

path = sys.argv[1]

with open(path) as f:
    logs = json.load(f)

zero = "0x" + "0" * 64

mint_total = 0
burn_total = 0
mints = []
burns = []

def amount_text(raw):
    return f"{Decimal(raw) / Decimal(10**18):.18f}"

for log in logs:
    topics = log.get("topics", [])

    if len(topics) < 3:
        continue

    amount = int(log.get("data", "0x0"), 16)

    entry = {
        "block": int(log["blockNumber"], 16),
        "transactionHash": log["transactionHash"],
        "logIndex": int(log["logIndex"], 16),
        "from": "0x" + topics[1][-40:],
        "to": "0x" + topics[2][-40:],
        "amountRaw": str(amount),
        "amountUSDr": amount_text(amount)
    }

    if topics[1].lower() == zero:
        mints.append(entry)
        mint_total += amount

    if topics[2].lower() == zero:
        burns.append(entry)
        burn_total += amount

print("\n=== SUPPLY GAP RECONCILIATION ===")
print("Transfer logs:", len(logs))
print("Mint events:", len(mints))
print("Burn events:", len(burns))
print("Total minted USDr:", amount_text(mint_total))
print("Total burned USDr:", amount_text(burn_total))
print("Net supply change:", amount_text(mint_total - burn_total))
print("Expected unexplained increase: 20010.000000000000000000")

print("\n=== MINT EVENTS ===")
print(json.dumps(mints, indent=2))

print("\n=== BURN EVENTS ===")
print(json.dumps(burns, indent=2))
PY

    local PY_STATUS=$?

    if [[ "$PY_STATUS" -ne 0 ]]; then
        echo "ERROR: Python analysis failed."
        return 1
    fi

    echo
    echo "SUCCESS: Reconciliation completed."
    echo "Combined raw logs: $OUT/supply-gap-transfer-logs.json"
    echo "Individual RPC responses: $OUT/supply-gap-transfer-part-1.json through part-3.json"

    return 0
}

main "$@"
