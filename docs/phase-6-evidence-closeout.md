# Phase 6 — USDr Evidence Closeout and Provenance Assessment

## 1. Purpose and scope

Phase 6 consolidates the evidence collected during Phases 1–5 into a single closeout record. It assesses the consistency of the retained on-chain data, records material findings and limitations, and defines the claims that can safely proceed to independent review.

This phase does not conduct a new broad chain scan. It relies on the retained documentation, RPC transcripts, transaction receipts, historical snapshots, and event datasets in this repository.

The six Phase 4 research questions remain authoritative and are reproduced in the Phase 4 findings report. They are not rewritten or reordered here.

## 2. Principal finding: persistent 20,010 USDr supply difference

At every one of the eight retained historical snapshots, direct USDr `totalSupply()` exceeds the supply reconstructed from the retained mint and burn event dataset by exactly 20,010 USDr.

| Snapshot block | Direct supply (USDr) | Event-reconstructed supply (USDr) | Difference (USDr) |
|---:|---:|---:|---:|
| 11,362,693 | 43,407.156129 | 23,397.156129 | 20,010 |
| 11,366,000 | 43,407.156129 | 23,397.156129 | 20,010 |
| 11,366,001 | 43,407.156129 | 23,397.156129 | 20,010 |
| 11,366,603 | 43,407.156129 | 23,397.156129 | 20,010 |
| 11,366,604 | 25,380.582077933504401529 | 5,370.582077933504401529 | 20,010 |
| 11,366,605 | 25,380.582077933504401529 | 5,370.582077933504401529 | 20,010 |
| 14,797,239 | 25,357.786154933504401529 | 5,347.786154933504401529 | 20,010 |
| Latest retained snapshot | 25,360.985727933504401529 | 5,350.985727933504401529 | 20,010 |

The earliest retained checkpoint is block 11,362,693. The evidence therefore establishes that the difference was already present by that checkpoint and remained constant across the retained snapshots. It does not establish when or how the difference originated before the earliest retained checkpoint.

The difference also remains constant across the large burn at block 11,366,604. This indicates that the event reconstruction tracks the subsequent supply movement while retaining the same baseline difference.

**Interpretation boundary:** the 20,010 USDr component is unexplained by the retained event reconstruction. The available evidence does not establish whether it represents an initial allocation, an earlier issuance, a historical state/accounting distinction, or another cause. None of these explanations should be asserted as fact without additional evidence.

## 3. Mint and burn event provenance audit

The retained event reconstruction contains 359 USDr mint/burn records:

- 251 `USDr_MINT` records.
- 108 `USDr_BURN` records.

A comparison against raw standard ERC-20 Transfer logs emitted by the USDr precompile address `0x0000000000000000000000000000000000000400` found:

- 359 raw zero-address mint/burn Transfer logs.
- 359 reconstructed mint/burn records.
- Zero raw entries missing from the reconstruction.
- Zero reconstructed entries missing from the raw-log comparison.
- Exact aggregate raw-amount agreement for both mint and burn directions.

The aggregate raw amounts matched exactly:

| Direction | Raw Transfer total | Reconstructed total | Difference |
|---|---:|---:|---:|
| Mint | 879794735235000000000000 | 879794735235000000000000 | 0 |
| Burn | 874443749507066495598471 | 874443749507066495598471 | 0 |

This supports the completeness and amount accuracy of the retained mint/burn event reconstruction relative to the retained raw-log dataset.

It does not independently prove that the raw-log dataset contains every relevant historical log from the chain. It also does not explain the constant 20,010 USDr difference.

## 4. Pinned-block state reconciliation

At pinned block `0xe1c9b7` (decimal 14,797,239), the retained direct RPC observations were:

- Block hash: `0x64156f9f6a5339bff36597e2aeb73d65970a7ca43c8806041b0864c435f89830`
- Direct USDr `totalSupply()`: 25,357.786154933504401529 USDr.
- Event-reconstructed supply: 5,347.786154933504401529 USDr.
- Direct escrow USDC.e balance: 26,348.747526 USDC.e.
- Event-reconstructed escrow balance: 26,348.747526 USDC.e.

The reconstructed escrow balance agrees exactly with the direct escrow balance at this checkpoint. The reconstructed supply remains lower than direct supply by 20,010 USDr.

This distinction matters: the retained USDC.e event reconstruction agrees with the direct escrow balance at the pinned block, while the retained USDr supply reconstruction does not agree with direct `totalSupply()`.

The escrow balance match does not, by itself, resolve the correct supply denominator or prove the full historical 1:1 backing relationship.

## 5. Historical totalSupply() observation at block 7,823

At block 7,823, the retained investigation found 45 USDr mint records in the first observed mint transaction:

`0xa6fae1913e0acb00842b432bfde3c5cb4f544324fdfec6d64aa27c52d9a4adb0`

The cumulative event-reconstructed supply after those records was 66,117.621055 USDr.

However, historical `eth_call` requests to `totalSupply()` on the USDr precompile returned zero at blocks 7,822, 7,823, and 7,824. Historical `balanceOf()` observations for recipients reflected balances consistent with the mint records.

This is a historical precompile/state observation that limits reliance on historical `totalSupply()` as an independent arbiter of early supply. The evidence does not establish the underlying implementation reason.

The early-block observation should not be conflated with the later, persistent 20,010 USDr difference across the eight retained snapshots.

## 6. Representative redemption-path transaction

The retained trace for:

`0xad4cdec49113957c8141537651bc4b468f78d37bc1ded6b447f129e5f871bf93`

shows a coordinated sequence involving the USDr escrow, the USDr precompile, the controller, and USDC.e.

The relevant amounts were:

- USDr transferred to escrow: 0.0001 USDr.
- USDr burned from escrow: 0.0001 USDr.
- USDC.e released from escrow: 0.0001 USDC.e.
- USDC.e subsequently transferred to another contract and burned.

The trace supports the existence of a coordinated USDr burn and USDC.e movement in this transaction. The exact business meaning of every custom call and event remains subject to ABI/source verification. The custom selector `0xf5bb7513` was not resolved to a verified function signature.

This transaction is a representative execution trace, not proof that every mint or burn follows the same path. It does not explain the 20,010 USDr supply difference.

## 7. Phase 5 access-control findings

Phase 5 examined the NativeTokenController role configuration and the historical burn path.

The retained evidence supports these conclusions:

- The controller uses `MINTER_ROLE`, administered through `DEFAULT_ADMIN_ROLE`.
- The additional minter address `0x6b205d256e8a153cba8057e5655db56e0e47a511` held administrative authority before granting itself `MINTER_ROLE`.
- The self-grant was therefore supported by its existing administrative role; the evidence does not establish an unauthorized privilege escalation.
- An `eth_call` simulation showed that the additional minter could call the controller's direct mint path at the tested state.
- A simulated call from an unprivileged address was rejected by access control.
- A historical controller burn transaction succeeded at block 11,366,604.
- A later burn simulation failed the allowance check at the tested state. This does not invalidate the historical successful burn.
- The historical burn's economic purpose is not established solely by the burn transaction or role evidence.

The simulations demonstrate behavior at the queried state; they are not additional executed transactions. The Phase 5 findings report and evidence register contain the detailed identifiers and supporting observations.

## 8. Precompile and ABI/source limitations

The USDr native-token interface was queried at `0x0000000000000000000000000000000000000400`. Its observed symbol is `USDr`, its decimals value is 18, and `eth_getCode` returned `0x00`.

The investigation identified standard Transfer and Approval topics and custom event topics, including:

`0xcc16f5dbb4873280815c1ee09dbd06736cffcc184412cf7a71a0fdb75d397ca5`

The custom event signature has not been verified against an authoritative ABI or source definition. The repository did not contain Solidity source or ABI files sufficient to establish all custom function and event semantics.

Accordingly:
- Do not infer custom function names from selectors without verified ABI evidence.
- Do not assign business meaning to unknown custom event topics solely from their indexed fields or transaction context.
- Do not claim an independently verified deployed-source match for the escrow implementation.
- Treat precompile behavior and historical RPC results as observed evidence, with the relevant method/state limitations recorded.

## 9. What the evidence establishes

The retained evidence supports the following statements:

1. The documented escrow model and its on-chain components can be investigated through direct RPC state reads, event reconstruction, receipts, and transaction traces.
2. The retained USDC.e escrow event reconstruction matches the direct escrow balance at the pinned checkpoint.
3. The retained raw USDr mint/burn Transfer logs match all 359 reconstructed mint/burn records by direction, transaction, and amount.
4. Direct USDr supply and event-reconstructed supply differ by exactly 20,010 USDr at all eight retained snapshots.
5. That difference was present by the earliest retained snapshot and persists across the subsequent observed supply changes.
6. The controller's role configuration provides an authorized route for the additional minter to obtain mint authority, and a direct mint simulation succeeded for that address at the tested state.
7. A historical controller burn occurred, but its economic purpose is unresolved.
8. A representative transaction shows USDr burn activity coordinated with USDC.e movement.

## 10. What the evidence does not establish

The evidence does not yet establish:

- The origin or classification of the 20,010 USDr baseline difference.
- The correct complete supply history before the earliest retained snapshot.
- That the unexplained difference represents an unauthorized mint or a protocol defect.
- That the system was definitively underbacked at the pinned checkpoint.
- That the system was definitively fully backed at every historical checkpoint.
- The exact semantics of all custom selectors and event signatures without authoritative ABI/source material.
- The economic purpose of the historical controller burn.
- That a successful `eth_call` simulation necessarily corresponds to an executed transaction.

## 11. Overall assessment

The investigation has established a material and reproducible supply-reconciliation discrepancy. The retained mint/burn event dataset matches the retained raw mint/burn Transfer logs, while direct USDr supply remains exactly 20,010 USDr higher at every retained snapshot.

The escrow USDC.e reconstruction agrees with direct escrow balance at the pinned checkpoint. This is useful corroboration of the collateral-side reconstruction, but it does not resolve the USDr supply denominator.

The defensible conclusion is therefore that the available evidence is insufficient to make a definitive system-wide 1:1 backing verdict. The 20,010 USDr difference is a material unresolved reconciliation item. It must be explained before historical backing ratios based on the event-reconstructed supply can be treated as conclusive.

## 12. Reproducibility and retained evidence

Relevant retained materials include:

- `docs/phase-1-documentation-baseline.md`
- `docs/phase-2-onchain-verification.md`
- `docs/phase-3-pinned-block-reconciliation.md`
- `docs/phase-4-findings-report.md`
- `docs/phase-4-research-scope.md`
- `docs/phase-5-access-control-findings.md`
- `docs/phase-5-reproduction-guide.md`
- `evidence/phase-3-command-log.md`
- `evidence/phase-3-rpc-transcript.md`
- `evidence/phase-4-historical-receipts-and-state.md`
- `evidence/phase-4-supply-event-reconstruction.md`
- `evidence/phase-4-rpc-capability-assessment.md`
- `evidence/phase-4-one-pass-audit/all-contract-logs.jsonl`
- `evidence/phase-4-one-pass-audit/supply-events.json`
- `evidence/phase-4-one-pass-audit/supply-events.csv`
- `evidence/phase-4-one-pass-audit/supply-gap-transfer-logs.json`
- `evidence/phase-4-one-pass-audit/transactions-and-receipts.jsonl`
- `evidence/phase-4-one-pass-audit/historical-state-snapshots-retry.jsonl`
- `evidence/phase-5-evidence-register.md`

Do not rerun Phase 4 collection scripts as part of this closeout without first reviewing their effects: the existing scripts may truncate or rebuild retained evidence files.

## 13. Phase 6 status and Phase 7 handoff

Phase 6 consolidates the current evidence and states its provenance and interpretation boundaries. It does not resolve the 20,010 USDr difference.

Phase 7 should focus on claim boundaries and independent review. Any final public conclusion should distinguish:
- directly observed on-chain facts;
- reconstructed values and their source datasets;
- simulations versus executed transactions;
- interpretations supported by transaction context;
- unresolved questions and limitations.

No commit or push is authorized by this closeout record. Publication remains subject to the user's explicit approval.
