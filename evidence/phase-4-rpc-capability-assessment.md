# Phase 4 RPC Capability Assessment

**Project:** Rayls USDr 1:1 Backing Verification  
**Phase:** Phase 4 — Historical USDr Supply and Escrow Reconstruction  
**Assessment date:** 2026-11-20  
**Network:** Rayls Mainnet  
**Chain ID:** 72957 (`0x11cfd`)  
**RPC endpoint:** `https://mainnet-rpc.rayls.com/`  
**Status:** Initial capability assessment completed

---

## 1. Purpose

This assessment records the results of testing the public Rayls Mainnet JSON-RPC endpoint for historical data retrieval required by Phase 4.

Phase 4 requires reconstruction of historical USDr supply changes and correlation of those changes with USDC.e movements and escrow balances.

The investigation therefore needs reliable access to:

- Historical transaction objects.
- Transaction receipts and execution status.
- Event logs emitted by relevant contracts.
- Historical contract state, including token balances and supply.
- Block-level information needed to establish transaction inclusion and ordering.

The purpose of this assessment is to establish which of these data types the tested public RPC can currently provide for the historical transactions under investigation.

This is a capability assessment of the tested endpoint and methods. It is not an assessment of the USDr protocol's solvency or a conclusion about whether any transaction succeeded or failed.

## 2. Relevant contracts and transactions

### 2.1 Contract addresses

| Component | Address |
|---|---|
| USDr native-token precompile | `0x0000000000000000000000000000000000000400` |
| USDC.e | `0x9001dbe4D68d36ab87923A2a9Dfb0c745fd25001` |
| USDrEscrow proxy | `0xD19A5e28FEd41FA289E92Ae61B9Bc5BD883DB0D2` |
| NativeTokenController proxy | `0x07E17E17e17E17E17e17e17e17e17E17E17E17E6` |

### 2.2 Historical transactions selected for testing

**Escrow deposit**

- Transaction hash: `0x802cdd6b480bfbdb02ea3c921671827b77a8582e7f03f3e1da4ceae1ee502c2c`
- Rayls block: 11,362,694 (`0xad6186`)
- Transaction sender: `0x0e301bEEF8daaD28f8e38D9Fce09112b78fE3161`
- Target: USDC.e contract
- Submitted operation: ERC-20 `transfer(address,uint256)`
- Encoded recipient: USDrEscrow proxy
- Encoded amount: 20,000 USDC.e

**USDr burn**

- Transaction hash: `0x3e1fb4b25043bc55e208b29a601966710c6ddf2fec4edcd015b1550fb43cfa4a`
- Rayls block: 11,366,604 (`0xad70cc`)
- Transaction sender/caller: `0x6B205d256E8a153CBa8057E5655db56e0E47A511`
- Target: NativeTokenController proxy
- Submitted operation: `burn(address,uint256)`
- Encoded account argument: `0x633Ac5e2315b973417e8caa6B3Ad2162e0461ce1`
- Encoded amount: 18,026.574051066495598471 USDr

These transactions were selected because they are relevant to the earlier investigation of the October 1 USDC.e escrow deposit and the historical 18,026.574051066495598471 USDr burn.

## 3. Experiments and results

### Experiment 1 — USDr precompile event-log query

**Method:** `eth_getLogs`

**Block range:** `0xad5ed0` to `0xad70cc`  
**Address filter:** USDr precompile, `0x0000000000000000000000000000000000000400`  
**Topic filter:** ERC-20 `Transfer` event signature.

**Result:**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": []
}
```

**Interpretation:** The query returned no matching logs. This does not establish that no USDr transfer or burn events occurred. The assumed emitting address and historical log availability were not independently established by this test.

### Experiment 2 — Individual receipt retrieval for the burn

**Method:** `eth_getTransactionReceipt`

**Transaction:** `0x3e1fb4b25043bc55e208b29a601966710c6ddf2fec4edcd015b1550fb43cfa4a`

**Result:**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": null
}
```

**Interpretation:** The endpoint did not return a receipt for the known transaction hash. The result does not establish transaction failure or absence.

### Experiment 3 — Burn transaction retrieval by hash

**Method:** `eth_getTransactionByHash`

**Transaction:** `0x3e1fb4b25043bc55e208b29a601966710c6ddf2fec4edcd015b1550fb43cfa4a`

**Result:** A transaction object was returned.

The retrieved object identified:

- Chain ID: `0x11cfd` (72957).
- Block number: `0xad70cc` (11,366,604).
- Transaction index: `0x0`.
- Sender: `0x6b205d256e8a153cba8057e5655db56e0e47a511`.
- Target: `0x07e17e17e17e17e17e17e17e17e17e17e17e17e6`.
- Input selector: `0x9dc29fac`.
- Transaction hash: `0x3e1fb4b25043bc55e208b29a601966710c6ddf2fec4edcd015b1550fb43cfa4a`.

The input selector corresponds to `burn(address,uint256)`.

The encoded arguments identify the account:

`0x633ac5e2315b973417e8caa6b3ad2162e0461ce1`

and the raw amount:

`0x3d138f8368ff4cf7f87`

The raw amount converts to 18,026.574051066495598471 USDr using 18 decimal places.

**Interpretation:** The endpoint can retrieve the historical transaction object and its submitted call data. This confirms the contents and block association of the submitted transaction. It does not independently confirm successful execution.

### Experiment 4 — Controller-address logs at the burn block

**Method:** `eth_getLogs`

**Block:** `0xad70cc`  
**Address filter:** NativeTokenController proxy.

**Result:**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": []
}
```

**Interpretation:** No logs were returned by this query. Because the receipt was also unavailable, this result cannot establish that the controller emitted no events.

### Experiment 5 — All logs at the burn block

**Method:** `eth_getLogs`

**Block:** `0xad70cc`  
**Address filter:** None.

**Result:**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": []
}
```

**Interpretation:** The endpoint returned an empty result even without an address filter. This strengthens the observation that the tested historical log query is not providing the expected block-level log data. It does not prove that the block contained no logs.

### Experiment 6 — Individual receipt retrieval for the escrow deposit

**Method:** `eth_getTransactionReceipt`

**Transaction:** `0x802cdd6b480bfbdb02ea3c921671827b77a8582e7f03f3e1da4ceae1ee502c2c`

**Result:**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": null
}
```

**Interpretation:** The endpoint did not return a receipt for the known escrow-deposit transaction either. The receipt-access issue is therefore not limited to the burn transaction.

### Experiment 7 — Full block retrieval for the escrow deposit

**Method:** `eth_getBlockByNumber`

**Parameters:** Block `0xad6186`, with full transaction objects requested (`true`).

**Result:** The endpoint returned the full block object.

Relevant block fields:

- Block number: `0xad6186` (11,362,694).
- Block hash: `0xb5e865317dc1bc0fc261a6a26e6f337bcab213886e23f0a6c15ba708ad1ab661`.
- Transactions: one.
- Transaction index: `0x0`.

The returned transaction object contained:

- Hash: `0x802cdd6b480bfbdb02ea3c921671827b77a8582e7f03f3e1da4ceae1ee502c2c`.
- Sender: `0x0e301beef8daad28f8e38d9fce09112b78fe3161`.
- Target: `0x9001dbe4d68d36ab87923a2a9dfb0c745fd25001`.
- Input selector: `0xa9059cbb`.
- Transaction index: `0x0`.

The selector corresponds to ERC-20 `transfer(address,uint256)`.

The encoded recipient is the USDrEscrow proxy:

`0xd19a5e28fed41fa289e92ae61b9bc5bd883db0d2`

The encoded amount is:

`0x4a817c800` = 20,000,000,000 base units.

With six USDC.e decimals, this equals **20,000 USDC.e**.

**Interpretation:** The endpoint can retrieve the historical block and its full transaction object. The transaction's inclusion and submitted transfer call data are independently observable through this RPC response. Successful execution is not independently established because the receipt is unavailable.

### Experiment 8 — Full block retrieval for the burn

**Method:** `eth_getBlockByNumber`

**Parameters:** Block `0xad70cc`, with full transaction objects requested (`true`).

**Result:** The endpoint returned the full block object.

Relevant block fields:

- Block number: `0xad70cc` (11,366,604).
- Block hash: `0x13752eed9f151bcce054472dafc048be273f34f32cecebe3d14955880775bf56`.
- Transactions: one.
- Transaction index: `0x0`.

The returned transaction object matched the earlier transaction-by-hash result:

- Hash: `0x3e1fb4b25043bc55e208b29a601966710c6ddf2fec4edcd015b1550fb43cfa4a`.
- Sender: `0x6b205d256e8a153cba8057e5655db56e0e47a511`.
- Target: NativeTokenController proxy.
- Input selector: `0x9dc29fac`.
- Encoded account: `0x633ac5e2315b973417e8caa6b3ad2162e0461ce1`.
- Encoded amount: 18,026.574051066495598471 USDr.

**Interpretation:** The full-block result independently reproduces the burn transaction object, its block association and submitted call data.

### Experiment 9 — Block receipts for the burn

**Method:** `eth_getBlockReceipts`

**Block:** `0xad70cc`

**Result:**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": []
}
```

**Interpretation:** The method was accepted, but the endpoint returned an empty array instead of the expected block receipt data. This does not establish that the transaction failed or that no logs were emitted.

### Experiment 10 — Block receipts for the escrow deposit

**Method:** `eth_getBlockReceipts`

**Block:** `0xad6186`

**Result:**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": []
}
```

**Interpretation:** The same empty-array result occurred for the escrow-deposit block. The observation is therefore not specific to the burn block.

### Experiment 11 — Historical USDC.e escrow balance query

**Method:** `eth_call`

**Contract:** USDC.e  
**Function:** `balanceOf(address)`  
**Account:** USDrEscrow proxy  
**Block parameter:** `0xad6186` (11,362,694)

**Result:**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32603,
    "message": "state at block #11362695 is pruned"
  }
}
```

**Interpretation:** The endpoint explicitly reports that the historical state required for the query is pruned. The requested historical balance cannot be retrieved through this call.

The error references block 11,362,695. This is the node's reported state-pruning message and should be preserved verbatim rather than interpreted as evidence that the requested block is missing.

## 4. Consolidated capability matrix

| Data requirement | Tested method | Observed result | Assessment |
|---|---|---|---|
| Historical transaction by hash | `eth_getTransactionByHash` | Burn transaction object returned | Available in tested case |
| Historical full block | `eth_getBlockByNumber` | Full block and transaction objects returned for both blocks | Available in tested cases |
| Individual historical receipt | `eth_getTransactionReceipt` | `null` for both transactions | Not available in tested cases |
| Historical contract logs | `eth_getLogs` | Empty results in tested queries | Not providing expected data |
| Block-level receipts | `eth_getBlockReceipts` | Empty arrays for both blocks | Not providing expected data |
| Historical contract state | `eth_call` | Explicit state-pruned error | Unavailable for tested block |

These results describe only the endpoint, methods, and historical blocks tested on 2026-11-20. They should not be generalized to every block or every method supported by the network.

## 5. What has been established

The following findings are supported by the direct RPC responses collected during this assessment:

1. The public Rayls RPC returned the full historical block object for block 11,362,694.
2. That block contained the transaction submitted by `0x0e301bEEF8daaD28f8e38D9Fce09112b78fE3161` to the USDC.e contract.
3. The transaction input encoded a transfer of 20,000 USDC.e to the USDrEscrow proxy.
4. The public Rayls RPC returned the full historical block object for block 11,366,604.
5. That block contained the transaction submitted by `0x6B205d256E8a153CBa8057E5655db56e0E47A511` to the NativeTokenController proxy.
6. The transaction input encoded a burn call for 18,026.574051066495598471 USDr against account `0x633Ac5e2315b973417e8caa6B3Ad2162e0461ce1`.
7. Individual receipt retrieval, block-receipt retrieval and the tested historical log queries did not return the expected data.
8. The historical USDC.e balance query failed with an explicit state-pruned error.

## 6. What has not been established

This assessment does not independently establish:

- Whether either transaction executed successfully.
- Whether the escrow deposit emitted a USDC.e `Transfer` event.
- Whether the burn emitted a controller `Burned` event or a token `Transfer` event.
- The USDC.e escrow balance at the end of block 11,362,694.
- The USDr total supply at either historical block.
- Whether the 20,000 USDC.e deposit was economically or operationally connected to the 18,026.574051066495598471 USDr burn.
- Whether the burn was associated with a bridge-out, redemption, correction or another operation.
- Whether the historical backing shortfall was resolved by the October 1 correction transactions.

The absence of returned receipts and logs from this endpoint must not be treated as proof that events or successful executions did not exist.

## 7. Methodological implications for Phase 4

The public endpoint is useful for retrieving historical block headers and transaction objects in the tested cases. However, the tested methods do not provide the receipts, event logs or historical state required to complete the Phase 4 reconstruction.

Continuing to repeat the same queries against the same endpoint is unlikely to resolve the identified evidence gaps without a change in data source or node capability.

The next data source must be tested for the following capabilities:

1. Retrieval of historical transaction receipts for the two known transaction hashes.
2. Retrieval of complete logs for the corresponding blocks.
3. Retrieval of USDr and USDC.e contract events over the historical Phase 4 investigation range.
4. Historical `eth_call` support for USDC.e `balanceOf`, USDr total supply and relevant contract state.
5. Sufficient historical coverage for the full supply and escrow reconstruction.

A candidate endpoint must be tested against the known transactions before being accepted as the Phase 4 evidence source. Results should be compared with the transaction hashes, block numbers and call data recorded in this assessment.

If a different provider is used, preserve its endpoint identity, query parameters, retrieval date and raw responses. Do not expose API credentials in the repository or research transcript.

## 8. Evidence classification

| Finding | Classification |
|---|---|
| Burn transaction object and submitted call data retrieved | Confirmed |
| Escrow-deposit transaction object and submitted call data retrieved | Confirmed |
| Both transactions included in the returned full block objects | Confirmed |
| Historical receipt and log access unavailable through tested methods | Confirmed for the tested queries |
| Historical state pruned for the tested `eth_call` | Confirmed |
| Either transaction failed | Unresolved |
| Either transaction emitted no events | Unresolved |
| Burn and deposit were economically connected | Unresolved |

## 9. Conclusion

The public Rayls Mainnet RPC provides historical block and transaction-object retrieval for the two selected Phase 4 transactions. It did not provide the corresponding historical receipts, useful log results or the requested historical USDC.e escrow balance.

The explicit state-pruned error establishes that the endpoint cannot supply the historical state needed for the tested balance query.

Accordingly, this endpoint alone is insufficient for the historical supply, event and escrow reconstruction required by Phase 4.

The investigation should retain the transaction objects already retrieved as direct RPC evidence and proceed by evaluating an alternative archive-capable data source. No conclusion about successful execution, event emission, historical backing or resolution of the shortfall should be drawn from the unavailable data.

---

**End of assessment**
