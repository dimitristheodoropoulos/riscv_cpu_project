# Cache Verification Plan

## Verification Strategy

The cache shall be verified using:

1. Directed tests
2. Constrained-random stimulus
3. Reference-model / scoreboard checking
4. SystemVerilog Assertions (SVA)
5. Functional coverage
6. Coverage closure
7. RTL synthesis / structural sanity checks

## Functional Areas

- Reset and invalidation
- Address decoding
- Read hit
- Read miss and refill
- Same-index tag replacement
- Write hit
- Write miss
- Byte-enable / WSTRB behavior
- Response backpressure
- Single-outstanding-request behavior
- Backing-memory protocol
- CPU request word-alignment contract

## Coverage

Coverage shall include:

- Read / write
- Hit / miss
- Read-hit / read-miss / write-hit / write-miss
- All cache indices
- WSTRB patterns
- Same-index / different-tag replacement
- Response backpressure
- Accepted CPU request word alignment (`CACHE-REQ-013`)

Meaningful crosses shall include access type × hit/miss × cache index.

## Assertions

SVA shall cover:

- Reset invalidation
- Response stability under backpressure
- Hit/tag consistency
- No backing-memory read on read hit
- Required refill behavior on read miss
- Valid/ready protocol rules
- Single outstanding request constraint

## Completion Criteria

The checkpoint is complete only when:

- All defined directed scenarios pass
- Constrained-random tests pass
- Scoreboard reports zero mismatches
- Required assertions pass
- Defined functional coverage targets are closed
- RTL passes synthesis/structural sanity checks

## Current Verification Status

The current `cache_v2` evidence consists of directed verification only.

The latest directed test completed with 48 executable pass records and 0 failures, including 34 `check()` assertions and 14 executable `CACHE-REQ-013` alignment checks.

The demonstrated directed evidence covers the functional areas listed above, including backing-memory valid/ready backpressure and the accepted CPU request word-alignment contract defined by `CACHE-REQ-013`.

Constrained-random stimulus, reference-model / scoreboard checking, SVA, functional coverage closure, and RTL synthesis / structural sanity checks are verification-plan activities and are not claimed as completed by this directed checkpoint.

Therefore, this result shall not be interpreted as full verification closure.