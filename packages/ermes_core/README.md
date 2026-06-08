# ermes_core

Core messaging functionality for the Ermes peer-to-peer messaging stack.

## Responsibilities

- **`ErmesService`** — high-level send/receive entry point with chunking, retransmission and key-exchange callbacks.
- **`ErmesSendRepo` / `ErmesReadRepo`** — outbound and inbound message pipelines, including encryption (via `ermes_cipher`), fragmentation and reassembly.
- **`ErmesRepository`** — transport-layer wrapper around an SHSP instance for a single remote peer.
- **`ErmesPeer`** — convenience facade combining the service, repository and signaling handler for a single peer.
- **`OrcErmes`** — orchestrator managing multiple connections, the signaling server and peer book.

## Architecture

`ermes_core` consumes interfaces defined in `iermes` and is composed with the other implementation packages (`ermes_signaling`, `ermes_storage`, `ermes_cipher`, `ermes_message_control`, `ermes_id_handler`). See the workspace `pubspec.yaml` and `CLAUDE.md` for the full topology.

## Exceptions

All errors raised by this package use `CoreException`, which extends `ErmesException` from `iermes`.

## Testing

Tests live in `packages/ermes_test/test/src/concrete_implementations/core/`.
