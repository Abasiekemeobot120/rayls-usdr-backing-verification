# Phase 5 — Access-Control and Alternative Minting Reproduction Guide

- **Research project:** Rayls USDr 1:1 backing verification
- **Network:** Rayls Mainnet
- **Chain ID:** 72957 (`0x11cfd`)
- **Environment:** GitHub Codespaces
- **RPC method:** Direct JSON-RPC through the configured `VC_RPC_URL`
- **Historical snapshot:** Block `0xe39323` (14,914,339)
- **Historical issuance transaction:** Block 7,823
**Status:** Reproduction commands and observed results recorded

## 1. Purpose

This guide records the commands used to reproduce the principal Phase 5 access-control and alternative minting observations.

Each experiment includes its purpose, command, observed output, interpretation, and limitations.

All tests using `eth_call` are read-only simulations. They do not submit transactions or modify chain state.

The RPC endpoint and credentials are intentionally excluded. Set `VC_RPC_URL` in the environment before running the commands.

## 2. Contract and account references

| Component | Address |
|---|---|
| USDr precompile | `0x0000000000000000000000000000000000000400` |
| NativeTokenController proxy | `0x07e17e17e17e17e17e17e17e17e17e17e17e17e6` |
| Controller implementation | `0x07e17e17e17e17e17e17e17e17e17e17e17e17e7` |
| USDrEscrow proxy | `0xd19a5e28fed41fa289e92ae61b9bc5bd883db0d2` |
| Original minter proxy | `0x17ea10b6ae4fde59fdbf471bd28ab9710f508816` |
| Additional minter/admin | `0x6b205d256e8a153cba8057e5655db56e0e47a511` |
| Unprivileged test caller | `0x000000000000000000000000000000000000dEaD` |
| Test recipient | `0x000000000000000000000000000000000000bEEF` |

The `MINTER_ROLE` identifier used in the tests is:

`0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6`

## 3. Experiment 1 — historical minter configuration

**Purpose:** Determine which controller address was stored in the original minter proxy at block 7,823.

- **Method:** `eth_getStorageAt`
- **Storage slot:** `0x3c`
**Historical block:** `7823`

### Command

```bash
python - <<'PY'
import os,json,urllib.request

p={"jsonrpc":"2.0","id":1,"method":"eth_getStorageAt",
   "params":["0x17ea10b6ae4fde59fdbf471bd28ab9710f508816",
             hex(0x3c),hex(7823)]}
req=urllib.request.Request(os.environ["VC_RPC_URL"],
    data=json.dumps(p).encode(),headers={"Content-Type":"application/json"})
d=json.load(urllib.request.urlopen(req))
if "error" in d:
    print("RPC ERROR:",d["error"]); raise SystemExit

v=d["result"]
print("Proxy storage slot 0x3c:",v)
print("Decoded address:","0x"+v[-40:])
PY
```

### Observed output

```text
Proxy storage slot 0x3c: 0x00000000000000000000000007e17e17e17e17e17e17e17e17e17e17e17e17e6
Decoded address: 0x07e17e17e17e17e17e17e17e17e17e17e17e17e6
```

**Interpretation:** At block 7,823, the original minter proxy's storage slot `0x3c` contained the NativeTokenController proxy address.

**Limitation:** This establishes the configured address. It does not independently establish which internal function path a particular transaction executed.

## 4. Experiment 2 — historical MINTER_ROLE membership

**Purpose:** Verify that the original minter held `MINTER_ROLE` at block 7,823.

- **Method:** `eth_call` to `hasRole(bytes32,address)`
- **Historical block:** `7823`
**Function selector:** `0x91d14854`

### Command

```bash
python - <<'PY'
import os,json,urllib.request

url=os.environ["VC_RPC_URL"]
controller="0x07e17e17e17e17e17e17e17e17e17e17e17e17e6"
minter="0x17ea10b6ae4fde59fdbf471bd28ab9710f508816"
role="9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6"
data="0x91d14854"+role+"0"*24+minter[2:].lower()

p={"jsonrpc":"2.0","id":1,"method":"eth_call",
   "params":[{"to":controller,"data":data},hex(7823)]}
req=urllib.request.Request(url,data=json.dumps(p).encode(),
    headers={"Content-Type":"application/json"})
d=json.load(urllib.request.urlopen(req))

if "error" in d:
    print("RPC ERROR:",d["error"])
else:
    print("Controller:",controller)
    print("Historical block: 7823")
    print("Original minter:",minter)
    print("MINTER_ROLE:", "TRUE" if int(d["result"],16)==1 else "FALSE")
PY
```

### Observed output

```text
Controller: 0x07e17e17e17e17e17e17e17e17e17e17e17e17e6
Historical block: 7823
Original minter: 0x17ea10b6ae4fde59fdbf471bd28ab9710f508816
MINTER_ROLE: TRUE
```

**Interpretation:** The original minter held `MINTER_ROLE` at the historical block of the 45-recipient issuance transaction.

**Limitation:** Role membership and configured controller address do not prove that the transaction executed the particular mint call identified in the implementation bytecode.

## 5. Experiment 3 — additional minter's ability to grant MINTER_ROLE

**Purpose:** Test whether the additional minter/admin can grant `MINTER_ROLE` to another address, and whether an unprivileged caller is rejected.

- **Method:** `eth_call` to `grantRole(bytes32,address)`
- **Snapshot block:** `0xe39323`
**Function selector:** `0x2f2ff15d`

### Command

```bash
python - <<'PY'
import os,json,urllib.request

url=os.environ["VC_RPC_URL"]
controller="0x07e17e17e17e17e17e17e17e17e17e17e17e17e6"
admin="0x6b205d256e8a153cba8057e5655db56e0e47a511"
outsider="0x000000000000000000000000000000000000dEaD"
target="0x000000000000000000000000000000000000bEEF"
role="9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6"
data="0x2f2ff15d"+role+"0"*24+target[2:].lower()

for sender in [admin,outsider]:
    p={"jsonrpc":"2.0","id":1,"method":"eth_call",
       "params":[{"from":sender,"to":controller,"data":data},"0xe39323"]}
    req=urllib.request.Request(url,data=json.dumps(p).encode(),
        headers={"Content-Type":"application/json"})
    d=json.load(urllib.request.urlopen(req))
    if "error" in d:
        print(sender, "REVERT:",
              d["error"].get("data",d["error"].get("message")))
    else:
        print(sender, "CALL SUCCESS:",d["result"])
PY
```

### Observed output

```text
0x6b205d256e8a153cba8057e5655db56e0e47a511 CALL SUCCESS: 0x
0x000000000000000000000000000000000000dEaD REVERT: 0xe2517d3f000000000000000000000000000000000000000000000000000000000000dead0000000000000000000000000000000000000000000000000000000000000000
```

**Interpretation:** The additional minter/admin's simulated role grant succeeds. The unprivileged caller is rejected with `AccessControlUnauthorizedAccount` (`0xe2517d3f`).

**Limitation:** The successful `eth_call` is not an on-chain role grant. It demonstrates that the call would pass the permission check under the queried state.

## 6. Experiment 4 — verify no role was actually granted

**Purpose:** Confirm that the simulated grant did not change the test recipient's role membership.

- **Method:** `eth_call` to `hasRole(bytes32,address)`
**Snapshot block:** `0xe39323`

### Command

```bash
python - <<'PY'
import os,json,urllib.request

url=os.environ["VC_RPC_URL"]
controller="0x07e17e17e17e17e17e17e17e17e17e17e17e17e6"
target="0x000000000000000000000000000000000000bEEF"
role="9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6"
data="0x91d14854"+role+"0"*24+target[2:].lower()

p={"jsonrpc":"2.0","id":1,"method":"eth_call",
   "params":[{"to":controller,"data":data},"0xe39323"]}
req=urllib.request.Request(url,data=json.dumps(p).encode(),
    headers={"Content-Type":"application/json"})
d=json.load(urllib.request.urlopen(req))

if "error" in d:
    print("RPC ERROR:",d["error"])
else:
    print("Test recipient has MINTER_ROLE:",
          "TRUE" if int(d["result"],16)==1 else "FALSE")
PY
```

### Observed output

```text
Test recipient has MINTER_ROLE: FALSE
```

**Interpretation:** The test recipient did not have `MINTER_ROLE` at the queried snapshot. The preceding grant test was a simulation only.

## 7. Experiment 5 — historical issuance transaction and trace limitation

- **Transaction:**
`0xa6fae1913e0acb00842b432bfde3c5cb4f544324fdfec6d64aa27c52d9a4adb0`

- **Block:** `7,823`
- **Transaction sender:** `0x0e301beef8daad28f8e38d9fce09112b78fe3161`
- **Target:** Original minter proxy
`0x17ea10b6ae4fde59fdbf471bd28ab9710f508816`

### Observed receipt summary

```text
status: 0x1
block: 7823
receipt logs: 136
USDr mint events: 45
recipients: 45
total USDr minted: 66,117.621055
USDC.e transfers into escrow in this receipt: 0
```

### Trace result

Both `debug_traceTransaction` using `callTracer` and `trace_transaction` failed because the RPC could not reconstruct historical state. The returned error identified a missing account change set for address:

`0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE`

at block `66846`.

**Interpretation:** The receipt records 45 USDr mint events and no USDC.e transfer into the escrow in that same receipt. The historical storage and role checks establish that the original minter was configured and authorized to call the controller.

**Limitation:** The trace failure prevents confirmation that this particular transaction executed the identified controller mint call. The receipt alone does not rule out other backing arrangements or external state changes.

## 8. Experiment 6 — controller burn permission and later-state allowance check

**Purpose:** Test whether the additional minter can pass the controller's role check for `burn(address,uint256)`.

- **Method:** `eth_call` to controller `burn(address,uint256)`
- **Function selector:** `0x9dc29fac`
**Test account:** `0x633ac5e2315b973417e8caa6b3ad2162e0461ce1`

### Observed result

```text
Additional minter:
REVERT — Insufficient allowance for controller: have 0, need 1

Unprivileged caller:
REVERT — AccessControlUnauthorizedAccount
```

The allowance query for the holder and controller returned zero.

**Interpretation:** The additional minter passed the controller's `MINTER_ROLE` gate and reached the allowance check. The unprivileged caller failed the access-control check.

**Limitation:** This later-state simulation did not demonstrate a successful burn under the tested snapshot conditions. It does not negate the historical successful controller burn initiated by the additional minter on October 1, 2026, documented in Phase 4. That historical burn followed the holder's approval of the exact amount. Its economic purpose remains unresolved.

## 9. Evidence conclusions

The experiments support the following bounded conclusions:

1. The original minter proxy was configured with the NativeTokenController address in storage slot `0x3c` at block 7,823.
2. The original minter held `MINTER_ROLE` at that block.
3. The additional minter/admin can simulate direct controller minting and can simulate granting `MINTER_ROLE` to another account.
4. An unprivileged caller is rejected by the controller's access-control checks.
5. The simulated grant did not change the test recipient's role membership.
6. The later-state burn simulation reached the controller's allowance check and failed; Phase 4 separately confirms a successful historical controller burn initiated by the additional minter.
7. The historical 45-recipient issuance transaction's exact internal execution path remains unresolved because the RPC could not provide a trace.

These results establish that the escrow is not demonstrated to be the exclusive authority capable of minting or burning USDr. They do not establish that the additional minter actually used its direct mint capability to issue USDr outside the escrow workflow.

## 10. Reproduction and safety notes

- Set `VC_RPC_URL` to an authorized Rayls Mainnet RPC endpoint.
- Historical queries require an endpoint that supports archive-state access for the requested block.
- The commands above use read-only JSON-RPC methods (`eth_getStorageAt` and `eth_call`).
- No private key is required.
- No transaction is broadcast.
- No contract storage or account role is changed by these experiments.
- RPC error messages may differ across providers. Record the complete error if a reproduction fails.
- The observed outputs in this document are the outputs captured during the original investigation; a later run may return different results if it queries a different block or endpoint.
