# TODO — fragmented-break

**Scenario**: `NAT_SCENARIO=fragmented-break`
**CI fit**: ✅ break produced on the LOCAL peer mid-chunk-stream
**Status**: [x] implemented (engine in ermes_test_shared, NAT_SCENARIO dispatch wired)

## Goal
Send a multi-MB payload (forces chunking), break the link while chunks are in
flight, then restore. The message must reassemble correctly after resume.

## Core path
- `ErmesService` chunking (`chunk_handler.dart`) + `ErmesReadRepo` reassembly.
- Retransmission of the chunks lost during the break.

## Actions wiring
- `side=b-only` (receiver on the runner), sender local.
- The local sender starts the large payload, then drops the outbound UDP path
  partway through the chunk stream, then restores it.
- `NAT_SCENARIO=fragmented-break`; payload size chosen to span many chunks.

## Asserts (strict)
- Reassembled payload byte-for-byte equals the source (checksum match).
- All chunks accounted for; no duplicate or missing chunk index.

## Metric line
`fragmented-break payloadBytes=<n> chunks=<n> retransmittedChunks=<n> checksumOk=true`

## Runner caveats
- Several MB over a public relay path is fine; keep within the job timeout.
