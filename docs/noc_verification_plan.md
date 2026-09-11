# NoC Verification v1 — Verification Plan

## 1. Objective

Verify a deliberately scoped 2×2 packet-switched NoC implementing deterministic
XY routing, valid/ready flow control, arbitration, multi-hop transport,
backpressure handling, packet integrity, assertions, and functional coverage.

The verification target is an architectural verification exercise and is not
intended to represent full production NoC sign-off.

## 1.1 Architecture Contract

The NoC v1 architecture contract shall be fixed before RTL implementation.

### Topology

The network shall be a 2×2 mesh with the following router coordinates:

    R00 ---- R01
     |        |
     |        |
    R10 ---- R11

Coordinate convention:

- X increases from West to East.
- Y increases from North to South.
- Routing resolves the X coordinate before the Y coordinate.

Each router shall have up to four directional links (North, South, East,
West) plus one locally attached endpoint.

Endpoint-to-router mapping shall be:

    EP0 -> R00
    EP1 -> R01
    EP2 -> R10
    EP3 -> R11

### Packet Format

NoC v1 shall use single-flit packets.

Each packet shall contain, at minimum:

- source endpoint ID
- destination endpoint ID
- transaction ID
- payload

A single accepted valid/ready transfer represents one complete packet
transaction. Multi-flit packets, packet fragmentation, virtual channels,
and wormhole-specific packet state are outside v1.

### Flow Control Contract

All NoC input/output links shall use valid/ready flow control.

A transfer occurs only when:

    valid && ready

When valid is asserted while ready is low, the complete packet/control
information shall remain stable until the transfer occurs or valid is
withdrawn according to the interface protocol.

### Routing Contract

Routing shall use deterministic XY routing.

For a packet at router (X,Y) targeting (DX,DY):

1. If X != DX, route in the X direction.
2. Otherwise, if Y != DY, route in the Y direction.
3. Otherwise, deliver to the local endpoint.

The routing reference model shall implement this rule independently of the
DUT implementation.

### Arbitration Contract

Output contention shall use deterministic round-robin arbitration.

For each output, at most one requester may be granted for a transfer.
The arbitration pointer shall advance according to the declared round-robin
policy after a successful service event.

The v1 bounded arbitration-service limit is four arbitration opportunities,
corresponding to the maximum four eligible input requesters per output
defined by the v1 arbitration scope.

### Ordering Contract

Ordering shall be required only within a single source-to-destination flow.

Packets belonging to the same source/destination flow shall be delivered in
injection order.

No global ordering requirement shall be imposed between independent flows.

### Invalid Destination Contract

A destination ID outside EP0..EP3 shall be treated as an invalid destination.

The DUT shall reject such a packet, shall not deliver it to any endpoint,
and shall expose an explicit error indication through the NoC interface.

Invalid-destination behavior shall be verified explicitly.

### Liveness / Deadlock Scope

v1 shall verify bounded arbitration service rather than claim unrestricted
deadlock freedom.

Under the declared assumptions that the relevant downstream path remains
available and the requesting traffic remains asserted, a continuously
requesting contender shall receive service within the declared arbitration
bound of four arbitration opportunities.

The verification shall also check that deterministic XY routing does not
introduce a cyclic wait condition within the v1 single-flit topology.

No claim of production-level deadlock freedom, fault tolerance, or arbitrary
traffic liveness shall be made.

## 2. Verification Architecture

The verification environment shall contain:

- NoC DUT
- packet transaction model
- packet generator / sequences
- driver
- monitor
- scoreboard
- reference routing model
- functional coverage
- protocol and routing SVA
- directed tests
- constrained-random stress where justified
- regression

Conceptually:

    Test
      |
    Sequence
      |
    Driver
      |
    NoC DUT
      |
    Monitor
      |
    Scoreboard <---- Reference Model
      |
    Coverage / SVA

## 3. Verification Layers

### 3.1 Structural Verification

Verify:

- four-router 2×2 topology
- router-to-router connectivity
- endpoint attachment
- legal interface connectivity

### 3.2 Routing Verification

Verify:

- local delivery
- one-hop routing
- horizontal routing
- vertical routing
- multi-hop routing
- all required source/destination combinations
- deterministic XY routing

### 3.3 Arbitration Verification

Verify:

- simultaneous requests for the same output
- legal arbitration decision
- absence of illegal simultaneous grants
- eventual service within the declared arbitration scope

### 3.4 Flow-Control Verification

Verify:

- valid/ready handshake
- downstream backpressure
- packet/flit stability while stalled
- no transfer when ready is low
- recovery after backpressure removal

### 3.5 Integrity Verification

The scoreboard shall verify:

- source
- destination
- payload
- transaction identity
- delivery
- no duplication
- no loss
- ordering within declared scope

### 3.6 Error Verification

Verify the defined behavior for:

- invalid destination
- unreachable destination
- malformed packet fields, if such fields are part of the final interface

## 4. Directed Scenarios

Minimum directed scenarios shall include:

1. Local endpoint delivery.
2. One-hop horizontal routing.
3. One-hop vertical routing.
4. Multi-hop horizontal/vertical routing.
5. Multi-hop source-to-destination corner cases.
6. Two sources contending for one output.
7. Backpressure at the destination.
8. Backpressure at an intermediate router.
9. Traffic recovery after backpressure.
10. Invalid/unreachable destination.
11. Packet integrity checks.
12. Multiple sequential packets.

## 5. Functional Coverage

Coverage shall include, at minimum:

- source endpoint
- destination endpoint
- routing direction
- hop count
- local vs remote delivery
- contention occurrence
- arbitration outcome
- backpressure occurrence
- packet delivery outcome
- invalid destination

Cross coverage shall be added only where it provides meaningful
verification value.

Coverage percentages shall not be treated as a substitute for scenario
closure.

## 6. Assertions

The SVA layer shall target:

- valid/ready protocol correctness
- payload stability while stalled
- legal routing decision
- mutually exclusive output grants
- no illegal simultaneous transfer
- packet/control stability
- required arbitration invariants

Assertions shall be bound to the DUT where practical.

## 7. Scoreboard / Reference Model

The reference model shall independently calculate the expected XY route.

For every injected packet it shall determine:

    source
      ↓
    expected destination
      ↓
    expected router path
      ↓
    expected delivery

The scoreboard shall compare observed delivery against the expected
transaction and detect:

- wrong destination
- wrong payload
- wrong route
- loss
- duplication
- ordering violation

## 8. Regression Strategy

Regression shall contain:

- directed routing tests
- arbitration tests
- backpressure tests
- integrity tests
- invalid-destination tests
- constrained-random traffic tests where justified

Failures shall be debugged to root cause before closure.

## 9. Coverage Closure

Functional coverage shall be closed against the declared v1 coverage model.

Code coverage shall be reported separately.

Unreachable or intentionally excluded coverage shall be documented rather
than artificially stimulated or waived without justification.

## 10. Verification Sign-off

NoC v1 sign-off requires:

- all mandatory tests PASS
- all mandatory assertions PASS
- zero scoreboard mismatches
- required functional coverage closed
- documented exclusions/waivers
- clean regression
- requirements-to-evidence mapping

The final sign-off shall explicitly state the limitations of the v1 scope.
