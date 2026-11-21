#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# RAYLS USDr PHASE 4 — ONE-PASS HISTORICAL AUDIT
# Network: Rayls Mainnet, chain ID 72957
# Read-only JSON-RPC. No transactions are submitted.
# ============================================================

: "${VC_RPC_URL:?VC_RPC_URL is not set}"

USDR="0x0000000000000000000000000000000000000400"
USDCE="0x9001dbe4D68d36ab87923A2a9Dfb0c745fd25001"
ESCROW="0xD19A5e28FEd41FA289E92Ae61B9Bc5BD883DB0D2"
CONTROLLER="0x07E17E17e17E17E17e17e17e17e17e17E17E17E6"
BRIDGEOUT="0xF5Df832527A452b7a6e3B7E3CdD3d67249eC03A7"

ZERO="0x0000000000000000000000000000000000000000"
TRANSFER_TOPIC="0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"

OUT="evidence/phase-4-one-pass-audit"
mkdir -p "$OUT"

RAW="$OUT/all-contract-logs.jsonl"
: > "$RAW"

rpc() {
  curl -fsS --max-time 120 "$VC_RPC_URL" \
    -H "Content-Type: application/json" \
    --data "$1"
}

rpc_method() {
  local method="$1"
  local params="$2"
  rpc "$(jq -nc --arg m "$method" --argjson p "$params" \
    '{jsonrpc:"2.0",method:$m,params:$p,id:1}')"
}

echo
echo "=== 1. NETWORK IDENTITY ==="

CHAIN=$(rpc_method eth_chainId '[]')
echo "$CHAIN" | tee "$OUT/chain-id.json"

CHAIN_ID=$(echo "$CHAIN" | jq -r '.result // empty')
if [[ "$CHAIN_ID" != "0x11cfd" ]]; then
  echo "ERROR: Expected Rayls chain ID 72957 (0x11cfd)."
  exit 1
fi

LATEST=$(rpc_method eth_blockNumber '[]')
echo "$LATEST" | tee "$OUT/latest-block.json"

LATEST_HEX=$(echo "$LATEST" | jq -r '.result')
LATEST_DEC=$((LATEST_HEX))

echo "Rayls chain verified."
echo "Latest block: $LATEST_HEX ($LATEST_DEC)"

echo
echo "=== 2. FULL-HISTORY EVENT COLLECTION ==="
echo "Scanning from genesis to latest block."
echo "Contracts: USDr precompile, USDC.e, escrow, controller, bridge-out."

ADDRESSES=$(jq -nc \
  --arg a "$USDR" \
  --arg b "$USDCE" \
  --arg c "$ESCROW" \
  --arg d "$CONTROLLER" \
  --arg e "$BRIDGEOUT" \
  '[$a,$b,$c,$d,$e]')

START=0
STEP=50000
COUNT=0

while (( START <= LATEST_DEC )); do
  END=$((START + STEP - 1))
  (( END > LATEST_DEC )) && END=$LATEST_DEC

  FROM_HEX=$(printf '0x%x' "$START")
  TO_HEX=$(printf '0x%x' "$END")

  PAYLOAD=$(jq -nc \
    --arg from "$FROM_HEX" \
    --arg to "$TO_HEX" \
    --argjson addresses "$ADDRESSES" \
    '{jsonrpc:"2.0",method:"eth_getLogs",
      params:[{fromBlock:$from,toBlock:$to,address:$addresses}],id:1}')

  RESPONSE=$(curl -sS --max-time 120 "$VC_RPC_URL" \
    -H "Content-Type: application/json" \
    --data "$PAYLOAD")

  if ! echo "$RESPONSE" | jq -e '.result | type == "array"' >/dev/null 2>&1; then
    echo "RPC range error at $FROM_HEX - $TO_HEX"

    if (( STEP <= 1000 )); then
      echo "$RESPONSE" > "$OUT/failed-range.json"
      echo "Unable to scan this range. Raw error saved."
      exit 1
    fi

    STEP=$((STEP / 2))
    echo "Reducing chunk size to $STEP blocks and retrying."
    continue
  fi

  echo "$RESPONSE" | jq -c '.result[]' >> "$RAW"

  COUNT=$((COUNT + 1))
  if (( COUNT % 10 == 0 )); then
    echo "Scanned through block $TO_HEX"
  fi

  START=$((END + 1))

  if (( STEP < 50000 )); then
    STEP=$((STEP * 2))
    (( STEP > 50000 )) && STEP=50000
  fi

  sleep 0.05
done

echo
echo "Full-history log collection completed."
echo "Raw logs: $RAW"
echo "Log count: $(wc -l < "$RAW")"

echo
echo "=== 3. DECODE AND RECONSTRUCT SUPPLY/BACKING EVENTS ==="

node - "$RAW" "$OUT" "$USDR" "$USDCE" "$ESCROW" "$CONTROLLER" "$BRIDGEOUT" <<'NODE'
const fs = require("fs");

const [,, rawPath, outDir, usdrAddr, usdceAddr, escrowAddr,
       controllerAddr, bridgeoutAddr] = process.argv;

const lower = x => (x || "").toLowerCase();
const USDR = lower(usdrAddr);
const USDCE = lower(usdceAddr);
const ESCROW = lower(escrowAddr);
const CONTROLLER = lower(controllerAddr);
const BRIDGEOUT = lower(bridgeoutAddr);
const ZERO = "0x0000000000000000000000000000000000000000";
const TRANSFER =
  "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef";

const logs = fs.readFileSync(rawPath, "utf8")
  .split(/\r?\n/)
  .filter(Boolean)
  .map(x => JSON.parse(x));

const addr = topic => "0x" + topic.slice(-40).toLowerCase();

const relevant = logs.filter(l => {
  const a = lower(l.address);
  return (a === USDR || a === USDCE) &&
    lower(l.topics?.[0]) === TRANSFER &&
    l.topics.length >= 3;
});

relevant.sort((a,b) => {
  const blockA = BigInt(a.blockNumber);
  const blockB = BigInt(b.blockNumber);
  if (blockA !== blockB) return blockA < blockB ? -1 : 1;

  const txA = BigInt(a.transactionIndex || "0x0");
  const txB = BigInt(b.transactionIndex || "0x0");
  if (txA !== txB) return txA < txB ? -1 : 1;

  const logA = BigInt(a.logIndex || "0x0");
  const logB = BigInt(b.logIndex || "0x0");
  return logA < logB ? -1 : logA > logB ? 1 : 0;
});

let supply = 0n;
let escrowBalance = 0n;
let maxShortfall = 0n;
let firstShortfall = null;
let lastShortfall = null;
let resolution = null;

const supplyEvents = [];
const csv = [
  "block,transactionHash,event,amountRaw,supplyRaw,escrowUsdceRaw,shortfallUsdceRaw,surplusUsdceRaw"
];

const candidateTx = new Set();

function decimal(raw, places) {
  const neg = raw < 0n;
  let n = neg ? -raw : raw;
  const base = 10n ** BigInt(places);
  const whole = n / base;
  const fraction = (n % base).toString().padStart(places, "0");
  return (neg ? "-" : "") + whole.toString() + "." + fraction;
}

for (const l of relevant) {
  const contract = lower(l.address);
  const from = addr(l.topics[1]);
  const to = addr(l.topics[2]);
  const amount = BigInt(l.data || "0x0");
  let event = null;

  if (contract === USDR) {
    if (from === ZERO) {
      supply += amount;
      event = "USDr_MINT";
    } else if (to === ZERO) {
      supply -= amount;
      event = "USDr_BURN";
    }
  }

  if (contract === USDCE) {
    if (to === ESCROW) escrowBalance += amount;
    if (from === ESCROW) escrowBalance -= amount;
  }

  if (event) {
    candidateTx.add(l.transactionHash);

    const requiredUsdceRaw = supply / (10n ** 12n);
    const shortfall = requiredUsdceRaw > escrowBalance
      ? requiredUsdceRaw - escrowBalance : 0n;
    const surplus = escrowBalance > requiredUsdceRaw
      ? escrowBalance - requiredUsdceRaw : 0n;

    const row = {
      block: Number(BigInt(l.blockNumber)),
      transactionHash: l.transactionHash,
      transactionIndex: l.transactionIndex,
      logIndex: l.logIndex,
      event,
      from,
      to,
      amountRaw: amount.toString(),
      amountUSDr: decimal(amount, 18),
      supplyRaw: supply.toString(),
      supplyUSDr: decimal(supply, 18),
      escrowRaw: escrowBalance.toString(),
      escrowUSDCe: decimal(escrowBalance, 6),
      requiredBackingUSDCe: decimal(requiredUsdceRaw, 6),
      shortfallUSDCe: decimal(shortfall, 6),
      surplusUSDCe: decimal(surplus, 6)
    };

    supplyEvents.push(row);

    csv.push([
      row.block, row.transactionHash, event, amount.toString(),
      supply.toString(), escrowBalance.toString(),
      shortfall.toString(), surplus.toString()
    ].join(","));

    if (shortfall > 0n) {
      if (firstShortfall === null) firstShortfall = row;
      lastShortfall = row;
      if (shortfall > maxShortfall) maxShortfall = shortfall;
      resolution = null;
    } else if (firstShortfall !== null && resolution === null) {
      resolution = row;
    }
  }
}

// Include relevant contract activity and the historical range from the
// recent investigation, so transaction senders/calldata can be recovered.
for (const l of logs) {
  const a = lower(l.address);
  const block = Number(BigInt(l.blockNumber));
  const isHistoricalRange = block >= 0x124f80 && block <= 0x133d29;
  const isUsdrTransfer = a === USDR &&
    lower(l.topics?.[0]) === TRANSFER;

  if (a === CONTROLLER || a === ESCROW || a === BRIDGEOUT ||
      (a === USDCE && lower(l.topics?.[0]) === TRANSFER) ||
      (isHistoricalRange && isUsdrTransfer)) {
    candidateTx.add(l.transactionHash);
  }
}

fs.writeFileSync(
  `${outDir}/supply-events.json`,
  JSON.stringify(supplyEvents, null, 2)
);
fs.writeFileSync(`${outDir}/supply-events.csv`, csv.join("\n") + "\n");
fs.writeFileSync(
  `${outDir}/candidate-transactions.txt`,
  [...candidateTx].filter(Boolean).sort().join("\n") + "\n"
);

const summary = {
  totalLogsScanned: logs.length,
  relevantTransferLogs: relevant.length,
  supplyChangingTransactions: supplyEvents.length,
  uniqueCandidateTransactions: candidateTx.size,
  finalEventDerivedSupplyUSDr: decimal(supply,18),
  finalEventDerivedEscrowUSDCe: decimal(escrowBalance,6),
  firstObservedShortfall: firstShortfall,
  lastObservedShortfall: lastShortfall,
  firstObservedReturnToNoShortfall: resolution,
  maximumObservedShortfallUSDCe: decimal(maxShortfall,6),
  warning:
    "Event-derived reconstruction assumes the scan includes the complete relevant event history and that these contracts emit standard Transfer events for all balance changes. Compare against historical eth_call snapshots."
};

fs.writeFileSync(
  `${outDir}/event-reconstruction-summary.json`,
  JSON.stringify(summary, null, 2)
);

console.log(JSON.stringify(summary, null, 2));
NODE

echo
echo "=== 4. FETCH TRANSACTION DETAILS AND RECEIPTS ==="

cat >> "$OUT/candidate-transactions.txt" <<'TX'
0x3e1fb4b25043bc55e208b29a601966710c6ddf2fec4edcd015b1550fb43cfa4a
0xa6b61b11e55b194d11a4d419b3964cd06355847fe3319e1645b4f5c7acee8435
0x08dfa0ac555badc5b3b00a35f206bb20b23d2ba0a14e270a3be77fe884951636
0xd3d744e8b95c4bba308694bd8fb077b84d0d35c70970d2ab94d1c2b4399781a4
0x38e6bae11b4b24bee66e71d51dc00a6c65c362165df9851af60496ade550ea09
0xd29ca43f0672e003d64c39a74b87548c33accf23bd6d157df48d7323062e5a28
0x59ac69033d0d1f86d0443bd3614b4a6788dea559c7062304ee2ccc61c9b218f3
0x097b640d93fb203f2bbcae27b6e0a4892f7dd1dd1acca1ccde5c529b0aad7ffb
0x8735426f04ba432e865049cd5bdfca58e9d5b51f92a60413b4eeb1b39d76eca7
TX

sort -u "$OUT/candidate-transactions.txt" -o "$OUT/candidate-transactions.txt"

: > "$OUT/transactions-and-receipts.jsonl"

TOTAL=$(wc -l < "$OUT/candidate-transactions.txt")
INDEX=0

while read -r TX; do
  [[ -z "$TX" ]] && continue
  INDEX=$((INDEX + 1))

  TX_RESULT=$(rpc_method eth_getTransactionByHash "[\"$TX\"]")
  RECEIPT=$(rpc_method eth_getTransactionReceipt "[\"$TX\"]")

  jq -cn \
    --arg hash "$TX" \
    --argjson transaction "$TX_RESULT" \
    --argjson receipt "$RECEIPT" \
    '{hash:$hash,transaction:$transaction.result,receipt:$receipt.result,
      transactionError:$transaction.error,receiptError:$receipt.error}' \
    >> "$OUT/transactions-and-receipts.jsonl"

  if (( INDEX % 20 == 0 )); then
    echo "Fetched $INDEX / $TOTAL transaction records"
  fi

  sleep 0.05
done < "$OUT/candidate-transactions.txt"

echo "Transaction records saved."

echo
echo "=== 5. HISTORICAL STATE SNAPSHOTS ==="

: > "$OUT/historical-state-snapshots.jsonl"

# Known research checkpoints:
# - Before October 1 additional-minter grant
# - Grant block
# - Before and after the 18,026.574... USDr burn
# - Phase 3 pinned snapshot
# - Latest state

for BLOCK in 11362693 11366000 11366001 11366603 11366604 11366605 14797239; do
  BLOCK_HEX=$(printf '0x%x' "$BLOCK")

  SUPPLY=$(rpc_method eth_call \
    "[{\"to\":\"$USDR\",\"data\":\"0x18160ddd\"},\"$BLOCK_HEX\"]")

  ESCROW_BALANCE=$(rpc_method eth_call \
    "[{\"to\":\"$USDCE\",\"data\":\"0x70a08231$(printf '%064s' \"${ESCROW#0x}\" | tr ' ' '0')\"},\"$BLOCK_HEX\"]")

  jq -cn \
    --arg block "$BLOCK" \
    --arg blockHex "$BLOCK_HEX" \
    --argjson supply "$SUPPLY" \
    --argjson escrowBalance "$ESCROW_BALANCE" \
    '{block:$block,blockHex:$blockHex,
      usdrTotalSupply:$supply.result,
      usdrSupplyError:$supply.error,
      usdceEscrowBalance:$escrowBalance.result,
      usdceBalanceError:$escrowBalance.error}' \
    >> "$OUT/historical-state-snapshots.jsonl"

  echo "Snapshot queried at block $BLOCK ($BLOCK_HEX)"
done

LATEST_SUPPLY=$(rpc_method eth_call \
  "[{\"to\":\"$USDR\",\"data\":\"0x18160ddd\"},\"latest\"]")

LATEST_ESCROW=$(rpc_method eth_call \
  "[{\"to\":\"$USDCE\",\"data\":\"0x70a08231$(printf '%064s' \"${ESCROW#0x}\" | tr ' ' '0')\"},\"latest\"]")

jq -cn \
  --argjson supply "$LATEST_SUPPLY" \
  --argjson escrow "$LATEST_ESCROW" \
  '{block:"latest",usdrTotalSupply:$supply.result,
    usdrSupplyError:$supply.error,
    usdceEscrowBalance:$escrow.result,
    usdceBalanceError:$escrow.error}' \
  >> "$OUT/historical-state-snapshots.jsonl"

echo
echo "=== 6. CONTRACT AND PRECOMPILE IDENTITY ==="

: > "$OUT/contract-identity.jsonl"

for ADDRESS in "$USDR" "$USDCE" "$ESCROW" "$CONTROLLER" "$BRIDGEOUT" \
               "0x9b65aa6516d7493727f7465f03ccdfc3500c8393" \
               "0x3bffb10f6f17f15164fbc0416f1bc42c56b2c191"; do

  CODE=$(rpc_method eth_getCode "[\"$ADDRESS\",\"latest\"]")

  jq -cn --arg address "$ADDRESS" --argjson code "$CODE" \
    '{address:$address,code:$code.result,error:$code.error}' \
    >> "$OUT/contract-identity.jsonl"
done

SYMBOL=$(rpc_method eth_call "[{\"to\":\"$USDR\",\"data\":\"0x95d89b41\"},\"latest\"]")
DECIMALS=$(rpc_method eth_call "[{\"to\":\"$USDR\",\"data\":\"0x313ce567\"},\"latest\"]")

jq -n \
  --argjson symbol "$SYMBOL" \
  --argjson decimals "$DECIMALS" \
  '{symbol:$symbol.result,decimals:$decimals.result}' \
  > "$OUT/usdr-metadata.json"

echo
echo "=== 7. COMPLETION ==="

echo "Evidence directory: $OUT"
echo
echo "Files created:"
find "$OUT" -maxdepth 1 -type f -printf '%f (%s bytes)\n' | sort

echo
echo "Git status (no commit or push performed):"
git status --short

echo
echo "PHASE 4 ONE-PASS AUDIT FINISHED."
