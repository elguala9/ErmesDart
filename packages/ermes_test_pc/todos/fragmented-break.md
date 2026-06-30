# TODO — fragmented-break

**Scenario**: `NAT_SCENARIO=fragmented-break`
**Status**: [x] implemented (engine in ermes_test_shared, NAT_SCENARIO dispatch wired)

## Goal
Send a multi-MB payload (forces chunking in `ErmesService`), break the link
while chunks are in flight, then restore. The message must reassemble correctly
after resume.

## Core path
- `ErmesService` chunking (`chunk_handler.dart`) + `ErmesReadRepo` reassembly.
- Retransmission of the chunks lost during the break.

## Setup
Two PCs. Payload size chosen to span many chunks (e.g. several MB).

## Steps
1. Establish the connection.
2. Start sending the large payload.
3. Break the link partway through the chunk stream.
4. Restore; let retransmission complete the transfer.

## Asserts (strict)
- Reassembled payload byte-for-byte equals the source (checksum match).
- All chunks accounted for; no duplicate or missing chunk index.

## Metric line
`fragmented-break payloadBytes=<n> chunks=<n> retransmittedChunks=<n> checksumOk=true`
