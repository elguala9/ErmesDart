# TODO — Network-change test from a PC (real interface handoff)

Test connection re-establishment on a **real** network change from a PC
(WiFi ↔ cellular/tethering, AP roaming), matching the actual mobile use case.

## Goal

Reproduce a genuine WiFi ↔ 5G handoff: the PC's **public IP changes for real**,
the STUN hole-punched mapping dies, and the core must re-rendezvous and resume
the exchange. This is the scenario that ultimately matters for mobile usage.

## Why it should already work

Same mechanism as the Podman test:

- disconnect listener in `OrcConnectionOpener.open()`
  (`orc_ermes_connection_opener.dart:72`),
- `handlePeerDisconnect()` backoff + reconnect (`orc_ermes_callbacks.dart:35`),
- `openConnection` republishes the signal and re-dials (`orc_ermes.dart:78`).

## Approach — real dual interface (Option C)

- Run the peer **natively** on a Linux laptop (NOT inside a Docker/Podman
  Desktop VM, which masks the real public-IP change).
- Establish the connection over `wlan0` and start an exchange with a stable
  remote peer (second machine, or GitHub Actions via `nat_run.dart`).
- Trigger a real network change by switching the default route to a second
  interface (USB-tethered phone / second WiFi):

  ```sh
  sudo ip route replace default via <gw-tethering> dev usb0
  # or, with NetworkManager:
  nmcli con down <wifi>; nmcli con up <tethering>
  ```

  The public IP changes for real → exact WiFi ↔ 5G handoff.
- Verify: connection drops, core auto-reconnects (`handlePeerDisconnect` →
  `openConnection` re-rendezvous), exchange resumes. Measure reconnect time and
  any message loss.

## Work items

- [x] Reuse/extend the `network-change` scenario harness (shared with the
      Podman task): stay connected → detect reconnect → verify resume within a
      budget, with timing + lost-message metrics. DONE — same engines as the
      Podman test (`NatHeartbeatInitiator` / `NatHeartbeatResponder`, selected
      with `NAT_SCENARIO=network-change`). The PC variant just supplies the
      trigger differently (real `ip route` / `nmcli` handoff instead of a
      container network swap); the silence-based break detection and
      re-`rendezvous()` are identical, so no PC-specific harness code is
      needed.
- [ ] Write a short runbook (in `scripts/README.md` or `NAT_TEST.md`) with the
      exact `ip route` / `nmcli` commands for WiFi → tethering and back, plus
      how to run the stable peer on Actions.
- [ ] Note OS limits: needs a native Linux PC with two interfaces; document a
      macOS/Windows equivalent (route change) as best-effort.

## Constraints

- Needs a **native Linux PC with two interfaces**; the peer must run natively,
  not in a Desktop VM.
- The `network-change` scenario harness is **shared** with the Podman test —
  implement once, reuse here.
