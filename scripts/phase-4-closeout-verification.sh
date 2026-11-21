#!/usr/bin/env bash
set -uo pipefail

: "${VC_RPC_URL:?VC_RPC_URL is not set}"

OUT="evidence/phase-4-one-pass-audit"
mkdir -p "$OUT"

USDR="0x0000000000000000000000000000000000000400"
USDCE="0x9001dbe4D68d36ab87923A2a9Dfb0c745fd25001"
ESCROW="0xD19A5e28FEd41FA289E92Ae61B9Bc5BD883DB0D2"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

rpc() {
  local method="$1"
  local params="$2"
  local output="$3"

  local payload
  payload=$(jq -nc --arg m "$method" --argjson p "$params" \
    '{jsonrpc:"2.0",method:$m,params:$p,id:1}')

  local status
  status=$(curl -sS --max-time 90 \
    -o "$output" -w '%{http_code}' \
    "$VC_RPC_URL" \
    -H "Content-Type: application/json" \
    --data "$payload") || true

  if jq -e . "$output" >/dev/null 2>&1; then
    jq --arg http "$status" '. + {httpStatus:$http}' "$output"
  else
    jq -n --arg http "$status" \
      --rawfile body "$output" \
      '{httpStatus:$http,rawResponse:$body}'
  fi
}

echo "=== A. HISTORICAL STATE QUERY DIAGNOSTICS ==="

SNAPSHOTS="$OUT/historical-state-snapshots-retry.jsonl"
: > "$SNAPSHOTS"

BALANCE_DATA="0x70a08231$(printf '%064s' "${ESCROW#0x}" | tr ' ' '0')"

for BLOCK in 11362693 11366000 11366001 11366603 11366604 11366605 14797239 latest; do
  if [[ "$BLOCK" == "latest" ]]; then
    TAG="latest"
  else
    TAG=$(printf '0x%x' "$BLOCK")
  fi

  echo
  echo "--- Block $BLOCK ($TAG) ---"

  rpc eth_getBlockByNumber "[\"$TAG\",false]" "$TMP/block.json" \
    > "$TMP/block-result.json"

  rpc eth_call \
    "[{\"to\":\"$USDR\",\"data\":\"0x18160ddd\"},\"$TAG\"]" \
    "$TMP/supply.json" > "$TMP/supply-result.json"

  rpc eth_call \
    "[{\"to\":\"$USDCE\",\"data\":\"$BALANCE_DATA\"},\"$TAG\"]" \
    "$TMP/balance.json" > "$TMP/balance-result.json"

  jq -cn \
    --arg block "$BLOCK" \
    --slurpfile b "$TMP/block-result.json" \
    --slurpfile s "$TMP/supply-result.json" \
    --slurpfile e "$TMP/balance-result.json" \
    '{block:$block,
      blockResult:$b[0],
      supplyResult:$s[0],
      escrowBalanceResult:$e[0]}' \
    | tee -a "$SNAPSHOTS"
done

echo
echo "=== B. BURN AND CORRECTION TRANSACTION EVIDENCE ==="

TXS=(
  0x3e1fb4b25043bc55e208b29a601966710c6ddf2fec4edcd015b1550fb43cfa4a
  0xa6b61b11e55b194d11a4d419b3964cd06355847fe3319e1645b4f5c7acee8435
  0x08dfa0ac555badc5b3b00a35f206bb20b23d2ba0a14e270a3be77fe884951636
  0xd3d744e8b95c4bba308694bd8fb077b84d0d35c70970d2ab94d1c2b4399781a4
  0x38e6bae11b4b24bee66e71d51dc00a6c65c362165df9851af60496ade550ea09
  0xd29ca43f0672e003d64c39a74b87548c33accf23bd6d157df48d7323062e5a28
  0x59ac69033d0d1f86d0443bd3614b4a6788dea559c7062304ee2ccc61c9b218f3
)

TXOUT="$OUT/critical-transactions-retry.jsonl"
: > "$TXOUT"

for TX in "${TXS[@]}"; do
  rpc eth_getTransactionByHash "[\"$TX\"]" "$TMP/tx.json" \
    > "$TMP/tx-result.json"

  rpc eth_getTransactionReceipt "[\"$TX\"]" "$TMP/receipt.json" \
    > "$TMP/receipt-result.json"

  jq -cn \
    --arg hash "$TX" \
    --slurpfile t "$TMP/tx-result.json" \
    --slurpfile r "$TMP/receipt-result.json" \
    '{hash:$hash,transaction:$t[0],receipt:$r[0]}' \
    | tee -a "$TXOUT"
done

echo
echo "=== C. USDC.e TRANSFERS AROUND THE BURN ==="

node - "$OUT/all-contract-logs.jsonl" "$OUT" "$USDCE" "$ESCROW" <<'NODE'
const fs = require("fs");

const [,, rawPath, outDir, token, escrow] = process.argv;
const lower = x => (x || "").toLowerCase();
const ZERO = "0x0000000000000000000000000000000000000000";
const TRANSFER =
  "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef";

const logs = fs.readFileSync(rawPath, "utf8")
  .split(/\r?\n/).filter(Boolean).map(JSON.parse);

const targetBlock = 11366604;
const fromBlock = 11362693;
const toBlock = 11366605;

const rows = logs.filter(l =>
  lower(l.address) === lower(token) &&
  lower(l.topics?.[0]) === TRANSFER &&
  Number(BigInt(l.blockNumber)) >= fromBlock &&
  Number(BigInt(l.blockNumber)) <= toBlock
).map(l => ({
  block: Number(BigInt(l.blockNumber)),
  transactionHash: l.transactionHash,
  logIndex: l.logIndex,
  from: "0x" + l.topics[1].slice(-40),
  to: "0x" + l.topics[2].slice(-40),
  amountRaw: BigInt(l.data).toString(),
  amountUSDCe: (Number(BigInt(l.data)) / 1e6).toFixed(6),
  involvesConfiguredEscrow:
    lower("0x" + l.topics[1].slice(-40)) === lower(escrow) ||
    lower("0x" + l.topics[2].slice(-40)) === lower(escrow)
}));

fs.writeFileSync(
  `${outDir}/usdce-transfers-around-correction.json`,
  JSON.stringify(rows, null, 2)
);

console.log(JSON.stringify({
  interval: `${fromBlock}–${toBlock}`,
  correctionBlock: targetBlock,
  transferCount: rows.length,
  transfersInvolvingConfiguredEscrow:
    rows.filter(x => x.involvesConfiguredEscrow).length,
  transfers: rows
}, null, 2));
NODE

echo
echo "=== D. EXISTING AUDIT SUMMARY ==="

jq '{
  totalLogsScanned,
  relevantTransferLogs,
  supplyChangingTransactions,
  uniqueCandidateTransactions,
  finalEventDerivedSupplyUSDr,
  finalEventDerivedEscrowUSDCe,
  firstObservedShortfall,
  lastObservedShortfall,
  firstObservedReturnToNoShortfall,
  maximumObservedShortfallUSDCe
}' "$OUT/event-reconstruction-summary.json"

echo
echo "=== E. OUTPUT FILES ==="

find "$OUT" -maxdepth 1 -type f -printf '%f (%s bytes)\n' | sort

echo
echo "=== GIT STATUS ==="
git status --short

echo
echo "CLOSEOUT VERIFICATION FINISHED."
