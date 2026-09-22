# Memory Controller v1 — Interface / Requirements Contract

## 1. Scope

Memory Controller v1 is a small synchronous memory-controller artifact intended to sit behind the existing `cache_v2` backing-memory interface.

The controller provides a single-word memory transaction interface with:

* read transactions
* write transactions
* byte write enables (`WSTRB`)
* `valid/ready` request handshake
* single outstanding transaction
* deterministic request completion
* valid/ready request protocol with reset-time backpressure
* reset

The controller is intentionally limited to a simple SRAM-like backing-memory model.

### Out of Scope

Memory Controller v1 does **not** implement:

* AXI/AHB protocol conversion
* bursts
* multiple outstanding transactions
* transaction IDs
* DDR/LPDDR interfaces
* PHY/training
* refresh
* DFI
* ECC
* cache functionality
* address translation
* arbitration between multiple requesters
* speculative accesses
* reordering
* asynchronous clock-domain crossing

---

## 2. Intended Integration

The intended topology is:

```text
                  CPU
                   |
                   v
              +---------+
              | Cache V2|
              +---------+
                   |
                   | backing-memory interface
                   v
          +-------------------+
          | Memory Controller |
          +-------------------+
                   |
                   v
              SRAM / Memory
                 model
```

The controller must preserve the existing Cache V2 backing-memory transaction semantics.

No modification to `rtl/cache_v2.sv` is required for v1.

---

## 3. Controller Interface

Suggested RTL module:

```systemverilog
module memory_controller (
    input  logic        clk,
    input  logic        rst,

    // Request interface from Cache V2
    input  logic        mem_valid,
    output logic        mem_ready,
    input  logic        mem_write,
    input  logic [31:0] mem_addr,
    input  logic [31:0] mem_wdata,
    input  logic [3:0]  mem_wstrb,

    // Read data returned to Cache V2
    output logic [31:0] mem_rdata
);
```

The interface deliberately matches the existing Cache V2 memory-side contract.

---

## 4. Request Handshake

A memory request is accepted and completed on the active clock edge when:

```text
mem_valid && mem_ready
```

is true.

For v1, the request handshake is also the transaction-completion event. There is no separate memory response-valid phase.

If `mem_valid=1` and `mem_ready=0`, the request has **not** been accepted
and the transaction has not completed. In v1, `mem_ready=0` occurs only
while reset is asserted; v1 does not implement an internal stalled or busy
transaction state.

---

## 5. Single Outstanding Transaction

### MC-REQ-001 — Single outstanding request

The controller shall support at most one accepted memory request per clock cycle.

For v1, request acceptance and transaction completion occur on the same active clock edge when:

```text
mem_valid && mem_ready
```

is true.

Therefore v1 does not contain a multi-cycle outstanding transaction state after an accepted request. A successfully accepted request is immediately considered complete from the interface protocol perspective.

The controller shall not accept more than one request on the same clock edge.

During reset, a request remains unaccepted because `mem_ready=0`.

---

## 6. Request Stability

### MC-REQ-002 — Stable request under protocol backpressure

When:

```text
mem_valid = 1
mem_ready  = 0
```

the controller shall not accept the request.

The v1 controller does not generate internal backpressure after reset:
`mem_ready` is low during reset and remains asserted after reset release.
Therefore this requirement defines the valid/ready protocol contract for
the requester; v1 does not provide a stalled transaction state for the
verification environment to exercise.

The requester is responsible for maintaining:

* `mem_valid`
* `mem_write`
* `mem_addr`
* `mem_wdata`
* `mem_wstrb`

until the handshake occurs.

The controller shall use only the request values present at the accepted handshake.

---

## 7. Read Transactions

### MC-REQ-003 — Read request

A request with:

```text
mem_write = 0
```

shall perform a memory read.

On transaction completion, `mem_rdata` shall contain the 32-bit word stored at the requested word address.

For a read transaction:

```text
mem_valid && mem_ready && !mem_write
```

identifies an accepted read request.

---

## 8. Write Transactions

### MC-REQ-004 — Write request

A request with:

```text
mem_write = 1
```

shall perform a memory write.

The controller shall use:

* `mem_addr`
* `mem_wdata`
* `mem_wstrb`

from the accepted request.

---

## 9. WSTRB Semantics

### MC-REQ-005 — Byte-enable semantics

`mem_wstrb[3:0]` selects which bytes of the destination 32-bit word are updated.

Mapping:

```text
mem_wstrb[0] -> bits [7:0]
mem_wstrb[1] -> bits [15:8]
mem_wstrb[2] -> bits [23:16]
mem_wstrb[3] -> bits [31:24]
```

For each byte:

```text
WSTRB = 1
    -> destination byte is updated

WSTRB = 0
    -> destination byte remains unchanged
```

### MC-REQ-006 — Partial-write preservation

A write with a partial `WSTRB` shall not modify bytes whose corresponding strobe bit is zero.

For example:

```text
old = AAAABBBB
data = 11223344
WSTRB = 0101
```

shall update only bytes 0 and 2.

The resulting value shall be:

```text
AA22BB44
```

assuming the conventional little-endian byte mapping defined above.

---

## 10. Addressing

### MC-REQ-007 — Word-addressed storage

The controller shall provide 32-bit word accesses.

The memory model shall be addressed using the word-aligned portion of `mem_addr`.

For v1:

```text
mem_addr[1:0] = 2'b00
```

is the supported access alignment.

The controller shall not implement byte, half-word, burst, or unaligned transaction semantics.

### MC-REQ-008 — Alignment contract

The Cache V2 interface provides word-aligned requests to the backing-memory interface.

For v1, only requests satisfying:

```text
mem_addr[1:0] = 2'b00
```

are within the supported interface contract.

The controller shall not implement unaligned-access handling, byte-address conversion, or an alignment-error response.

Unaligned requests are therefore outside the v1 supported protocol contract and are not required to be detected or rejected by the controller.

---

## 11. Read Data Semantics

### MC-REQ-009 — Read-data validity

For an accepted read transaction:

```text
mem_valid && mem_ready && !mem_write
```

`mem_rdata` shall represent the requested memory word on the same active clock edge.

Because v1 has no separate memory response-valid signal, the request handshake is also the read-data completion event.

The controller shall not return data from a previous unrelated request.

### MC-REQ-010 — Write response data

The existing Cache V2 protocol has no separate response channel for the backing memory.

Therefore v1 shall not introduce a separate write-response signal.

A write transaction is considered complete on the same active clock edge on which:

```text
mem_valid && mem_ready && mem_write
```

is true.

---

## 12. Backpressure and Ready Behavior

### MC-REQ-011 — v1 ready behavior

The v1 controller shall not generate internal request backpressure.

During reset:

```text
mem_ready = 0
```

After reset is released:

```text
mem_ready = 1
```

The controller therefore has no multi-cycle stalled or busy transaction
state in v1.

### MC-REQ-012 — No premature completion

A request shall not be considered accepted unless:

```text
mem_valid && mem_ready
```

is true.

---

## 13. Reset

### MC-REQ-013 — Reset behavior

`rst` shall be active high, matching the existing Cache V2 reset convention.

During reset the controller shall:

* prevent request acceptance
* present `mem_ready=0`
* not modify memory contents unless explicitly required by the memory model

Request acceptance remains synchronous: a transaction is accepted only on the active clock edge when `mem_valid && mem_ready` is true.

After reset is released, `mem_ready` shall become asserted and the controller shall be ready to accept a request.

---

## 14. Determinism

### MC-REQ-014 — Deterministic transaction behavior

For identical initial memory contents and identical accepted request sequences, the controller shall produce identical memory updates and read data.

There shall be no unspecified transaction ordering in v1 because only one transaction may be outstanding.

---

## 15. Minimum Verification Requirements

The v1 controller shall be verified at minimum for:

1. reset to idle
2. single read
3. single write
4. read-after-write
5. full-word write
6. partial `WSTRB` write
7. preservation of disabled bytes
8. reset-time request blocking
9. correct read data
10. no premature transaction completion
11. aligned access behavior
12. repeated independent transactions

The verification environment should use a reference memory/scoreboard rather than relying only on direct signal checks.

---

## 16. Assertion Targets

The following properties define the minimum assertion targets for v1.
They describe the protocol and data-integrity properties that are applicable
to the implemented controller. Standalone SVA execution is not required to
claim the directed v1 verification evidence.

### MC-SVA-001 — Acceptance requires valid and ready

A request is accepted only when:

```text
mem_valid && mem_ready
```

### MC-SVA-002 — Single-cycle transaction semantics

For v1, an accepted transaction occurs only on an active clock edge when:

```text
mem_valid && mem_ready
```

is true. Acceptance and completion occur on that same edge.

### MC-SVA-003 — Reset-time ready behavior

During reset:

```text
mem_ready = 0
```

After reset release:

```text
mem_ready = 1
```

No internal multi-cycle stalled transaction state exists in v1.

### MC-SVA-004 — WSTRB byte preservation

For a write transaction, bytes corresponding to `WSTRB=0` must remain unchanged.

### MC-SVA-005 — Reset leaves no outstanding transaction

Because v1 has no multi-cycle outstanding transaction state, reset shall
not permit a request to be accepted while `rst` is asserted.

---

## 17. Functional Coverage Targets

The minimum functional coverage model should include:

### Access type

```text
READ
WRITE
```

### Write strobes

At minimum:

```text
0000
0001
0010
0100
1000
1111
```

plus representative multi-byte combinations.

### Ready behavior

```text
reset:     mem_ready = 0
post-reset: mem_ready = 1
```

### Address classes

At minimum:

```text
lowest supported word
representative middle address
highest supported word
```

### Transaction sequences

```text
READ
WRITE
WRITE -> READ
READ -> READ
WRITE -> WRITE
```

Coverage closure is not claimed merely by executing these cases; all defined coverage goals must be reviewed against the implemented scope.

---

## 18. v1 Completion Criteria

Memory Controller v1 shall be considered complete only when:

* RTL compiles cleanly enough for the selected simulator
* directed tests pass with zero failures
* read/write behavior matches the reference model
* WSTRB behavior is verified
* reset-time request blocking and post-reset ready behavior are verified
* single-cycle request acceptance behavior is verified
* applicable protocol requirements are verified
* no unintended multiple acceptance is observed on a single clock edge
* `git diff --check` is clean
* evidence is documented without claiming unsupported features

The artifact shall **not** be described as a DDR controller, AMBA memory controller, or full SoC memory subsystem.

---

## 19. Explicit v1 Boundary

The central design rule for v1 is:

> **Implement only the smallest controller that gives the existing Cache V2 backing-memory interface a real, independently verifiable memory-controller boundary.**

No Cache V2 redesign is required.

No DDR/PHY complexity is required.

No additional protocol is introduced unless a concrete limitation is discovered during implementation or verification.
