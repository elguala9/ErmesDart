# NAT Test B — GitHub Actions (free, no credit card, fully automated)

## Goal
Run BOTH peers inside GitHub Actions: two parallel jobs (or two runners), each
a real `OrcErmes` peer, talking to each other over a **public Nostr relay** +
**public STUN**. GitHub-hosted runners sit behind Azure NAT, so this is a real
NAT <-> NAT test — and it runs entirely in CI, free (2000 min/month), no credit
card. Claude drives and verifies this test.

This reuses the two standalone binaries built in TODO_NAT_TEST_A.

## Why two jobs in CI (not one CI peer + one local)
- A local peer would require a human at a machine; the point of B is full
  automation. Two parallel CI jobs overlap in time automatically, satisfying
  the "must be running concurrently" constraint.
- Both runners are behind restrictive Azure NAT -> good chance of exercising
  restricted-cone / symmetric behaviour, which is exactly what we want to learn.

## Tasks

### 1. Prerequisite
- [x] TODO_NAT_TEST_A binaries (`nat_peer_a.dart`, `nat_peer_b.dart`) exist and
      read config from env vars. Created in `packages/ermes_test_docker/bin/`
      with strict env validation (`NatConfig.fromEnvStrict`), a resilient
      rendezvous loop (`nat_rendezvous.dart`) and a shared protocol
      (`nat_test_protocol.dart`). See `packages/ermes_test_docker/NAT_TEST.md`.

### 2. Workflow file
- [x] Create `.github/workflows/nat-test.yml`.
- [x] Trigger: `workflow_dispatch` (manual) + `push` to `nat-test` branch.
- [x] Two jobs running in parallel: `peer-a` and `peer-b` (no `needs:` between
      them, so they start together).
- [x] Each job:
  - `actions/checkout` (this repo **+** the public `shsp` dependency repo
    `elguala9/SingleHandshakeProtocolDart` into a sibling dir, so the
    `dependency_overrides: shsp` path `../SingleHandShakeProtocolDart/...`
    resolves — discovered while wiring this up).
  - `dart-lang/setup-dart` + pub cache.
  - `dart pub get`
  - `dart compile exe packages/ermes_test_docker/bin/nat_peer_X.dart -o peer`
  - run `./peer` with env vars (public STUN + public relay + fixed test keys),
    via `set -o pipefail | tee` so the exit code is preserved.
- [x] Fixed test Nostr keypairs + account ids: inline throwaway values, with
      optional `NAT_ALICE_PRIVKEY` / `NAT_BOB_PRIVKEY` secret overrides.
- [x] Set a hard timeout per job (`timeout-minutes: 15`; binary budgets sized
      to fail with diagnostics before the timeout fires).
- [x] Upload each peer's stdout/log as a workflow artifact (`if-no-files-found:
      error`).
- [x] Job exit code 0 = pass, non-zero = fail (the binaries `exit(...)`).

### 3. Rendezvous timing in CI
- [x] Both jobs start ~together but compile times differ. The rendezvous retry
      loop (`nat_rendezvous.dart`, 6-min budget, 20s interval, re-publishes a
      fresh signal each attempt) handles the skew.
- [x] Startup grace: peer-a waits 15s (`NatTestProtocol.initiatorStartupGrace`)
      before its first attempt so peer-b can publish first.

### 4. Run & verify (Claude does this)
- [x] Commit workflow + binaries on a branch (`chore/exhaust-todo`). A one-shot
      launcher `melos run nat:run` (`packages/ermes_test_docker/bin/nat_run.dart`)
      pushes HEAD to the `nat-test` branch, waits for the run, watches it live,
      downloads both peer logs and prints PASS/FAIL. The user triggers the push.
- [x] Trigger: push to the `nat-test` branch (auto-fires the workflow; manual
      `workflow_dispatch` needs the workflow on the default branch first).
- [x] Poll `gh run list` / `gh run watch`; download artifacts with
      `gh run download`. Done by the launcher (and verified manually).
- [x] Report (run `27154951917`): the two runners did **NOT** connect. **FAIL**
      per peer — but **not** a NAT failure. Both peers failed at the *signaling*
      layer: `All relays failed to publish` on every rendezvous attempt for the
      full 6-min budget. NAT traversal was never exercised.

### 5. Document outcome
- [ ] Whether GitHub runners' NAT allows hole punching: **STILL UNKNOWN** —
      blocked upstream by signaling. The single relay `wss://relay.damus.io`
      rejected all anonymous publishes, so no signal was ever exchanged.
- [x] **Finding (run 27154951917):** `relay.damus.io` alone is unusable for
      anonymous CI signalling (rejects writes / likely needs NIP-42 AUTH). Fix
      applied: `NOSTR_RELAYS` now lists several open-write relays
      (`nos.lol`, `relay.damus.io`, `nostr-pub.wellorder.net`, `relay.primal.net`)
      so a publish succeeds if *any* relay accepts. Re-run pending to learn the
      actual NAT behaviour.
- [ ] If symmetric -> confirms the TURN gap; note it as a finding. (Pending a
      run that gets past signaling.)

## Notes / constraints
- GitHub-hosted runners: ~2000 free minutes/month for private repos, unlimited
  for public repos. No credit card.
- Outbound UDP from runners is allowed; inbound is NATed (that's the test).
- Keep keys throwaway — never reuse real identities in CI secrets.
