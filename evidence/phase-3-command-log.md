# Phase 3 Command and Result Log

**Research date:** 2026-11-20
**Network:** Rayls Mainnet
**Chain ID:** 72957
**Pinned block:** 14,797,239 (`0xe1c9b7`)
**Status:** Historical results documented; reproduction commands reconstructed.

## 1. Important provenance note

The original RPC command history was not available in the retained terminal history. Therefore, the requests in `scripts/phase-3-reproduce.sh` are reconstructed from the contract addresses, function selectors and results preserved in the Phase 3 report and RPC transcript.

The results below are previously observed historical results. They are not represented as fresh executions of the reproduction script.

## 2. Reconstructed RPC request sequence

The reproduction script sends eight `eth_call` requests at block `0xe1c9b7`.

| No. | Contract | Function | Selector |
|---:|---|---|---|
| 1 | USDC.e | `decimals()` | `0x313ce567` |
| 2 | USDC.e | `balanceOf(USDrEscrow)` | `0x70a08231` |
| 3 | USDC.e | `totalSupply()` | `0x18160ddd` |
| 4 | USDr | `decimals()` | `0x313ce567` |
| 5 | USDr | `totalSupply()` | `0x18160ddd` |
| 6 | USDrEscrow | `circulatingUsdr()` | `0x2f4f83af` |
| 7 | USDrEscrow | `requiredUsdceBacking()` | `0x6d0dc771` |
| 8 | USDrEscrow | `withdrawableSurplus()` | `0xb6739070` |

Run the reconstructed requests with:

```bash
./scripts/phase-3-reproduce.sh
```

The script requires `FRPC_URL` to be configured in the environment. It does not intentionally print the endpoint.

## 3. Previously observed results

| Query | Raw result |
|---|---:|
| USDC.e decimals | 6 |
| USDC.e escrow balance | 26,348,747,526 |
| USDC.e total supply | 26,518,729,181 |
| USDr decimals | 18 |
| USDr total supply | 25,357,786,154,933,504,401,529 |
| `circulatingUsdr()` | 25,357,786,154,933,504,401,529 |
| `requiredUsdceBacking()` | 25,357,786,154 |
| `withdrawableSurplus()` | 990,961,372 |

The exact hexadecimal returns for the token balance, token supply and escrow getters are preserved in `evidence/phase-3-rpc-transcript.md`.

## 4. Historical provider behaviour

- The public Rayls RPC returned the pinned block header.
- Historical `eth_call` requests through that provider failed because the requested state was pruned.
- A separate archival provider returned the historical state results documented above.
- The archival endpoint and credential are intentionally excluded.

## 5. Reproduction status and limitations

- [x] Historical block identified.
- [x] Contract addresses and function selectors documented.
- [x] Previously observed raw results preserved.
- [x] Reconstructed reproduction script created.
- [x] Script Bash syntax checked.
- [ ] Fresh execution of the reconstructed script independently verified.

A successful Bash syntax check establishes only that the script parses. It does not establish that the RPC requests have been freshly executed or independently verified.

The evidence supports a point-in-time backing reconciliation at the selected block. It does not prove continuous solvency or complete cross-chain reserve custody.