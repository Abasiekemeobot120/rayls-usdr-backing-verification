# Phase 4: Historical USDr Supply Event Reconstruction

- **Research project:** Rayls USDr 1:1 backing verification
- **Network:** Rayls Mainnet
- **Chain ID:** 72957 (`0x11cfd`)
- **Investigation interval:** Blocks 11,362,694–11,366,604
- **Evidence source:** Direct JSON-RPC responses from the Validation Cloud Rayls Mainnet endpoint
- **Collection environment:** GitHub Codespaces
- **Status:** Initial event reconstruction completed; wider historical inventory and economic interpretation remain outstanding.

## 1. Purpose

This document records historical logs returned by two contract-address queries over the same block interval:

- NativeTokenController proxy:
  `0x07e17e17e17e17e17e17e17e17e17e17e17e17e6`
- USDr native-token precompile:
  `0x0000000000000000000000000000000000000400`

It also records the transaction receipt for the 50 USDr transfer identified in the precompile logs.

The objective is to reconstruct the observable transaction sequence surrounding the 18,026.574051066495598471 USDr burn.

This document distinguishes raw observations from decoded interpretations. It does not claim that the interval represents the complete history of USDr supply.

## 2. Method and provenance

The user retrieved the JSON-RPC responses directly in GitHub Codespaces using the Validation Cloud Rayls Mainnet endpoint.

The endpoint URL and credential are intentionally excluded.

The two log queries used:

- RPC method: `eth_getLogs`
- From block: `0xad6186` (11,362,694)
- To block: `0xad70cc` (11,366,604)

The controller query filtered by the NativeTokenController proxy address.

The precompile query filtered by the USDr native-token precompile address and did not specify a topic filter.

A separate `eth_getTransactionReceipt` query retrieved the receipt for the 50 USDr transfer.

## 3. NativeTokenController logs

The controller query returned two logs.

### 3.1 MINTER_ROLE grant

| Field | Value |
|---|---|
| Block | 11,366,001 (`0xad6e71`) |
| Timestamp | `0x6abe5f0c` |
| Transaction | `0xa6b61b11e55b194d11a4d419b3964cd06355847fe3319e1645b4f5c7acee8435` |
| Log index | `0x0` |
| Contract | NativeTokenController proxy |
| Event topic 0 | `0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d` |
| Event topic 1 | `0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6` |
| Indexed address | `0x6b205d256e8a153cba8057e5655db56e0e47a511` |
| Second indexed address | `0x6b205d256e8a153cba8057e5655db56e0e47a511` |
| Data | `0x` |

The event topics correspond to the AccessControl role-grant event structure. The role identifier is the `MINTER_ROLE` identifier previously established in Phase 2.

The same address appears as both the account receiving the role and the sender recorded in the event.

**Finding:** The additional minter address granted itself the MINTER_ROLE in this transaction.

This is consistent with the Phase 2 role-grant investigation.

### 3.2 NativeTokenController burn event

| Field | Value |
|---|---|
| Block | 11,366,604 (`0xad70cc`) |
| Timestamp | `0x6abe60b0` |
| Transaction | `0x3e1fb4b25043bc55e208b29a601966710c6ddf2fec4edcd015b1550fb43cfa4a` |
| Log index | `0x2` |
| Event topic 0 | `0x6ab368f832c266c8eb942b84fbcaa20aedc24a699d2a05fae2568028733b1d09` |
| Indexed caller | `0x6b205d256e8a153cba8057e5655db56e0e47a511` |
| Indexed account | `0x633ac5e2315b973417e8caa6b3ad2162e0461ce1` |
| Raw amount | `0x0000000000000000000000000000000000000000000003d138f8368ff4cf7f87` |
| Decoded amount | 18,026.574051066495598471 USDr |

**Finding:** The controller emitted a burn event recording the additional minter as caller and the separate burn account as the account being burned.

The successful receipt for this transaction was separately preserved in `phase-4-historical-receipts-and-state.md`.

## 4. USDr native-token precompile logs

The unfiltered precompile query returned five logs.

### 4.1 Transfer into the eventual burn account

| Field | Value |
|---|---|
| Block | 11,363,419 (`0xad645b`) |
| Transaction | `0x08dfa0ac555badc5b00a35f206bb20b23d2ba0a14e270a3be77fe884951636` |
| Log index | `0x0` |
| Event topic | `0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef` |
| From | `0xab5309be3d6e228288da1f68df3f993a550dec7c` |
| To | `0x633ac5e2315b973417e8caa6b3ad2162e0461ce1` |
| Raw amount | `0x0000000000000000000000000000000000000000000003d138f8368ff4cf7f87` |
| Decoded amount | 18,026.574051066495598471 USDr |

The canonical ERC-20 `Transfer` topic identifies this as a token transfer.

**Finding:** The eventual burn account received exactly the amount later approved and burned.

### 4.2 Approval to the NativeTokenController

| Field | Value |
|---|---|
| Block | 11,364,313 (`0xad65d9`) |
| Transaction | `0xd3d744e8b95c4bba308694bd8fb077b84d0d35c70970d2ab94d1c2b4399781a4` |
| Log index | `0x0` |
| Event topic | `0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925` |
| Owner | `0x633ac5e2315b973417e8caa6b3ad2162e0461ce1` |
| Spender | `0x07e17e17e17e17e17e17e17e17e17e17e17e17e6` |
| Raw allowance | `0x0000000000000000000000000000000000000000000003d138f8368ff4cf7f87` |
| Decoded allowance | 18,026.574051066495598471 USDr |

The canonical ERC-20 `Approval` topic identifies this as an allowance event.

**Finding:** The burn account approved the NativeTokenController to spend exactly the amount it had received.

### 4.3 Separate 50 USDr transfer

| Field | Value |
|---|---|
| Block | 11,365,773 (`0xad6d8d`) |
| Timestamp | `0x6abe5e6e` |
| Transaction | `0x7c2909e6f79e520721eacd6a63ccb4d1199c9c704010630178f9035d18fcf561` |
| Log index | `0x0` |
| Event topic | `0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef` |
| From | `0x0e301beef8daad28f8e38d9fce09112b78fe3161` |
| To | `0x6b205d256e8a153cba8057e5655db56e0e47a511` |
| Raw amount | `0x000000000000000000000000000000000000000000000002b5e3af16b1880000` |
| Decoded amount | 50 USDr |

**Finding:** The address that received the October 1 cross-chain USDC.e arrival transferred 50 USDr to the additional minter.

This is a separate transfer from the 18,026.574051066495598471 USDr burn sequence. The available log does not establish its purpose.

### 4.4 Burn-related precompile event

| Field | Value |
|---|---|
| Block | 11,366,604 (`0xad70cc`) |
| Transaction | `0x3e1fb4b25043bc55e208b29a601966710c6ddf2fec4edcd015b1550fb43cfa4a` |
| Log index | `0x0` |
| Event topic | `0xcc16f5dbb4873280815c1ee09dbd06736cffcc184412cf7a71a0fdb75d397ca5` |
| Indexed account | `0x633ac5e2315b973417e8caa6b3ad2162e0461ce1` |
| Raw amount | `0x0000000000000000000000000000000000000000000003d138f8368ff4cf7f87` |
| Decoded amount | 18,026.574051066495598471 USDr |

This topic was previously observed in the successful burn receipt. Its full ABI interpretation should be verified against the relevant native-token event definition before assigning a definitive event name.

### 4.5 Zero-address transfer

| Field | Value |
|---|---|
| Block | 11,366,604 (`0xad70cc`) |
| Transaction | `0x3e1fb4b25043bc55e208b29a601966710c6ddf2fec4edcd015b1550fb43cfa4a` |
| Log index | `0x1` |
| Event topic | `0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef` |
| From | `0x633ac5e2315b973417e8caa6b3ad2162e0461ce1` |
| To | `0x0000000000000000000000000000000000000000` |
| Raw amount | `0x0000000000000000000000000000000000000000000003d138f8368ff4cf7f87` |
| Decoded amount | 18,026.574051066495598471 USDr |

**Finding:** The same transaction emitted a canonical `Transfer` event from the burn account to the zero address.

This agrees with the successful controller burn receipt and the controller event.

## 5. Receipt verification for the 50 USDr transfer

The transaction receipt was retrieved separately using `eth_getTransactionReceipt`.

| Field | Value |
|---|---|
| Transaction | `0x7c2909e6f79e520721eacd6a63ccb4d1199c9c704010630178f9035d18fcf561` |
| Receipt status | `0x1` — successful |
| Block | 11,365,773 (`0xad6d8d`) |
| Block hash | `0x57e8a60c7f6293517fa6f2df67255963176fc1fd62b029f5ff6ee390e68486f3` |
| Sender | `0x0e301beef8daad28f8e38d9fce09112b78fe3161` |
| Transaction target | `0x6b205d256e8a153cba8057e5655db56e0e47a511` |
| Gas used | `0x5208` |
| Cumulative gas used | `0x5208` |
| Effective gas price | `0xd693a4000` |

The receipt contains one log from the USDr precompile. It records the 50 USDr transfer from the sender to the transaction target.

**Finding:** This was a successful direct transfer transaction, not merely an unconfirmed transaction object.

The receipt does not explain the economic purpose of the transfer.

## 6. Reconstructed transaction sequence

The observed events establish the following order:

| Order | Block | Event | Amount |
|---:|---:|---|---:|
| 1 | 11,363,419 | USDr transferred to eventual burn account | 18,026.574051066495598471 |
| 2 | 11,364,313 | Burn account approves NativeTokenController | 18,026.574051066495598471 |
| 3 | 11,365,773 | October 1 recipient transfers USDr to additional minter | 50 |
| 4 | 11,366,001 | Additional minter receives MINTER_ROLE | Role grant |
| 5 | 11,366,604 | Additional minter calls controller to burn from burn account | 18,026.574051066495598471 |
| 6 | 11,366,604 | Precompile emits burn-related event and zero-address transfer | 18,026.574051066495598471 |

The role grant and 50 USDr transfer occurred before the burn.

The burn account's receipt, approval, and burn amounts match exactly.

## 7. Supply-event assessment for this interval

The unfiltered `eth_getLogs` query against the USDr precompile returned five logs:

- Two ordinary ERC-20-style `Transfer` events.
- One `Approval` event.
- One burn-related precompile event.
- One zero-address `Transfer` event associated with the burn.

More precisely, the five returned logs comprise:

1. Transfer into the burn account.
2. Approval to the controller.
3. Separate 50 USDr transfer to the additional minter.
4. Burn-related precompile event.
5. Transfer from the burn account to the zero address.

No zero-address-to-account `Transfer` event appears in this returned set.

The controller query returned two logs:

1. MINTER_ROLE grant.
2. Controller burn event.

### Bounded conclusion

Within the requested interval and for the queried addresses, the returned logs identify:

- One observed USDr burn of 18,026.574051066495598471 USDr.
- No observed standard zero-address-to-account mint transfer.
- One separate 50 USDr transfer to the additional minter.
- One MINTER_ROLE grant to that same additional minter.

The supply snapshots previously retrieved at blocks 11,362,694 and 11,366,604 differ by exactly the identified burn amount.

Together, these observations strongly support the conclusion that the identified burn explains the difference between those two sampled total-supply values.

This is not yet a complete historical inventory of every possible supply-changing mechanism. The conclusion is limited to the returned logs from the queried controller and precompile addresses over the specified interval.

## 8. What remains unresolved

The evidence does not yet establish:

1. Why the additional minter received 50 USDr.
2. Why the burn account received the 18,026.574051066495598471 USDr.
3. Whether the burn represented redemption, bridge-out, correction, or another operational action.
4. Whether the separate 50 USDr transfer had any relationship to the burn.
5. Whether other contracts or mechanisms could alter USDr supply without emitting the queried precompile or controller events.
6. Whether the October 1 correction transactions resolved the entire historical shortfall.
7. The complete historical inventory of USDr mint and burn events outside this interval.

These questions require further transaction, contract, and event analysis.

## 9. Evidence conclusion

The retrieved historical logs and receipts establish a coherent sequence for the 18,026.574051066495598471 USDr burn:

- The burn account received the exact amount.
- The burn account approved the NativeTokenController for the exact amount.
- The additional minter had a MINTER_ROLE grant recorded in the queried interval.
- The additional minter called the controller.
- The controller and USDr precompile emitted corresponding burn records.
- The burn account's balance was transferred to the zero address.
- The burn transaction receipt confirms successful execution.

A separate successful 50 USDr transfer from the October 1 recipient to the additional minter is also confirmed, but its purpose remains unknown.

The evidence supports the burn as the explanation for the difference between the two sampled total-supply values. It does not establish the complete economic explanation for the historical backing shortfall.
