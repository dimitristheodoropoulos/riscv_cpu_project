# Cache Verification Requirements

## Scope

The verification target is a 32-bit, direct-mapped, single-word-per-line
cache with 16 cache lines.

## Requirements

| ID | Requirement |
|---|---|
| CACHE-REQ-001 | Reset shall invalidate all cache lines. |
| CACHE-REQ-002 | Address shall be decoded as TAG [31:6], INDEX [5:2], BYTE OFFSET [1:0]. |
| CACHE-REQ-003 | A valid matching tag shall produce a read hit. |
| CACHE-REQ-004 | A read miss shall cause a backing-memory refill before response. |
| CACHE-REQ-005 | A different tag mapping to the same index shall replace the existing line. |
| CACHE-REQ-006 | A write hit shall update both cache and backing memory. |
| CACHE-REQ-007 | A write miss shall update backing memory without cache allocation. |
| CACHE-REQ-008 | WSTRB shall update only the selected bytes. |
| CACHE-REQ-009 | Response data shall remain stable while RSP_VALID=1 and RSP_READY=0. |
| CACHE-REQ-010 | A read hit shall not generate a backing-memory read. |
| CACHE-REQ-011 | Only one CPU request may be outstanding at a time. |
| CACHE-REQ-012 | Cache-to-memory transactions shall follow the defined valid/ready protocol. |
| CACHE-REQ-013 | All cache requests shall be 32-bit word-aligned (`req_addr[1:0] == 2'b00`). |

## Out of Scope

- Burst transactions
- Multiple outstanding requests
- Cache coherence
- Multi-level caches
- Virtual memory / MMU integration
- Speculative execution
- Write-back / dirty eviction
- AXI protocol

## Interface and Timing Contract

### CPU-side Interface

All CPU cache requests shall be 32-bit word-aligned. Therefore,
`req_addr[1:0]` shall be `2'b00`; the byte-offset field is reserved for
address decomposition and shall not select a different word within a cache line.

The cache shall provide:

- `req_valid`
- `req_ready`
- `req_write`
- `req_addr`
- `req_wdata`
- `req_wstrb`
- `rsp_valid`
- `rsp_ready`
- `rsp_rdata`

A CPU request shall be accepted on a rising clock edge only when
`req_valid && req_ready` are both asserted.

A response shall be transferred on a rising clock edge only when
`rsp_valid && rsp_ready` are both asserted.

While `rsp_valid=1` and `rsp_ready=0`, the response payload shall remain stable.

### Backing-memory Interface

The cache shall provide:

- `mem_valid`
- `mem_ready`
- `mem_write`
- `mem_addr`
- `mem_wdata`
- `mem_wstrb`
- `mem_rdata`

A memory transaction shall be accepted on a rising clock edge only when
`mem_valid && mem_ready` are both asserted.

### Read Miss Sequence

A read miss shall follow this sequence:

1. Accept the CPU request.
2. Detect the cache miss.
3. Issue one read transaction to backing memory.
4. Accept the memory response.
5. Refill the selected cache line.
6. Generate the CPU response.
7. Complete the response when `rsp_valid && rsp_ready` are asserted.

### Write Sequence

A write shall follow the defined write-through, no-write-allocate policy.

For a write hit:

1. Accept the CPU request.
2. Update the selected cache line according to `req_wstrb`.
3. Issue the corresponding backing-memory write.
4. Complete the CPU transaction.

For a write miss:

1. Accept the CPU request.
2. Issue a backing-memory write according to `req_wstrb`.
3. Do not allocate a cache line.
4. Complete the CPU transaction.

### Clocking

All request, response, cache-state, and backing-memory transaction state
changes shall occur synchronously on the rising edge of `clk`.

### Reset

The cache shall use an active-high synchronous reset signal named `rst`.

When `rst=1` at a rising edge of `clk`, all cache lines shall be invalidated.

When `rst=0`, the cache shall operate normally.

No valid cache entry shall remain after a reset cycle.

## Current Verification Evidence

The current `cache_v2` directed verification run completed with 48 executable pass records and 0 failures, including 34 `check()` assertions and 14 executable `CACHE-REQ-013` alignment checks.

The directed evidence covers:

- read miss and backing-memory refill
- read-hit behavior without an additional backing-memory read
- same-index / different-tag replacement
- write hit and write-through update
- write miss with no-write-allocate behavior
- WSTRB byte selection
- CPU response backpressure and payload stability
- single-outstanding-request behavior
- backing-memory valid/ready backpressure
- accepted-request word-alignment contract (`CACHE-REQ-013`)

CACHE-REQ-007 is supported by a write-miss followed by a read that requires a new backing-memory read, providing direct evidence of no cache allocation.

CACHE-REQ-012 is supported by directed backpressure testing showing that `mem_valid` remains asserted while `mem_ready=0`, no memory transaction completes during the stall, and the transaction completes correctly after `mem_ready` is asserted.

This evidence represents directed verification only. It does not constitute full verification closure for the verification strategy defined in the cache verification plan.