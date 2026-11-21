# Rayls USDr 1:1 Backing Verification

Independent, evidence-driven verification of USDr 1:1 backing on the Rayls Public Chain.

This research examines the documented USDr backing model through primary documentation, on-chain state, transaction reconstruction, cross-chain transfer evidence, access-control analysis, and reproducible experiments.

## Research phases

| Phase | Research area | Status |
|---|---|---|
| Phase 0 | Network identification, block references, and research baseline | Complete |
| Phase 1 | Documentation and backing-model baseline | Complete |
| Phase 2 | On-chain verification, transaction tracing, and evidence collection | Complete |
| Phase 3 | Pinned-block backing reconciliation | Complete |
| Phase 4 | Consolidated findings and research assessment | Complete |
| Phase 5 | Controller access control and alternative minting analysis | Evidence collection complete |
| Phase 6 | Consolidated evidence package and provenance audit | Complete |
| Phase 7 | Cross-phase claim-boundary review | Complete |

### Phase 0 — Research baseline

[Read the Phase 0 session record](docs/session-2026-11-18-phase-0.md)

### Phase 1 — Documentation baseline

[Read the Phase 1 documentation baseline](docs/phase-1-documentation-baseline.md)

### Phase 2 — On-chain verification

[Read the Phase 2 evidence report](docs/phase-2-onchain-verification.md)

### Phase 3 — Pinned-block backing reconciliation

[Read the Phase 3 reconciliation report](docs/phase-3-pinned-block-reconciliation.md)

[Read the Phase 3 RPC evidence transcript](evidence/phase-3-rpc-transcript.md)

### Phase 4 — Findings and research assessment

[Read the Phase 4 findings report](docs/phase-4-findings-report.md)

[Read the Phase 4 research scope](docs/phase-4-research-scope.md)

### Phase 5 — Access control and alternative minting

[Read the Phase 5 access-control findings](docs/phase-5-access-control-findings.md)

[Read the Phase 5 reproduction guide](docs/phase-5-reproduction-guide.md)

[Read the Phase 5 evidence register](evidence/phase-5-evidence-register.md)

### Phase 6 — Evidence closeout

[Read the Phase 6 evidence closeout](docs/phase-6-evidence-closeout.md)

[Read the Phase 6 evidence register](evidence/phase-6-evidence-register.md)

### Phase 7 — Claim-boundary review

[Read the Phase 7 cross-phase claim-boundary review](docs/phase-7-claim-boundary-review.md)

## Research principles

- Prefer primary documentation and directly observable on-chain evidence.
- Record exact transaction hashes, addresses, block references, and token amounts.
- Distinguish documented claims, observed facts, independently reconstructed evidence, and inference.
- State evidence limitations explicitly.
- Distinguish read-only simulations from transactions that actually changed chain state.
- Do not equate an unusual transaction or access-control configuration with proven misconduct or insolvency.
- Do not infer that a permission was exercised merely because an account possesses it.

## Current research boundary

The investigation has identified a positive USDr escrow backing snapshot and reconstructed selected on-chain conversion and cross-chain transfer activity. These observations are bounded to the blocks, transactions, and state queries documented in the relevant phase reports; they do not establish perpetual or system-wide solvency.

Phase 5 confirmed that both the USDrEscrow proxy and an additional account hold `MINTER_ROLE` on the NativeTokenController at the pinned snapshot. The additional account also holds `DEFAULT_ADMIN_ROLE` and can simulate a direct controller mint successfully using `eth_call`. This establishes an alternative controller-level mint capability, not proof that the account actually issued USDr outside the escrow workflow.

The Phase 5 later-state burn simulation did not complete: the tested call reached an allowance check and failed because the allowance was zero at that snapshot. This does not negate the successful historical controller burn initiated by the additional minter on October 1, 2026, documented in Phase 4. The holder had approved the exact amount before that transaction. The economic purpose of the historical burn and any associated collateral movement remain unresolved. The execution path of an early 45-recipient issuance transaction also remains unresolved because the historical trace could not be retrieved. A separate 300 USDC.e-to-300 USDr escrow-mediated conversion was reconstructed for one sampled transaction; it does not establish that every historical mint followed that route.

Accordingly, the current evidence does not establish unauthorized minting, actual off-escrow issuance by the additional minter, or proven undercollateralization. A successful historical controller burn initiated by the additional minter is confirmed, but its economic purpose and any associated collateral movement remain unresolved. Phases 3 and 4 completed the pinned-block backing reconciliation and consolidated findings; Phases 6 and 7 completed the evidence-provenance closeout and cross-phase claim-boundary review. The resulting assessment remains limited to the sampled blocks, transactions, and state queries. In particular, it does not establish perpetual or system-wide solvency, resolve the historical supply discrepancy, or independently reconcile Ethereum-side USDC custody. Independent review remains a useful next step.

## Research artifacts

A video recording of the Phase 2 Rayls Explorer investigation was made during the research. The recording is not included in this repository.
