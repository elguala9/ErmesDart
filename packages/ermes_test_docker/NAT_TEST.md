# Real NAT-traversal test (two peers, no cloud)

Two standalone binaries drive a genuine NAT <-> NAT test of `OrcErmes`
over a **public Nostr relay** + **public STUN**, with no signaling server
of our own and no paid infrastructure:

| Binary | Role | Behaviour |
|--------|------|-----------|
| `bin/nat_peer_a.dart` | initiator (Alice) | connect → send `messageCount` `testData` → require an ACK for every one → send `endOfTests` |
| `bin/nat_peer_b.dart` | responder (Bob) | connect → ACK every `testData` → require the full sequence + `endOfTests` |

Both run the same rendezvous loop (`lib/src/nat_rendezvous.dart`): they
keep re-publishing a fresh STUN signal and retry `openConnection` until the
peer appears or the wall-clock budget (`lib/src/nat_test_protocol.dart`)
runs out. This absorbs the start-time skew between the two sides — start
them in any order, as long as they **overlap in time**.

## Strict by design

Every binary exits **0 only if its whole contract passed**. It exits
non-zero (and prints `RESULT: FAIL -> …` with a stack trace to stderr) on
*any* problem:

- a missing or malformed environment variable (`NatConfig.fromEnvStrict`
  reports **all** problems at once);
- `NOSTR_PUBKEY` not matching the role's expected pubkey;
- rendezvous timing out without a connection;
- a malformed or unexpected message;
- a single missing ACK / missing `testData`;
- the ACK / exchange / endOfTests wait timing out.

There is no "soft pass": the old Docker binaries treated an empty test list
as success — these do not.

## Environment variables

| Variable | Required | Meaning |
|----------|----------|---------|
| `NOSTR_PRIVKEY` | yes | this side's Nostr private key (64 hex) |
| `NOSTR_PUBKEY`  | yes | this side's Nostr public key (64 hex) — must equal the role's `*_PUBKEY` |
| `ALICE_PUBKEY`  | yes | Alice's public key (shared by both sides) |
| `BOB_PUBKEY`    | yes | Bob's public key (shared by both sides) |
| `STUN_HOST`     | yes | e.g. `stun.l.google.com` |
| `STUN_PORT`     | yes | e.g. `19302` |
| `NOSTR_RELAYS`  | yes | comma-separated `wss://` relays, e.g. `wss://relay.damus.io` |
| `ACCOUNT_ID`    | no  | self account id; defaults to `NOSTR_PUBKEY` |
| `SHSP_PORT`     | no  | fix the local SHSP UDP port for easier diagnosis |

## Throwaway test identities (NOT real — generated for this test only)

```
ALICE (peer A)
  privkey = baeed075852a757626e2bae3220c915ec43bcdc81343f83b0f50e3a933063d6c
  pubkey  = b92ad53e9350444f5572b4ffdc51a9839161729b0f5a62e68a3694c78d3dc4c5

BOB (peer B)
  privkey = 187f26af502a4b1dff9c80ab7798ffaace92c3db4ce85301300558ae02a3310e
  pubkey  = 40f72d5b56f8fcda629d4fd9e046038480cc71aaee01b3a2fc524aba6803dcac
```

Regenerate with `NostrKeys.generate()` if you ever need fresh ones. Never
reuse real identities here.

## Test A — two real networks (manual)

Run peer A on one machine/network and peer B on another (e.g. home PC +
phone 4G/5G hotspot), while both are running.

**Linux / macOS (machine 1, Alice):**
```bash
dart compile exe packages/ermes_test_docker/bin/nat_peer_a.dart -o nat_peer_a
STUN_HOST=stun.l.google.com STUN_PORT=19302 \
NOSTR_RELAYS=wss://relay.damus.io \
ALICE_PUBKEY=b92ad53e9350444f5572b4ffdc51a9839161729b0f5a62e68a3694c78d3dc4c5 \
BOB_PUBKEY=40f72d5b56f8fcda629d4fd9e046038480cc71aaee01b3a2fc524aba6803dcac \
NOSTR_PUBKEY=$ALICE_PUBKEY \
NOSTR_PRIVKEY=baeed075852a757626e2bae3220c915ec43bcdc81343f83b0f50e3a933063d6c \
./nat_peer_a
```

**Windows PowerShell (machine 2, Bob):**
```powershell
dart compile exe packages/ermes_test_docker/bin/nat_peer_b.dart -o nat_peer_b.exe
$env:STUN_HOST="stun.l.google.com"; $env:STUN_PORT="19302"
$env:NOSTR_RELAYS="wss://relay.damus.io"
$env:ALICE_PUBKEY="b92ad53e9350444f5572b4ffdc51a9839161729b0f5a62e68a3694c78d3dc4c5"
$env:BOB_PUBKEY="40f72d5b56f8fcda629d4fd9e046038480cc71aaee01b3a2fc524aba6803dcac"
$env:NOSTR_PUBKEY=$env:BOB_PUBKEY
$env:NOSTR_PRIVKEY="187f26af502a4b1dff9c80ab7798ffaace92c3db4ce85301300558ae02a3310e"
.\nat_peer_b.exe
```

Expected: full-cone / restricted-cone NATs (typical home routers) PASS;
symmetric NAT / CGNAT (typical mobile 4G/5G) is expected to FAIL until the
protocol gains TURN — documenting that failure is a valid outcome.

## Test A via Docker (no Dart, no repo on the host)

The single image `docker/Dockerfile.nat` holds **both** peers and picks the
role from its argument (`a` = initiator, `b` = responder). All identities,
STUN and relays default to the public throwaway values, so a zero-config run
is just one line per machine.

**Fastest path — one-line runner script** (no build, no repo, no Dart; just
Docker on each machine). It pulls the published image, runs the chosen role
and prints `RESULT: PASS/FAIL`. Works on Linux, macOS and Windows (Git Bash
or WSL):
```bash
curl -fsSL https://raw.githubusercontent.com/elguala9/ErmesDart/master/scripts/run-nat-test-pc.sh | sh -s -- a   # machine 1 (Alice)
curl -fsSL https://raw.githubusercontent.com/elguala9/ErmesDart/master/scripts/run-nat-test-pc.sh | sh -s -- b   # machine 2 (Bob)
```
Override the image with `ERMES_NAT_IMAGE=quay.io/<namespace>/ermes-nat-test:<tag>`;
any exported peer env var (`NOSTR_*`, `STUN_*`, `SHSP_PORT`, ...) is
forwarded into the container. The script auto-detects Docker or Podman
(force one with `ERMES_NAT_ENGINE=podman`).

**Verified (2026-06-11):** the image built locally with Podman 5.8 on
Windows/WSL (role `b`, home NAT) connected to a GitHub-hosted runner
(role `a` via `nat-test.yml` with `side=a-only`, Azure NAT) and completed
the full testData/ACK/endOfTests sequence — PASS on both sides.

**Stale signals (largely mitigated since 2026-06-12).** Signals persist on
the relay for 10 minutes (`epochTimestampExpireConversation`). If a peer ran
recently with the same identity, the OTHER side may first grab that stale
signal and punch toward a dead port. `OrcConnectionOpener.open()` now watches
each dial for a few seconds: if the peer republishes a fresher signal (a
higher `epochTimestampStartConversation`) while the connection hasn't come
up, it re-dials toward the new, live mapping instead of waiting on the dead
port. Because both peers republish at the start of every synchronized
rendezvous window, the fresh signal normally appears well within that watch
window. It is still cleanest to use fresh keypairs (or wait ~10 minutes)
after an aborted run, but a leftover signal no longer strands the next run.

Or run the image directly:
```bash
docker run --rm --network host quay.io/<namespace>/ermes-nat-test a   # machine 1 (Alice)
docker run --rm --network host quay.io/<namespace>/ermes-nat-test b   # machine 2 (Bob)
```
where `<namespace>` is the Quay.io namespace the image was published under
(see "Publishing" below).

Or build it locally (context must be the repo root):
```bash
docker build -f packages/ermes_test_docker/docker/Dockerfile.nat \
  -t ermes-nat-test .
```

Run on two different machines / networks:
```bash
docker run --rm --network host ermes-nat-test a   # machine 1 (Alice)
docker run --rm --network host ermes-nat-test b   # machine 2 (Bob)
```

`--network host` lets the SHSP UDP socket see the real host NAT. Without it
the container sits behind Docker's bridge NAT — an extra layer that falsifies
the result. On **Docker Desktop (Windows/macOS)** the container runs inside a
Linux VM, so `--network host` still adds that VM's NAT: the test runs but is
less clean than a native Linux host. Prefer a real Linux host for an
authentic result.

Override any default (e.g. your own keys or relays):
```bash
docker run --rm --network host \
  -e NOSTR_RELAYS=wss://nos.lol \
  -e SHSP_PORT=51820 \
  ermes-nat-test a
```

### Publishing to Quay.io

`.github/workflows/docker-publish-nat.yml` builds the image in CI and pushes
it to Quay.io as `quay.io/elguala/ermes-nat-test`, tagged both
`latest` (or the `tag` input) and the commit SHA.

One-time setup:
1. Create a Quay.io robot account with write access to the
   `elguala/ermes-nat-test` repository (quay.io → elguala → Robot Accounts).
2. Add two repository secrets (Settings → Secrets and variables → Actions):
   `QUAY_USERNAME` (the robot name, e.g. `elguala+ci`) and `QUAY_TOKEN`.

Then publish from **Actions → Publish NAT-test image to Quay.io → Run
workflow** (or push to `master` touching the relevant paths). Pulling the image
needs no account when the Quay repository is public: anonymous `docker run`
works.

Manual publish from a machine with Docker, if ever needed:
```bash
docker tag ermes-nat-test quay.io/<namespace>/ermes-nat-test:latest
docker push quay.io/<namespace>/ermes-nat-test:latest
```

## Test B — both peers in GitHub Actions (free, automated)

`.github/workflows/nat-test.yml` runs both peers as two parallel
GitHub-hosted runners behind Azure NAT.

- Trigger: **Actions → NAT Test → Run workflow** (`workflow_dispatch`), or
  push to the `nat-test` branch.
- The workflow checks out this repo **and** the public `shsp` dependency
  repo (`elguala9/SingleHandshakeProtocolDart`) into a sibling directory so
  the `dependency_overrides: shsp` path resolves.
- Each job compiles its binary, runs it with the env vars above, and uploads
  its log as an artifact (`peer-a-log`, `peer-b-log`).
- Job exit code = binary exit code: 0 pass, non-zero fail.

Drive and inspect a run:
```bash
gh workflow run nat-test.yml
gh run watch
gh run download --name peer-a-log --name peer-b-log
```

**Verified:** runs `27287740652` and `27288514758` (2026-06-10) completed
with both jobs green — the two Azure-NATed runners rendezvoused over the
public relays and exchanged the full testData/ACK/endOfTests sequence, so
GitHub runners' NAT does allow this hole punch. Earlier finding kept for
reference: `wss://relay.damus.io` alone rejects anonymous publishes, which
is why `NOSTR_RELAYS` lists several open-write relays.
