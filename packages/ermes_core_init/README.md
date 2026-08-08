# ermes_core_init

Dependency-injection entry points for the Ermes stack.

## Purpose

Wires the concrete implementations (`ermes_core`, `ermes_signaling`, `ermes_storage`, etc.) onto the interfaces in `iermes` so consumers can ask for an orchestrator (`IOrcErmes`) without building the dependency graph by hand.

## Public surface

- **`initializeErmes(...)`** — single composition-root function: registers the whole stack (storage, cipher, id-handler, message-control, signaling, core) under one keyed `RegistryManager` entry and returns the resulting `IOrcErmes`. Pass a distinct `key` per peer to run several stacks side by side in one process.
- **`getIOrcErmes({key})`** — resolves the orchestrator already registered under `key`.
- **`ErmesInjector`** — the class `initializeErmes` delegates to; use it directly only if you need to call `register()` without immediately resolving the orchestrator.

`initializeErmes` is responsible for:
- Registering the storage, cipher, id-handler and message-control graphs (the latter two only when `registerIdHandler` / `registerMessageControl` are set).
- Binding the STUN/SHSP sockets and pointing the `ipv4` handler at a custom server when `initializeStunShsp: true` and `stunHost` are supplied.
- Constructing the signaling server/handler chain and, when `connectSignaling: true`, opening the relay WebSockets.
- Constructing the `OrcErmes` orchestrator itself.

## Testing

Tests live in `packages/ermes_test/test/src/concrete_implementations/injection/`.
