# TODO — Network-change test via Podman (NAT mapping swap)

Simulate a network change while a connection is **live**, entirely on one
Linux host with Podman (or Docker), and verify the core auto-reconnects
(`handlePeerDisconnect` → `openConnection` re-rendezvous).

## 1. Goal

A real network switch (WiFi → 4G, roaming, AP change) does not just drop the
link: it changes the peer's **public source IP:port**. The STUN hole-punched
UDP mapping dies and must be renegotiated (new Nostr signal → new hole-punch).
This test forces that condition reproducibly and checks the exchange resumes.

## 2. Why it should already work

- `OrcConnectionOpener.open()` registers `addOnDisconnectListener`
  (`orc_ermes_connection_opener.dart:72`).
- On disconnect, `handlePeerDisconnect()` (`orc_ermes_callbacks.dart:35`)
  does exponential backoff (1s, 2s, 4s…) and re-calls `openConnection(peer)`.
- `openConnection` republishes the signal and re-dials / re-hole-punches
  (`orc_ermes.dart:78`).

The test verifies this end-to-end and measures reconnect time / message loss.

## 3. Approach — container network swap (Option A)

- Do **NOT** use `--network host` for the moving peer; attach it to a
  user-defined bridge so its IP / NAT mapping can change at runtime.
- Two bridge networks:
  - `ermes-netA` — `172.30.0.0/16` (start state)
  - `ermes-netB` — `172.31.0.0/16` (swap destination)
- Start `peer-b` on `netA`, let the SHSP handshake complete and an exchange
  start; keep `peer-a` stable (host network locally, or on GitHub Actions via
  `nat_run.dart`).
- Mid-exchange, swap the network to force a new mapping:

  ```sh
  podman network disconnect ermes-netA ermes-net-change-peer-b
  sudo conntrack -D -p udp            # drop the stale UDP hole-punched flow
  podman network connect    ermes-netB ermes-net-change-peer-b
  ```

- Verify: peer detects disconnect → `handlePeerDisconnect` backoff →
  `openConnection` republishes signal → new hole-punch → exchange resumes
  within a budget. Emit `PASS` / `FAIL`.

## 4. Compose vs script — why it is split

Compose is **declarative**: it can express the START state but not a timed,
mid-run mutation. So the work is split by responsibility:

| Concern | Owner | Where |
|---|---|---|
| Two networks' subnets, two peers, roles, init/TTY | Compose | `docker/docker-compose.net-change.yml` |
| Ensure `netB`, swap `netA`→`netB`, conntrack flush, timing, verdict | Script | `scripts/run-net-change-test-compose.sh` |

> `netB` is **not** declared in compose: it is the swap destination and belongs
> to the CHANGE step, so the script creates it idempotently. Container names are
> pinned in compose (`ermes-net-change-peer-a/-b`) so the script can target them
> without guessing the compose project prefix.

## 5. Status

- [x] **Compose scaffolding** — `docker/docker-compose.net-change.yml`:
      `peer-a` (host network, stable) + `peer-b` (bridge `netA`, `NET_ADMIN`),
      single image, role via `command`, `NAT_SCENARIO=network-change` env
      (ignored by today's image, consumed once item #6 lands).
- [x] **Swap driver** — `scripts/run-net-change-test-compose.sh`: engine auto-detect
      (docker/podman/podman-compose), `--init` setup, wait-for-live-marker,
      disconnect → pause → conntrack flush → connect, `wait` for the exit code,
      Ctrl+C teardown, native-Linux fidelity warning.
- [x] **Harness scenario (item #6)** — DONE. Selected with
      `NAT_SCENARIO=network-change` (already wired in compose). The moving peer
      now stays connected on a `testData`/`ack` heartbeat across the break:
      `NatHeartbeatInitiator` (peer-a) and `NatHeartbeatResponder` (peer-b) in
      `lib/src/`. The responder prints `STEADY EXCHANGE LIVE;` once the
      heartbeat is steady (the script's `READY_MARKER` default now matches),
      both sides detect the silence and re-`rendezvous()`, and the initiator
      reports reconnect time + messages lost. The script proves real
      reconnection, not just bring-up + swap.

## 6. `network-change` harness scenario — IMPLEMENTED

The default `nat_peer_a` / `nat_peer_b` send a one-shot burst of
`NatTestProtocol.messageCount` (5) messages and exit, so there is no live
exchange to interrupt. The `network-change` scenario extends the harness so
the swap has something to break:

- [x] `network-change` mode gated by env `NAT_SCENARIO=network-change`
      (already wired in compose). `nat_peer_a` / `nat_peer_b` branch on
      `isNetworkChangeScenario()` and hand off to the heartbeat engines.
- [x] After the first rendezvous the peers keep exchanging `testData`/`ack`
      on a heartbeat (`NatTestProtocol.heartbeatInterval`, 2s) instead of
      stopping after the burst.
- [x] Once `preBreakHeartbeats` are acked the responder prints
      `STEADY EXCHANGE LIVE;` (`NatTestProtocol.steadyExchangeMarker`) so the
      script knows when to swap. The script's `READY_MARKER` default now
      matches this exact text.
- [x] After the break both sides detect `linkSilenceThreshold` of silence and
      reuse `rendezvous()`; the exchange must resume within
      `reconnectBudget`. The initiator records **reconnect time** and
      **messages lost** (logged as `RECONNECT METRICS:`) then exits `0`
      (PASS) / non-zero (FAIL).
- [ ] `DockerMsgType.disconnectNow` is left unused: the network swap (Podman)
      or the route change (PC) is the trigger, so no peer-driven break signal
      is needed. Wire it only if a swap-free local smoke test is wanted.

Implementation: `lib/src/nat_heartbeat_initiator.dart`,
`lib/src/nat_heartbeat_responder.dart`, `lib/src/nat_network_change.dart`,
and the `network-change` constants in `lib/src/nat_test_protocol.dart`.

> This item is **shared** with the PC test (`TODO_NET_CHANGE_PC.md`) — the same
> engines drive both.

## 7. How to run

```sh
# native Linux host or WSL2
sh scripts/run-net-change-test-compose.sh --init     # first run: pull image + nets
sh scripts/run-net-change-test-compose.sh            # subsequent runs
```

The image must be rebuilt/pulled with the heartbeat engines for the scenario
to take effect; the moving peer reads `NAT_SCENARIO=network-change` from
compose. Useful overrides: `ERMES_NAT_ENGINE=podman`, `READY_MARKER=...`
(default `"STEADY EXCHANGE LIVE;"`), `READY_TIMEOUT=360`, `BREAK_PAUSE=3`,
`ERMES_NAT_IMAGE=...`.

## 8. Constraints

- Needs a **native Linux host (or WSL2)** so `conntrack` and the network swap
  work; not faithful under Docker/Podman Desktop VM NAT (the VM adds its own
  NAT layer that masks the public-mapping change). The script warns and still
  runs, but `PASS`/`FAIL` is only meaningful on native Linux.
- `conntrack` must be installed on the host (`conntrack-tools`); the script
  warns if it is missing and skips the flush.
- Item #6 (the `network-change` scenario harness) is **shared** with the PC
  test — implement once, reuse in both.
