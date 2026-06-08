# ErmesDart Flow Documentation

End-to-end documentation of how a message travels through the ErmesDart stack,
plus the signaling handshake that establishes the transport.

| Document | Covers |
|---|---|
| [message_lifecycle.md](message_lifecycle.md) | Send pipeline (serialize → fragment → hash → dispatch) and receive pipeline (decode → dedup → reassemble → route) |
| [signaling_handshake.md](signaling_handshake.md) | The signaling handshake sequence that bootstraps a peer-to-peer socket |

The diagrams are written in [Mermaid](https://mermaid.js.org/) and render
directly on GitHub.
