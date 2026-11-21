# Phase 7 — Cross-Phase Claim-Boundary Review and Final Assessment

## 1. Purpose

Phase 7 closes the research assessment by reviewing the claims and limitations carried forward from Phases 1–6.

The objective is to distinguish documented design, directly observed on-chain state, reconstructed transaction evidence, reproducible findings, inferences, and unresolved questions.

This phase does not initiate another broad blockchain investigation. It consolidates the available evidence and establishes the claims that can responsibly be made in the final research article.

## 2. Cross-phase consistency review

### 2.1 Documentation baseline

Phase 1 established the documented design:

- Ethereum USDC is locked through the LayerZero bridge and represented as USDC.e on Rayls.
- USDC.e is deposited into the Rayls USDC.e/USDr escrow.
- USDr is minted against the escrowed USDC.e.
- The documented exit process converts USDr to USDC.e before bridging back to Ethereum.
- The documentation described a separate genesis minting permission and an intention to restrict minting authority over time.

These are documented design claims. They are not, by themselves, evidence of continuous backing, complete reserve custody, or exclusive escrow minting authority.

### 2.2 On-chain transaction and control evidence

Phase 2 established an observable implementation of the documented mechanism, reconstructed an Ethereum-to-Rayls USDC/USDC.e funding path, identified a substantial USDr burn, and identified an additional controller MINTER_ROLE holder.

Phase 2 also explicitly left full Ethereum-side collateral custody, the purpose of the October 1 burn, and full-system solvency unresolved.

Phase 5 subsequently refined the interpretation of the additional minter's authorization. The account held DEFAULT_ADMIN_ROLE before granting itself MINTER_ROLE. The available role-history evidence therefore supports authorization through the observed role hierarchy; it does not establish an unauthorized privilege escalation.

The additional account's mint capability was demonstrated through eth_call simulation. This is evidence of callable authority, not evidence that an alternative mint transaction was executed.

### 2.3 Pinned-block reconciliation and later supply reconstruction

Phase 3 directly compared USDr supply, escrow USDC.e balance, and escrow accounting getters at block 14,797,239.

At that block:

- Direct USDr total supply: 25,357.786154933504401529 USDr.
- Direct escrow balance: 26,348.747526 USDC.e.
- Escrow surplus over direct supply: approximately 990.961371066495598471 USDC.e.

The independent calculation agreed with the escrow's withdrawableSurplus() result, and circulatingUsdr() agreed with the native precompile's totalSupply().

Phase 6 later identified a 20,010 USDr difference between direct totalSupply() and the retained event-derived supply reconstruction. This does not invalidate the Phase 3 direct-state comparison. It qualifies the completeness of the historical event-derived reconstruction.

The difference was present at all eight retained historical snapshots, beginning with the earliest retained checkpoint at block 11,362,693. The evidence does not establish its origin or prove that the difference was constant throughout all chain history.

These findings are therefore compatible:

- The direct pinned-block state comparison supports a positive escrow surplus at that checkpoint.
- The event-derived historical supply reconstruction is incomplete relative to direct totalSupply() by 20,010 USDr at the retained checkpoints.

Neither finding should be used to silently replace or reinterpret the other.

## 3. Final claim classification

| Claim | Classification | Boundary |
|---|---|---|
| Rayls documents a 1:1 USDr/USDC.e backing design | Documented | Design intent, not continuous operational proof |
| Escrow exceeded direct USDr supply at block 14,797,239 | Directly verified | One historical checkpoint |
| Escrow getters agreed with independent calculations | Directly verified | Same pinned checkpoint |
| Event-derived supply differed from direct supply by 20,010 USDr | Directly verified within retained evidence | Eight retained snapshots; origin unresolved |
| All 359 retained mint/burn records matched retained raw Transfer logs | Directly verified within retained dataset | Does not establish exhaustive chain-wide log collection |
| An additional account held controller minting authority | Directly verified | Does not establish misuse |
| The additional account executed a substantial USDr burn | Directly verified | Economic purpose and collateral treatment unresolved |
| The additional account could simulate a direct controller mint | Demonstrated by eth_call | Not an executed mint transaction |
| The observed burn was definitively a redemption or bridge-out | Unresolved | Available evidence does not establish the complete relationship |
| All Ethereum bridge collateral and associated liabilities reconcile | Unresolved | Full cross-chain custody and liability reconciliation was not completed |
| USDr was undercollateralized | Not established | No definitive conclusion supported |
| USDr was fully backed at all times | Not established | No continuous, system-wide proof |

## 4. Principal findings that survive the review

### 4.1 Positive pinned-block escrow result

At block 14,797,239, the directly measured USDC.e escrow balance exceeded directly measured USDr supply. The independent surplus calculation agreed with the escrow getter.

This is a verified point-in-time result. It is not proof of perpetual solvency or complete cross-chain backing.

### 4.2 Persistent event-derived supply difference

The retained historical snapshots show a 20,010 USDr difference between direct supply and event-derived supply.

The retained raw-log audit matched all 359 reconstructed mint/burn records against the retained raw mint/burn Transfer logs, with no unmatched entries in that dataset.

This establishes internal consistency of the retained records. It does not prove that the retained raw logs constitute a complete history of every relevant issuance and burn.

The origin of the 20,010 USDr difference remains unresolved.

### 4.3 Additional privileged minting authority

The investigation established that an additional account held controller minting authority and that it executed a substantial burn.

Phase 5's role-history analysis supports that the account obtained MINTER_ROLE through the observed DEFAULT_ADMIN_ROLE hierarchy.

A direct mint call was successful in simulation, but no executed alternative mint transaction was established. The finding is a control-model consideration, not proof of unauthorized issuance.

### 4.4 Burn and redemption-path mechanics

The investigation traced a representative transaction in which 0.0001 USDr was burned and 0.0001 USDC.e moved through the observed redemption-related path.

This provides evidence of coordinated token and collateral movements. The exact semantics of unidentified selectors and custom events remain unverified where authoritative ABI or source evidence was unavailable.

The substantial historical burn has not been conclusively linked to a complete redemption or bridge-out settlement.

## 5. Material unresolved questions

| Unresolved question | Importance to core conclusion | Evidence still needed |
|---|---|---|
| What accounts for the 20,010 USDr difference? | High | Complete historical supply provenance and authoritative explanation of the missing component |
| Is the complete historical USDr supply reconstruction exhaustive? | High | Complete issuance/burn history reconciled against authoritative state |
| Do Ethereum bridge reserves cover all relevant liabilities? | High | Full Ethereum custody and cross-chain liability reconciliation at matched checkpoints |
| Did the additional minter execute alternative issuance? | High for control assessment | An identified successful mint transaction or complete transaction-history evidence |
| What was the economic purpose of the substantial burn? | Medium–High | Authoritative transaction semantics and any linked collateral or settlement movement |
| What explains the early 45-recipient issuance and historical totalSupply() behaviour? | Medium | Authoritative precompile semantics and historical implementation evidence |
| What are the exact semantics of unidentified selectors and custom events? | Medium | Verified deployed ABI/source material and implementation matching |

These questions are not all prerequisites for the narrower pinned-block finding. They are material limitations on broader claims about complete supply accounting, exclusive minting, redemption, and system-wide backing.

## 6. Claims the final article must not make

The available evidence does not justify claiming that:

- USDr is definitively undercollateralized.
- USDr is proven fully backed at every point in time.
- All Ethereum-side collateral and liabilities have been reconciled.
- The additional minter executed an alternative mint merely because an eth_call succeeded.
- The additional minter acted without authorization.
- The substantial burn was definitively a redemption or bridge-out.
- The 20,010 USDr difference is proof of missing collateral, fraud, or unauthorized issuance.
- Matching all retained raw logs proves that the retained dataset contains every relevant historical event.

## 7. Overall assessment

The investigation verified that, at the selected historical checkpoint, the Rayls USDr escrow held more USDC.e than the directly measured USDr supply required. The escrow's accounting getter agreed with the independent calculation.

The investigation also identified a persistent 20,010 USDr difference between direct supply and the retained event-derived reconstruction across eight sampled checkpoints. It established additional privileged minting authority, traced a substantial burn, and examined a representative redemption-related transaction path.

These findings provide information beyond the documented design, particularly concerning historical supply reconstruction, controller permissions, and observed burn mechanics.

However, the investigation did not complete a full Ethereum-side reserve and liability reconciliation, establish the origin of the 20,010 USDr difference, prove an executed alternative mint, or conclusively establish the purpose of the substantial burn.

**Final conclusion:** The evidence supports a positive USDC.e escrow surplus against directly measured USDr supply at the selected historical checkpoint. It does not establish continuous or system-wide backing, and it does not demonstrate undercollateralization, unauthorized issuance, or fraud.

## 8. Research boundaries and reproducibility

This review relies on the retained documentation, evidence registers, RPC transcripts, transaction records, event reconstructions, historical snapshots, and reproduction materials in this repository.

The retained evidence must remain distinguishable by provenance:

- Official documentation describes intended design.
- Direct RPC reads establish queried on-chain state at specified blocks.
- Transaction and receipt records establish observed execution and emitted logs.
- Event reconstruction establishes results derived from the retained event dataset.
- eth_call establishes simulated call behaviour, not an executed transaction.
- Inferences must remain labelled as inferences.
- Missing ABI, source, or historical state evidence must remain explicitly disclosed.

No retained evidence or prior phase should be silently overwritten to make the final narrative appear more conclusive.

## 9. Phase 7 status

The cross-phase claim-boundary review is complete.

The repository is ready for independent review of its existing evidence and documentation. Any external reviewer recommendations should be evaluated against the retained evidence, with new claims accepted only where they can be verified and reproduced.

The final full research article will be prepared after the independent review and any justified improvements have been incorporated.

No commit or push is authorized by this closeout.
