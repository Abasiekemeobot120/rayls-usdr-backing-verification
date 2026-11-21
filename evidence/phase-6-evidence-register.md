# Phase 6 — Evidence Register

## Purpose

This register indexes the principal evidence used in the Phase 6 closeout. It distinguishes retained source data from analytical conclusions. Paths are relative to the repository root.

## Core reconciliation evidence

| Evidence | Repository path | Use | Limitation |
|---|---|---|---|
| Historical direct-state snapshots | `evidence/phase-4-one-pass-audit/historical-state-snapshots-retry.jsonl` | Direct USDr supply and escrow balance observations at retained checkpoints | Only the retained checkpoints are represented |
| Reconstructed supply events | `evidence/phase-4-one-pass-audit/supply-events.json` | Event-derived USDr supply reconstruction | Does not explain the constant 20,010 USDr difference |
| Reconstructed supply CSV | `evidence/phase-4-one-pass-audit/supply-events.csv` | Human-readable event reconstruction | Derived from retained event records |
| Raw contract logs | `evidence/phase-4-one-pass-audit/all-contract-logs.jsonl` | Raw event-level comparison | Completeness depends on original collection scope |
| Supply-gap Transfer logs | `evidence/phase-4-one-pass-audit/supply-gap-transfer-logs.json` | Retained raw mint/burn Transfer evidence | Does not independently identify the origin of the baseline difference |
| Transaction and receipt records | `evidence/phase-4-one-pass-audit/transactions-and-receipts.jsonl` | Transaction-level provenance and receipt inspection | Custom semantics require ABI/source confirmation |

## Phase-specific analysis

| Document | Repository path | Purpose |
|---|---|---|
| Phase 1 baseline | `docs/phase-1-documentation-baseline.md` | Documentation and model baseline |
| Phase 2 verification | `docs/phase-2-onchain-verification.md` | Initial on-chain observations |
| Phase 3 reconciliation | `docs/phase-3-pinned-block-reconciliation.md` | Pinned-block state and backing reconciliation |
| Phase 4 findings | `docs/phase-4-findings-report.md` | Historical supply and escrow reconstruction; preserves the six original research questions |
| Phase 4 scope | `docs/phase-4-research-scope.md` | Research scope and question definitions |
| Phase 5 findings | `docs/phase-5-access-control-findings.md` | Controller roles, mint simulation, and burn evidence |
| Phase 5 reproduction guide | `docs/phase-5-reproduction-guide.md` | Reproduction instructions for Phase 5 |
| Phase 5 evidence register | `evidence/phase-5-evidence-register.md` | Phase 5 identifiers and evidence index |
| Phase 6 closeout | `docs/phase-6-evidence-closeout.md` | Consolidated conclusions and limitations |

## Key observed results

1. Direct USDr supply exceeds event-reconstructed supply by exactly 20,010 USDr at all eight retained snapshots.
2. The earliest retained checkpoint is block 11,362,693; the evidence does not identify when the difference originated before that checkpoint.
3. All 359 retained raw zero-address mint/burn Transfer logs matched the 359 reconstructed mint/burn records by transaction, direction, and amount.
4. At pinned block 14,797,239, the reconstructed USDC.e escrow balance matches the direct RPC balance: 26,348.747526 USDC.e.
5. At that same checkpoint, direct USDr supply is 25,357.786154933504401529 USDr, while event-reconstructed supply is 5,347.786154933504401529 USDr.
6. A representative transaction trace shows 0.0001 USDr burned and 0.0001 USDC.e moved from escrow; custom function semantics are not fully ABI-verified.
7. Phase 5 role evidence shows the additional minter had administrative authority before granting itself MINTER_ROLE. The direct mint result was an `eth_call` simulation, not proof of an executed mint transaction.

## Interpretation boundaries

- The 20,010 USDr difference is established; its cause is not.
- A matching escrow balance does not resolve the correct supply denominator.
- The event-log comparison validates the retained raw-log dataset against the reconstruction; it does not independently prove completeness of all chain history.
- Historical `totalSupply()` at block 7,823 returned zero while recipient balances reflected mint activity. This limits the use of that historical method result as a supply arbiter.
- Unknown selectors and event topics must remain unidentified until authoritative ABI/source evidence is obtained.
- Do not characterize the system as definitively underbacked or definitively fully backed based only on the current evidence.

## Preservation and publication

The Phase 6 closeout is an analytical document; it does not replace or modify raw evidence. Preserve all existing evidence files and Phase 5 working-tree changes. No commit or push is implied by this register.
