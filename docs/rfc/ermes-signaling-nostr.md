# ERMES-over-Nostr Signaling (Informative)

- **Status:** Informative / Work in Progress
- **Category:** Non-normative companion to the
  [ERMES Protocol Specification](./ermes-protocol.md).
- **Scope:** Describes one optional signaling backend for ERMES signal
  exchange (§6 of the core specification): publishing and retrieving
  signals via Nostr relays. Nothing in this document is part of the ERMES
  wire contract. An implementation that signals peers by another channel —
  a statically-configured address, a QR code, a private relay, or anything
  else conforming to §6.1 and §6.3 of the core specification — can
  disregard this document entirely.

## 1. Relationship to the Core Specification

The [ERMES Protocol Specification](./ermes-protocol.md) defines a
**signal** (§6.1) — a small, self-contained record a peer publishes so a
counterpart can locate and dial it — and requires only that *some* channel
deliver that record from one peer to another (§6.3). This document
describes one such channel: using [Nostr](https://nostr.com/) relays as a
rendezvous point for signal exchange. It is entirely optional; ERMES itself
does not depend on Nostr, or on any other specific signaling backend.

## 2. Publishing and Retrieving a Signal via Nostr

A peer MAY publish its signal (§6.1 of the core specification) as the body
of a Nostr event, and retrieve a counterpart's signal by fetching that
counterpart's most recent matching event from one or more relays.

- Nostr relays **MUST** be treated purely as a rendezvous/bootstrap
  channel. They **MUST NOT** carry application messages — no ERMES
  envelope (§7 of the core specification), encrypted or plaintext, is ever
  published to a relay.
- A peer **SHOULD** re-publish its signal before it expires, and **SHOULD**
  re-publish (with a fresh address) if its own NAT mapping changes. What
  triggers this check — a background timer, or simply a side effect of
  another operation such as reconnecting to a peer — is
  implementation-specific and not part of the wire contract.
- A peer **SHOULD** poll for the counterpart's signal for a bounded period
  and give up (rather than poll indefinitely) if no valid signal appears.

## 3. Validation

A signal retrieved from Nostr is validated exactly as any other signal: the
receiving peer applies the rules of §6.1 of the core specification —
rejecting a signal that is expired, self-published, or older than a
previously-seen signal for the same counterpart — with no Nostr-specific
exception or relaxation.

## 4. Open Points

This backend inherits
[Open Point O-11](./ermes-protocol.md#11-open-points) from the core
specification (self-signal detection mechanism is unspecified) and defines
no additional open points of its own at this time.
