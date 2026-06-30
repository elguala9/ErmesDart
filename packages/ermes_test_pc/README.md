# ermes_test_pc

PC-to-PC NAT traversal tests: the two peers run on **two real machines** behind
real NATs, meeting over public Nostr relays and STUN. The peer binaries
themselves live in [`ermes_test_shared`](../ermes_test_shared); this
package provides the ways to run them on a PC and the documentation.

## Contents

- `docker/Dockerfile.nat` — single image holding both peers; the role (`a`/`b`)
  is chosen at run time via `nat-entrypoint.sh`.
- `docker/docker-compose.net-change.yml` — local network-change reconnection
  harness.
- `NAT_TEST.md` — full protocol, manual two-machine run, Docker run, and the
  network-change scenario.
- `TODO_MULTI_PC_TESTS.md`, `TODO_NET_CHANGE_PC.md`, `PUBLISH_IMAGE_QUAY.md`,
  `todos/` — the P1–P6 scenario backlog and image-publishing guide.

## Running

The peer binaries are compiled from `ermes_test_shared`. See the workspace
melos scripts (`nat:image:a`/`nat:image:b`, `nat:compose:build`, `netchange:*`)
and `NAT_TEST.md`. Build context for `Dockerfile.nat` is the repository root.
