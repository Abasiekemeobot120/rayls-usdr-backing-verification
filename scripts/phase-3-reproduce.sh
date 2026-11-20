
#!/usr/bin/env bash
set -euo pipefail

# Phase 3 historical RPC reproduction.
# Commands reconstructed from the published Phase 3 evidence.
# Does not print or embed the RPC endpoint credential.

: "${FRPC_URL:?Set FRPC_URL in your environment before running this script}"

BLOCK="0xe1c9b7"

USDC_E="0x9001dbe4D68d36ab87923A2a9Dfb0c745fd25001"
USDR="0x0000000000000000000000000000000000000400"
ESCROW="0xD19A5e28FEd41FA289E92Ae61B9Bc5BD883DB0D2"

rpc_call() {
    local label="$1"
    local address="$2"
    local calldata="$3"
    local response

    printf '\n--- %s ---\n' "$label"

    response=$(curl --silent --show-error --fail \
        -H "Content-Type: application/json" \
        --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$address\",\"data\":\"$calldata\"},\"$BLOCK\"],\"id\":1}" \
        "$FRPC_URL" 2>/dev/null) || {
        printf 'RPC request failed: %s\n' "$label" >&2
        return 1
    }

    printf '%s\n' "$response"
}

printf 'Phase 3 historical reads at block %s\n' "$BLOCK"

rpc_call "USDC.e decimals" "$USDC_E" "0x313ce567"
rpc_call "USDC.e escrow balance" "$USDC_E" "0x70a08231000000000000000000000000d19a5e28fed41fa289e92ae61b9bc5bd883db0d2"
rpc_call "USDC.e total supply" "$USDC_E" "0x18160ddd"

rpc_call "USDr decimals" "$USDR" "0x313ce567"
rpc_call "USDr total supply" "$USDR" "0x18160ddd"

rpc_call "Escrow circulatingUsdr" "$ESCROW" "0x2f4f83af"
rpc_call "Escrow requiredUsdceBacking" "$ESCROW" "0x6d0dc771"
rpc_call "Escrow withdrawableSurplus" "$ESCROW" "0xb6739070"

printf '\nReproduction requests completed.\n'
