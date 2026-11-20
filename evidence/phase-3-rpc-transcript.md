# Phase 3 RPC Evidence Transcript

**Verification date:** 2026-11-20
**Network:** Rayls Mainnet
**Chain ID:** 72957 (`0x11cfd`)
**Pinned block:** 14,797,239 (`0xe1c9b7`)
**Block hash:** `0x64156f9f6a5339bff36597e2aeb73d65970a7ca43c8806041b0864c435f89830`

## 1. RPC provider behaviour

Two RPC providers were tested for historical state access.

- Public Rayls RPC (`https://mainnet-rpc.rayls.com/`) returned the block header but historical `eth_call` requests failed because the requested state was pruned.
- A separate archival RPC provider successfully returned the historical contract-call results at the pinned block.
- The archival provider endpoint and credential are intentionally omitted from this transcript.

## 2. Token contract calls

All historical calls targeted block `0xe1c9b7`.

| Contract | Method | Result |
|---|---|---|
| USDC.e | `decimals()` | 6 |
| USDC.e | `balanceOf(USDrEscrow)` | `26,348,747,526` raw |
| USDC.e | `totalSupply()` | `26,518,729,181` raw |
| USDr | `decimals()` | 18 |
| USDr | `totalSupply()` | `25,357,786,154,933,504,401,529` raw |

## 3. Escrow getter calls

The following selectors were queried against the USDrEscrow proxy at the pinned block.

| Getter | Selector | Decoded result |
|---|---|---:|
| `circulatingUsdr()` | `0x2f4f83af` | 25,357.786154933504401529 USDr |
| `requiredUsdceBacking()` | `0x6d0dc771` | 25,357.786154 USDC.e |
| `withdrawableSurplus()` | `0xb6739070` | 990.961372 USDC.e |

## 4. Raw escrow getter returns

**circulatingUsdr():**

`0x00000000000000000000000000000000000000000000055ea5f9bc9a5a076079`

**requiredUsdceBacking():**

`0x00000000000000000000000000000000000000000000000000000005e7711c2a`

**withdrawableSurplus():**

`0x000000000000000000000000000000000000000000000000000000003b10dedc`

## 5. Interpretation

The independently calculated required backing and surplus agree with the values returned by the escrow getters at the pinned block.

This is a single-block reconciliation. It does not establish continuous solvency, prove complete cross-chain reserve custody, or establish the purpose of every observed USDr supply change.

## 6. Reproduction limitations

- Historical state access requires an RPC provider retaining the requested block state.
- Provider credentials are not included in this file.
- No credential, API key, or authenticated endpoint URL should be committed to the repository.
- The raw results above document the observed calls; they are not a substitute for a fresh independent reproduction.