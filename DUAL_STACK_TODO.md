# Dual-Stack (IPv6-main + IPv4 fallback) & Socket Migration — Plan

## Goal

Support IPv6 as the primary transport with automatic fallback to IPv4, inside a
**single `OrcErmes`** (not two instances), and enable transparent socket
**migration on IP change** — all without rebuilding peers.

This must keep working with mixed peers, in particular the GitHub-runner NAT
test where the runner has no usable IPv6: the two sides must auto-converge on
IPv4 while two IPv6-capable peers use IPv6.

## Status

This plan was originally written against `stun_shsp` 0.3.0. The workspace has
since migrated to **stun_shsp 0.4.0 / shsp 1.10.1 / stun 1.6.1 /
nostr_signaling 0.6.0** on singleton_manager 2.x, which changed the ground this
plan stood on. Everything below is restated against the APIs that actually
exist now.

**What the upgrade already gave us for free** (was TODO work in the 0.3.0 plan):

- Per-family registration. `initializeStunShsp(key:)` registers an
  `IStunShspHandler` and an `IShspSocket` under the `'ipv4'` and `'ipv6'`
  subkeys, plus `IDualStunShspHandler` under the default subkey. Selecting a
  family is now a registry lookup, not a getter on a singleton.
- Socket migration primitives, previously absent:
  `migrateStunShspSocketIpv4/Ipv6`, `migrateDualStunShspSockets`,
  `migrateShspSocketIpv4/Ipv6`, `migrateStunHandlerSocket`, and
  `DualShspSocketAuto.refreshSockets()`. The migratable entry is never replaced,
  only its underlying `RawDatagramSocket`, so peers survive migration.
- Dual-family STUN results. `StunResponse` now carries both families at once
  (`publicIp(type)` / `publicPort(type)`, both nullable) instead of one
  address, so a single `performStunRequest()` can fill both signal slots.

**What the upgrade invalidated in the old plan:**

- `StunShspHandlerSingleton`, `DualShspSocketWrapperDI`, `ShspSocketWrapper` and
  the `ipv4ShspSocket` / `ipv6ShspSocket` getters are all gone. The 0.3.0
  finding that "the generic `IShspSocket` DI key is wired to only the IPv4
  socket" no longer describes anything real.
- `ShspSocketWrapper` was renamed `ShspSocketMigratable`
  (`IShspSocketMigratable`). It is still both an `IShspSocket` and migratable,
  which is what makes step B viable.
- `performStunRequest({bool ipv6})` lost its flag; the whole stun dual API moved
  from `bool ipv6` to `InternetAddressType type`.
- `DualStunShspHandler` is deliberately **not** an `IDualStunHandler` any more —
  use its `.dualStunHandler` getter for the STUN surface.

**Current behaviour after the migration:** deliberately unchanged, IPv4-primary.
`ErmesSignalingHandler` and `OrcErmes` both resolve their handler and socket
under `@Subkey('ipv4')`. `stun_discovery._pickAddress` prefers IPv6 when the
STUN response has it, but only ever fills one signal slot — so the original
convergence gap is still open.

## Decision (unchanged)

- One `OrcErmes`, one signal advertising **both** families.
- Family is negotiated at peer-build time (capability intersection).
- Peers are built on the per-family migratable sockets, enabling migration.
- Migration on IP change via the stun_shsp `migrate*` helpers.

Two `OrcErmes` (one per family) is rejected: it collides on the per-identity
relay signal, fragments connection/retransmission state, and doubles the
rendezvous work.

## TODO

### A. Signaling: advertise both families
- [ ] **A1** — `stun_discovery.dart`: replace `_pickAddress` (which picks ONE
  family) with a dual accessor returning both slots from the single
  `StunResponse`. A family is advertised only if `publicIp(type)` is non-null
  AND an `IShspSocket` is registered under that family's subkey.
- [ ] **A2** — `ErmesSignalingHandler.createSignal`: fill all four slots
  (`ipv4/ipv4Port/ipv6/ipv6Port`) when available, instead of the current
  one-family-plus-empty-slots shape.

### B. Peer building: negotiate family + per-family migratable socket
- [ ] **B1** — `ErmesSignalingHandler._buildPeer`: select IPv6 only if the remote
  signal carries IPv6 AND this peer has an `IShspSocket` registered under the
  `'ipv6'` subkey; otherwise IPv4 (capability intersection). It currently
  prefers IPv6 from the signal alone, without checking local capability.
- [ ] **B2** — pass the matching per-family socket to `ShspPeerFactory.create`
  instead of the single injected `socket`. This means `ErmesSignalingHandler`
  and `OrcErmes` need both families, so their `@Subkey('ipv4')` constructor
  parameters become a pair (or an injected `IDualStunShspHandler`) — note
  `@Subkey.inherited()` exists for the case where one class is connected once
  per subkey.

### C. Receive path
- [ ] **C1** — verify an IPv6 peer actually receives: confirm inbound frames from
  an IPv6 peer reach `dispatchMessage`. Peer callbacks are set on the peer's own
  socket, and each family now has its own registered socket, so anything that
  still assumes a single socket will silently drop IPv6 traffic.

### D. Migration on IP change (still not wired, but the primitives now exist)
- [ ] **D1** — on detected IP change call `migrateDualStunShspSockets(...)` (or
  `DualShspSocketAuto.refreshSockets()`). No peer rebuild: the registered
  migratable entries stay, only their raw sockets change.
- [ ] **D1b** — handle "IPv6 no longer available after the change": the `'ipv6'`
  entry must stop being selectable by **B1** rather than resolve to a dead
  socket.
- [ ] **D2** — choose the change-detection trigger: periodic STUN mapping hash
  vs OS network-change event. *(TO DECIDE)*
- [ ] **D3** — after migration, republish the signal (`createSignal`) with the
  new ip/ports. Fresh sockets get new ports → NAT mapping changes → republish
  required.

### E. Cleanup / constraints
- [ ] **E1** — remove the `@Subkey('ipv4')` pins in `ErmesSignalingHandler` and
  `OrcErmes` once **B2** supplies both families. They are the deliberate
  IPv4-primary markers left by the migration; grep for them to find every place
  a family is currently hard-coded.
- [ ] **E2** — `nat_rendezvous._refreshOwnNatMapping` already pings both
  families via their subkeys; keep it in sync with whatever **A1** decides is
  advertised.
- [ ] **E3** — respect project rules: files ≤150 lines, functions ≤30 lines, no
  `dynamic` / no `as` casts, dedicated factories.

### F. Tests & validation
- [ ] **F1** — unit tests: `createSignal` fills both slots; `_buildPeer` picks
  correctly for each combination of local capability and remote signal
  (IPv4-only peer, dual-stack, IPv6-only).
- [ ] **F2** — `melos run test --no-select` (no regression in
  signaling/handshake). Baseline after the version migration: `ermes_test`
  1476/1476, `ermes_test_with_mock` 101/101, `ermes_signaling` 48/48,
  `ermes_storage` 90/90, `ermes_cipher` 50/50, `ermes_id_handler` 47/47,
  `ermes_message_control` 34/34, `ermes_core_init` 12/12. Note
  `ermes_signaling_service_test` talks to a public Nostr relay and times out
  intermittently — re-run before treating it as a regression.
- [ ] **F3** — `melos test:github:long-outage` (must converge on IPv4 with the
  runner) + other P1 scenarios.

## Open decisions
1. **Scope of C/D**: they touch `ermes_core` (production). Do them now (true
   end-to-end IPv6), or land A+B+F first to unblock the test and do C+D after?
2. **D2 trigger**: STUN mapping hash (periodic) vs OS network-change event.
3. **A/B in the library**: `createSignal` / `_buildPeer` live in
   `ermes_signaling` (production) → dual-stack becomes the default behaviour for
   all consumers. Confirm this is intended (it is the "IPv6-main + fallback"
   goal).
