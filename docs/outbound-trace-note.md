# Outbound Trace Note — USDr Burn and Cross-Chain Exit Evidence

**Project:** Independent USDr 1:1 Backing Verification
**Research scope:** October 1, 2026 transaction sequence and available outbound-path evidence
**Status:** Evidence review complete; full outbound sequence not reconstructed

## 1. Purpose

This note makes the boundary of the outbound-path investigation explicit.

The available evidence does not establish one complete transaction sequence connecting a USDr burn to a USDC.e release from the configured escrow, a bridge message, and an Ethereum-side USDC unlock.

The October 1, 2026 activity is the closest substantially reconstructed example. However, it contains an independently observed inbound USDC-to-USDC.e funding sequence and a separate USDr burn. The available evidence does not prove that the deposit and burn were economically or operationally linked.

## 2. Observed October 1 inbound funding sequence

The following cross-chain funding path was reconstructed:

| Step | Transaction or message | Observed action | Amount |
|---|---|---|---:|
| Ethereum source | `0x097b640d93fb203f2bbcae27b6e0a4892f7dd1dd1acca1ccde5c529b0aad7ffb` | USDC transfer through the Stargate USDC Pool; `OFTSent` event emitted | 20,000.000699 USDC |
| LayerZero message | `0xd1a54800891e863dc488164224d2071072c077c8c12c9fef9f0d5d2bc7855c43` | Ethereum endpoint 30101 to Rayls endpoint 30415; delivery reported successful | 20,000.000699 USDC |
| Rayls destination | `0x8735426f04ba432e865049cd5bdfca58e9d5b51f92a60413b4eeb1b39d76eca7` | `execute302` destination processing and USDC.e issuance | 20,000.000699 USDC.e |
| Rayls escrow deposit | `0x802cdd6b480bfbdb02ea3c921671827b77a8582e7f03f3e1da4ceae1ee502c2c` | Transfer of USDC.e to the configured USDrEscrow proxy | 20,000 USDC.e |

The Ethereum source transaction and Rayls destination transaction are linked by the recorded LayerZero message. The subsequent escrow deposit was made by the same sender that received the Rayls USDC.e. The sender retained the 0.000699 USDC.e difference.

This is an observed inbound funding path. It is not an outbound redemption path.

## 3. Separately reconstructed USDr burn sequence

The following USDr activity was also reconstructed on October 1:

| Step | Transaction | Observed action | Amount |
|---|---|---|---:|
| Transfer to burn holder | `0x08dfa0ac555badc5b3b00a35f206bb20b23d2ba0a14e270a3be77fe884951636` | USDr transferred to the eventual burn holder | 18,026.574051066495598471 USDr |
| Controller approval | `0xd3d744e8b95c4bba308694bd8fb077b84d0d35c70970d2ab94d1c2b4399781a4` | Holder approved the NativeTokenController for the exact burn amount | 18,026.574051066495598471 USDr |
| Controller burn | `0x3e1fb4b25043bc55e208b29a601966710c6ddf2fec4edcd015b1550fb43cfa4a` | Additional minter initiated a successful controller burn from the holder | 18,026.574051066495598471 USDr |

Direct historical state showed USDr totalSupply decreasing by the exact burn amount, from 43,407.156129 USDr to 25,380.582077933504401529 USDr.

No USDC.e transfer appears in the supplied logs for the burn transaction. Phase 4 also found no additional USDC.e movement involving the configured escrow in the inspected block range beyond the 20,000 USDC.e deposit.

The deposit and burn are independently evidenced. Their temporal proximity and contribution to the measured escrow-versus-supply correction do not establish that they formed one redemption operation.

## 4. Outbound steps not established

The investigation did not reconstruct the following complete sequence:

1. A USDr redemption or burn linked to a specific outbound operation.
2. A corresponding USDC.e release from the configured escrow to an identified recipient.
3. A bridge-out transaction or message linked to that release.
4. A corresponding Ethereum-side USDC unlock or release linked to the same bridge operation.

The verified `USDrBridgeOut` contract at `0xF5Df832527A452b7a6e3B7E3CdD3d67249eC03A7` has a `swapAndBridge` ABI function and a `BridgedOut` event. This establishes the existence of a bridge-out mechanism. It does not establish that the function was called in the October 1 burn sequence.

Accordingly, the October 1 burn must not be described as a confirmed redemption, bridge-out, or Ethereum unlock.

## 5. Evidence boundary and conclusion

The strongest supported conclusion is that the research reconstructed an inbound Ethereum USDC-to-Rayls USDC.e funding path, a subsequent 20,000 USDC.e escrow deposit, and a separate exact-amount USDr funding, approval, and burn sequence.

A complete outbound USDr-to-Ethereum redemption path remains unverified. No conclusion about the absence of all outbound activity should be drawn from this bounded investigation.

For the underlying transaction analysis, see:

- `docs/phase-2-onchain-verification.md`
- `docs/phase-4-findings-report.md`

**Claim boundary:** The existence of a verified bridge-out contract is not evidence that a particular burn used it. The observed inbound funding sequence is not evidence of an outbound release. The economic relationship between the October 1 deposit and burn remains unresolved.
