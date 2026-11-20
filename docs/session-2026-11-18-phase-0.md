
# Research Session — 2026-11-18
## Phase 0: Controlled Environment and RPC Baseline

### 1. Objective

Establish and preserve the initial research environment and chain-state reference points for the independent verification of USDr's claimed 1:1 backing.

This session records:
- Repository identity and initial Git state.
- Available toolchain.
- Rayls Public Chain RPC connectivity and chain identity.
- Rayls safe/finalized-tag reference block.
- Ethereum RPC connectivity and reference blocks.
- A time-aligned Ethereum block near the Rayls reference timestamp.
- Evidence classifications, limitations, and the next research action.

This was an observational session. No transactions were submitted, no funds were moved, and no packages were installed.

---

### 2. Repository baseline

Repository:
`/workspaces/rayls-usdr-backing-verification`

Remote:
`https://github.com/Abasiekemeobot120/rayls-usdr-backing-verification`

Branch: `main`

Initial HEAD:
`795c7b0 Initial commit`

Initial Git status:
`## main...origin/main`

Initial tracked files:
`README.md`

Initial README content:

> # rayls-usdr-backing-verification
>
> Independent, evidence-driven verification of USDr 1:1 backing on the Rayls Public Chain, covering on-chain reconciliation, transaction tracing, cross-chain backing, access control, and reproducible experiments.

Commands used:

```bash
pwd && git status --short --branch && git remote -v && git log -1 --oneline
git show --stat --oneline --decorate HEAD
git ls-tree -r --name-only HEAD
cat README.md
```

Observed result: the repository was on `main`, tracking `origin/main`, with initial commit `795c7b0`. The initial tracked tree contained only `README.md`.



### 3. Environment and toolchain

Environment time observed during the session:
- UTC: 2026-11-18 19:04:28
- Codespace timezone: UTC (+0000)

Available tools and versions:

| Tool | Observed version/status |
|---|---|
| Node.js | v24.22.2 |
| npm | 11.19.1 |
| Go | go1.27.3 linux/amd64 |
| Python | 3.14.2 |
| curl | 8.5.0 |
| jq | 1.7 |
| cast | Not installed |
| forge | Not installed |
| anvil | Not installed |
| solc | Not installed |

The absence of Foundry and solc does not prevent the initial JSON-RPC read operations.

The environment inspection was performed using:

```bash
printf '%s\n' '--- environment time ---'
date '+%Y-%m-%d %H:%M:%S %Z (%z)'
date -u '+%Y-%m-%d %H:%M:%S UTC'

printf '\n%s\n' '--- available tools ---'
for tool in node npm go python3 curl jq cast forge anvil solc; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf '%-10s %s\n' "$tool" "$(command -v "$tool")"
  else
    printf '%-10s %s\n' "$tool" 'NOT INSTALLED'
  fi
done
```

Observed result: the listed tools and versions were available as recorded above. Foundry components and solc were not installed.

No software was installed during this session.



---

### 4. Rayls Public Chain RPC baseline

RPC endpoint:

`https://mainnet-rpc.rayls.com/`

#### 4.1 Chain identity

JSON-RPC method: `eth_chainId`

Observed result:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x11cfd"
}
```

Chain ID:
- Hexadecimal: `0x11cfd`
- Decimal: `72957`

This is the chain ID returned by the Rayls RPC endpoint during this session.

#### 4.2 Reference block

Both `eth_getBlockByNumber("safe", false)` and `eth_getBlockByNumber("finalized", false)` returned the same reference block during the observation.

Reference block:
- Number (hex): `0xe118c3`
- Number (decimal): `14751939`
- Hash: `0x80e043b557cf51a73c524ad81cdd133fc874bd1d9ad496f2d81edafd5e618a9c`
- Timestamp (hex): `0x6afdf75a`
- Timestamp (UTC): `2026-11-18 19:07:06`
- Parent hash: `0x4d0a5fddc0c3083525ec4b9cfa54b457235253eda9d52b6a9f67427e3c628de6`

An explicit lookup by block number `0xe118c3` returned the same block number, hash, timestamp, and parent hash.

This block is the selected Rayls reference point for the planned reconciliation experiment.

**Evidence boundary:** The RPC returned this block for both the safe and finalized tags during the observation. This is an observed RPC result, not an independent assessment of the chain's consensus or finality mechanism.



---

### 5. Ethereum RPC baseline

RPC endpoint:

`https://ethereum-rpc.publicnode.com`

Chain ID:
- Hexadecimal: `0x1`
- Decimal: `1`

#### 5.1 Finalized checkpoint

The Ethereum `finalized` tag returned:

- Block number (hex): `0x193806c`
- Block number (decimal): `26443884`
- Hash: `0xbd8af961f884bdcb8b5d4229873f0f5bf787ef5dd1135b91d16d6c81080a9ade`
- Timestamp (hex): `0x6afdf4d7`
- Timestamp (UTC): `2026-11-18 18:56:23`
- Parent hash: `0x7806b042a9cadc6cbfff502f87b5f430984cb52e28777c1f562e6827eb03c84a`

An explicit lookup of block `0x193806c` returned the same block identity.

#### 5.2 Safe checkpoint

The Ethereum `safe` tag returned:

- Block number (hex): `0x19380ac`
- Block number (decimal): `26443948`
- Hash: `0xa720e3873b40b28642ad0953a6625b9781670bc54a1954541c082f085af570ec`
- Timestamp (hex): `0x6afdf7d7`
- Timestamp (UTC): `2026-11-18 19:09:11`
- Parent hash: `0x4b051fa948a61578eeee33aef39a3447b2cd13841278277d2352603cde86a3aa`

An explicit lookup of block `0x19380ac` returned the same block identity.

The Ethereum safe and finalized checkpoints differ by 64 blocks. They are distinct checkpoints and must not be treated as interchangeable.

**Evidence boundary:** These are observations returned by the specified Ethereum RPC endpoint. They do not establish that the Ethereum and Rayls checkpoints represent synchronized cross-chain state.



---

### 6. Time-aligned Ethereum reference block

The selected Rayls reference timestamp was:

- Hexadecimal: `0x6afdf75a`
- Unix timestamp: `1795028826`
- UTC: `2026-11-18 19:07:06`

A binary search was performed over the Ethereum block interval from finalized block `26443884` to safe block `26443948`.

**Hypothesis:** An Ethereum block exists within this interval whose timestamp is the last one less than or equal to the selected Rayls reference timestamp.

**Method:** Retrieve block timestamps and use binary search to identify the last Ethereum block satisfying:

`Ethereum block timestamp <= Rayls reference timestamp`

#### 6.1 Ethereum block immediately at or before the Rayls timestamp

- Number (hex): `0x19380a1`
- Number (decimal): `26443937`
- Hash: `0x1b330d574c48e59d86c8086712cfd3873d1b9c09deeae166a233f86407f048e8`
- Timestamp (hex): `0x6afdf753`
- Timestamp (UTC): `2026-11-18 19:07:05`
- Parent hash: `0x0997956f21793a2cfba6dcbd06e192e4607d149d8c0398046da1c884891e607e`

#### 6.2 Next Ethereum block

- Number (hex): `0x19380a2`
- Number (decimal): `26443938`
- Hash: `0x10090e21a9b7fc98af8a089deb25464d174c956dd7e6430acc1c620af824c903`
- Timestamp (hex): `0x6afdf75f`
- Timestamp (UTC): `2026-11-18 19:07:11`
- Parent hash: `0x1b330d574c48e59d86c8086712cfd3873d1b9c09deeae166a233f86407f048e8`

Direct block lookups confirmed both block identities and timestamps.

#### 6.3 Interpretation and limitation

Ethereum block `26443937` is one second before the Rayls reference timestamp.

Ethereum block `26443938` is five seconds after the Rayls reference timestamp.

Therefore, block `26443937` is the closest Ethereum block at or before the Rayls reference timestamp.

**Important limitations:**
- This Ethereum block is not the Ethereum finalized-tag checkpoint recorded in Section 5.
- Timestamp proximity does not establish synchronized cross-chain state.
- It does not establish equivalent finality between the two networks.
- Any cross-chain balance comparison must disclose the timestamp difference and the checkpoint-selection method.



---

### 7. Ethereum ancestry check

A script was run to examine Ethereum blocks `26443937` through `26443948`, comparing each block's `parentHash` with the preceding block's `hash`.

The reported output was:

```json
{
  "referenceBlock": "0x19380a1",
  "referenceHash": "0x1b330d574c48e59d86c8086712cfd3873d1b9c09deeae166a233f86407f048e8",
  "safeHead": "0x19380ac",
  "safeHeadHash": "0xa720e3873b40b28642ad0953a6625b9781670bc54a1954541c082f085af570ec",
  "consecutiveParentLinksVerified": 11,
  "referenceIsAncestorOfObservedSafeHead": true
}
```

#### 7.1 Evidence limitation

The terminal echo of the multiline script appeared corrupted around its heredoc terminator.

The reported output is consistent with the individually retrieved block identities and parent-hash links. However, the script execution has not yet been cleanly reproduced.

**Classification:** Observed script output, provisional pending clean reproduction.

Do not rely on this ancestry result as a critical conclusion until it has been independently reproduced.

If this fact becomes material to the final cross-chain analysis, repeat the ancestry check using a clean script or another independently verifiable method.


---

### 8. Tooling and execution notes

The following issues occurred during Phase 0:

1. An early shell function printed headings alongside RPC responses before piping the combined output to `jq`. This caused JSON parsing errors. Direct `curl` requests piped to `jq` subsequently returned valid responses.
2. A multiline shell script used for the Ethereum ancestry check appeared corrupted around its heredoc terminator in the terminal. The reported output is retained in Section 7 but remains provisional until clean reproduction.
3. Repeated long terminal pastes caused input corruption. The session document was therefore edited directly in the VS Code editor.
4. The Codespaces browser tab was accidentally closed during editing. The existing Codespace was reopened, and the document was confirmed to remain in the workspace.

No package installations, contract deployments, transactions, or Git history modifications were performed during these steps.

### 9. Evidence classification

The following classifications apply to the Phase 0 evidence:

| Evidence item | Classification | Qualification |
|---|---|---|
| Repository identity, branch, remote, and initial commit | Observed | Confirmed through Git commands |
| Local toolchain versions | Observed | Reported by installed command-line tools |
| Rayls chain ID | Observed | Returned by the specified Rayls RPC endpoint |
| Rayls safe and finalized block responses | Observed | RPC responses; not an independent consensus audit |
| Ethereum chain ID | Observed | Returned by the specified Ethereum RPC endpoint |
| Ethereum safe and finalized block responses | Observed | RPC responses from PublicNode |
| Ethereum block selected by timestamp comparison | Independently reproduced | Binary-search result followed by direct block lookups |
| Ethereum ancestry from the selected reference block to the observed safe head | Observed, provisional | Script output retained, but clean reproduction remains outstanding |
| Cross-chain state synchronization | Unverified | Timestamp proximity alone does not establish synchronized state |
| USDr backing ratio or solvency | Not assessed | Requires the later reconciliation and transaction-tracing phases |

These labels describe the strength of the evidence collected in this phase. They do not imply that an RPC observation has been independently verified against another provider or consensus source.

### 10. Scope and limitations

Phase 0 establishes the research environment and a reproducible reference-point methodology. It does not establish whether USDr is fully backed.

The following limitations apply:

- The Rayls and Ethereum reference blocks were obtained from different RPC providers and are not proven to represent synchronized cross-chain state.
- The Ethereum timestamp-aligned block is not the Ethereum finalized checkpoint.
- A timestamp-aligned block is a comparison reference, not proof of equivalent finality.
- The Ethereum ancestry script output remains provisional until clean reproduction.
- No USDr total supply, escrow balance, Ethereum collateral balance, or withdrawable surplus has yet been reconciled.
- No inbound or outbound transaction has yet been traced end to end.
- No current minting or burning authority has yet been independently established.
- A single block snapshot, even if reconciled, cannot prove perpetual solvency, future redemption capacity, or the absence of historical shortfalls.

All subsequent cross-chain comparisons must state the block numbers, hashes, timestamps, RPC endpoints, and any timing or finality limitations.

### 11. Phase 0 outcome

**Status: Environment and reference-point baseline established; documentation pending final verification.**

The repository and toolchain have been identified. The Rayls Public Chain RPC returned chain ID `72957`, and the selected Rayls reference block was:

- Block: `14751939`
- Hash: `0x80e043b557cf51a73c524ad81cdd133fc874bd1d9ad496f2d81edafd5e618a9c`
- Timestamp: `2026-11-18 19:07:06 UTC`

The Ethereum RPC returned chain ID `1`. The selected timestamp-aligned Ethereum reference block was:

- Block: `26443937`
- Hash: `0x1b330d574c48e59d86c8086712cfd3873d1b9c09deeae166a233f86407f048e8`
- Timestamp: `2026-11-18 19:07:05 UTC`

These observations provide fixed reference points for the next research phase. They do not establish the backing status of USDr.

### 12. Next action: Phase 1 — Documentation Baseline

The next phase is a documentation-only review of official Rayls materials.

The objectives are to:

1. Identify the documented USDr minting and redemption mechanisms.
2. Reconstruct the documented inbound path from Ethereum USDC to Rayls USDr.
3. Reconstruct the documented reverse path from USDr to Ethereum USDC.
4. Identify the stated roles of USDC.e, USDr, the escrow, and the bridge.
5. Record any documented restrictions on direct USDr bridging.
6. Identify statements about privileged minting authority and any intended transition to escrow-only minting.
7. Quote and cite the relevant official documentation precisely.

**Phase boundary:** Do not make on-chain backing claims in Phase 1. Contract addresses, role assignments, balances, and actual runtime behavior will be investigated in the later phases.

No Git commit or push is authorized by this checkpoint. Preserve the working document and all existing repository contents.
