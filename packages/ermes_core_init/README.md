# ermes_core_init

Dependency-injection entry points for the Ermes stack.

## Purpose

Wires the concrete implementations (`ermes_core`, `ermes_signaling`, `ermes_storage`, etc.) onto the interfaces in `iermes` so consumers can ask for an orchestrator (`IOrcErmes`) without building the dependency graph by hand.

## Public surface

- **`initialPointErmes(...)`** — singleton entry point: returns the process-wide `IOrcErmes`.
- **`initialPointErmesRegistry(...)`** — keyed registry variant: independent `IOrcErmes` instances per key (useful for tests or multi-tenant scenarios).

Both entry points are responsible for:
- Initialising the STUN/SHSP socket singleton.
- Registering the storage, id-handler and message-control services in the DI container.
- Constructing the signaling server/handler chain.

## Testing

Tests live in `packages/ermes_test/test/src/initial_point/`.
