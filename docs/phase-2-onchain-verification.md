# Phase 2 — On-chain Verification and Transaction Evidence

**Project:** Independent USDr 1:1 Backing Verification

**Network:** Rayls Public Chain and Ethereum Mainnet

**Phase status:** Evidence collection complete

**Research date:** 18–20 November 2026

**Publication status:** Prepared for review; not yet committed or pushed

---

## 1. Purpose and scope

Phase 2 tested the documented USDr backing model against observable on-chain state and transaction activity.

The investigation focused on:

- USDr total supply and USDC.e held by the USDr escrow.
- The escrow's required-backing and surplus calculations.
- NativeTokenController minting and burning permissions.
- An observed October 1, 2026 USDr burn and its preceding transactions.
- The Ethereum-to-Rayls USDC/USDC.e transfer path.
- The verified USDrBridgeOut contract and its bridge-out mechanism.

The purpose was to establish reproducible evidence, not to presume that a discrepancy or unusual role necessarily demonstrates misconduct or insolvency.

## 2. Documented backing model

Rayls documentation describes the following conversion model:

1. USDC is locked on Ethereum through the cross-chain bridge infrastructure.
2. Corresponding USDC.e is issued on Rayls.
3. USDC.e is deposited into the USDr escrow.
4. Equivalent USDr is minted.
5. For redemption, USDr is returned to the escrow, burned, and exchanged for available USDC.e.
6. USDC.e can then be bridged back to Ethereum.

The documented target is 1:1 backing: circulating USDr should be supported by the corresponding USDC.e escrow balance.

The documentation describes the intended system design. It does not, by itself, establish current balances, complete custody across chains, or the current authorization state of every minter.

Primary documentation:
- Rayls Public Chain Tokenomics: https://docs.rayls.com/docs/public-chain-tokenomics
- Rayls High-Level Architecture: https://docs.rayls.com/docs/rayls-high-level-architecture
- Rayls Public Chain Reference: https://docs.rayls.com/docs/public-chain-reference

## 3. Network and contract identification

Rayls Public Chain:
- Chain ID: 72957 (`0x11cfd`)
- RPC: https://mainnet-rpc.rayls.com/
- Explorer: https://explorer.rayls.com/

Relevant contracts and addresses:

| Component | Address |
|---|---|
| USDr native-token precompile | `0x0000000000000000000000000000000000000400` |
| USDC.e | `0x9001dbe4D68d36ab87923A2a9Dfb0c745fd25001` |
| USDrEscrow proxy | `0xD19A5e28FEd41FA289E92Ae61B9Bc5BD883DB0D2` |
| USDrEscrow implementation | `0x0a1688c05e9fabf09108b9dbfd25266342b188df` |
| NativeTokenController proxy | `0x07E17E17e17E17E17E17e17e17e17e17E17E17E6` |
| NativeTokenController implementation | `0x07e17e17e17e17e17e17e17e17e7` |
| USDrBridgeOut | `0xF5Df832527A452b7a6e3B7E3CdD3d67249eC03A7` |

USDr is represented through the Rayls native-token precompile rather than a conventional ERC-20 deployment.

## 4. On-chain backing snapshot

The balance and supply snapshot was queried at Rayls block **14,797,239** (`0xe1c9b7`).

Block details:
- Block hash: `0x64156f9f6a5339bff36597e2aeb73d65970a7ca43c8806041b0864c435f89830`
- Timestamp: 2026-11-19 12:02:33 UTC
- State root: `0xc6725458e49ab30b241023ca5a8950d0aa79ad04a247151fc18047445f22b206`

Observed values:

| Metric | Value |
|---|---:|
| USDr total supply | 25,357.786154933504401529 USDr |
| USDC.e total supply | 26,518.729181 USDC.e |
| USDC.e held by USDrEscrow | 26,348.747526 USDC.e |
| Required USDC.e backing, rounded down to token precision | 25,357.786154 USDC.e |
| Calculated liquid surplus | 990.961372 USDC.e |
| USDC.e supply outside escrow | 169.981655 USDC.e |

The escrow backing calculation uses the 18-decimal USDr supply converted to 6-decimal USDC.e units:

`requiredBackingRaw = floor(USDrTotalSupplyRaw / 10^12)`

Therefore:

`26,348.747526 - 25,357.786154 = 990.961372 USDC.e`

At this snapshot, the escrow's liquid USDC.e balance exceeded the calculated required backing.

**Interpretation:** This is a positive point-in-time escrow balance comparison. It is not proof of full-system solvency, complete Ethereum-side collateralization, or the absence of other liabilities.

## 5. USDrEscrow contract logic

The verified USDrEscrow source was inspected.

Relevant logic includes:

- `circulatingUsdr()` derives circulation from USDr total supply.
- `requiredUsdceBacking()` calculates required backing using the 1e12 decimal conversion.
- `withdrawableSurplus()` returns the amount by which liquid USDC.e exceeds required backing, or zero if it does not.
- `pullToTreasury` is restricted by `TREASURY_ROLE` and limited to withdrawable surplus.
- `swapUsdceForUsdr` receives USDC.e and invokes the configured minter/burner to mint USDr.
- `swapUsdrForUsdce` pulls USDr, burns the effective redemption amount, and transfers USDC.e to the recipient.
- `setMinterBurner` allows an authorized administrator to replace the configured controller.
- USDC.e rescue is limited to surplus; other-token rescue behavior is separately defined.

An important source-code comment states that the backing calculation depends on the escrow being the exclusive mint/burn authority. If another address can burn USDr without a corresponding USDC.e outflow, total supply falls while escrow liquidity remains, increasing the calculated surplus.

This is a material control dependency: the backing formula alone does not enforce exclusive mint/burn authority. Controller roles and other issuance/burn pathways must also be considered.

## 6. NativeTokenController and additional minter

The NativeTokenController source inspected defines `MINTER_ROLE` and restricts its `mint` and `burn` functions to that role. The controller invokes the USDr precompile and emits `Minted` and `Burned` events.

The deployed controller proxy was queried for role membership.

Observed:
- The USDrEscrow proxy holds `MINTER_ROLE`.
- A second address also holds `MINTER_ROLE`:
  `0x6B205d256E8a153CBa8057E5655db56e0E47A511`

The controller source available through the explorer was marked as a partial match, so it is used as implementation guidance rather than conclusive proof that every deployed source line matches.

### 6.1 Additional minter grant

Transaction:
`0xa6b61b11e55b194d11a4d419b3964cd06355847fe3319e1645b4f5c7acee8435`

- Date: 2026-10-01 13:24:28 UTC
- Block: 11,366,001
- Method: `grantRole`
- Granting transaction sender: `0x6B205d256E8a153CBa8057E5655db56e0E47A511`
- Account granted: `0x6B205d256E8a153CBa8057E5655db56e0E47A511`
- Role: `MINTER_ROLE`

The transaction is an explicit self-grant. The role-admin configuration observed was `DEFAULT_ADMIN_ROLE`. Historical membership of the sender in the admin role at the grant block was not established. Therefore, the evidence does not establish an unauthorized privilege escalation.

### 6.2 Additional minter burn

Transaction:
`0x3e1fb4b25043bc55e208b29a601966710c6ddf2fec4edcd015b1550fb43cfa4a`

- Date: 2026-10-01 13:31:28 UTC
- Block: 11,366,604
- Caller: `0x6B205d256E8a153CBa8057E5655db56e0E47A511`
- Method: `burn`
- Account whose USDr was burned: `0x633Ac5e2315b973417e8caa6B3Ad2162e0461ce1`
- Amount: **18,026.574051066495598471 USDr**

The transaction emitted the USDr burn and transfer-to-zero-address events, together with the controller's `Burned` event.

No USDC.e transfer appears in the supplied burn transaction logs. This observation does not exclude a separate transaction, another contract path, or activity on another chain.

The evidence establishes that an address other than the escrow exercised the controller's burn authority. It does not establish that the burn was unauthorized, that it was unrelated to a legitimate redemption or bridge operation, or that it caused undercollateralization.

## 7. October 1 sender and approval trace

The USDr burn recipient was traced backwards.

### 7.1 USDr transfer to the burn recipient

Transaction:
`0x08dfa0ac555badc5b3b00a35f206bb20b23d2ba0a14e270a3be77fe884951636`

- Date: 2026-10-01 12:54:49 UTC
- Block: 11,363,419
- Sender: `0xab5309BE3d6E228288DA1F68dF3f993A550dEC7c`
- Recipient: `0x633Ac5e2315b973417e8caa6B3Ad2162e0461ce1`
- Amount: **18,026.574051066495598471 USDr**

The sender's observed incoming USDr transfers totalled 18,026.581673562495598471 USDr. Its observed outgoing transfer was 18,026.574051066495598471 USDr, leaving a transfer-flow residual of 0.007622496 USDr. This is not a complete account balance reconciliation.

### 7.2 Exact-amount approval

Transaction:
`0xd3d744e8b95c4bba308694bd8fb077b84d0d35c70970d2ab94d1c2b4399781a4`

- Date: 2026-10-01 12:59:13 UTC
- Sender: `0x633Ac5e2315b973417e8caa6B3Ad2162e0461ce1`
- Spender: NativeTokenController proxy
- Method: `approve`
- Approved amount: **18,026.574051066495598471 USDr**

The approved amount exactly matches both the preceding incoming transfer and the later burn amount.

This establishes a strong transaction-level connection between the recipient's USDr, its allowance to the controller, and the subsequent burn. It does not independently establish the economic purpose of the burn.

## 8. October 1 USDC.e deposit and cross-chain source

A separate USDC.e funding sequence was reconstructed.

### 8.1 Ethereum source transaction

Ethereum transaction:
`0x097b640d93fb203f2bbcae27b6e0a4892f7dd1dd1acca1ccde5c529b0aad7ffb`

- Ethereum block: 25,305,973 (`0x18e3775`)
- Sender: `0x0e301bEEF8daaD28f8e38D9Fce09112b78fE3161`
- Transaction target: `0xacddac6c77318b615f7f6fb9bb67c6833e9c05f1`
- Status: successful
- USDC amount: **20,000.000699 USDC**

The Ethereum receipt included a USDC transfer from the sender to the transaction target, followed by a transfer of the same amount to the Stargate USDC Pool at:

`0xc026395860db2d07ee33e05fe50ed7bd583189c7`

The pool emitted an `OFTSent` event with the same amount and destination endpoint ID 30415.

### 8.2 LayerZero message evidence

GUID:
`0xd1a54800891e863dc488164224d2071072c077c8c12c9fef9f0d5d2bc7855c43`

LayerZero Scan identified:
- Source endpoint: 30101 (Ethereum)
- Destination endpoint: 30415 (Rayls)
- Source transaction: `0x097b640d93fb203f2bbcae27b6e0a4892f7dd1dd1acca1ccde5c529b0aad7ffb`
- Destination transaction: `0x8735426f04ba432e865049cd5bdfca58e9d5b51f92a60413b4eeb1b39d76eca7`
- Message status: `DELIVERED`
- Transfer amount: **20,000.000699 USDC**

The scan reported successful verification by the configured DVNs and successful destination delivery.

### 8.3 Rayls destination issuance

Rayls transaction:
`0x8735426f04ba432e865049cd5bdfca58e9d5b51f92a60413b4eeb1b39d76eca7`

- Date: 2026-10-01 12:43:36 UTC
- Method: `execute302`
- Destination recipient: `0x0e301bEEF8daaD28f8e38D9Fce09112b78fE3161`
- USDC.e minted: **20,000.000699 USDC.e**

The transaction logs included the USDC.e mint and Stargate/LayerZero delivery events. The verified Executor implementation's `execute302` function calls the LayerZero Endpoint V2 receive path; the Executor itself is not the USDC.e minter.

### 8.4 Escrow deposit

Rayls transaction:
`0x802cdd6b480bfbdb02ea3c921671827b77a8582e7f03f3e1da4ceae1ee502c2c`

- Date: 2026-10-01 12:46:29 UTC
- Block: 11,362,694
- Sender: `0x0e301bEEF8daaD28f8e38D9Fce09112b78fE3161`
- Recipient: USDrEscrow proxy
- Amount: **20,000 USDC.e**

The sender received 20,000.000699 USDC.e and, 2 minutes 53 seconds later, transferred 20,000 USDC.e to the escrow. The difference retained by the sender was 0.000699 USDC.e.

This is strong evidence of a cross-chain USDC transfer, corresponding Rayls USDC.e issuance, and subsequent escrow funding. It does not establish a direct economic relationship between this deposit and the separate 18,026.574051066495598471 USDr burn.

## 9. USDrBridgeOut contract

The contract at:

`0xF5Df832527A452b7a6e3B7E3CdD3d67249eC03A7`

was identified by the Rayls explorer as a fully verified `USDrBridgeOut` contract, not a proxy.

Its ABI includes:
- `swapAndBridge(uint256 _usdrAmount,uint32 _dstEid,bytes32 _recipient,uint256 _minAmountLd,bytes _extraOptions)`
- `quoteSwapAndBridge`
- `BridgedOut(address indexed sender,uint32 indexed dstEid,bytes32 recipient,uint256 usdrAmount,uint256 usdceBridged)`

The decoded constructor arguments identify:
- USDC.e: `0x9001dbe4D68d36ab87923A2a9Dfb0c745fd25001`
- USDrEscrow: `0xD19A5e28FEd41FA289E92Ae61B9Bc5BD883DB0D2`
- OFT bridge: `0x74c9f2b00581f1b11aa7ff05aa9F608B7389De67`
- USDC.e spender: same OFT bridge address
- Admin and pauser: `0x633Ac5e2315b973417e8caa6B3Ad2162e0461ce1`

This identifies a separate bridge-out mechanism that can be tested against observed burn and bridge transactions. Constructor configuration and ABI inspection do not prove that this function was called during the October 1 burn.

## 10. Additional transaction context

The additional minter received a 50 USDr transfer on October 1:

`0x7c2909e6f79e520721eacd6a63ccb4d1199c9c704010630178f9035d18fcf561`

The transfer originated from `0x0e301bEEF8daaD28f8e38D9Fce09112b78fE3161`.

The same sender also transferred 50 USDr to the eventual burn recipient in a separate transaction:

`0x3d86100cc0656f6cff17a1ab4244f91ea3d62a67eedac7a339943052b9026ff5`

These transfers are contextual evidence only. Their purpose has not been established, and they should not be characterized as payment, compensation, or a burn fee.

The sender address also initiated two historical `RewardClaimer.approveMintsRange` transactions in May 2026. The observed mint events involved a different `Minted.caller` address. This links the sender to prior reward-range approval activity but does not establish the purpose of the October 1 transfers.

## 11. Evidence assessment

| Finding | Evidence status | What it establishes |
|---|---|---|
| Documented 1:1 model | Documented | Intended USDr/USDC.e backing design |
| November 19 escrow snapshot | Observed on-chain | Escrow USDC.e exceeded calculated required backing at that block |
| Additional MINTER_ROLE holder | Observed on-chain | A second address held controller mint/burn authority at the time queried |
| October 1 additional-minter burn | Observed on-chain | 18,026.574051066495598471 USDr was burned by the additional minter |
| Exact-amount approval chain | Independently reconstructed | Recipient approved the controller for exactly the amount subsequently burned |
| Ethereum-to-Rayls USDC transfer | Independently reconstructed | 20,000.000699 USDC moved through the observed Stargate/LayerZero route and was delivered as USDC.e |
| Subsequent escrow deposit | Observed on-chain | 20,000 USDC.e was transferred to USDrEscrow |
| USDrBridgeOut mechanism | Verified contract/ABI inspection | A separate USDr-to-USDC.e bridge-out function exists |
| October 1 burn purpose | Unresolved | Available evidence does not conclusively identify the burn as redemption or bridge-out |
| Complete Ethereum collateral custody | Unresolved | Full cross-chain custody and liability reconciliation was not completed |
| Full-system solvency | Not established | A single escrow snapshot cannot prove system-wide solvency |

## 12. Limitations and unresolved questions

1. The escrow snapshot is point-in-time evidence, not a continuous historical solvency proof.
2. The Ethereum-side USDC custody and all associated cross-chain liabilities have not been fully reconciled.
3. The additional minter's historical authorization at the exact grant block has not been independently established.
4. The October 1 burn has not been conclusively tied to a `USDrBridgeOut.swapAndBridge` execution or a corresponding USDC.e outflow.
5. The absence of a USDC.e transfer in the supplied burn transaction logs does not prove no related transfer occurred separately.
6. The NativeTokenController explorer source was a partial match; deployed-source equivalence should not be overstated.
7. The October 1 transaction-history pagination investigation was not treated as a prerequisite for closing Phase 2.
8. No demonstrated evidence in this phase proves undercollateralization, unauthorized minting, or fraud.

## 13. Phase 2 conclusion

Phase 2 established that the documented 1:1 backing mechanism has an observable on-chain implementation and that, at the November 19 snapshot, the USDr escrow held more USDC.e than the calculated required backing.

It also identified a material control dependency: a second address held `MINTER_ROLE` and executed a substantial USDr burn outside the escrow address. The exact-amount approval and preceding transfer were reconstructed. The available evidence does not establish that this activity was unauthorized or that it created a backing deficit.

Separately, an October 1 Ethereum USDC transfer was traced through Stargate/LayerZero to Rayls USDC.e issuance and a subsequent USDr escrow deposit. This demonstrates an observed cross-chain funding path, but does not complete a system-wide Ethereum custody reconciliation or prove that the funding was related to the separate burn.

**Overall Phase 2 assessment:** The evidence supports a positive escrow backing snapshot and confirms additional mint/burn authority that warrants examination. It does not establish full-system solvency or undercollateralization.

## 14. Phase 2 research artifact

A video recording was made of the Phase 2 Rayls Explorer investigation. The recording is noted as a research milestone artifact; the video itself is not included in this repository.

## 15. Transition to Phase 3

Phase 3 will focus on consolidated backing reconciliation and security assessment:

- Reconcile USDr supply with escrow USDC.e.
- Evaluate all identified minting and burning authorities and pathways.
- Assess Ethereum-side custody and cross-chain backing evidence.
- Classify demonstrated exceptions, control risks, and unresolved liabilities.
- State precisely what can and cannot be concluded about the 1:1 backing claim.

Phase 2 evidence collection is considered complete. Unresolved questions are carried forward as explicit limitations and Phase 3 assessment targets rather than used to delay documentation of the completed milestone.
