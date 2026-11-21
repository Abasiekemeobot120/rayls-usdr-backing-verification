# Phase 4 — Historical USDr Supply and Escrow Reconstruction

**Project:** Rayls USDr 1:1 Backing Verification  
**Network:** Rayls Mainnet  
**Chain ID:** 72957  
**Phase:** 4  
**Status:** Evidence collection complete; findings documented; historical event/state reconciliation remains unresolved

## 1. Research objective

Reconstruct historical USDr supply changes and investigate their relationship with USDC.e movements and the USDr escrow balance.

The investigation will use direct blockchain data retrieval and local analysis from GitHub Codespaces. Blockchain explorers will not be relied upon as the primary source of transaction data or evidence.

## 2. Target research questions

The following questions are the fixed research questions for Phase 4. They must be reproduced verbatim, in the same order, in the final findings report and eventual research article.

1. What transactions caused USDr to be minted or burned?
2. Who initiated those transactions, and which contracts executed them?
3. Can each supply change be linked to a corresponding USDC.e movement?
4. What explains the 18,026.574051066495598471 USDr burn?
5. What caused the historical backing shortfall?
6. Did the October 1 correction transactions resolve that shortfall?

## 3. Investigation methodology

The primary method will be direct JSON-RPC retrieval and local analysis in GitHub Codespaces.

The investigation will use, where supported:

- `eth_getLogs` to retrieve relevant USDr and USDC.e event logs.
- `eth_getTransactionByHash` to retrieve transaction details.
- `eth_getTransactionReceipt` to retrieve execution receipts and emitted logs.
- `eth_getBlockByNumber` to establish block context and timestamps.
- Historical `eth_call` requests to inspect contract state at selected blocks.
- Transaction tracing methods, if supported by the available RPC provider, to investigate internal execution.

Raw responses will be preserved before decoding or interpretation.

## 4. Investigation workstreams

### Workstream A — USDr supply event reconstruction

Identify historical USDr mint and burn events. Establish the relevant transaction hashes, block numbers, timestamps, amounts, emitting contracts, and associated addresses.

### Workstream B — Transaction initiators and execution

Reconstruct the transactions responsible for supply changes. Distinguish transaction sender, immediate caller, executing contract, event emitter, and token recipient or source.

### Workstream C — USDC.e correlation

Investigate whether each identified USDr supply change can be linked to a USDC.e deposit, withdrawal, transfer, or other relevant operation.

Amount similarity alone will not be treated as proof of a relationship.

### Workstream D — Specific USDr burn investigation

Reconstruct the burn of 18,026.574051066495598471 USDr and investigate its surrounding transactions and contract execution.

The investigation must establish what the available evidence supports without assuming that the burn necessarily represents redemption or bridge-out.

### Workstream E — Historical backing shortfall

Reconstruct USDr supply and USDC.e escrow balances at relevant historical blocks. Identify when the reported shortfall arose, its magnitude, and the transactions or state changes associated with it.

### Workstream F — October 1 correction assessment

Reconstruct the October 1 correction transactions and compare relevant historical state before and after them.

Determine whether the transactions resolved the identified shortfall, and specify the limits of that conclusion.

## 5. Evidence and verification standards

Each material finding must be supported by reproducible evidence.

The investigation will distinguish:

- **Confirmed:** directly supported by retrieved blockchain data or independently reproduced calculations.
- **Supported interpretation:** consistent with multiple pieces of evidence but not conclusively established.
- **Unresolved:** evidence is incomplete or unavailable.
- **Rejected:** contradicted by verified evidence.

Transaction relationships must be established through transaction execution, event data, contract logic, or other direct evidence. Matching amounts or nearby timestamps alone are insufficient.

## 6. Technical limitations

Historical state access may depend on archive-node availability. Provider limitations, unsupported tracing methods, missing logs, and unavailable historical state must be recorded explicitly.

A failed RPC request must not be interpreted as a zero balance, absent transaction, or proof that an event did not occur.

RPC credentials must not be committed, printed, or included in published evidence.

## 7. Planned deliverables

- Phase 4 research scope and methodology.
- Reproducible Codespaces investigation scripts.
- Raw RPC evidence and decoded event records.
- Historical USDr supply transaction register.
- USDC.e correlation and escrow reconstruction.
- Phase 4 findings report with evidence limitations.
- Article-ready answers to the six verbatim research questions.

## 8. Publication requirement

The six target research questions in Section 2 must appear unchanged and in the same order in the final Phase 4 findings report and eventual research article.

Answers must be evidence-based and may include qualifications or unresolved findings. The wording of the questions must not be paraphrased, shortened, merged, or reordered.

## 9. Phase status

Phase 4 evidence collection and the targeted investigation are complete. Findings are documented in [Phase 4 findings report](phase-4-findings-report.md). The historical event/state reconciliation discrepancy remains unresolved and is explicitly qualified in that report. No system-wide backing conclusion is claimed beyond the verified configured-escrow checkpoint.