# Phase 4: Historical Receipts and State Evidence

**Research project:** Rayls USDr 1:1 backing verification  
**Network:** Rayls Mainnet  
**Chain ID:** 72957 (`0x11cfd`)  
**Evidence collection method:** Direct JSON-RPC queries through the Validation Cloud Rayls Mainnet endpoint  
**Collection environment:** GitHub Codespaces  
**Status:** Historical receipt and state observations preserved; full supply-event reconstruction remains outstanding.

## 1. Purpose

This document records historical transaction receipts and historical contract-state observations retrieved during Phase 4.

The evidence addresses three connected questions:

- Did the 18,026.574051066495598471 USDr burn execute successfully?
- What were the USDr total supply and USDC.e escrow balance at the sampled historical block heights?
- How did the measured escrow-minus-supply position change across those two snapshots?

The observations are recorded separately from interpretations. They do not constitute a complete reconstruction of every historical mint, burn, deposit, or withdrawal.

## 2. Evidence provenance and limitations

The JSON-RPC observations in this document were retrieved directly by the user in Codespaces through a Validation Cloud Rayls Mainnet endpoint. The values below were transcribed from the returned outputs.

The endpoint URL and credential are deliberately excluded.

The public Rayls RPC had previously failed to provide the historical receipts and state required for this investigation. The Validation Cloud endpoint successfully returned the historical observations recorded here.

Important limitations:

1. The historical state calls represent state at the requested block heights. They are not a continuous record of activity between those blocks.
2. Matching supply differences and a burn amount do not, by themselves, establish that no other supply changes occurred in the interval.
3. Matching escrow balances at two sampled block heights do not rule out intermediate deposits and withdrawals that netted to the same balance.
4. The evidence confirms the execution of the specific burn, but does not establish its economic purpose.
5. A complete historical mint/burn event inventory and transaction-to-escrow correlation remain necessary.
6. The receipt log topics are recorded as returned. The canonical ERC-20 `Transfer` topic is recognizable, but a complete ABI-based decoding of every event has not yet been performed.

## 3. Historical USDr burn receipt

### Transaction identification

| Field | Value |
|---|---|
| Transaction hash | `0x3e1fb4b25043bc55e208b29a601966710c6ddf2fec4edcd015b1550fb43cfa4a` |
| Block number | `11,366,604` (`0xad70cc`) |
| Block hash | `0x13752eed9f151bcce054472dafc048be273f34f32cecebe3d14955880775bf56` |
| Timestamp | `2026-10-01 13:31:28 UTC` |
| Sender / caller | `0x6b205d256e8a153cba8057e5655db56e0e47a511` |
| Transaction target | NativeTokenController proxy |
| Target address | `0x07e17e17e17e17e17e17e17e17e17e17e17e17e6` |
| Receipt status | `0x1` — successful |
| Gas used | `0xa35d` |

### Receipt observations

The receipt returned three relevant logs:

1. A log from the USDr native-token precompile at `0x0000000000000000000000000000000000000400`.
   - Topic: `0xcc16f5...`
   - Indexed account: `0x633ac5e2315b973417e8caa6b3ad2162e0461ce1`
   - Amount data: `0x3d138f8368ff4cf7f87`

2. An ERC-20 `Transfer` log.
   - Topic: `0xddf252...`
   - From: `0x633ac5e2315b973417e8caa6b3ad2162e0461ce1`
   - To: zero address
   - Amount: the same raw amount, `0x3d138f8368ff4cf7f87`

3. A NativeTokenController event.
   - Topic: `0x6ab368...`
   - Indexed caller: `0x6b205d256e8a153cba8057e5655db56e0e47a511`
   - Indexed account: `0x633ac5e2315b973417e8caa6b3ad2162e0461ce1`
   - Amount data: the same raw amount.

### Decoded burn amount

The raw amount corresponds to:

**18,026.574051066495598471 USDr**

### Directly supported finding

The receipt status is `0x1`, and the returned logs record the corresponding amount being transferred to the zero address and a controller burn event.

This confirms that the identified transaction successfully executed the 18,026.574051066495598471 USDr burn.

It does not establish why the burn was performed or whether it was part of a redemption, bridge-out, correction, or another operational process.

## 4. Historical USDC.e escrow deposit receipt

### Transaction identification

| Field | Value |
|---|---|
| Transaction hash | `0x802cdd6b480bfbdb02ea3c921671827b77a8582e7f03f3e1da4ceae1ee502c2c` |
| Block number | `11,362,694` (`0xad6186`) |
| Block hash | `0xb5e865317dc1bc0fc261a6a26e6f337bcab213886e23f0a6c15ba708ad1ab661` |
| Timestamp | `2026-10-01 12:46:29 UTC` |
| Sender | `0x0e301beef8daad28f8e38d9fce09112b78fe3161` |
| Token contract | `0x9001dbe4d68d36ab87923a2a9dfb0c745fd25001` |
| Receipt status | `0x1` — successful |

### Receipt observation

The receipt returned an ERC-20 `Transfer` log:

- From: `0x0e301beef8daad28f8e38d9fce09112b78fe3161`
- To: USDrEscrow proxy, `0xd19a5e28fed41fa289e92ae61b9bc5bd883db0d2`
- Raw amount: `0x4a817c800`
- Token decimals: 6

Decoded amount:

**20,000 USDC.e**

### Directly supported finding

The successful receipt confirms that 20,000 USDC.e was transferred from the sender to the USDrEscrow proxy in this transaction.

## 5. Cross-chain USDC.e arrival receipt

### Rayls destination transaction

| Field | Value |
|---|---|
| Transaction hash | `0x8735426f04ba432e865049cd5bdfca58e9d5b51f92a60413b4eeb1b39d76eca7` |
| Block number | `11,362,493` (`0xad608d`) |
| Block hash | `0x3cc0e3b5cd06718d020516f25bca18811dde7ea99fa0edcafb3fb4622f2f0489` |
| Timestamp | `2026-10-01 12:43:36 UTC` |
| Transaction sender | `0xe93685f3bba03016f02bd1828badd6195988d950` |
| Transaction target | LayerZero executor, `0x4208d6e27538189bb48e603d6123a94b8abe0a0b` |
| Receipt status | `0x1` — successful |

### Receipt observations

The receipt returned:

- A USDC.e OFT-related event.
- A token transfer from the zero address to `0x0e301beef8daad28f8e38d9fce09112b78fe3161`.
- A LayerZero bridge event containing GUID:

`0xd1a54800891e863dc488164224d2071072c077c8c12c9fef9f0d5d2bc7855c43`

The raw token amount was:

`0x4a817cabb`

Decoded at 6 decimals:

**20,000.000699 USDC.e**

### Relationship to the escrow deposit

The destination transaction occurred at 12:43:36 UTC.

The escrow deposit occurred at 12:46:29 UTC, approximately 2 minutes and 53 seconds later.

The destination transaction minted 20,000.000699 USDC.e to the recipient. The later escrow deposit transferred 20,000 USDC.e from that same recipient to the escrow.

The difference is:

**0.000699 USDC.e**

This is consistent with the recipient retaining the 0.000699 USDC.e remainder after depositing 20,000 USDC.e.

The LayerZero GUID and the previously collected Ethereum-side evidence associate the arrival with the cross-chain transfer initiated by:

`0x097b640d93fb203f2bbcae27b6e0a4892f7dd1dd1acca1ccde5c529b0aad7ffb`

The Ethereum source transaction was documented during Phase 2. Its receipt was not retrieved as part of the current Validation Cloud receipt collection.

### Directly supported finding

The Rayls destination receipt confirms successful minting of 20,000.000699 USDC.e to the recipient. The subsequent receipt confirms that 20,000 USDC.e from the same recipient was deposited into the escrow.

This establishes a transaction-level sequence for this particular deposit. It does not establish a direct economic relationship between this deposit and the separate 18,026.574051066495598471 USDr burn.

## 6. Historical USDC.e escrow balance

The USDC.e contract queried was:

`0x9001dbe4d68d36ab87923a2a9dfb0c745fd25001`

The escrow address queried was:

`0xd19a5e28fed41fa289e92ae61b9bc5bd883db0d2`

The historical `eth_call` used the USDC.e `balanceOf(address)` method.

### Returned values

| Requested block | Raw RPC result | Decoded balance |
|---|---|---:|
| 11,362,694 (`0xad6186`) | `0x0000000000000000000000000000000000000000000000000000000623ddd199` | 26,371.543449 USDC.e |
| 11,366,604 (`0xad70cc`) | `0x0000000000000000000000000000000000000000000000000000000623ddd199` | 26,371.543449 USDC.e |

Both calls returned the same raw value.

### Directly supported finding

At the two sampled block heights, the USDrEscrow proxy held **26,371.543449 USDC.e**.

The identical sampled balances do not establish that the escrow balance remained unchanged throughout the intervening period. Intermediate movements are not ruled out.

## 7. Historical USDr total supply

The USDr native-token precompile queried was:

`0x0000000000000000000000000000000000000400`

The `totalSupply()` selector used was:

`0x18160ddd`

### Returned values

| Requested block | Raw RPC result | Decoded total supply |
|---|---|---:|
| 11,362,694 (`0xad6186`) | `0x0000000000000000000000000000000000000000000009311b4d565b14ff1000` | 43,407.156129 USDr |
| 11,366,604 (`0xad70cc`) | `0x00000000000000000000000000000000000000000000055fe2551fcb202f9079` | 25,380.582077933504401529 USDr |

### Supply difference

The difference between the two sampled total-supply values is:

43,407.156129  
− 25,380.582077933504401529  
= **18,026.574051066495598471 USDr**

This is exactly equal to the amount recorded in the successful burn receipt.

### Directly supported finding

The sampled total supply decreased by exactly the amount of the identified burn between these two block heights.

This is strong evidence that the burn accounts for the difference between the two sampled supply values.

However, a complete event inventory is still required to establish whether any other mint or burn transactions occurred in the interval.

## 8. Sampled backing comparison

For this comparison, the measured difference is calculated as:

**USDC.e escrow balance − USDr total supply**

This is a comparison of the two sampled on-chain values. It is not, by itself, a complete proof of the system's backing across all chains or custody locations.

### At block 11,362,694

- Escrow balance: 26,371.543449 USDC.e
- USDr total supply: 43,407.156129 USDr

Calculation:

26,371.543449 − 43,407.156129  
= **−17,035.612680**

At this sampled block height, the escrow balance was 17,035.612680 below the USDr supply, using the nominal 1:1 comparison.

### At block 11,366,604

- Escrow balance: 26,371.543449 USDC.e
- USDr total supply: 25,380.582077933504401529 USDr

Calculation:

26,371.543449 − 25,380.582077933504401529  
= **+990.961371066495598471**

At this sampled block height, the escrow balance exceeded the USDr supply by 990.961371066495598471, using the same nominal comparison.

### Change in measured backing difference

+990.961371066495598471  
− (−17,035.612680)  
= **18,026.574051066495598471**

This change is exactly equal to the identified USDr burn amount.

### Interpretation

The sampled values strongly support the conclusion that the burn improved the measured escrow-minus-supply position by reducing USDr supply.

The escrow balance returned by the two sampled historical calls was identical, while the sampled USDr supply was lower by the burn amount.

This supports a specific and limited conclusion:

**At the two sampled block heights, the identified burn explains the full change in the measured escrow-minus-supply difference.**

It does not yet establish the complete cause of the earlier shortfall, the economic purpose of the burn, or whether the October 1 transactions resolved every component of the historical backing issue.

## 9. Consolidated observations

| Observation | Result | Evidence status |
|---|---|---|
| Historical burn receipt | Successful, status `0x1` | Confirmed |
| Burn amount | 18,026.574051066495598471 USDr | Confirmed |
| Historical escrow deposit | Successful transfer of 20,000 USDC.e | Confirmed |
| Cross-chain arrival | Successful mint of 20,000.000699 USDC.e | Confirmed |
| Escrow balance at block 11,362,694 | 26,371.543449 USDC.e | Confirmed by historical state call |
| Escrow balance at block 11,366,604 | 26,371.543449 USDC.e | Confirmed by historical state call |
| Supply at block 11,362,694 | 43,407.156129 USDr | Confirmed by historical state call |
| Supply at block 11,366,604 | 25,380.582077933504401529 USDr | Confirmed by historical state call |
| Difference between sampled supply values | 18,026.574051066495598471 USDr | Calculated |
| Change in sampled escrow-minus-supply difference | 18,026.574051066495598471 | Calculated |
| Complete inventory of intervening supply events | Not yet established | Unresolved |
| Complete inventory of intervening escrow movements | Not yet established | Unresolved |
| Economic purpose of the burn | Not yet established | Unresolved |

## 10. Remaining Phase 4 work

The following work is still required before drawing a complete historical conclusion:

1. Reconstruct all relevant USDr mint and burn transactions, including their callers, accounts, amounts, and execution receipts.
2. Decode the NativeTokenController and USDr precompile events using the correct ABI or verified event signatures.
3. Determine whether other supply changes occurred between blocks 11,362,694 and 11,366,604.
4. Reconstruct relevant USDC.e escrow inflows and outflows over the same historical interval.
5. Investigate the operational purpose of the 18,026.574051066495598471 USDr burn.
6. Identify and verify the October 1 correction transactions and assess whether they resolved the historical shortfall.

## 11. Evidence conclusion

The Validation Cloud historical RPC observations establish that:

- The 18,026.574051066495598471 USDr burn executed successfully.
- The USDr total supply at the two sampled block heights differed by exactly the burn amount.
- The USDC.e escrow balance returned at those two sampled block heights was identical.
- The measured escrow-minus-supply difference moved from a 17,035.612680 shortfall to a 990.961371066495598471 surplus.
- The change in that measured difference exactly matches the burn amount.

These observations provide strong evidence that the identified burn materially changed the sampled backing position by reducing USDr supply.

They do not yet prove the complete historical cause of the shortfall or the economic purpose of the burn. Those conclusions require the remaining transaction and event reconstruction.
