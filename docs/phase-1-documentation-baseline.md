# Phase 1 — Documentation Baseline

## 1. Objective

Establish the documented USDr issuance and redemption design using official Rayls documentation.

This phase records what Rayls publicly claims about the system. It does not independently verify contract behaviour, live permissions, current reserve balances, or transaction execution.

**Primary source:**

- [Rayls — Public Chain Tokenomics](https://docs.rayls.com/docs/public-chain-tokenomics)

**Supporting source:**

- [Rayls — High-Level Architecture](https://docs.rayls.com/docs/rayls-high-level-architecture)

## 2. Documented USDr design

Rayls describes USDr as the native gas token of the Rayls Public Chain. It is pegged 1:1 to the US dollar and is documented as being backed by USDC bridged from Ethereum.

The tokenomics documentation states that each USDr in circulation should have a corresponding USDC.e locked in an on-chain USDC.e/USDr escrow on Rayls.

The documented backing relationship therefore has two layers:

1. USDC held in the LayerZero bridge contract on Ethereum.
2. Corresponding USDC.e held in the USDC.e/USDr escrow on Rayls.

The documentation presents USDC.e as the bridged representation of Ethereum USDC.

**Evidence classification:** Documented design claim. Not independently verified.

## 3. Documented inbound issuance flow

Rayls describes a two-step lock-and-mint process.

### Step 1 — Ethereum USDC to Rayls USDC.e

1. A user starts with USDC on Ethereum.
2. The user bridges USDC to Rayls through LayerZero.
3. The USDC is locked in the LayerZero bridge contract on Ethereum.
4. An equivalent amount of USDC.e is minted on the Rayls Public Chain.

The documentation describes this as a 1:1 lock-and-mint relationship between Ethereum USDC and Rayls USDC.e.

### Step 2 — Rayls USDC.e to USDr

1. The newly minted USDC.e is locked in the USDC.e/USDr escrow contract on Rayls.
2. An equivalent amount of USDr is minted to the user.

Rayls identifies the USDC.e held in this escrow as the direct backing for USDr.

### Automated and manual routes

The documentation says the LayerZero bridge can run both legs automatically. In that case, a user bridging USDC from Ethereum receives USDr directly on Rayls.

It also says users can interact with USDC.e directly and perform the second exchange manually.

**Documented sequence:**

Ethereum USDC → LayerZero lock → Rayls USDC.e mint → USDC.e/USDr escrow → USDr mint.

**Evidence classification:** Documented design claim. Actual transaction execution and accounting remain to be verified.

## 4. Documented redemption and exit flow

Rayls explicitly states that USDr itself cannot be bridged out to Ethereum.

Instead, the documented exit route is:

1. The holder converts USDr back into USDC.e through the Rayls escrow.
2. The USDC.e is bridged back to Ethereum.
3. The corresponding Ethereum USDC is returned through the bridge process.

The documentation establishes the intended conversion and exit path, but this page does not specify the complete technical sequence of contract calls, token burns, escrow releases, bridge messages, or settlement confirmations.

Those mechanics must be established from contract source code and real transaction traces in later phases.

**Documented sequence:**

USDr → USDC.e conversion → bridge back to Ethereum → USDC release.

**Evidence classification:** Documented exit design. Detailed execution mechanics not yet independently verified.

## 5. Special minting authority at genesis

The tokenomics documentation states that a separate Rayls Minter wallet has permission to mint USDr for foundation-controlled accounts at genesis.

It describes this permission as a bootstrap mechanism and says the plan is to revoke the role over time so that only the escrow contract can mint USDr.

This distinction is important.

The documentation describes an intended future restriction. It does not establish that the Rayls Minter role has already been revoked.

The following questions remain open for Phase 2 and Phase 5:

- Which address currently holds the minter role?
- Which contract enforces the minting permission?
- Does the Rayls Minter wallet still have minting authority?
- Does the escrow contract have exclusive minting authority?
- Can any other address or privileged role mint USDr outside the escrow process?

**Evidence classification:** Documented genesis arrangement and stated future intention. Current permissions are unverified.

## 6. Claimed backing invariant

The documented design implies the following accounting relationship:

USDr circulating supply should correspond 1:1 to USDC.e held in the USDC.e/USDr escrow.

A second relationship connects the USDC.e supply to the USDC locked in the Ethereum LayerZero bridge.

These are distinct relationships and should be measured separately.

For the later on-chain reconciliation, the core comparison will be:

- USDr total supply on Rayls.
- USDC.e balance held by the USDr escrow on Rayls.
- Corresponding Ethereum USDC held in the relevant bridge contract.

The documentation does not itself provide a verified live balance reconciliation at a selected block.

**Evidence classification:** Documented accounting model. Live backing not yet independently verified.

## 7. Evidence boundaries and limitations

This phase relies on official Rayls documentation.

It does not establish:

- The current USDr total supply.
- The current USDC.e escrow balance.
- The current Ethereum USDC bridge balance.
- Whether the three quantities reconcile at a particular block.
- Whether all USDr issuance has passed through the escrow.
- Whether the genesis minter role has been revoked.
- Whether redemption works as described in every live execution path.
- Whether the system has sufficient backing at all times.

Documentation describes the intended system. Independent source-code inspection, on-chain state reads, and transaction tracing are required to test whether the deployed system matches that description.

A single successful reconciliation at one block would also not prove perpetual solvency or guaranteed future redemption.

## 8. Phase 1 preliminary conclusion

The official Rayls tokenomics documentation describes USDr as a 1:1 stable gas token backed through a two-layer arrangement:

1. Ethereum USDC is locked through LayerZero and represented as USDC.e on Rayls.
2. USDC.e is locked in a Rayls escrow, against which USDr is minted.

The documented exit route reverses this process by converting USDr into USDC.e before bridging back to Ethereum.

The documentation also acknowledges a genesis minting permission held by a separate Rayls Minter wallet, with a stated intention to revoke that permission over time.

These statements define the design claims that the subsequent research will test. They are not yet independent evidence that the deployed contracts, current permissions, and live balances satisfy those claims.

## 9. Next research phase

**Phase 2 — Contract Inventory**

Identify and inspect the deployed contracts involved in:

- USDr issuance and supply accounting.
- USDC.e custody in the Rayls escrow.
- Ethereum USDC custody in the LayerZero bridge.
- Minting and burning permissions.
- Bridge and redemption execution.

Record verified contract addresses, source-verification status, relevant functions, roles, and source-code references before performing the Phase 3 balance reconciliation.

No transactions or state-changing actions are authorized by this research phase.

## 10. Source register and verification date

**Research verification date:** 2026-11-19

### Primary source

**Title:** Public Chain Tokenomics

**Publisher:** Rayls Documentation

**URL:** https://docs.rayls.com/docs/public-chain-tokenomics

**Use in this research:**

- USDr purpose, peg, and documented backing model.
- Ethereum USDC lock and Rayls USDC.e mint.
- USDC.e/USDr escrow and USDr issuance.
- Automated and manual issuance routes.
- Genesis Rayls Minter wallet and stated revocation plan.
- USDr conversion to USDC.e and restriction on bridging USDr directly out.

### Supporting source

**Title:** Rayls High-Level Architecture

**Publisher:** Rayls Documentation

**URL:** https://docs.rayls.com/docs/rayls-high-level-architecture

**Use in this research:**

- General description of the Rayls Public Chain.
- Confirmation that USDr is the Public Chain gas token.
- High-level description of USDr's relationship to USDC bridged from Ethereum.

**Source limitation:** The supporting architecture page is not a substitute for the detailed tokenomics description. The tokenomics page is the primary reference for the issuance and redemption claims in this phase.

### Source-handling note

These are public documentation sources, not immutable technical specifications. Their contents may change. The verification date records when this research checked the pages; it does not establish when each statement was first published or whether the deployed contracts currently implement it.
