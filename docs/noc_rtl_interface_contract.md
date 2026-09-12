# NoC v1 RTL Interface Contract

## 1. Purpose

This document freezes the RTL-visible interface contract for the NoC v1
verification scope.

It is derived from:

- `docs/noc_verification_plan.md`
- `docs/noc_verification_requirements.md`

This document defines the interface, packet format, routing-visible
parameters, flow-control semantics, reset behavior, invalid-destination
behavior, and arbitration-visible contract required before RTL implementation.

This is a verification-oriented v1 contract. It does not claim production
NoC completeness, fault tolerance, virtual channels, wormhole routing,
multi-flit packets, or unrestricted deadlock freedom.

---

## 2. Frozen Topology

The NoC is a 2x2 mesh:

```text
R00 ---- R01
 |        |
 |        |
R10 ---- R11

```

Coordinates:

* **X increases:** West -> East
* **Y increases:** North -> South

Router mapping:

| Router | Coordinates (X,Y) | Endpoint |
| --- | --- | --- |
| R00 | (0,0) | EP0 |
| R01 | (1,0) | EP1 |
| R10 | (0,1) | EP2 |
| R11 | (1,1) | EP3 |

The router coordinate is a static implementation parameter.

---

## 3. Packet Format

NoC v1 uses a single-flit packet.

SystemVerilog representation:

```sv
typedef struct packed {
    logic [2:0]  src_id;
    logic [2:0]  dst_id;
    logic [3:0]  txn_id;
    logic [31:0] payload;
} noc_packet_t;

```

Field widths:

| Field | Width |
| --- | --- |
| `src_id` | 3 bits |
| `dst_id` | 3 bits |
| `txn_id` | 4 bits |
| `payload` | 32 bits |
| **Total** | **42 bits** |

Endpoint encoding:

* `3'b000` -> EP0
* `3'b001` -> EP1
* `3'b010` -> EP2
* `3'b011` -> EP3
* `3'b100` -> invalid
* `3'b101` -> invalid
* `3'b110` -> invalid
* `3'b111` -> invalid

The packet is transferred as one complete unit. NoC v1 does not support
multi-flit packets, packet fragmentation, virtual channels, or wormhole state.

---

## 4. Direction Encoding

The RTL shall use the following logical directions:

```sv
typedef enum logic [2:0] {
    DIR_LOCAL = 3'b000,
    DIR_NORTH = 3'b001,
    DIR_SOUTH = 3'b010,
    DIR_EAST  = 3'b011,
    DIR_WEST  = 3'b100
} noc_dir_t;

```

Physical/logical orientation:

```text
        NORTH
          ^
          |
WEST <--- ROUTER ---> EAST
          |
          v
        SOUTH

```

`DIR_LOCAL` represents the endpoint attached to the router.

---

## 5. Port Naming

Each router direction uses the following interface convention:

```text
<direction>_in_valid
<direction>_in_ready
<direction>_in_packet

<direction>_out_valid
<direction>_out_ready
<direction>_out_packet

```

where `<direction>` is one of:

* `north`
* `south`
* `east`
* `west`
* `local`

Therefore a router exposes five logical input/output directions:

* `north`
* `south`
* `east`
* `west`
* `local`

Each direction uses the same valid/ready transfer semantics.

Invalid-destination reporting uses explicit per-input error ports:

```text
north_error_valid
north_error_dst_id

south_error_valid
south_error_dst_id

east_error_valid
east_error_dst_id

west_error_valid
west_error_dst_id

local_error_valid
local_error_dst_id
```

For each direction:

* `<direction>_error_valid` is a 1-bit error indication associated
  exclusively with `<direction>_in_*`;

* `<direction>_error_dst_id` is a 3-bit destination ID associated exclusively
  with the corresponding `<direction>_error_valid`.

The error signal naming and direction mapping are part of the frozen RTL
interface contract.

---

## 6. Valid/Ready Transfer Contract

A packet transfer occurs exactly when:

$$\text{transfer} = \text{valid} \land \text{ready}$$

For an input interface:

$$\text{in\_transfer} = \text{in\_valid} \land \text{in\_ready}$$

For an output interface:

$$\text{out\_transfer} = \text{out\_valid} \land \text{out\_ready}$$

The receiving side shall not consider a packet accepted unless both
`valid` and `ready` are asserted in the same cycle.

When `valid=1` and `ready=0`, the producer shall keep `valid=1` and hold
the packet contents stable until the transfer occurs.

A producer shall not withdraw a valid packet solely because `ready=0`.

For a stalled NoC output:

* `out_valid = 1`
* `out_ready = 0`

the following packet fields shall remain stable:

* `src_id`
* `dst_id`
* `txn_id`
* `payload`

No packet may be silently dropped because `ready=0`.

---

## 7. Routing Contract

Routing is deterministic XY routing.

For a packet currently at router coordinate $(X,Y)$ with destination
coordinate $(DX,DY)$:

```text
if DX > X:
    EAST
else if DX < X:
    WEST
else if DY > Y:
    SOUTH
else if DY < Y:
    NORTH
else:
    LOCAL

```

X direction has priority over Y direction.

The routing decision is stateless for a single-flit packet and is recomputed
from the current router coordinate and destination endpoint.

The routing function shall be identical between RTL intent and the independent
verification reference model.

---

## 8. Local Delivery

When the destination coordinate equals the current router coordinate:

* $DX == X$
* $DY == Y$

the routing decision is: `LOCAL`.

The packet shall not be forwarded to another directional output.
Local delivery uses the same valid/ready transfer semantics.

---

## 9. Arbitration Contract

Each output has deterministic round-robin arbitration.

The arbiter shall:

1. Consider only eligible input requesters for the selected output;
2. Select at most one requester per output for a transfer;
3. Preserve the selected packet's identity;
4. Advance the arbitration pointer only after a successful service event;
5. Not advance the pointer merely because a request exists.

### 9.1 Eligible Requesters

The physical router has five input directions:

* `NORTH`
* `SOUTH`
* `EAST`
* `WEST`
* `LOCAL`

However, for any particular output, deterministic XY routing restricts the
number of eligible requesters.

The v1 arbitration bound is: **maximum 4 eligible input requesters per output**.

This four-requester bound is the scope used by NOC-REQ-008 and NOC-REQ-017.
The implementation shall not interpret the bound as saying that a router has
only four physical inputs.

### 9.2 Round-Robin Pointer

Each output maintains its own arbitration pointer.
The pointer identifies the starting position for the next arbitration search.

After a successful transfer:

$$\text{pointer} = \text{requester\_after\_served\_requester}$$

The pointer shall not advance when:

* There is no eligible request;
* An eligible request exists but downstream `ready=0`;
* No packet transfer occurs.

### 9.3 Bounded Service

Under the declared v1 assumptions, a continuously requesting eligible contender
with an available downstream path shall receive service within four arbitration
opportunities.

This is a bounded arbitration/liveness requirement.
It is not a general claim of unrestricted NoC liveness under arbitrary future
extensions.

---

## 10. Backpressure

Backpressure propagates through the valid/ready protocol.

If an output cannot accept a packet:

* `out_ready = 0`

the upstream arbitration logic shall not complete a transfer on that output.

A packet presented with:

* `out_valid = 1`
* `out_ready = 0`

shall remain stable.

No transfer shall be counted by the verification environment unless
`out_valid && out_ready` is true.

---

## 11. Packet Integrity

For every accepted packet, the following fields shall remain unchanged while
the packet traverses the NoC:

* `src_id`
* `dst_id`
* `txn_id`
* `payload`

A successful delivery shall therefore preserve the complete 42-bit packet.

The NoC shall not:

* Duplicate an accepted packet;
* Silently drop an accepted packet;
* Modify source ID;
* Modify destination ID;
* Modify transaction ID;
* Modify payload.

---

## 12. Ordering

Ordering is guaranteed only within a source-to-destination flow.

For packets sharing:

* Same `src_id`
* Same `dst_id`

delivery order shall match injection order.

No global ordering guarantee exists between independent source/destination
flows.

---

## 13. Invalid Destination

The following destination IDs are invalid:

* `3'b100`
* `3'b101`
* `3'b110`
* `3'b111`

An invalid destination packet shall:

* Not be delivered to any endpoint;
* Not be forwarded as a valid routed packet;
* Produce an explicit error indication through the NoC interface.

### 13.1 Error Interface

The router shall expose explicit per-input error reporting for the five
physical input directions.

The error ports are:

| Input direction | Error valid         | Error destination ID |
| --------------- | ------------------- | -------------------- |
| `NORTH`         | `north_error_valid` | `north_error_dst_id` |
| `SOUTH`         | `south_error_valid` | `south_error_dst_id` |
| `EAST`          | `east_error_valid`  | `east_error_dst_id`  |
| `WEST`          | `west_error_valid`  | `west_error_dst_id`  |
| `LOCAL`         | `local_error_valid` | `local_error_dst_id` |

For each input direction, an invalid-destination event occurs exactly when an
invalid packet is accepted on that input:

`<direction>_in_valid && <direction>_in_ready &&
invalid(<direction>_in_packet.dst_id)`.

The corresponding `<direction>_error_valid` shall be asserted for one clock
cycle for that event.

The corresponding `<direction>_error_dst_id` shall contain the invalid 3-bit
destination ID associated with that accepted packet and shall remain stable for
the entire cycle in which the corresponding `<direction>_error_valid=1`.

Each accepted invalid packet shall generate exactly one corresponding
per-input error event.

Multiple invalid-destination events on different input directions may occur
in the same cycle and shall be reported independently.

No separate error handshake is required in NoC v1.

An invalid-destination event is an error/reporting event and is not a successful
NoC packet transfer.

An accepted invalid-destination packet shall be consumed/rejected by the router
and shall not be routed to any directional output or local endpoint.

No endpoint shall observe an invalid-destination packet as a successful local
delivery.

---

## 14. Reset Contract

The NoC v1 reset shall be:

* `rst`
* active-high
* synchronous

On a clock edge where `rst=1`:

* Arbitration pointers shall return to their defined initial state;
* Internal valid state shall be cleared;
* All per-input error-reporting indications and pending error-reporting
  state shall be cleared;
* No packet transfer shall be generated solely because of reset.

After reset deassertion, the router shall begin from the deterministic initial
arbitration state.

The initial round-robin pointer value shall be `DIR_LOCAL` for every output.

---

## 15. Verification-Visible Invariants

The following invariants are part of the RTL contract.

* **Transfer:** $\text{transfer} \iff \text{valid} \land \text{ready}$
* **Stability under backpressure:** If `valid && !ready`, packet contents remain stable until the transfer or legal withdrawal condition defined by the interface.
* **Routing:** The selected output shall exactly match deterministic XY routing.
* **Arbitration:** At most one requester shall be granted for an output in a transfer cycle.
* **Integrity:** Accepted packet fields shall not be modified during forwarding.
* **Invalid destination:** An invalid destination shall never result in endpoint delivery.

* **Invalid-destination reporting:** Each accepted invalid packet shall
  generate exactly one error event on its corresponding input, and simultaneous
  invalid events on different inputs shall be reported independently.
* **Ordering:** Packets belonging to the same source-to-destination flow shall be delivered in injection order.
* **Bounded service:** Under the declared assumptions, a continuously requesting eligible contender shall be serviced within four arbitration opportunities.

---

## 16. Interface Freeze Criteria

Before RTL implementation begins, the following shall remain frozen:

* Endpoint ID width;
* Endpoint encoding;
* Transaction ID width;
* Payload width;
* Packet width;
* Direction encoding;
* Router coordinate representation;
* Valid/ready semantics;
* Packet stability semantics;
* Invalid-destination behavior;
* Per-input error signal semantics;
* Exact per-input error signal naming:
  * `north_error_valid` / `north_error_dst_id`;
  * `south_error_valid` / `south_error_dst_id`;
  * `east_error_valid` / `east_error_dst_id`;
  * `west_error_valid` / `west_error_dst_id`;
  * `local_error_valid` / `local_error_dst_id`;
* Error signal direction mapping;
* Simultaneous invalid-destination error reporting semantics;
* Reset polarity;
* Reset timing;
* Reset initial arbitration state;
* Exact port naming;
* Arbitration requester eligibility;
* Round-robin pointer update rule;
* Four-opportunity bounded-service rule.
Any change to these items shall be treated as an interface-contract change and
shall be reviewed before RTL implementation.

---
## 17. Requirement Traceability

| Requirement | RTL Contract Evidence |
| --- | --- |
| **NOC-REQ-001** | 2x2 topology |
| **NOC-REQ-002** | Endpoint mapping and IDs |
| **NOC-REQ-003** | Deterministic XY routing |
| **NOC-REQ-004** | Valid/ready transfer contract |
| **NOC-REQ-005** | Local delivery |
| **NOC-REQ-006** | One-hop routing |
| **NOC-REQ-007** | Multi-hop routing |
| **NOC-REQ-008** | Round-robin arbitration |
| **NOC-REQ-009** | Backpressure |
| **NOC-REQ-010** | Packet integrity |
| **NOC-REQ-011** | No duplication/loss |
| **NOC-REQ-012** | Same-flow ordering |
| **NOC-REQ-013** | Invalid destination/error interface |
| **NOC-REQ-014** | Verification-visible invariants |
| **NOC-REQ-015** | Routing/contention/backpressure observability |
| **NOC-REQ-016** | Regression closure |
| **NOC-REQ-017** | Bounded arbitration/liveness |

---

## 18. Scope Boundary

This contract does not define:

* Multi-flit packets;
* Wormhole routing;
* Virtual channels;
* Adaptive routing;
* Fault tolerance;
* Link-level retry;
* Packet retransmission;
* QoS;
* Credit-based flow control;
* Arbitrary topology discovery;
* Production-level deadlock freedom;
* Unrestricted traffic-performance guarantees.

Those features are outside NoC v1 scope.
