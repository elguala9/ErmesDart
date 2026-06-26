# Protocol Architecture

ErmesDart is a peer-to-peer encrypted messaging protocol. Peers discover each
other through a signaling rendezvous, punch a hole through NAT with STUN,
establish a UDP socket via SHSP (Single Hand Shake Protocol), and then exchange
encrypted, reliable, fragmented messages.

This document gives the structural map. The per-flow sequences live in the
sibling documents linked from [README.md](README.md).

## Package layout

Interfaces live in `iermes`; every other package is an implementation that
depends on the interfaces, never the reverse.

```mermaid
flowchart TB
    iermes["iermes<br>(abstract interfaces + types)"]

    subgraph impl["Implementations"]
        core["ermes_core<br>orchestrator, service, repos"]
        signaling["ermes_signaling<br>signaling handler + server, STUN"]
        cipher["ermes_cipher<br>ECDH key exchange, AES ciphers"]
        storage["ermes_storage<br>persistent encrypted storage"]
        idh["ermes_id_handler<br>per-peer id counters"]
        mc["ermes_message_control<br>id tracking, gap detection"]
        book["(book service)<br>peer registry"]
    end

    core --> iermes
    signaling --> iermes
    cipher --> iermes
    storage --> iermes
    idh --> iermes
    mc --> iermes

    core --> signaling
    core --> cipher
    core --> storage
    core --> idh
    core --> mc
    core --> book
```

## Runtime component map

A single `OrcErmes` orchestrator owns the signaling and connection machinery.
Each established peer gets its own `ErmesPeer` → `ErmesService` stack.

```mermaid
flowchart TB
    subgraph orchestrator["OrcErmes (orchestrator)"]
        conns["ErmesConnectionsHandler"]
        ss["IErmesSignalingServer<br>(relay/rendezvous)"]
        sh["IErmesSignalingHandler<br>(signal → SHSP socket)"]
        book["IErmesBookService<br>(peer registry)"]
    end

    subgraph peer["Per-peer stack (one per connection)"]
        ep["ErmesPeer"]
        svc["ErmesService"]
        send["ErmesSendRepo"]
        read["ErmesReadRepo"]
        mmc["MissingMessagesController"]
        repo["ErmesRepository : ShspInstance<br>(UDP transport)"]
    end

    subgraph crypto["Encryption"]
        ecdh["ECDHKeyExchangeService"]
        ch["ErmesPeerCipherHandler"]
        cipher["ErmesPeerCipher<br>(encrypt/decrypt + rotation)"]
        rot["ErmesPeerKeyRotator"]
    end

    orchestrator --> ep
    ep --> svc
    svc --> send
    svc --> read
    svc --> mmc
    svc --> repo
    send --> repo
    read --> repo

    ep --> rot
    rot --> cipher
    ch --> cipher
    ecdh --> cipher
    send -. encrypt .-> cipher
    read -. decrypt .-> cipher
```

## Layered responsibilities

| Layer | Component(s) | Responsibility |
|---|---|---|
| Orchestration | `OrcErmes`, `ErmesConnectionsHandler` | Open/close connections, hold the peer map |
| Discovery | `IErmesSignalingServer`, `IErmesSignalingHandler`, STUN | Exchange signals, discover public address, SHSP handshake |
| Session | `ErmesPeer`, `ErmesService` | Per-peer lifecycle, wire send/receive, dispatch service messages |
| Reliability | `ErmesSendRepo`, `ErmesReadRepo`, `MissingMessagesController`, `IErmesMessageControlService` | Fragmentation, reassembly, dedup, gap detection, retransmission |
| Security | `ECDHKeyExchangeService`, `ErmesPeerCipher`, `ErmesPeerKeyRotator` | Key exchange, symmetric encryption, key rotation |
| Transport | `ErmesRepository` (`ShspInstance`) | UDP send/receive over the SHSP socket |
| Persistence | `IErmesStorageAndCachingMessages` | Store sent roots (retransmission) and received messages (dedup/reassembly) |

## Core interfaces (`iermes`)

`Repository`, `Service`, `Peer`, `Orchestrator`, `SignalingHandler`,
`SignalingServer`, `Storage`, `IdHandler`, `Connection`, `MessageControl`. Each
implementation references only these abstractions, which keeps the transport,
crypto, and storage backends swappable and the suite testable against
interfaces rather than concrete classes.
