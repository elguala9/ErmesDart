# ErmesDart Flow Documentation

End-to-end documentation of the ErmesDart peer-to-peer protocol: how peers
discover each other, establish an encrypted transport, and exchange reliable,
fragmented messages.

## Suggested reading order

| Document | Covers |
|---|---|
| [architecture.md](architecture.md) | Package layout, runtime component map, layered responsibilities |
| [connection_establishment.md](connection_establishment.md) | `openConnection()` flow: STUN discovery → publish/poll signals → dial → re-dial on fresher signal |
| [signaling_handshake.md](signaling_handshake.md) | The lower-level signaling handshake that bootstraps the SHSP socket |
| [encryption.md](encryption.md) | ECDH key exchange, periodic key rotation, per-message encrypt/decrypt |
| [message_lifecycle.md](message_lifecycle.md) | Send pipeline (serialize → fragment → hash → dispatch) and receive pipeline (decode → dedup → reassemble → route) |
| [message_types.md](message_types.md) | The `MessageRoot` envelope and every payload / service-message type |
| [retransmission.md](retransmission.md) | Id tracking and the four retransmission paths (timer, threshold, acknowledge, array request) |

The diagrams are written in [Mermaid](https://mermaid.js.org/) and render
directly on GitHub.
