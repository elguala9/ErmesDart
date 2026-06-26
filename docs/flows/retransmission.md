# Reliability & Retransmission

The transport is UDP, so the protocol layers reliability on top: every sent
`MessageRoot` is persisted, every received id is tracked, and gaps trigger
retransmission. `MissingMessagesController` drives retransmission;
`IErmesMessageControlService` tracks which ids have arrived.

## Id tracking

```mermaid
flowchart LR
    rx["message received<br>(ErmesReadRepo)"] --> arr["controlService.idArrived(id)"]
    arr --> range["update received-id range"]
    range --> last["getLastReceivedId()<br>= largest consecutive id"]
    range --> miss["idsToRequest()<br>numberOfMissingIds()"]
```

`getLastReceivedId()` returns the largest id received with no gaps before it —
that is the value reported to the peer in an acknowledge.

## The four retransmission paths

```mermaid
flowchart TB
    subgraph reactive["Reactive (this peer detects a gap)"]
        p1["1. Periodic timer<br>every intervalMs"] --> req["controlService.idsToRequest()"]
        p2["2. Threshold<br>after each message:<br>numberOfMissingIds() ≥ threshold"] --> req
        req --> resend["sendAgain(id) for each missing id"]
    end

    subgraph proactive["Driven by the remote peer"]
        p3["3. Acknowledge<br>ServiceMessageAcknowledge(ackLastReceivedId=X)"] --> gap["gap = ourCurrent − X − 1"]
        gap -->|"gap > 0"| smm["sendMissingMessages([X+1 .. ourCurrent−1])"]
        p4["4. Array request<br>ServiceMessageArrayRequest(arrayId=[...])"] --> smm
    end

    resend --> store["MessageRootStorage lookup<br>→ re-serialize → transport"]
    smm --> store
```

| # | Path | Trigger | Who decides |
|---|---|---|---|
| 1 | Periodic timer | `Timer.periodic(intervalMs)` | local |
| 2 | Threshold | after a message, missing count ≥ threshold | local |
| 3 | Acknowledge | peer sends `ServiceMessageAcknowledge` | remote (gap computed locally) |
| 4 | Array request | peer sends `ServiceMessageArrayRequest` | remote (explicit id list) |

## Acknowledge round-trip

```mermaid
sequenceDiagram
    participant A as Peer A (sender)
    participant B as Peer B (receiver)

    A->>B: messages id 1..10
    Note over B: ids 4 and 7 lost in transit
    B->>A: ServiceMessageAcknowledge(ackLastReceivedId=3)
    Note over A: gap = current − 3 − 1
    A->>B: sendAgain(4..10)  (idempotent — dups dropped by hash)
    Note over B: ChunkHandler.getMissingChunkIndices()<br>also reports holes inside fragmented messages
    B->>A: ServiceMessageArrayRequest([4,7]) (precise re-request)
    A->>B: sendAgain(4), sendAgain(7)
```

## Why retransmission is safe

- **Persistence:** `MessageRootStorage` keeps each sent root keyed by id, so
  `sendAgain(id)` resends the exact bytes without re-fragmenting or re-hashing.
- **Deduplication:** the receiver drops any root whose integrity hash is already
  in `_processedHashes`, so resends and duplicates are harmless.
- **Fragment-aware:** `ChunkHandler.getMissingChunkIndices()` exposes holes
  within a fragmented message so only the missing chunks need re-requesting.

See [message_lifecycle.md](message_lifecycle.md) for the full send/receive
pipeline these hooks plug into.
