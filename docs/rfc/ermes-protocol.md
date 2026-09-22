# ERMES Protocol Specification (Draft)

- **Status:** Draft / Work in Progress
- **Category:** Informational
- **Scope:** Wire protocol and peer behavior only. This document is
  implementation- and language-agnostic; it does not describe any particular
  SDK, package, or programming language.

## 1. Status of this Document

This document specifies ERMES, a peer-to-peer messaging protocol with
optional end-to-end encryption, built on top of a mandatory handshake
transport (SHSP). It follows the conventions of RFC 2119 for requirement
levels: **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT**, **MAY**.

## 2. Terminology

- **Peer**: An endpoint participating in an ERMES conversation, identified by
  a stable `IdSignaling`.
- **IdSignaling**: A stable, unique string identifying a peer. It is
  assigned and managed by the signaling layer and is opaque to the core
  protocol.
- **Encryption public key**: The public half of a peer's long-term ECDH key
  pair, used only for key agreement (§6.3, §8.1). It is distinct from
  `IdSignaling` and may rotate over time (§8.6).
- **Connection**: A logical, bidirectional channel between exactly two
  peers, carried over exactly one SHSP instance for exactly one IP address
  family. Two peers that are reachable over both IPv4 and IPv6 (§5) have
  two independent Connections between them, not one Connection spanning
  both families: each Connection has its own message-id sequence (§7.2),
  its own directional session keys and rotation schedule (§8), and its own
  acknowledge/retransmission/eviction state (§9-§10), entirely independent
  of the other family's. This matches §5's requirement that failure or
  migration of one address family **MUST NOT** affect the other.
- **Signal**: A small, self-describing record a peer publishes so that a
  remote peer can locate and dial it.
- **Message**: An application-level unit of data exchanged over a
  connection, identified by a monotonically increasing per-connection **id**.
- **Session key**: A symmetric key used to encrypt messages sent from one
  peer to another. Session keys are directional and may be rotated.
- **Mapping**: A local record associating a message id with either its
  original wire representation (for retransmission) or its decoded content
  (for local history). See [Section 8](#8-storage-and-mapping-should).

## 3. Design Goals

1. Establish a direct, NAT-traversing transport between two peers without a
   relay carrying application data.
2. Provide integrity for every message, and end-to-end confidentiality once
   the two peers have established a session key. Encryption itself is
   optional (§8.5), not a precondition for using this protocol.
3. Tolerate an unreliable underlying transport (UDP) via application-level
   sequencing and retransmission.
4. Keep the discovery/rendezvous mechanism (how peers find each other)
   separate and swappable from the data path.
5. Remain agnostic to how (or whether) an implementation persists messages
   beyond what is required for retransmission.

## 4. Protocol Layering

```
+-------------------------------------------+
| Application (MessageData / fragmentation) |
+-------------------------------------------+
| Sequencing & retransmission control       |
+-------------------------------------------+
| Encryption envelope (optional per message)|
+-------------------------------------------+
| SHSP (mandatory transport)                |
+-------------------------------------------+
| UDP + STUN (NAT traversal)                |
+-------------------------------------------+

Out of band, prior to the above:
+-------------------------------------------+
| Rendezvous / signaling (backend-agnostic) |
+-------------------------------------------+
```

Only the SHSP layer and everything below it is **mandatory**. Signaling and
persistent storage are auxiliary and are specified at MAY/SHOULD level
respectively.

Sequencing sits above encryption, not below it: a message's `id` (§7.2) is
assigned before the inner message is built, and encryption — when a session
key is available — is applied to that already-sequenced inner message as a
whole (§8.4), ids included. The diagram above reflects this: data flows
from the application through sequencing, then optionally through
encryption, and only then reaches SHSP.

## 5. Transport: SHSP (MUST)

ERMES **MUST** run its data path over SHSP (Single HandShake Protocol), a
lightweight, connection-oriented protocol over UDP with built-in NAT
traversal. SHSP is not an implementation detail an ERMES peer can substitute
— the message envelope, sequencing, and retransmission semantics defined in
this document all assume an SHSP-shaped underlying channel: application
traffic carried as SHSP "Data" datagrams (a receiver **MUST** inspect this
tag to tell data from session-management traffic) with every other datagram
kind opaque to the ERMES layer. SHSP itself, including its framing,
handshake, keep-alive, and NAT-traversal behavior, is specified in a
separate document and is not described here.

A connection normally keeps one UDP 4-tuple for its lifetime, but a peer
**MAY** rebind or migrate the local socket underneath an existing logical
connection (e.g., on detecting that its own address or NAT mapping changed)
without tearing the connection down; the mechanics of migration belong to
the SHSP document, not this one. A peer **MAY** operate independent SHSP
sessions for IPv4 and IPv6 simultaneously; each address family is fully
independent, and failure or migration of one **MUST NOT** affect the other.
Symmetric NAT and UDP-blocked environments cannot use SHSP as specified.
ERMES **MUST NOT** define, and an implementation **MUST NOT** rely on, a
TURN-equivalent relay path for application data: a direct, non-relayed data
path between the two peers (§3) is a non-negotiable design goal, not a
default that yields to a fallback. Peers behind a symmetric NAT, or on a
network that blocks UDP outright, are therefore explicitly **out of scope**
and unsupported by this protocol, for this reason IPV6 is always the best choice. 
An implementation **MAY** detect this condition — e.g. after a bounded number of 
failed SHSP handshake/hole-punch attempts — and surface it to the application as 
a permanent, non-retryable connection failure, distinct from the transient-disconnect 
reconnect behavior described below. 

A peer **SHOULD** attempt to reestablish a connection after an unexpected
disconnect — a fresh SHSP handshake to the same counterpart — using a
bounded number of attempts with increasing backoff, rather than treating a
single disconnect as permanent. This reconnect behavior is ERMES peer
behavior layered above SHSP, distinct from any keep-alive/retry SHSP itself
performs underneath a still-open connection.

## 6. Signaling / Rendezvous (MAY)

ERMES needs some way for two peers to learn each other's `IdSignaling`,
encryption public key, and reachable address(es) before an SHSP handshake
can be attempted. This document specifies a **signal** — a small,
self-contained, serializable record — and leaves the mechanism for
exchanging it explicitly **MAY**-level: any channel capable of delivering a
signal record from one peer to another satisfies this section.

### 6.1 Signal contents

A signal **MUST** contain at minimum:

- the publishing peer's `IdSignaling` (§2),
- the publishing peer's encryption public key (§2), used for key agreement
  (§6.3) and independent of `IdSignaling`,
- a reachable `(address, port)` pair for IPv4, for IPv6, or independent
  pairs for both — at least one family's pair **MUST** be genuinely
  reachable; a signal MAY leave the pair for an unsupported family empty,
- a validity window: a start time and an expiry, after which the signal
  **MUST NOT** be trusted or dialed.

A receiving peer **MUST** reject a signal that is expired, that is a
self-signal (one the peer itself published), or that is older than a
previously-seen signal for the same counterpart (**MUST NOT** regress to a
stale signal once a fresher one has been observed). Self-signal detection
**MUST** be performed by comparing the signal's `IdSignaling` (§6.1)
against the receiving peer's own `IdSignaling`: a peer is identified by its
stable `IdSignaling` (§2), while its advertised `(address, port)` and its
encryption public key are not stable — the address can legitimately change
between the moment a peer publishes its own signal and the moment it
observes it again (e.g. via a mobile network change), distinct peers can
transiently share an `(address, port)` pair (e.g. behind the same NAT), and
the encryption public key may rotate over time (§8.6). A receiving peer
**MUST NOT** use `(address, port)` equality, alone or as a substitute for
the `IdSignaling` comparison, to decide self-signal status; it **MAY**
additionally use `(address, port)` equality only as a secondary,
non-authoritative signal for local diagnostics.
A peer **MAY** additionally
reject a signal that, although not yet expired and not a regression, is old
enough relative to its own start time to be considered stale under an
implementation-defined threshold.
--- TODO: CLARIFY THIS THING OF THE WINDOW, IT IS VAGUE ----

### 6.2 Out-of-band and static signal exchange (informative)

Because a signal is a small, self-contained record (§6.1), nothing in this
protocol requires a pub/sub or relay-based exchange at all. A signal MAY be
delivered by any channel capable of carrying its fields from one peer to
the other — a QR code, manual copy/paste, a different pub/sub system, a
private relay, or simply a **statically-configured record**: a peer that
already knows its counterpart's `IdSignaling`, encryption public key, and a
fixed, reachable `(address, port)` — a conventional static IP and port, a
hostname, or anything else configured out of band — MAY construct the signal
locally
and proceed directly to the SHSP handshake (§5) against that address,
without publishing or retrieving anything over a network. This is a fully
conforming use of this protocol, not a degraded or special-cased mode:
ERMES's only requirement is that *some* valid signal (§6.1) becomes
available to each peer before it dials the other; how that signal reaches
the peer is intentionally out of scope.

This document takes no position on which channel is used; it only requires
that whatever channel is used, the receiving side applies the validation
rules in §6.1 — including a locally-constructed static signal, which still
needs a start time and expiry, even if both are trivially renewed on every
connection attempt.

### 6.3 Key agreement via the signal

The signal's encryption public key field **MUST** be usable, together with
the local peer's own key pair, to derive a shared secret via an
elliptic-curve Diffie-Hellman (ECDH) exchange. No private key material or
derived secret is ever placed on the signaling channel — only the
encryption public key. `IdSignaling` is an identifier, not key material,
and **MUST NOT** be used in key agreement. A receiving peer trusts the
signal as delivered: this document does not verify that a signal's
`IdSignaling` and encryption public key belong together, beyond trusting
whichever channel carried the signal.

## 7. Message Envelope (MUST)

### 7.1 Outer envelope

Every unit sent over the SHSP data channel (§5) **MUST** be a
self-contained, versioned envelope. The envelope **MUST** be serialized as a
single top-level object carrying exactly the following fields:

| Field                 | Presence                        | Meaning |
|-----------------------|----------------------------------|---------|
| `v`                   | MUST                              | Envelope version tag, `X.Y` (major.minor — see below). The current value is `3.0`; the inner payload always uses the single-level shape of §7.2. A receiver **MUST** branch its parsing on the major component `X`. A receiver **MAY** additionally accept a legacy, unversioned form (`v` absent, treated as `1.0`); like every other version, it follows the same `message`-or-`messageSerialized`/`digest` presence rule below and therefore has a plaintext variant too — encryption's optionality (§8.5) is universal and is not narrowed for this legacy form. |
| `integrityCheckValue` | MUST                              | A hash computed over the serialized inner payload (§7.2) **before** any encryption is applied. Carried as an opaque string. |
| `message`             | present iff no session key is used | The inner payload (§7.2), serialized in the clear, inline in the envelope. |
| `messageSerialized`   | present iff a session key is used  | The inner payload (§7.2), serialized and then encrypted; carried as an opaque byte string. |
| `digest`              | present iff `messageSerialized` is present | An identifier, chosen by the sender's cipher, of the specific session key (§8.2) used to encrypt `messageSerialized`. |

A legacy, unversioned envelope is not a special case of the presence rule
above: it carries `message` in the clear under the same condition (no
session key established/available for that message) as any versioned
envelope, and `messageSerialized`/`digest` otherwise.

`v` versions the ERMES envelope only, and is unrelated to SHSP's own
handshake version (§5): SHSP negotiates and versions its handshake under
its own specification, entirely opaque to the ERMES layer running on top of
it. ERMES's envelope version is a two-part `X.Y` (major.minor) value:

- **`X` (major)** identifies the envelope's wire shape (§7.2). A change to
  `X` denotes a wire-breaking change: peers on different majors cannot
  interoperate.
- **`Y` (minor)** selects, as a single unit, a fixed set of protocol
  parameters — key rotation cadence (§8.3, §8.6), retransmission
  timer/threshold values (§9.4), and eviction retention window (§10.2) —
  defined per minor version in §7.5. These parameters are **not**
  independently configurable
  per peer; a peer's only choice is which `Y` (under its supported `X`) to
  advertise.

ERMES version negotiation happens once, at ERMES-level handshake time,
layered above SHSP: as the first service message each peer sends on a newly
established connection, it **MUST** advertise the single highest `X.Y` it
supports. Compatibility is decided by comparing the two advertised `X`
values, a check either peer can perform identically and independently,
requiring no knowledge of the counterpart's full supported range:

- If the two `X` values **differ**, the peers are **NOT** compatible — the
  wire shapes cannot interoperate. A peer **MUST** treat this as a
  permanent, non-retryable ERMES-level connection failure and **MUST NOT**
  proceed to exchange application data on this connection, even though the
  underlying SHSP transport (§5) may itself be healthy. (This is a
  distinct failure from the SHSP-level unsupported-network case of §5.)
- If the two `X` values **match**, the peers **are** compatible: both
  **MUST** adopt the lower of the two advertised `Y` values, and the fixed
  parameter set for that `Y` (§7.5), for the connection's lifetime.

`v` remains a field on every envelope precisely so this agreement is
independently verifiable per message rather than merely assumed from setup:
a receiver **MUST** still branch its parsing on `X` as required above, and
**MUST** treat an envelope whose `v` does not match the version negotiated
for that connection as a protocol violation. SHSP's version and ERMES's
version remain two independent numbers in two independent layers, negotiated
by two independent handshakes.

Exactly one of `message` / `messageSerialized`+`digest` **MUST** be present
per §8.5: a plaintext envelope carries `message` and omits `digest`; an
encrypted envelope carries `messageSerialized` and `digest` and omits
`message`. An envelope **MUST NOT** carry both forms at once.

`digest` **MUST** deterministically identify the key: encrypting several
messages under the same session key **MUST** yield the same `digest` on
every one of them, even though the ciphertext differs message to message. A
`digest` **MUST** therefore be derived only from the key material itself
(e.g. a hash of the key, or a stable identifier assigned when the key was
generated) and **MUST NOT** incorporate any per-message value the cipher
introduces, such as a nonce, IV, or authentication tag — deriving `digest`
from ciphertext or from any such per-message value violates this
requirement and breaks the receiver's key lookup (§8.2).

A receiver **MUST** recompute the integrity value after decryption (or after
reading `message` directly, in the plaintext case) and **MUST** discard the
envelope if it does not match `integrityCheckValue`. A receiver **SHOULD**
treat the integrity value as an idempotency/deduplication key: if a value has
already been seen and accepted, the message **SHOULD** be treated as a
duplicate and not delivered to the application a second time.

### 7.2 Inner message types

The inner payload — the plaintext read directly from `message`, or the
decrypted plaintext of `messageSerialized` (§7.1) — **MUST** be a single
object of the form `{type, message}`, where `type` is one of `data`,
`chunk`, or `service`, and `message` is the type-specific body described
below. The full shape of an ordinary data message is therefore
`{"type":"data","message":{id, data}}`.

The body (the value of the `message` field) **MUST** be one of:

- **`data`** — a **Data message**, `{id, data}`: `id` is the message's
  per-connection sequence number (see below) and `data` is the raw
  application payload bytes.
- **`chunk`** — a **Chunk message**, `{id, data, refId, index, roof}`: `id`
  is this chunk's own per-connection sequence number; `data` is this
  fragment's payload bytes; `refId` is the identifier shared by every chunk
  belonging to the same logical (pre-fragmentation) message; `index` is this
  chunk's position; `roof` is the total number of chunks in the group. All
  chunks sharing one `refId` **MUST** be reassembled in `index` order, `0` to
  `roof - 1`.
- **`service`** — a **Service message**, a control message not delivered to
  the application, `{id, reason, ...}`: `id` is the per-connection sequence
  number, and `reason` is a discriminator selecting the kind and its
  additional fields:

  | `reason`      | Kind                          | Additional fields |
  |---------------|-------------------------------|--------------------|
  | `x`           | Connection close               | — |
  | `c`           | Generic control                 | — |
  | `a`           | Acknowledge (§9.2)               | `ackCurrentId`, `ackLastReceivedId` |
  | `newkey`      | New-key / key rotation (§7.4)    | `algorithm`, `key`, `start`, `expiration`, `startMessage`, `endMessage` |
  | `newpubkey`   | Public-key rotation (§8.6)       | `key` |
  | *(see note)*  | Array request (§9.3)             | `arrayId` |
  | `gone`        | Retransmission unavailable (§10.2) | `arrayId` |

  A sender **SHOULD** tag an array-request with a distinct `reason` (e.g.
  `array`); a receiver **SHOULD** recognize an array-request primarily by
  the presence of `arrayId` rather than by requiring an exact `reason`
  match, since not every implementation reserves a matching literal for it.

  A `gone` message is the counterpart's answer to an array-request (§9.3)
  or an acknowledge-implied gap (§9.2) that named one or more ids it can no
  longer resend: its `arrayId` lists exactly those ids, drawn from the same
  per-connection id space as the request that prompted it. A peer **MUST**
  send `gone` rather than silently ignoring such an id (see §10.2).

Every data, chunk, and service message **MUST** carry an `id` drawn from a
per-connection, monotonically increasing sequence, minted by the sender.
Ids are sequence numbers, not content hashes, and **MUST NOT** be reused
within a connection's lifetime.

### 7.3 Fragmentation

A sender **MUST** fragment an outgoing application payload whenever it would
otherwise produce a serialized envelope exceeding a safe per-datagram size
budget (chosen conservatively below common minimum-MTU limits so a single
UDP datagram is never fragmented at the IP layer). Fragmentation is applied
to the raw application payload **before** encryption, not after: a sender
splits an oversized payload into chunk messages (§7.2) first, and each
resulting chunk is then independently wrapped in its own outer envelope
(§7.1) and independently encrypted (when a session key is available) —
exactly as if it were its own standalone message. Each chunk therefore
carries its own `id`, its own `integrityCheckValue`, and, when encrypted,
its own `digest`; there is no single encrypted blob that is split after the
fact.

A `gone` service message (§7.2, §10.2) naming any id that belongs to a
`refId` group **MUST** be treated as failure of the entire group: a receiver
**MUST** discard every chunk it has buffered for that `refId` and **MUST
NOT** wait for a `gone` covering each individually missing member, since the
group can never complete reassembly once one member is confirmed
unrecoverable. This is not the same condition as the underlying connection
closing: a peer **SHOULD** reestablish a dropped connection (§5), and a
receiver **MUST NOT** discard a partially reassembled `refId` group merely
because the connection is currently closed or reconnecting — only a `gone`
naming one of its member ids justifies discarding it.

### 7.4 Key rotation traffic

A new session key **MUST** be delivered to the counterpart as a `new-key`
service message (§7.2, `reason: newkey`), addressed and sequenced exactly
like any other message on the connection. Its fields **MUST** be:

| Field          | Meaning |
|----------------|---------|
| `algorithm`    | Identifier of the symmetric cipher the key is for (e.g. AES). |
| `key`          | The key material itself. |
| `start`        | Time from which the key becomes valid for decryption. |
| `expiration`   | Time after which the key **MUST NOT** be used for new encryption. |
| `startMessage` | First message `id` (§7.2) the sender will encrypt under this key. |
| `endMessage`   | Last message `id` the sender intends to encrypt under this key, if known. |

`startMessage` and `endMessage` **MUST** be actively enforced by a receiver:
they are bounds expressed in the same per-connection message-id sequence
(§7.2) the receiver already tracks independently of any clock, so a
receiver **MUST** reject decryption of a message whose `id` falls outside
`[startMessage, endMessage]` (when `endMessage` is present) for the key
named by its `digest`, treating such a mismatch the same as any other
integrity failure (§7.1). `start` and `expiration`, by contrast, are
wall-clock values, and this document does not require the two peers' clocks
to be synchronized; a receiver **MUST NOT** reject a message solely for
falling outside `start`/`expiration` — these two fields remain advisory,
informing the sender's own bookkeeping (e.g. when to stop encrypting under a
key or when to safely discard it), not a receiver-side enforcement
boundary.

If an active outbound session key already exists at the time of rotation,
the `new-key` service message **MUST** be encrypted under that still-active
key — key material introducing a new session key **MUST NOT** be
transmitted in the clear once any encrypted session already exists between
the two peers. An implementation **MUST** maintain, per counterpart, a
single explicit "current outbound key" pointer — distinct from the set of
concurrently-valid decrypt keys (§8.2), which may legitimately hold several
entries at once — naming exactly the one key presently used to encrypt new
outbound traffic. Building a `new-key` message **MUST** encrypt it under the
pointer's value as it stood immediately before this rotation, and only
afterward **MUST** the pointer be updated to reference the newly announced
key. A general-purpose priority or expiration ordering over outbound-eligible
keys **MUST NOT** be used in place of this pointer for this specific
decision, since a newly-added key and the key it supersedes can otherwise
appear equally eligible under such an ordering. The very first session key on a fresh
connection is the one exception to the above: it is never sent as a
`new-key` service message, and no key material for it is ever transmitted
at all, over the signal or otherwise. Per §6.3, only the two peers'
encryption public keys are exchanged (over the signal or any other channel,
§6.2); each peer then independently *derives* the first symmetric
session key from the ECDH shared secret (§8.1). A `new-key` service message
is therefore only ever used to rotate to a subsequent key (§8.3), never to
establish the first one.

### 7.5 Fixed protocol parameters by version

Per §7.1, a connection's negotiated minor version `Y` fixes — as a single,
non-negotiable unit — every parameter this document would otherwise leave to
independent per-peer tuning. A peer's only degree of freedom is which
`X.Y` it advertises (§7.1); it **MUST NOT** deviate from the fixed values
below for whichever `Y` was negotiated for a given connection.

| Parameter | `3.0` |
|-----------|-------|
| Symmetric session-key rotation, by message count (§8.3) | N messages (to be decided) |
| Encryption public-key rotation, by elapsed time (§8.6) | T (to be decided, e.g. 1 day) |
| Missing-messages threshold, reactive check (§9.4) | 10 missing ids |
| Retransmission-mapping retention window for unacknowledged entries (§10.2) | 3600 seconds |

The table is headed by the current minor version (`Y = 0`) alone, not by
the major `X`: per §7.1, the fixed set is selected by `Y` alone, and a
future minor version under the same major would add its own column here
without touching the values already fixed for the current one.

Introducing a new minor version under an existing major is exactly how any future revision
to these values, individually or together, **MUST** be made — never by
silently changing a value already in use under a `Y` peers have negotiated
(the same wire-stability principle as §7.1).

## 8. Encryption (MUST once a session key exists)

### 8.1 Key agreement

Each peer **MUST** possess a long-term encryption key pair (public/private)
usable for ECDH. The shared secret derived per §6.3 **MUST** be used,
directly or via a key-derivation step, to seed the first symmetric session
key for a connection.

Because a signal's encryption public key (§6.1) is not itself scoped to an
address family, two Connections to the same counterpart (§2 — one per
address family) derive from the same ECDH shared secret. The key-derivation step
**MUST** therefore mix in a per-connection context (e.g. the address
family) when seeding each Connection's first session key, so that two
Connections to the same counterpart never end up encrypting under
identical key material merely because they share one ECDH shared secret.

### 8.2 Directional keys

Encryption keys **MUST** be directional: the key a peer uses to encrypt
outgoing messages to a given counterpart is distinct from the key it uses to
decrypt incoming messages from that same counterpart, even though both may
initially derive from the same ECDH shared secret. A peer **MUST** be able
to hold more than one valid decrypt key per counterpart at once (to bridge a
key-rotation window) and **MUST** select among them using the digest carried
in the message envelope (§7.1 — which also states the determinism this
lookup depends on).

### 8.3 Symmetric session-key rotation

A peer **MUST** rotate its outbound session key after the message-count
interval fixed for the connection's negotiated minor version (§7.5). This
interval is not a per-peer tuning choice (see §7.5); a peer **MUST NOT**
use a different cadence than the one its negotiated `Y` fixes. A
rotated-in key **MUST** be usable for decryption by the receiver strictly
after it is delivered via §7.4, and a peer **SHOULD** retain a prior key
for some grace period so that messages already in flight under the old key
are not rejected as undecryptable.

### 8.4 Scope of encryption

When a session key is available, the **entire inner message** (its type tag
and all associated fields, including ids and control fields for service
messages) **MUST** be encrypted — not only an application-visible "payload"
field. Only the outer envelope's version, integrity value, and key digest
(§7.1) remain unencrypted, since the receiver needs them to select a key and
verify integrity before decrypting.

### 8.5 Encryption is optional

Establishing a session key (§8.1) at all is **OPTIONAL**. A peer **MAY**
send every message on a connection in the clear (plaintext inner message,
no `digest`) for the connection's entire lifetime; this is a legitimate
steady state in its own right, not merely a transient bootstrapping window
that must eventually close. This document does not require that encryption
ever be established between two peers, and the confidentiality half of the
design goals (§3) applies only once — and for as long as — both peers have
chosen to do so; the integrity guarantee of §7.1 (`integrityCheckValue`) is
unconditional and applies identically to plaintext and encrypted envelopes.

If a peer has not yet established (or has not yet received) any usable
encrypt key for a given counterpart — whether because key agreement is
still in progress, or because encryption was simply never enabled for this
connection — it sends in the clear rather than blocking. An implementation
that does intend to encrypt **SHOULD** still minimize the window before its
first session key takes effect, so that the asymmetric-trust period, where
it occurs, stays short.

### 8.6 Encryption public-key rotation

A peer **MUST** rotate its encryption public key (§2) after the elapsed-time
interval fixed for the connection's negotiated minor version (§7.5). To do
so it **MUST** generate a new ECDH key pair and announce the new public half
both in-band and out-of-band:

- in-band, as a `newpubkey` service message (§7.2) carrying the new public
  key in its `key` field, addressed and sequenced like any other message on
  the connection;
- out-of-band, by re-publishing its signal (§6.1) with the new encryption
  public key and the same `IdSignaling`.

A `newpubkey` message carries only public material and **MAY** be sent in
the clear; its integrity is covered by `integrityCheckValue` (§7.1).
Rotating the encryption public key **MUST NOT** change the peer's
`IdSignaling` (§2).

On receiving a `newpubkey` — or observing a re-published signal carrying a
new encryption public key for the same `IdSignaling` — both peers **MUST**
re-derive the ECDH shared secret and, from it, fresh directional session
keys (§8.2), exactly as the first key is seeded at connection establishment
(§8.1). The symmetric session-key rotation of §8.3 then continues on the
new keys. A peer **SHOULD** retain the prior key for a grace period so that
messages already in flight under the old key are not rejected as
undecryptable.

## 9. Sequencing and Retransmission (MUST)

Because the underlying transport is UDP, ERMES **MUST** implement
application-level detection and recovery of lost messages.

### 9.1 Gap detection

A receiver **MUST** track the highest contiguous message id received from
each counterpart and **MUST** record any id gap (a received id higher than
expected, implying earlier ids were skipped) as missing.

### 9.2 Acknowledge

A peer **SHOULD** periodically send an acknowledge service message (§7.2,
`reason: a`) carrying exactly two fields: `ackCurrentId`, its own current
highest sent message `id`, and `ackLastReceivedId`, the highest id it has
received from the counterpart. On receipt, a peer **MUST** compute the
implied gap (its own current id minus the counterpart's `ackLastReceivedId`)
and, when positive, **SHOULD** proactively resend the messages in that
range without waiting to be asked.

`ackCurrentId` serves a distinct purpose from `ackLastReceivedId`: a
receiver **MUST** additionally compare it against its own §9.1-tracked
highest contiguous id received from that counterpart. When `ackCurrentId`
is higher, the receiver **MUST** record every id in between as missing,
folding them into its §9.1 gap record (subject to recovery via §9.3/§9.4)
even though no data message has arrived to reveal the gap the way §9.1
otherwise relies on — this is precisely the case §9.1's inbound tracking
alone cannot detect (a run of trailing messages lost with nothing sent
afterward to expose the hole).

### 9.3 Explicit array request

A peer **MAY** send an array-request service message (§7.2) carrying a
single field, `arrayId`: a list of the specific message ids it is missing.
On receipt, the counterpart **MUST** attempt to resend each id named in
`arrayId` from its own record of previously-sent messages (§10); for any
named id it can no longer resend, it **MUST** instead name that id in a
`gone` service message (§7.2, §10.2) rather than silently dropping it.

### 9.4 Periodic and threshold-triggered checks

A peer **SHOULD** periodically evaluate its own recorded gaps — ids it is
missing *from the counterpart*, built from inbound sequence tracking (§9.1)
and not to be confused with ids the counterpart might be missing from it,
which is a separate id-namespace built from the peer's own outbound
sequence and is only ever driven by an incoming acknowledge (§9.2). A peer
**SHOULD** also evaluate this same recorded-gap record reactively after
each processed inbound message, triggering recovery once the number of
outstanding missing ids reaches the threshold fixed for the connection's
negotiated minor version (§7.5) — no longer an independently configured
value (see §7.5).

Both triggers resolve to the same wire action: on firing — whether
periodic or threshold-triggered — a peer **MUST** send an array-request
service message (§9.3) to that counterpart, naming every currently-missing
id from its §9.1 record. §9.4 defines no new message; it defines two
additional occasions — a timer, and a threshold crossing — on which a peer
sends the same array-request proactively, without waiting for the
application to ask.

### 9.5 Retransmission identity

A resend of message id N **MUST** be bit-for-bit the same envelope
originally sent for id N (same encryption state, same digest) — not a
re-derivation — so that the receiver's deduplication (§7.1) and ordering
guarantees are not violated by a retransmission.

## 10. Storage and Mapping (SHOULD)

ERMES does not require a full message database to function, but it
**SHOULD** maintain a **mapping** from message id to enough information to
satisfy a retransmission request (§9) for some bounded retention window.

### 10.1 What MUST be mapped

For any message id a peer might still be asked to resend, it **SHOULD**
retain the exact previously-sent envelope (§9.5) keyed by that id. This
mapping is the minimum necessary state; it is not required to be persisted
across process restarts, and it is not required to retain decoded/plaintext
history — that is a local application concern, not a protocol requirement.

### 10.2 Eviction and the "message no longer exists" case

Once a counterpart's acknowledge (§9.2) reports an id via
`ackLastReceivedId`, that id is confirmed delivered and, per the gap
semantics of §9.2/§9.4, will never again be named in an array-request (§9.3)
or implied by a gap from that counterpart: a peer **MUST** evict that id's
entry from the mapping at that point (or **MAY** defer the actual eviction,
provided it treats the id as no longer retrievable no later than the next
time it would otherwise be evicted). A peer **MUST** additionally evict any
entry that has not yet been acknowledged once it exceeds the retention
window fixed for the connection's negotiated minor version (§7.5) — this is
no longer an optional, implementation-chosen policy: both the trigger (age
against the fixed window) and its parameter (the window's duration) are
mandated by §7.5, trading a known, version-fixed amount of retransmission
reliability for a bounded memory footprint, the same way for every
implementation of a given version rather than differing case by case. When a
peer receives a request (§9.3) or implied gap (§9.2) for an id it has since
evicted (whether via ack-confirmation or the fixed retention window) or
never held, it:

- **MUST NOT** silently drop the request with no wire-visible effect, and
- **MUST** instead send a `gone` service message (§7.2) naming that id, so
  the counterpart can stop requesting it and, where applicable, surface the
  loss to its application.

### 10.3 Relation to the id mapping

The message-id sequence itself (§7.2) is a simple per-connection counter and
is not, by itself, a content-addressed identifier. Any mapping used for
retransmission or for the "no longer exists" response of §10.2 is keyed by
this sequence id, not by a hash of the content.

