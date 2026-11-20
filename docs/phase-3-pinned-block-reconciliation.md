# Phase 3 — Pinned-Block USDr Backing Reconciliation

**Status:** Complete
**Verification date:** 2026-11-20
**Network:** Rayls Mainnet
**Chain ID:** 72957 (`0x11cfd`)
**Pinned block:** 14,797,239 (`0xe1c9b7`)

## 1. Research question

At a specific historical Rayls Mainnet block, did the USDr escrow contract hold enough USDC.e to cover the USDr supply according to the escrow contract's required-backing calculation?

This phase tests a point-in-time accounting relationship. It does not establish perpetual solvency, prove the custody of all reserves across chains, or independently verify every possible mint and redemption pathway.

## 2. Hypothesis

At the selected block:

1. The USDC.e balance held by USDrEscrow should be at least the required USDC.e backing for the USDr supply.
2. The escrow's on-chain `requiredUsdceBacking()` getter should agree with an independent calculation from the USDr total supply.
3. The escrow's `withdrawableSurplus()` getter should agree with the difference between its USDC.e balance and required backing, subject to integer arithmetic.

## 3. Pinned block identity

| Field | Value |
|---|---|
| Block number | 14,797,239 (`0xe1c9b7`) |
| Block hash | `0x64156f9f6a5339bff36597e2aeb73d65970a7ca43c8806041b0864c435f89830` |
| State root | `0xc6725458e49ab30b241023ca5a8950d0aa79ad04a247151fc18047445f22b206` |
| Timestamp | `0x6afee559` |
| Timestamp (UTC) | 2026-11-19 12:02:33 UTC |
| Chain ID | 72957 (`0x11cfd`) |

## 4. Contracts and queried values

| Contract | Address |
|---|---|
| USDC.e | `0x9001dbe4D68d36ab87923A2a9Dfb0c745fd25001` |
| USDr native precompile | `0x0000000000000000000000000000000000000400` |
| USDrEscrow proxy | `0xD19A5e28FEd41FA289E92Ae61B9Bc5BD883DB0D2` |

USDC.e `balanceOf(address)` was queried for the escrow address. The token supply selector was `0x18160ddd`, and the decimals selector was `0x313ce567`.

## 5. Historical RPC provider behaviour

The public Rayls RPC endpoint returned the pinned block header, but historical `eth_call` requests failed with a pruned-state error referring to block `#14797240`.

The historical calls were repeated successfully against the Validation Cloud Rayls Mainnet endpoint configured in the shell as `$FRPC_URL`. The endpoint credential is excluded from this repository and from the recorded commands.

This is a historical-state availability limitation of the public endpoint, not evidence that the queried contract values are invalid or zero.

## 6. Historical token results

All calls below were made against block `0xe1c9b7`.

### Token decimals

| Token | Decimals |
|---|---:|
| USDC.e | 6 |
| USDr | 18 |

### USDC.e escrow balance

Raw return:
`0x000000000000000000000000000000000000000000000000000000062281fb06`

Raw integer: `26,348,747,526`

Decoded balance: **26,348.747526 USDC.e**

### USDC.e total supply

Raw return:
`0x000000000000000000000000000000000000000000000000000000062ca3b1dd`

Raw integer: `26,518,729,181`

Decoded supply: **26,518.729181 USDC.e**

### USDr total supply

Raw return:
`0x00000000000000000000000000000000000000000000055ea5f9bc9a5a076079`

Raw integer: `25,357,786,154,933,504,401,529`

Decoded supply: **25,357.786154933504401529 USDr**

## 7. Independent backing calculation

USDr has 18 decimals and USDC.e has 6 decimals. The required USDC.e backing is calculated by dividing the USDr raw supply by `10^12`, using integer division.

```text
USDr total supply raw: 25,357,786,154,933,504,401,529
Divisor:                1,000,000,000,000
Required backing raw:  25,357,786,154
Required backing:      25,357.786154 USDC.e
```

## 8. Escrow surplus calculation

The escrow surplus is the escrow's USDC.e balance minus the required backing.

```text
Escrow balance raw:    26,348,747,526
Required backing raw:  25,357,786,154
Surplus raw:              990,961,372
Surplus:                   990.961372 USDC.e
```

The USDC.e supply outside the escrow at the pinned block is:

```text
Total supply raw:      26,518,729,181
Escrow balance raw:    26,348,747,526
Outside escrow raw:       169,981,655
Outside escrow:            169.981655 USDC.e
```


## 9. On-chain escrow getter cross-check

Function selectors were derived from these exact signatures:

| Function | Selector |
|---|---|
| `circulatingUsdr()` | `0x2f4f83af` |
| `requiredUsdceBacking()` | `0x6d0dc771` |
| `withdrawableSurplus()` | `0xb6739070` |

All three calls targeted the USDrEscrow proxy at block `0xe1c9b7`.

| Getter | Raw return value | Decoded value |
|---|---|---:|
| `circulatingUsdr()` | `0x00000000000000000000000000000000000000000000055ea5f9bc9a5a076079` | 25,357.786154933504401529 USDr |
| `requiredUsdceBacking()` | `0x00000000000000000000000000000000000000000000000000000005e7711c2a` | 25,357.786154 USDC.e |
| `withdrawableSurplus()` | `0x000000000000000000000000000000000000000000000000000000003b10dedc` | 990.961372 USDC.e |

The getter values match the independently retrieved supply and calculated backing and surplus.

## 10. Additional supply context

USDC.e total supply was 26,518.729181 USDC.e. The escrow held 26,348.747526 USDC.e.

The difference was 169.981655 USDC.e. This is the supply not held at the queried escrow address; it is not a complete reserve-custody statement.

## 11. Findings

1. **Pinned-block backing check passed.** At block 14,797,239, escrow held 26,348.747526 USDC.e against required backing of 25,357.786154 USDC.e.
2. **Surplus cross-check passed.** The independently calculated surplus of 990.961372 USDC.e matched `withdrawableSurplus()`.
3. **Supply cross-check passed.** `circulatingUsdr()` matched the USDr native precompile's total supply.
4. **Historical RPC limitation recorded.** The public Rayls RPC returned the block header but reported pruned state for the historical calls. The successful historical reads used the configured Validation Cloud endpoint.

## 12. Conclusion and limitations

The Phase 3 pinned-block reconciliation passed. At the selected historical block, USDrEscrow held more USDC.e than the required backing calculated from USDr supply. The escrow's getters agreed with the independent calculations.

This result applies to one historical Rayls Mainnet block. It does not prove continuous solvency, complete reserve custody across chains, or correctness of every mint, burn, redemption, and bridge-out pathway.

Phase 2 identified a second address holding `MINTER_ROLE` and an observed USDr burn of 18,026.574051066495598471 USDr. The available evidence did not conclusively link that burn to a redemption or bridge-out. These questions remain open for the subsequent control and outbound-flow investigations.

## 13. Reproduction and evidence

- Raw commands and JSON-RPC responses: `evidence/phase-3-rpc-transcript.md`
- Reproduction script: `scripts/phase-3-reproduce.sh`
- Repository baseline: `ac1d3d2`

The reproduction script uses the existing `$FRPC_URL` environment variable. It must not embed or print the endpoint credential.

**Result:** Point-in-time backing reconciliation passed.

**Confidence:** High for the reported values and arithmetic at the pinned block, based on matching historical reads and escrow getter cross-checks.

**Scope:** One historical Rayls Mainnet block; not a continuous solvency proof or complete cross-chain reserve attestation.
