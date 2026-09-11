# NoC Verification v1 — Requirements

## Scope

This document defines the verification requirements for a deliberately scoped
2×2 packet-switched NoC verification target.

The objective is to verify routing, packet delivery, arbitration, backpressure,
packet integrity, assertions, and functional coverage within the declared v1 scope.

This is not a full production NoC sign-off.

## Architecture Scope

- 2×2 mesh topology
- 4 routers
- 4 logical endpoints
- Deterministic XY routing
- Packet/flit-based transport
- Valid/ready flow control
- Scoped arbitration
- Multi-hop routing
- Directed and constrained-random verification

## Architecture Contract

The following architectural contracts are fixed for NoC v1 and shall be used
consistently by the RTL, reference model, scoreboard, assertions, tests, and
functional coverage.

### Topology and Addressing

The topology is:

    R00 ---- R01
     |        |
     |        |
    R10 ---- R11

Coordinate convention:

- X increases from West to East.
- Y increases from North to South.
- Routing resolves the X coordinate before the Y coordinate.

Endpoint mapping:

    EP0 -> R00
    EP1 -> R01
    EP2 -> R10
    EP3 -> R11

### Packet Model

NoC v1 uses single-flit packets containing:

- source endpoint ID (3 bits)
- destination endpoint ID (3 bits)
- transaction ID (4 bits)
- payload (32 bits)

Endpoint ID encoding is:

    3'b000 -> EP0
    3'b001 -> EP1
    3'b010 -> EP2
    3'b011 -> EP3
    3'b100-3'b111 -> invalid

The logical packet width is 42 bits.

Each accepted valid/ready transfer represents one complete packet.

### Flow Control

A packet/flit transfer occurs only on:

    valid && ready

When valid is high and ready is low, packet/control information shall remain
stable until transfer or legal withdrawal according to the interface contract.

### Routing

Routing is deterministic XY:

1. Route in X until the destination X coordinate is reached.
2. Route in Y until the destination Y coordinate is reached.
3. Deliver locally when both coordinates match.

### Arbitration

Output contention uses deterministic round-robin arbitration.

At most one requester may be granted to a given output for a transfer.

The v1 bounded arbitration-service limit is four arbitration opportunities,
corresponding to the maximum four eligible input requesters per output
defined by the v1 arbitration scope.

### Ordering

Ordering is required only within a source/destination flow.

Packets from the same source to the same destination shall be delivered in
injection order. No global ordering requirement is imposed between independent
flows.

### Invalid Destination

Destination IDs encoded as 3'b100 through 3'b111 are invalid.

Invalid destinations shall be rejected, shall not be delivered to any
endpoint, and shall produce an explicit error indication through the NoC
interface.

### Liveness / Deadlock Scope

v1 verifies bounded arbitration service under declared assumptions rather than
claiming unrestricted deadlock freedom.

A continuously requesting contender with an available downstream path shall
receive service within four arbitration opportunities.

The verification shall also check that deterministic XY routing does not create
a cyclic wait condition within the v1 single-flit topology.

No production-level deadlock-freedom or arbitrary-traffic liveness claim is made.

## Out of Scope

- Virtual channels
- Adaptive routing
- QoS
- Fault-tolerant routing
- Cache coherence
- AXI-to-NoC bridge
- Production deadlock-avoidance architecture
- Full NoC performance characterization
- Full silicon sign-off

## Requirements

| ID | Requirement | Verification Method | Status |
|---|---|---|---|
| NOC-REQ-001 | 2×2 mesh topology shall contain four routers with defined connectivity. | Structural / Integration | PENDING |
| NOC-REQ-002 | Endpoints shall have deterministic source and destination addressing. | Directed / Scoreboard | PENDING |
| NOC-REQ-003 | The NoC shall implement deterministic XY routing within the declared topology. | Directed / Reference Model | PENDING |
| NOC-REQ-004 | Packet/flit transfer shall use a defined valid/ready handshake. | Directed / SVA | PENDING |
| NOC-REQ-005 | Packets addressed to a locally attached endpoint shall be delivered correctly. | Directed / Scoreboard | PENDING |
| NOC-REQ-006 | One-hop packets shall be routed to the correct output. | Directed / Scoreboard | PENDING |
| NOC-REQ-007 | Multi-hop packets shall traverse the correct router sequence. | Directed / Scoreboard | PENDING |
| NOC-REQ-008 | Contending traffic shall be arbitrated according to the declared arbitration policy. | Directed / Constrained-Random | PENDING |
| NOC-REQ-009 | Backpressure shall prevent illegal packet/flit transfer when the downstream interface is not ready. | Stress / SVA | PENDING |
| NOC-REQ-010 | Packet source, destination, payload, and transaction identity shall be preserved through routing. | Scoreboard | PENDING |
| NOC-REQ-011 | Legal traffic shall not result in packet duplication or packet loss. | Scoreboard / Stress | PENDING |
| NOC-REQ-012 | Ordering shall be preserved within the declared v1 traffic scope. | Scoreboard | PENDING |
| NOC-REQ-013 | Invalid or unreachable destinations shall produce the defined error behavior. | Directed | PENDING |
| NOC-REQ-014 | Mandatory routing, handshake, arbitration, and stability properties shall be asserted. | SVA | PENDING |
| NOC-REQ-015 | Functional coverage shall cover routing, destinations, contention, and backpressure scenarios. | Functional Coverage | PENDING |
| NOC-REQ-016 | The complete NoC v1 verification regression shall pass without mandatory failures. | Regression | PENDING |
| NOC-REQ-017 | Under the declared arbitration assumptions, a continuously requesting contender shall receive service within four arbitration opportunities, and v1 shall not create a cyclic wait condition under deterministic XY routing. | Directed / Constrained-Random / SVA | PENDING |

## Closure Criteria

NoC v1 shall be considered verified only when:

1. All mandatory directed scenarios pass.
2. All mandatory SVA properties pass.
3. The scoreboard reports zero mismatches.
4. Required routing scenarios are covered.
5. Required contention scenarios are covered.
6. Required backpressure scenarios are covered.
7. Invalid-destination behavior is verified.
8. Regression completes without mandatory failures.
9. Bounded arbitration-service and v1 deadlock/liveness checks pass.
10. Any code-coverage limitations or waivers are explicitly documented.
11. No claims beyond the declared v1 scope are made.

## Evidence Policy

A requirement shall not be marked VERIFIED without concrete simulation,
assertion, coverage, or structural evidence supporting the requirement.
