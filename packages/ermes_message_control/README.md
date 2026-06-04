# ermes_message_control

Tracking and retransmission control for Ermes messages.

## Purpose

Detects gaps in received-message ID sequences and asks the remote peer to resend the missing ones. Used by `ErmesService` to implement reliable delivery on top of an unreliable transport (e.g. SHSP).

## Public surface

- **`ErmesMessageControlService`** — implements `IErmesMessageControlService` from `iermes`. Tracks `idArrived` events, exposes `getLastReceivedId()` and `getMissingIds()`.
- **`ErmesMessageControlRepository`** — in-memory store of arrived/missing IDs.
- **Factories** — `ErmesMessageControlServiceFactory`, `ErmesMessageControlRepositoryFactory` plus their `Input` classes.

## Integration

`ErmesService` can be constructed with a message-control service plus an optional periodic timer (`missingMessagesCheckIntervalMs`) and reactive threshold (`missingMessagesThreshold`). When triggered, the service emits a `ServiceMessageArrayRequest` to the peer.

## Exceptions

Errors raised by this package use `MessageControlException`, which extends `ErmesException` from `iermes`.

## Testing

Tests live in `packages/ermes_test/test/src/types/message_control_interface_test.dart` and in the aggregated suite.
