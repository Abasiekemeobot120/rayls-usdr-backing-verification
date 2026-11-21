# Phase 5 — USDr Access-Control and Alternative Minting Findings

- **Research project:** Rayls USDr 1:1 backing verification
- **Network:** Rayls Mainnet
- **Chain ID:** 72957 (`0x11cfd`)
- **Pinned snapshot:** Block `0xe39323` (14,914,339)
- **Snapshot timestamp:** 2026-11-21 07:42:22 UTC
- **Research method:** Direct JSON-RPC queries, historical storage reads, read-only `eth_call` simulations, event-log analysis, bytecode inspection, and transaction tracing
**Status:** Phase 5 evidence collection sufficiently complete for the evidence-package stage

---

## 1. Executive finding

The Phase 5 investigation identified an additional account that holds both `DEFAULT_ADMIN_ROLE` and `MINTER_ROLE` on the NativeTokenController.

At the pinned snapshot, this account can simulate a direct call to the controller's `mint(address,uint256)` entrypoint successfully. An unprivileged test account is rejected by the controller's access-control check.

The investigation also found that the additional account can simulate granting `MINTER_ROLE` to another account. The simulated grant did not change on-chain role membership because the test used `eth_call`, not a transaction.

These observations demonstrate that the escrow is not the only address with controller-level mint authority. They establish an alternative minting capability, but do not establish that this capability was actually used to issue USDr outside the escrow conversion workflow.

The later-state burn simulation did not complete: the additional minter passed the controller's role check but encountered an allowance requirement. This result is specific to the tested snapshot and does not negate the successful historical controller burn documented in Phase 4. On October 1, 2026, the additional minter initiated a successful controller burn of 18,026.574051066495598471 USDr from a holder who had approved the exact amount. The economic purpose of that historical burn remains unresolved. The escrow's corresponding later-state burn simulation was inconclusive.

A historical 300 USDC.e-to-300 USDr conversion was independently reconstructed through transaction receipt and call-trace evidence. A separate early 45-recipient issuance transaction could not be traced because the RPC provider failed to serve the required historical trace.

**Central conclusion:** The on-chain access-control configuration creates a material dependency on the governance and operational control of the NativeTokenController. The escrow's backing calculations alone do not establish that the escrow is the exclusive authority capable of changing USDr supply.

---

## 2. Scope and methodology

Phase 5 examined whether USDr supply-control permissions are confined to the escrow workflow or whether other accounts can exercise controller-level minting or burning authority.

The investigation used:

- `eth_getStorageAt` to inspect proxy implementation and configuration storage.
- `eth_call` to test role membership and simulate contract entrypoints without changing state.
- `eth_getLogs` to reconstruct standard role-grant and role-revocation events.
- `eth_getCode` and runtime-bytecode inspection to examine deployed contract behavior.
- Transaction receipts and call traces to reconstruct selected historical execution paths.
- Historical block queries to compare the configuration at earlier issuance dates with the pinned snapshot.

The principal snapshot was block `0xe39323`.

All `eth_call` results described as successful or reverted are simulations. They are not evidence that a transaction was submitted or that state changed.

### 2.1 Principal contracts and accounts

| Component | Address |
|---|---|
| USDr precompile | `0x0000000000000000000000000000000000000400` |
| NativeTokenController proxy | `0x07e17e17e17e17e17e17e17e17e17e17e17e17e6` |
| Controller implementation | `0x07e17e17e17e17e17e17e17e17e17e17e17e17e7` |
| USDrEscrow proxy | `0xd19a5e28fed41fa289e92ae61b9bc5bd883db0d2` |
| Original minter proxy | `0x17ea10b6ae4fde59fdbf471bd28ab9710f508816` |
| Additional minter/admin | `0x6b205d256e8a153cba8057e5655db56e0e47a511` |
| Escrow deployer/admin | `0x633ac5...61ce1` |
| Unprivileged test caller | `0x000000000000000000000000000000000000dEaD` |

The full addresses and raw outputs should be retained in the reproduction guide and evidence register.

---

## 3. NativeTokenController role structure

### 3.1 Role identifiers and administration

The `MINTER_ROLE` identifier used in the investigation is:

`0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6`

The controller's `getRoleAdmin(MINTER_ROLE)` query returned the zero hash, corresponding to `DEFAULT_ADMIN_ROLE`.

At the pinned snapshot:

- The USDrEscrow proxy holds `MINTER_ROLE`.
- The additional account `0x6b205d256e8a153cba8057e5655db56e0e47a511` holds `MINTER_ROLE`.
- The additional account also holds `DEFAULT_ADMIN_ROLE`.
- The escrow proxy does not hold `DEFAULT_ADMIN_ROLE`.

This means the additional account has both the permission to invoke controller functions protected by `MINTER_ROLE` and the administrative permission associated with managing that role.

### 3.2 Historical role events

The investigation scanned standard `RoleGranted` and `RoleRevoked` events emitted by the NativeTokenController from deployment history through block `0xe39323`.

Four `RoleGranted` events were found, with no standard `RoleRevoked` event in the scanned range:

| Block | Role | Account receiving role | Transaction |
|---:|---|---|---|
| 5,558 | `MINTER_ROLE` | `0x17ea10b6ae4fde59fdbf471bd28ab9710f508816` | `0xf1715f4b2e02be5a2fcdd1399877e9508bbba003472add86fea9b364ede9d8b9` |
| 2,555,708 | `MINTER_ROLE` | USDrEscrow proxy | `0xbf6e119c9609ca64790006814d9a6c9e38af50c5263842ab63e479a9fe3e1891` |
| 9,526,443 | `DEFAULT_ADMIN_ROLE` | `0x6b205d256e8a153cba8057e5655db56e0e47a511` | `0x5ff23c59cc6b7e36e8bf803f6b8aec77f668b9b27fe138b4b5e675fea69bc833` |
| 11,366,001 | `MINTER_ROLE` | `0x6b205d256e8a153cba8057e5655db56e0e47a511` | `0xa6b61b11e55b194d11a4d419b3964cd06355847fe3319e1645b4f5c7acee8435` |

The additional account received `DEFAULT_ADMIN_ROLE` before it received `MINTER_ROLE`.

A historical membership check at the block immediately before the `MINTER_ROLE` grant confirmed that the additional account already held `DEFAULT_ADMIN_ROLE`.

**Correction to the earlier Phase 2 interpretation:** The additional account's later `MINTER_ROLE` grant was a self-grant performed by an account that already held `DEFAULT_ADMIN_ROLE`. The evidence therefore supports an authorized role grant under the controller's existing role hierarchy. It does not support describing this event as an unauthorized privilege escalation.

The absence of standard `RoleRevoked` events is limited to the controller's scanned event history. It does not independently rule out every possible alternative permission-management mechanism.

---

## 4. Direct controller mint capability

### 4.1 Authorized caller simulation

At block `0xe39323`, an `eth_call` from the additional minter to the controller's `mint(address,uint256)` entrypoint returned successfully.

The function selector was:

`0x40c10f19`

The simulated call returned:

`0x0000000000000000000000000000000000000000000000000000000000000001`

This is evidence that the additional account passed the controller's direct mint entrypoint checks in the simulated call.

### 4.2 Unprivileged caller simulation

The same class of call from the dummy unprivileged address reverted with:

`0xe2517d3f`

The revert data identifies `AccessControlUnauthorizedAccount` and encodes the dummy caller and required `MINTER_ROLE`.

This demonstrates that the controller's access-control check distinguishes the authorized minter from an unprivileged caller.

### 4.3 Interpretation

The additional account possesses a direct controller-level mint capability independent of calling the escrow's public conversion function.

This is a permission finding. It does not establish that the account has submitted a successful direct mint transaction, that it has used this capability to issue USDr outside the escrow, or that any particular quantity of USDr was minted through this route.

No actual mint transaction was broadcast as part of this experiment.

---

## 5. Administrative ability to grant MINTER_ROLE

At the pinned snapshot, the additional account simulated a call to `grantRole(MINTER_ROLE, testRecipient)`.

The simulated call succeeded.

The same simulated grant from the dummy unprivileged account reverted with `AccessControlUnauthorizedAccount`, identifying the required `DEFAULT_ADMIN_ROLE`.

A subsequent `hasRole(MINTER_ROLE, testRecipient)` query returned false.

This is the expected result because `eth_call` executes a read-only simulation and does not persist the simulated storage changes.

The result demonstrates that the additional account has the administrative authority to grant the controller's minter role. It does not demonstrate that the test recipient was actually granted that role on-chain.

---

## 6. Burn permission and allowance limitation

The controller's `burn(address,uint256)` entrypoint uses selector:

`0x9dc29fac`

A simulated burn from the additional minter reached an allowance check and reverted with:

`Insufficient allowance for controller: have 0, need 1`

The USDr precompile allowance query for the tested holder and controller returned zero.

The dummy unprivileged caller was rejected by the controller's `MINTER_ROLE` access-control check.

A corresponding simulation using the escrow proxy as caller reverted without a useful reason or decoded error. That result is inconclusive.

### Interpretation

The additional account passed the controller's minter-role gate for the tested burn call, but the call did not complete because the controller lacked the required allowance for the tested holder.

The experiment does not establish a successful burn under the later snapshot conditions tested. Separately, Phase 4 documents a successful historical controller burn initiated by the additional minter on October 1, 2026, after the holder approved the exact amount. The historical transaction's economic purpose is not established by the receipt evidence.

The evidence supports a distinction between:

- **Role-level permission:** the additional account is authorized to reach the controller's protected burn entrypoint.
- **Successful execution:** the tested burn did not complete because the allowance requirement was not satisfied.

A successful historical controller burn initiated by the additional minter is confirmed in Phase 4. The later-state simulation did not reproduce a successful burn, and the economic purpose of the historical burn remains unresolved.

---

## 7. Original minter contract and historical configuration

The original minter address is a proxy contract, not an externally owned account.

At block 7,823:

- Its proxy storage slot `0x3c` contained the NativeTokenController proxy address.
- A historical `hasRole(MINTER_ROLE, originalMinter)` query returned true.
- The controller address stored in the original minter's configuration therefore matched the controller examined in Phase 5.

The original minter's implementation bytecode contains the `mint(address,uint256)` selector and a code path that performs a call using that selector to the address loaded from storage slot `0x3c`.

This is bytecode-level evidence of a controller-minting path in the implementation.

However, the deployed implementation's exact source-code match was not established. Sourcify lookups at the checked endpoints did not return a verified source match. The absence of a match at those endpoints is not proof that source code is unavailable elsewhere.

The early historical issuance transaction discussed below could not be traced to establish whether this particular controller-minting path was used.

---

## 8. Historical issuance transaction: unresolved execution path

The investigation examined the historical transaction:

`0xa6fae1913e0acb00842b432bfde3c5cb4f544324fdfec6d64aa27c52d9a4adb0`

The transaction was included at block 7,823 and its receipt succeeded.

The receipt contained 136 logs, including 45 USDr mint events to 45 recipients. The aggregate amount represented by those mint events was 66,117.621055 USDr.

No USDC.e transfer into the escrow was identified in that transaction receipt.

The attempt to obtain an execution trace failed because the RPC provider could not apply a historical system call while reconstructing the trace. The error concerned historical state access for a system-contract address.

Consequently, the receipt establishes that the transaction succeeded and emitted the observed USDr mint events. It does not, by itself, establish the exact internal call path or prove which contract function initiated each mint.

The absence of a USDC.e transfer in the same receipt is an important observation, but it must not be converted into a claim about the complete economic context without the missing execution trace and any relevant surrounding transactions.

**Finding:** The exact internal execution path of this early 45-recipient issuance remains unresolved.

---

## 9. Historical escrow-mediated conversion control case

To compare the unresolved issuance with a traceable conversion, the investigation reconstructed this transaction:

`0x3165655970de671130f99f970457950204eaf1b017b927f16eb56808d39b80c6`

The transaction was included at block 10,610,801.

The receipt showed:

- 300 USDC.e transferred from `0x5d1c636ab61782beb04cc685922f0197758a81aa` to the USDrEscrow proxy.
- 300 USDr minted from the zero address to `0x1569a4bb96f22b00eb07fb4d556bc1ee8e06b8ba`.

The call trace showed the following relevant sequence:

1. The conversion flow called the USDrEscrow proxy.
2. The escrow implementation queried the USDC.e balance.
3. The escrow called USDC.e `transferFrom` to transfer 300 USDC.e into the escrow.
4. The escrow called the NativeTokenController proxy using the `mint(address,uint256)` selector.
5. The controller delegated to its implementation and called the USDr precompile's mint entrypoint.

The trace and receipt together support the conclusion that this sampled transaction followed an escrow-mediated 300 USDC.e-to-300 USDr conversion path.

The trace excerpt did not expose the complete mint calldata amount, so the amount comparison relies on the receipt's USDr mint event and the corresponding USDC.e transfer.

This is a control case for one transaction. It does not establish that every historical USDr mint followed the same path.

---

## 10. Escrow administration and configured controller

At the pinned snapshot, the USDrEscrow proxy's configured controller getter returned the NativeTokenController proxy.

The escrow's `paused()` getter returned false.

Read-only simulations established that:

- An unprivileged caller could not invoke the tested pause/unpause administration path.
- The escrow administrator could simulate a successful `pause()` call.
- An administrator could simulate a successful `grantRole(DEFAULT_ADMIN_ROLE, testAccount)` call.
- An unprivileged caller could not simulate the same grant successfully.
- The administrator could simulate `setMinterBurner` with the current controller address.
- The administrator could also simulate that setter with the USDC.e contract address.
- An unprivileged caller was rejected by the setter's access-control check.
- The escrow's configured controller remained unchanged in the pinned state because these were simulations only.

The setter tests establish that the tested administrator passed the authorization check for the candidate values. They do not establish that every accepted address would be a suitable or safe controller.

The escrow's standard role-event history contained role grants and an implementation upgrade event. No standard `RoleRevoked` event was found in the scanned history. The role identifiers not conclusively mapped to named roles remain identified by their hashes rather than guessed labels.

---

## 11. Relationship to the 1:1 backing mechanism

The earlier escrow analysis identified a design dependency: the backing calculation assumes the escrow is the exclusive authority capable of minting and burning USDr.

The Phase 5 controller evidence shows that the escrow is not the only account holding controller-level `MINTER_ROLE`.

The additional minter's direct mint simulation demonstrates a separate controller entrypoint capability. Its successful role-authorized simulation is material to the control model because it means the escrow's conversion function is not the only demonstrated route through which an authorized account can reach the controller's mint function.

The later-state burn simulation did not complete because the tested holder's allowance was zero. However, Phase 4 confirms that the additional minter initiated a successful historical controller burn after the holder approved the exact amount. The investigation has not established that the additional account completed an actual alternative mint-and-burn cycle: its direct mint capability was demonstrated through `eth_call`, not an actual mint transaction. The economic purpose of the historical burn remains unresolved.

The key control implication is narrower:

**The escrow's backing formula is not, by itself, proof that all USDr supply changes must pass through the escrow.** The controller's role configuration and the operational control of its authorized accounts are also relevant to the integrity of the backing relationship.

Whether an alternative minting capability has actually been exercised, and whether any resulting supply change was matched by USDC.e collateral, require separate transaction-level evidence.

---

## 12. Evidence classification

| Proposition | Evidence status | Boundary |
|---|---|---|
| Escrow holds controller `MINTER_ROLE` | Confirmed at pinned snapshot | Role membership query |
| Additional account holds `MINTER_ROLE` | Confirmed at pinned snapshot | Role membership query |
| Additional account holds `DEFAULT_ADMIN_ROLE` | Confirmed at pinned snapshot | Role membership query and historical event |
| Additional account can simulate direct controller minting | Confirmed by read-only simulation | Not an actual mint transaction |
| Unprivileged caller is rejected by controller mint access control | Confirmed by read-only simulation | Tested caller and entrypoint |
| Additional account can simulate granting `MINTER_ROLE` | Confirmed by read-only simulation | No persistent grant occurred |
| Additional account initiated a successful historical controller burn | Confirmed in Phase 4 | Transaction receipt succeeded; holder had approved the exact amount |
| Original minter had controller configured at block 7,823 | Confirmed by historical storage read | Slot `0x3c` |
| Original minter held `MINTER_ROLE` at block 7,823 | Confirmed by historical role query | Historical block query |
| Early 45-recipient issuance used the escrow | Unresolved | Historical trace unavailable |
| Sampled 300-to-300 conversion used escrow before controller mint | Confirmed for the sampled transaction | Receipt plus call trace |
| Every historical mint used the escrow | Not established | One traceable control transaction is insufficient |
| Escrow is the exclusive authority capable of changing USDr supply | Not supported by observed controller permissions | Additional controller minter exists |

---

## 13. Limitations and unresolved questions

1. **No actual alternative mint transaction was established.** Direct minting was tested using `eth_call`; no transaction was broadcast.
2. **The later-state burn simulation failed at the allowance check.** This does not negate the successful historical controller burn initiated by the additional minter and documented in Phase 4.
3. **The early 45-recipient issuance trace remains unavailable.** The receipt and logs are available, but the exact internal execution path was not reconstructed.
4. **Exact deployed source equivalence is incomplete.** The original minter implementation was inspected at bytecode level, but a verified source match was not established.
5. **Event scans have a defined boundary.** The absence of standard role-revocation events applies to the scanned controller and escrow event histories, not every conceivable permission mechanism.
6. **Simulations are not state transitions.** Successful `eth_call` results do not prove that an equivalent transaction would necessarily be included or remain successful under different state conditions.
7. **No conclusion about current or perpetual solvency follows from these access-control tests.** The findings concern authority and execution paths, not a complete reserve audit.

---

## 14. Phase 5 conclusion and transition

Phase 5 has produced sufficient evidence to proceed to the consolidated evidence package.

The strongest supported finding is that an additional account holds controller-level mint and administrative permissions, and can simulate a direct controller mint successfully. This means the escrow is not the sole account with demonstrated controller-level mint authority.

The evidence does not establish that the additional account actually minted USDr outside the escrow. However, Phase 4 confirms that the account initiated a successful historical controller burn after the holder approved the exact amount. The economic purpose of that burn remains unresolved. The early issuance transaction's execution path also remains unresolved.

The next phase should consolidate the raw RPC outputs, role-event records, transaction receipts, trace evidence, bytecode observations, reproduction commands, and explicit limitations into a traceable evidence package.

No claim of unauthorized minting, actual off-escrow issuance by the additional minter, or proven undercollateralization should be made on the basis of Phase 5. The successful historical additional-minter-initiated controller burn is documented in Phase 4; its economic purpose and any associated collateral movement remain unresolved.
