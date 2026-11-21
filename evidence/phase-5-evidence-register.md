# Phase 5 — Evidence Register

- **Project:** Rayls USDr 1:1 backing verification
- **Network:** Rayls Mainnet
- **Chain ID:** 72957 (`0x11cfd`)
- **Pinned snapshot:** `0xe39323` (14,914,339)
- **Collection date:** 2026-11-21
**Method:** Direct JSON-RPC through `VC_RPC_URL`

## Evidence index

| ID | Evidence item | Evidence type | Block / reference | Principal observation | Limitation |
|---|---|---|---|---|---|
| P5-01 | Controller implementation and proxy configuration | Storage and bytecode inspection | Snapshot `0xe39323` | Controller proxy resolves to implementation `0x07e17e17e17e17e17e17e17e17e17e17e17e17e7` | Does not establish source-code equivalence |
| P5-02 | Controller MINTER_ROLE membership | `eth_call` | Snapshot `0xe39323` | Escrow and additional minter both return true | Snapshot membership only |
| P5-03 | Controller DEFAULT_ADMIN_ROLE membership | `eth_call` | Snapshot `0xe39323` | Additional minter holds administrative role; escrow does not | Snapshot membership only |
| P5-04 | Controller role event history | `eth_getLogs` | Deployment through `0xe39323` | Four RoleGranted events; no standard RoleRevoked event found | Limited to scanned standard events |
| P5-05 | Additional minter's prior admin membership | Historical `eth_call` | Block `0xad6e70` | Additional minter already held DEFAULT_ADMIN_ROLE before its MINTER_ROLE grant | Does not establish intra-block ordering beyond queried state |
| P5-06 | Direct controller mint simulation | `eth_call` | Snapshot `0xe39323` | Additional minter succeeds; dummy EOA fails access control | No transaction was broadcast |
| P5-07 | Role grant simulation | `eth_call` | Snapshot `0xe39323` | Additional minter can simulate granting MINTER_ROLE; dummy EOA is rejected | Simulated grant does not persist |
| P5-08 | Post-simulation role check | `eth_call` | Snapshot `0xe39323` | Test recipient remains without MINTER_ROLE | Confirms read-only simulation, not an actual grant |
| P5-09 | Controller burn simulation | `eth_call` | Snapshot `0xe39323` | Additional minter reaches allowance check; tested burn fails because allowance is zero | Later-state simulation only; does not negate the successful historical controller burn documented in Phase 4 |
| P5-10 | Original minter controller configuration | Historical storage read | Block 7,823; slot `0x3c` | Original minter proxy stores the NativeTokenController proxy address | Historical configuration only |
| P5-11 | Original minter role membership | Historical `eth_call` | Block 7,823 | Original minter returns true for MINTER_ROLE | Does not establish execution of a particular mint |
| P5-12 | Original minter implementation | Runtime bytecode inspection | Implementation `0x3ea6bac7d4138bcc126d0f17ae10122b3620aba6` | Bytecode contains mint selector `0x40c10f19` and a call path using slot `0x3c` | Exact deployed source match not established |
| P5-13 | Early 45-recipient issuance | Transaction receipt and logs | Block 7,823; tx `0xa6fae1913e0acb00842b432bfde3c5cb4f544324fdfec6d64aa27c52d9a4adb0` | Successful receipt; 45 USDr mint events; aggregate 66,117.621055 USDr; no USDC.e transfer into escrow identified in that receipt | Internal execution path unresolved because historical trace failed |
| P5-14 | Trace failure for early issuance | RPC trace attempt | Same transaction as P5-13 | Historical trace could not be reconstructed due to provider historical-state/system-call error | Provider limitation; not evidence of a particular execution path |
| P5-15 | Escrow-mediated conversion control case | Receipt and call trace | Block 10,610,801; tx `0x3165655970de671130f99f970457950204eaf1b017b927f16eb56808d39b80c6` | Trace shows USDC.e transferFrom into escrow before controller/precompile mint path; receipt records 300 USDC.e and 300 USDr | One sampled transaction; not proof of every historical mint |
| P5-16 | Escrow configured controller | `eth_call` | Snapshot `0xe39323` | Getter returns NativeTokenController proxy | Snapshot only |
| P5-17 | Escrow pause and role administration | `eth_call` | Snapshot `0xe39323` | Admin simulations succeed where tested; unprivileged calls fail authorization | Simulations only |
| P5-18 | Escrow controller setter | `eth_call` | Snapshot `0xe39323` | Admin can simulate setter with tested contract addresses; unprivileged caller is rejected | No configuration change occurred |
| P5-19 | Escrow role event history | `eth_getLogs` | Deployment through `0xe39323` | Role grants and implementation upgrade found; no standard RoleRevoked event found | Some role hashes remain unnamed |
| P5-20 | Historical minter reward claim | Receipt and call trace | Tx `0x1e224bea1babe9fadfa6c9db618857dadf80f2a869e83b436ebb72ba0f9108ed` | Sampled claimRewards call transfers 12,500 RLS; trace shows no controller or USDr-precompile call | One sampled reward claim; does not characterize every minter function |

## Important identifiers

### Contracts

- USDr precompile: `0x0000000000000000000000000000000000000400`
- NativeTokenController proxy: `0x07e17e17e17e17e17e17e17e17e17e17e17e17e6`
- NativeTokenController implementation: `0x07e17e17e17e17e17e17e17e17e17e17e17e17e7`
- USDrEscrow proxy: `0xd19a5e28fed41fa289e92ae61b9bc5bd883db0d2`
- Original minter proxy: `0x17ea10b6ae4fde59fdbf471bd28ab9710f508816`
- Original minter implementation: `0x3ea6bac7d4138bcc126d0f17ae10122b3620aba6`
- Additional minter/admin: `0x6b205d256e8a153cba8057e5655db56e0e47a511`

### Role and function identifiers

- `MINTER_ROLE`: `0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6`
- `mint(address,uint256)`: `0x40c10f19`
- `burn(address,uint256)`: `0x9dc29fac`
- `grantRole(bytes32,address)`: `0x2f2ff15d`
- `hasRole(bytes32,address)`: `0x91d14854`
- `getRoleAdmin(bytes32)`: `0x248a9ca3`

## Interpretation boundaries

1. A successful `eth_call` is a simulated execution, not a submitted transaction.
2. The additional minter's direct mint capability is demonstrated; actual off-escrow issuance by that account is not.
3. The later-state simulated burn did not complete because allowance was zero. Phase 4 independently confirms a successful historical controller burn initiated by the additional minter after the holder approved the exact amount; its economic purpose remains unresolved.
4. The early 45-recipient issuance receipt is confirmed, but its internal execution path remains unresolved.
5. The 300-to-300 escrow-mediated conversion is confirmed for the sampled transaction only.
6. The role-event scan does not rule out every possible non-standard permission mechanism.
7. These findings concern access control and selected execution paths. They do not independently establish perpetual solvency or undercollateralization.

## Related Phase 5 documents

- `docs/phase-5-reproduction-guide.md`
- `docs/phase-5-access-control-findings.md`
