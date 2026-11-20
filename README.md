# Rayls USDr 1:1 Backing Verification

Independent, evidence-driven verification of USDr 1:1 backing on the Rayls Public Chain.

This research examines the documented USDr backing model through primary documentation, on-chain state, transaction reconstruction, cross-chain transfer evidence, access-control analysis, and reproducible experiments.

## Research phases

| Phase | Research area | Status |
|---|---|---|
| Phase 0 | Network identification, block references, and research baseline | Complete |
| Phase 1 | Documentation and backing-model baseline | Complete |
| Phase 2 | On-chain verification, transaction tracing, and evidence collection | Complete |
| Phase 3 | Consolidated backing reconciliation and security assessment | Pending |

### Phase 0 — Research baseline
[Read the Phase 0 session record](docs/session-2026-11-18-phase-0.md)

### Phase 1 — Documentation baseline
[Read the Phase 1 documentation baseline](docs/phase-1-documentation-baseline.md)

### Phase 2 — On-chain verification
[Read the Phase 2 evidence report](docs/phase-2-onchain-verification.md)

## Research principles

- Prefer primary documentation and directly observable on-chain evidence.
- Record exact transaction hashes, addresses, block references, and token amounts.
- Distinguish documented claims, observed facts, independently reconstructed evidence, and inference.
- State evidence limitations explicitly.
- Do not equate an unusual transaction or access-control configuration with proven misconduct or insolvency.

## Current research boundary

Phase 2 established a positive USDr escrow backing snapshot and identified an additional `MINTER_ROLE` holder that executed a substantial USDr burn. It also reconstructed an October 1, 2026 Ethereum-to-Rayls USDC/USDC.e transfer and subsequent escrow deposit.

These findings do not, by themselves, establish full-system solvency or undercollateralization. Phase 3 will address consolidated backing reconciliation and the remaining assessment questions.

## Research artifacts

A video recording of the Phase 2 Rayls Explorer investigation was made during the research. The recording is not included in this repository.
