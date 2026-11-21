# Phase 4 — Historical USDr Supply and Escrow Reconstruction: Findings Report

**Project:** Rayls USDr 1:1 Backing Verification
**Network:** Rayls Mainnet
**Chain ID:** 72957
**Phase:** 4
**Evidence collection status:** Complete
**Report status:** Reviewed for publication
**Primary method:** Direct JSON-RPC retrieval and local analysis in GitHub Codespaces

---

## 1. Executive summary

Phase 4 investigated historical USDr supply changes, their relationship with USDC.e movements, the configured USDC.e escrow balance, the specific burn of 18,026.574051066495598471 USDr, and the October 1 correction transactions.

The investigation retrieved and analyzed historical logs, transactions, receipts, and selected historical contract state through direct JSON-RPC. It identified the 20,000 USDC.e deposit into the configured escrow and reconstructed the transaction sequence associated with the 18,026.574051066495598471 USDr burn.

At the verified post-correction checkpoint, direct historical state showed:

- Configured escrow USDC.e balance: **26,371.543449 USDC.e**
- Direct USDr totalSupply: **25,380.582077933504401529 USDr**
- Difference: **990.961371066495598471 USDC.e**

Thus, at that checkpoint, the configured escrow balance exceeded direct USDr totalSupply.

However, the investigation also found that a cumulative reconstruction from standard USDr Transfer events does not consistently match direct historical `totalSupply()` results. The discrepancy is not a minor rounding difference:

- At block 3,500,000, the event-derived supply exceeded direct totalSupply by **495,231.259606 USDr**.
- At block 3,569,194, the sampled difference was **+20,010 USDr**, with the same difference persisting at subsequent sampled checkpoints through the latest queried block.
- Blocks 3,569,193 and 3,569,194 contained no USDr logs and no transactions in the inspected results. The binary search therefore located a state/reconstruction boundary, not the transaction responsible for the discrepancy.

The underlying cause of this historical event/state inconsistency remains unresolved. Consequently, event-derived historical supply and shortfall figures must not be represented as independently confirmed direct contract state.

The evidence supports a measured correction of the configured escrow-versus-supply position at the October 1 checkpoint. It does not establish complete system-wide 1:1 backing across every possible reserve location, nor does it explain every historical supply change.

---

## 2. Fixed research questions

The following six questions are reproduced verbatim and in their original order.

1. What transactions caused USDr to be minted or burned?
2. Who initiated those transactions, and which contracts executed them?
3. Can each supply change be linked to a corresponding USDC.e movement?
4. What explains the 18,026.574051066495598471 USDr burn?
5. What caused the historical backing shortfall?
6. Did the October 1 correction transactions resolve that shortfall?

---

## 3. Methodology and evidence base

The investigation used direct JSON-RPC retrieval and local analysis in GitHub Codespaces. The evidence collection included:

- `eth_getLogs` for USDr, USDC.e, and relevant contract addresses.
- `eth_getTransactionByHash` for transaction sender, recipient, input, and block context.
- `eth_getTransactionReceipt` for execution status and emitted logs.
- `eth_getBlockByNumber` for block and transaction context.
- Historical `eth_call` requests for direct USDr `totalSupply()` and configured escrow USDC.e balances.
- Local scripts to decode, classify, reconcile, and preserve retrieved records.

The primary raw evidence is stored under:

`evidence/phase-4-one-pass-audit/`

Relevant files include:

- `usdr-all-events.json`
- `all-contract-logs.jsonl`
- `supply-events.json`
- `supply-events.csv`
- `event-reconstruction-summary.json`
- `historical-state-snapshots.jsonl`
- `historical-state-snapshots-retry.jsonl`
- `usdce-transfers-around-correction.json`
- `transactions-and-receipts.jsonl`
- `critical-transactions-retry.jsonl`
- `candidate-transactions.txt`
- `chain-id.json`
- `latest-block.json`

The reproducible investigation scripts are:

- `scripts/phase-4-one-pass-audit.sh`
- `scripts/phase-4-reconcile-supply-gap.sh`
- `scripts/phase-4-closeout-verification.sh`

The event reconstruction summary reports 14,484 scanned logs, 11,892 relevant Transfer logs in its configured scan, 359 supply-changing event records, and 524 unique candidate transactions. The 359 figure is an event-record count, not a count of unique supply-changing transactions.

A separate full-history USDr address scan retrieved 13,867 logs, including 12,345 standard Transfer logs. The event-replay analysis used unique Transfer records to avoid double-counting duplicate representations.

### Evidence classification

- **Confirmed:** Directly supported by retrieved blockchain data or reproduced calculations.
- **Supported interpretation:** Consistent with multiple evidence items but not conclusively established.
- **Unresolved:** Available evidence does not establish the cause or complete relationship.
- **Rejected:** Contradicted by verified evidence.

---

## 4. Findings by research question

### 4.1 What transactions caused USDr to be minted or burned?

**Finding: Confirmed in part; complete historical event/state reconciliation remains unresolved.**

The investigation retrieved the USDr Transfer history and classified mint and burn movements using the zero address as the source or destination. The full-history scan recorded 12,345 standard Transfer logs.

The event-derived cumulative figures at the latest queried block were:

| Measure | Event-derived amount |
|---|---:|
| Cumulative mint amount | 879,794.735235000029206276 USDr |
| Cumulative burn amount | 874,443.749507066444493830 USDr |
| Net event-derived supply | 5,350.985727933504401529 USDr |

The direct `totalSupply()` result at the latest queried block was:

**25,360.985727933504401529 USDr**

The difference was exactly:

**20,010 USDr**

The investigation also compared event-derived cumulative supply with direct historical `totalSupply()` at multiple blocks. It found a substantial earlier mismatch:

| Block | Event-derived supply | Direct totalSupply | Direct minus event-derived |
|---:|---:|---:|---:|
| 500,000 | 160,907.070870 | 0 | −160,907.070870 |
| 1,000,000 | 495,462.704358 | 231.444752 | −495,231.259606 |
| 2,000,000 | 767,610.339418 | 272,379.079812 | −495,231.259606 |
| 3,500,000 | 768,697.976374 | 273,466.716768 | −495,231.259606 |
| 4,000,000 | 818,643.274720 | 838,653.274720 | +20,010 |
| 11,500,000 | 5,370.582077933504401529 | 25,380.582077933504401529 | +20,010 |
| 14,904,852 | 5,350.985727933504401529 | 25,360.985727933504401529 | +20,010 |

All figures in this table are USDr. Values are shown at the precision returned or calculated in the investigation.

A binary-search diagnostic located block 3,569,194 as the first queried block at which the sampled difference equaled +20,010 USDr. The adjacent results were:

- Block 3,569,192: −495,231.259606 USDr
- Block 3,569,193: −495,231.259606 USDr
- Block 3,569,194: +20,010 USDr
- Block 3,569,195: +20,010 USDr
- Block 3,569,196: +20,010 USDr

The inspected blocks 3,569,193 and 3,569,194 returned no USDr logs and no transactions. The diagnostic therefore identifies a boundary in the sampled historical state/replay comparison; it does not identify a transaction or prove the cause of the change. The binary search also does not establish that the difference was monotonic at every intervening block.

A separate custom USDr event topic was checked against standard Transfer records. The deduplicated records matched standard Transfers in the same transactions, with the same recipient and amount. They should not be added to the supply reconstruction as independent mint or burn amounts.

**Assessment:** The event records provide a substantial historical transaction inventory, but a Transfer-only replay cannot be treated as a complete representation of direct USDr supply. The persistent +20,010 USDr difference and the earlier negative discrepancy remain unresolved. No unsupported explanation is assigned to either discrepancy.

### 4.2 Who initiated those transactions, and which contracts executed them?

**Finding: Confirmed for the specifically reconstructed correction and burn sequence; not every historical supply-changing transaction has been individually attributed.**

The investigation reconstructed the following sequence.

#### 20,000 USDC.e deposit

- Transaction: `0x802cdd6b480bfbdb02ea3c921671827b77a8582e7f03f3e1da4ceae1ee502c2c`
- Block: 11,362,694
- Sender: `0x0e301beef8daad28f8e38d9fce09112b78fe3161`
- Recipient: configured escrow `0xd19a5e28fed41fa289e92ae61b9bc5bd883db0d2`
- Amount: 20,000 USDC.e

#### Funding of the burn holder

- Transaction: `0x08dfa0ac555badc5b3b00a35f206bb20b23d2ba0a14e270a3be77fe884951636`
- Block: 11,365,915
- Sender: `0xab5309be3d6e228288da1f68df3f993a550dec7c`
- Recipient: `0x633ac5e2315b973417e8caa6b3ad2162e0461ce1`
- Amount: 18,026.574051066495598471 USDr
- The transaction transferred the exact amount to the eventual burn holder.

#### Controller approval

- Transaction: `0xd3d744e8b95c4bba308694bd8fb077b84d0d35c70970d2ab94d1c2b4399781a4`
- Block: 11,366,297
- Holder: `0x633ac5e2315b973417e8caa6b3ad2162e0461ce1`
- Spender/controller: `0x07e17e17e17e17e17e17e17e17e17e17e17e17e6`
- Amount approved: 18,026.574051066495598471 USDr
- Input selector: `0x095ea7b3`

#### Burn execution

- Transaction: `0x3e1fb4b25043bc55e208b29a601966710c6ddf2fec4edcd015b1550fb43cfa4a`
- Block: 11,366,604
- Transaction index: 0
- Transaction sender/initiator: `0x6b205d256e8a153cba8057e5655db56e0e47a511`
- Transaction recipient/controller: `0x07e17e17e17e17e17e17e17e17e17e17e17e17e6`
- Holder burned from: `0x633ac5e2315b973417e8caa6b3ad2162e0461ce1`
- Amount: 18,026.574051066495598471 USDr
- Input selector: `0x9dc29fac`
- Receipt status: successful

The USDr system token address `0x0000000000000000000000000000000000000400` emitted the standard Transfer from the holder to the zero address and the custom burn event. The controller also emitted an event recording the initiator and holder.

The USDr address behaves as a system/precompile token in the queried environment: `symbol()` returned `USDr`, `decimals()` returned 18, and `eth_getCode` returned `0x00`. It should not be described as an ordinary deployed token contract on the basis of this code response.

A preceding transaction, `0xa6b61b11e55b194d11a4d419b3964cd06355847fe3319e1645b4f5c7acee8435`, was sent by `0x6b205d256e8a153cba8057e5655db56e0e47a511` to the controller at block 11,366,001 and emitted a role-related event. Its input is consistent with a role-grant operation, but the function name should not be asserted without a verified ABI.

**Assessment:** The sender, controller, holder, funding transfer, approval, and successful burn execution are supported by transaction and receipt evidence. This reconstruction should not be generalized to every historical mint and burn without equivalent transaction-level attribution.

### 4.3 Can each supply change be linked to a corresponding USDC.e movement?

**Finding: Not established for every historical supply change. The correction sequence contains a directly observed USDC.e deposit followed by a separately observed USDr burn.**

The configured escrow was `0xd19a5e28fed41fa289e92ae61b9bc5bd883db0d2`.

The investigation found exactly one USDC.e transfer involving this escrow in the inspected block range 11,362,693–11,366,605: the 20,000 USDC.e deposit in transaction `0x802cdd6b480bfbdb02ea3c921671827b77a8582e7f03f3e1da4ceae1ee502c2c`.

Direct historical state reads around the correction showed:

| Block | Direct USDr totalSupply | Configured escrow USDC.e |
|---:|---:|---:|
| 11,362,693 | 43,407.156129 | 6,371.543449 |
| 11,366,000 | 43,407.156129 | 26,371.543449 |
| 11,366,001 | 43,407.156129 | 26,371.543449 |
| 11,366,603 | 43,407.156129 | 26,371.543449 |
| 11,366,604 | 25,380.582077933504401529 | 26,371.543449 |
| 11,366,605 | 25,380.582077933504401529 | 26,371.543449 |

The 20,000 USDC.e deposit increased the configured escrow balance. The subsequent burn reduced USDr supply and did not produce another USDC.e movement in the inspected escrow logs.

These events are temporally and operationally consistent with a correction sequence, but the evidence does not establish a one-to-one USDC.e movement for every historical mint or burn.

**Assessment:** The deposit and burn are independently evidenced. A complete transaction-by-transaction pairing of every historical USDr supply change with a corresponding USDC.e movement has not been established. The configured escrow is the measured reserve address in this investigation; this report does not assume it is necessarily the only reserve location in the system.

### 4.4 What explains the 18,026.574051066495598471 USDr burn?

**Finding: Confirmed transaction sequence and amount; the evidence does not by itself establish a broader business rationale.**

The holder `0x633ac5e2315b973417e8caa6b3ad2162e0461ce1` received exactly 18,026.574051066495598471 USDr in transaction:

`0x08dfa0ac555badc5b3b00a35f206bb20b23d2ba0a14e270a3be77fe884951636`

The holder then approved the controller `0x07e17e17e17e17e17e17e17e17e17e17e17e17e6` for that exact amount in transaction:

`0xd3d744e8b95c4bba308694bd8fb077b84d0d35c70970d2ab94d1c2b4399781a4`

The controller transaction was initiated by `0x6b205d256e8a153cba8057e5655db56e0e47a511` and executed successfully in transaction:

`0x3e1fb4b25043bc55e208b29a601966710c6ddf2fec4edcd015b1550fb43cfa4a`

The USDr system token emitted a Transfer from the holder to the zero address for exactly 18,026.574051066495598471 USDr.

Direct `totalSupply()` changed as follows:

- Before burn: 43,407.156129 USDr
- After burn: 25,380.582077933504401529 USDr
- Reduction: 18,026.574051066495598471 USDr

The supply reduction exactly matches the burn amount.

**Assessment:** The burn is not unexplained at the transaction level. Its funding, approval, initiator, controller, holder, successful execution, burn event, and exact supply reduction are established. The available evidence does not justify describing it as a redemption or bridge-out without additional proof of that business purpose.

### 4.5 What caused the historical backing shortfall?

**Finding: The measured shortfall was a mismatch between direct USDr supply and the configured escrow balance. The complete original cause remains unresolved.**

At block 11,362,693, before the 20,000 USDC.e deposit:

- Direct USDr totalSupply: 43,407.156129
- Configured escrow USDC.e: 6,371.543449
- Measured deficit: 37,035.612680

After the 20,000 USDC.e deposit, but before the burn:

- Direct USDr totalSupply: 43,407.156129
- Configured escrow USDC.e: 26,371.543449
- Measured deficit: 17,035.612680

The deposit reduced the measured deficit by exactly 20,000 USDC.e. The later burn reduced direct USDr supply by 18,026.574051066495598471 USDr.

The event-derived reconstruction separately reported a shortfall of 17,025.612680 USDC.e at block 11,147,588. That figure is an event-replay result at an earlier block and must not be substituted for the direct-state deficit measured at block 11,362,693.

The event reconstruction also reported a maximum historical shortfall of 767,610.339418 USDC.e. Because the event-derived supply does not consistently match direct historical `totalSupply()`, this maximum is an event-derived analytical result, not a verified maximum direct-state deficit.

The persistent event/state discrepancy prevents a complete, reliable historical supply reconstruction from standard Transfer logs alone. The investigation has not established the original sequence or mechanism that produced the entire historical mismatch. It has also not proven that the configured escrow address represents every reserve asset that should be included in a system-wide backing calculation.

**Assessment:** The measured shortfall at the investigated checkpoint is confirmed. The complete original cause of the historical shortfall is unresolved. The report does not attribute it to a particular mint, contract, operator, or missing reserve without evidence.

### 4.6 Did the October 1 correction transactions resolve that shortfall?

**Finding: Yes, for the measured configured-escrow-versus-direct-supply position at the verified post-correction checkpoint. System-wide backing is not established by this result alone.**

The correction sequence included:

1. A 20,000 USDC.e deposit into the configured escrow in transaction `0x802cdd6b480bfbdb02ea3c921671827b77a8582e7f03f3e1da4ceae1ee502c2c`.
2. A successful burn of 18,026.574051066495598471 USDr in transaction `0x3e1fb4b25043bc55e208b29a601966710c6ddf2fec4edcd015b1550fb43cfa4a`.

At block 11,366,604, direct historical state showed:

- Configured escrow USDC.e: 26,371.543449
- Direct USDr totalSupply: 25,380.582077933504401529
- Escrow excess over supply: 990.961371066495598471

The configured escrow balance therefore exceeded direct USDr totalSupply at this checkpoint.

The event-derived reconstruction reports a surplus of 21,000.961372 USDC.e at the corresponding burn event. That larger figure reflects the 20,010 USDr event/state discrepancy and is not the direct-state result. The direct-state calculation is used for the correction assessment in this report.

**Assessment:** The correction resolved the measured shortfall between the configured escrow balance and direct USDr totalSupply at the verified post-correction checkpoint. It does not prove complete system-wide 1:1 backing unless all relevant reserve locations and liabilities are accounted for.

---

## 5. Principal unresolved issue: historical event/state reconciliation

The most important technical limitation discovered in Phase 4 is the mismatch between cumulative standard Transfer-event replay and direct historical USDr `totalSupply()`.

The discrepancy is present at multiple historical checkpoints and changes between the sampled blocks 3,500,000 and 4,000,000. The binary-search diagnostic returned block 3,569,194 as the first queried block with a +20,010 USDr difference. However, the inspected blocks 3,569,193 and 3,569,194 contained no transactions and no USDr logs.

This means:

1. The event-derived history cannot be treated as a complete, independently reconciled supply ledger.
2. The +20,010 USDr difference must not be attributed to a specific mint or burn based only on the binary-search boundary.
3. The earlier −495,231.259606 USDr difference is a separate discrepancy and also remains unexplained.
4. The investigation does not establish whether these discrepancies arise from historical system-token behavior, changes in state representation, RPC historical-state semantics, incomplete event coverage, or another mechanism.

These are possible areas of explanation, not established causes.

The discrepancies are retained as explicit unresolved findings rather than being silently adjusted or forced into an event-derived reconciliation.

---

## 6. Overall conclusions

Phase 4 established the following:

- A substantial historical USDr event inventory was retrieved and analyzed.
- The 20,000 USDC.e escrow deposit was identified and verified.
- The 18,026.574051066495598471 USDr burn was reconstructed through funding, approval, controller initiation, successful execution, token events, and direct supply change.
- Direct historical state established a 37,035.612680 USDC.e deficit before the deposit at the investigated checkpoint.
- Direct historical state established a 990.961371066495598471 USDC.e excess of configured escrow balance over USDr totalSupply after the correction.
- The full historical cause of the shortfall and the event/state discrepancies remains unresolved.
- The investigation did not establish a corresponding USDC.e movement for every historical USDr supply change.
- The correction result is scoped to the configured escrow and the verified checkpoint; it is not a proof of complete system-wide backing.

**Phase 4 evidence collection is complete.** The unresolved historical event/state reconciliation issue is documented as a limitation and finding. It does not invalidate the directly verified correction transactions or the direct-state checkpoint calculation, but it limits claims based solely on historical event replay.

---

## 7. Reproducibility and publication notes

The raw evidence and scripts listed in Section 3 are retained in the repository working tree. RPC credentials must remain outside the repository.

Before publication:

- Review the raw evidence files for accidental RPC credentials or other secrets.
- Confirm that the scripts do not print or persist the RPC endpoint or credentials.
- Verify that the report's transaction hashes and numerical values match the preserved raw evidence.
- Keep the six research questions unchanged in any eventual article.
- Preserve the distinction between direct historical state and event-derived reconstruction.

No claim in this report should be interpreted as an independent audit opinion, proof of all system-wide reserves, or a finding of misconduct. The conclusions are limited to the network data, addresses, blocks, transactions, and state reads documented in the Phase 4 evidence.
