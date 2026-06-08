# Signaling Handshake

Before two peers can exchange messages they must discover each other's public
network address and establish an SHSP (Single Hand Shake Protocol) socket.
`ErmesSignalingHandler` (in `ermes_signaling`) owns this flow, backed by a
signaling server (`IErmesSignalingServer`) used as a rendezvous.

## Sequence

```mermaid
sequenceDiagram
    participant A as Alice (ErmesSignalingHandler)
    participant STUN as STUN server
    participant SS as Signaling server
    participant B as Bob (ErmesSignalingHandler)

    Note over A: createSignal()
    A->>STUN: discoverPublicAddress()
    STUN-->>A: public IP + port
    A->>SS: setSignal(SignalErmes{ipv4/ipv6, ports, epoch window})
    SS-->>B: getSignal() delivers Alice's signal
    Note over B: processSignal(signal, from=Alice, callback)
    B->>B: bookService.getPeerInfo(Alice)
    B->>B: _buildPeer(signal)  // prefer IPv6, else IPv4
    B->>B: ShspInstance.fromPeer(peer)
    B->>A: handshake(instance) — SHSP exchange
    A-->>B: SHSP socket established
    Note over A,B: onSocketReady fires; ErmesPeer/ErmesService wire up
```

## Steps

1. **`createSignal([remotePeerId])`** — the initiator discovers its public
   address via STUN (`discoverPublicAddress`, optionally using a custom STUN
   server set with `setCustomStunServer`). It classifies the address as IPv4
   and/or IPv6 and builds a `SignalErmes` containing the reachable addresses,
   ports, its public key and a validity window
   (`epochTimestampStartConversation` … `+ secondsExpirationDefault`, 10 min).
2. **Publish** — the signal is written to the signaling server, which the
   remote peer reads (compressed get/set on the server side).
3. **`processSignal(signal, from, callback)`** — the receiver looks up the
   sender via `IErmesBookService.getPeerInfo`, then `_buildPeer` selects a
   transport address, **preferring IPv6** and falling back to IPv4. If neither
   is present a `SignalingException` is thrown.
4. **`ShspInstance.fromPeer(peer)`** — wraps the chosen peer/socket.
5. **`handshake(instance, callback, signal, from)`** — performs the SHSP
   exchange and, on success, registers the per-peer socket in the connection
   map and invokes the `SocketReadyCallback`.
6. **Teardown / reconnect** — `clearConnection` / `softClearConnection` drop a
   peer's socket and callbacks; `ErmesSignalingReconnector` retries a dropped
   connection with bounded, exponentially backed-off attempts.

## Connection state

Per-peer sockets and readiness callbacks live in `ErmesSignalingConnectionMixin`
(`activeConnections`, `socketReadyCallbacks`), keeping the handler itself
focused on signal creation and processing.
