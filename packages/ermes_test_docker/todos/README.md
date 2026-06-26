# Two-PC test backlog — index

One `todo.md` per scenario. Each is a self-contained spec: goal, the
`NAT_SCENARIO` selector, the core code path it stresses, setup, steps, the
strict pass/fail asserts, and the metric line it must print.

Shared harness: `NatHeartbeatInitiator` / `NatHeartbeatResponder`,
`MessageEnvelope` / `DockerMsgType`, drivers in `scripts/`. See
`../TODO_MULTI_PC_TESTS.md` for the high-level overview.

## P1 — Disconnection / reconnection
- [graceful-reconnect](graceful-reconnect.md)
- [peer-restart](peer-restart.md)
- [long-outage](long-outage.md)
- [flap](flap.md)
- [dual-net-change](dual-net-change.md)
- [flap-storm](flap-storm.md)

## P2 — Message reliability under churn
- [lossless-reconnect](lossless-reconnect.md)
- [fragmented-break](fragmented-break.md)
- [gap-detection](gap-detection.md)

## P3 — Encryption / key exchange
- [encrypted](encrypted.md)
- [rekey](rekey.md)
- [rekey-on-reconnect](rekey-on-reconnect.md)

## P4 — Load / stress
- [throughput](throughput.md)
- [large-payload](large-payload.md)
- [keepalive](keepalive.md)

## P5 — Adverse network conditions
- [lossy](lossy.md)
- [latency-jitter](latency-jitter.md)
- [relay-failover](relay-failover.md)
- [mtu-edge](mtu-edge.md)

## P6 — Multi-peer topologies (3+ machines)
- [mesh-3peer](mesh-3peer.md)
- [star-topology](star-topology.md)
- [group-churn](group-churn.md)

## Cross-cutting
- [nat-type-matrix](nat-type-matrix.md)
