# Evidence Index — USDr Backing Verification

This index provides the primary navigation points for the retained research evidence, key transaction references, and reproduction scripts.

## 1. Phase 3 pinned-block reference

The Phase 3 backing reconciliation uses the following historical Rayls Mainnet block:

| Field | Value |
|---|---|
| Block number | 14,797,239 |
| Block number (hex) | `0xe1c9b7` |
| Block hash | `0x64156f9f6a5339bff36597e2aeb73d65970a7ca43c8806041b0864c435f89830` |
| Verification date | 2026-11-20 |

Primary report: `docs/phase-3-pinned-block-reconciliation.md`

## 2. Key transaction and message references

The October 1, 2026 evidence contains an inbound Ethereum-to-Rayls funding sequence and a separately reconstructed USDr burn sequence. These are not established as one linked redemption operation.

### Inbound funding sequence

| Evidence | Transaction or message identifier |
|---|---|
| Ethereum USDC source transaction | `0x097b640d93fb203f2bbcae27b6e0a4892f7dd1dd1acca1ccde5c529b0aad7ffb` |
| LayerZero message GUID | `0xd1a54800891e863dc488164224d2071072c077c8c12c9fef9f0d5d2bc7855c43` |
| Rayls destination issuance transaction | `0x8735426f04ba432e865049cd5bdfca58e9d5b51f92a60413b4eeb1b39d76eca7` |
| Rayls USDC.e escrow deposit transaction | `0x802cdd6b480bfbdb02ea3c921671827b77a8582e7f03f3e1da4ceae1ee502c2c` |

### Separate USDr burn sequence

| Evidence | Transaction identifier |
|---|---|
| USDr transfer to burn holder | `0x08dfa0ac555badc5b3b00a35f206bb20b23d2ba0a14e270a3be77fe884951636` |
| NativeTokenController approval | `0xd3d744e8b95c4bba308694bd8fb077b84d0d35c70970d2ab94d1c2b4399781a4` |
| NativeTokenController burn | `0x3e1fb4b25043bc55e208b29a601966710c6ddf2fec4edcd015b1550fb43cfa4a` |

The available evidence does not establish a complete outbound sequence connecting this burn to a USDC.e escrow release, bridge message, and Ethereum-side USDC unlock. See `docs/outbound-trace-note.md`.

## 3. Reproduction scripts

| Phase | Script | Purpose |
|---|---|---|
| Phase 3 | `scripts/phase-3-reproduce.sh` | Reproduce the pinned-block backing reconciliation |
| Phase 4 | `scripts/phase-4-one-pass-audit.sh` | Run the consolidated Phase 4 audit |
| Phase 4 | `scripts/phase-4-reconcile-supply-gap.sh` | Reconcile the historical supply gap |
| Phase 4 | `scripts/phase-4-closeout-verification.sh` | Run Phase 4 closeout checks |

Review each script before execution. Some scripts may regenerate or modify local evidence outputs.

## 4. Supporting research documents

- `docs/phase-2-onchain-verification.md` — transaction tracing and on-chain observations.
- `docs/phase-3-pinned-block-reconciliation.md` — pinned-block backing calculations and RPC evidence.
- `docs/phase-4-findings-report.md` — consolidated Phase 4 findings.
- `docs/phase-5-access-control-findings.md` — controller access-control findings.
- `docs/phase-5-reproduction-guide.md` — Phase 5 reproduction procedure.
- `docs/phase-6-evidence-closeout.md` — evidence provenance and closeout.
- `docs/phase-7-claim-boundary-review.md` — cross-phase claim-boundary assessment.

## 5. RPC access note

Historical state reads at the Phase 3 pinned block required a non-public Validation Cloud Rayls Mainnet RPC endpoint because the public endpoint returned a pruned-state error. The endpoint URL and credentials are intentionally excluded from this repository. Reproduction requires the appropriate endpoint to be configured locally; do not commit RPC credentials.
