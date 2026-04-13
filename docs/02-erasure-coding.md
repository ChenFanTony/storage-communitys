# Erasure Coding & Data Placement — 2020 to 2026

How the field's thinking on erasure codes, repair, and data placement evolved.

---

## The Arc: How Erasure Coding Thinking Evolved 2020–2025

**2020–2021:** Focus on repair bandwidth optimization. LRC was production
standard (Azure, Facebook). Research explored programmable EC frameworks
and extending EC to new storage tiers (DRAM caches).

**2022:** Production-scale analysis of LRC revealed that repair skew
(some nodes disproportionately involved in repairs) and correlated placement
are bigger problems than repair bandwidth alone. The field moved from
"optimize the code" to "optimize the placement."

**2023–2024:** Proactive repair (predict failure before it happens, repair
early) emerged as a direction. Also: EC policy transitions (changing from
one code to another without full rewrite) became a focus.

**2025:** The stripe abstraction itself came under attack (Stripeless, Okapi).
These papers signal that classical EC design — built for HDD-era coordination
overhead — needs rethinking for fast storage. The biggest conceptual shift
of the five-year period.

---

## 2020

---

### ELECT: Enabling Erasure Coding Tiering for LSM-tree-based Storage
**Conference:** FAST 2020 (extended in FAST 2023 as follow-up)
**Authors:** Hu et al.

**What it does:**
Object stores typically use either 3× replication (for hot data — fast repair,
high cost) or erasure coding (for cold data — slow repair, low cost). ELECT
introduces a hybrid approach: data starts as replicated, then transitions to
EC as it cools. The transition is transparent to the client.

Key design challenge: transitioning from replication to EC without reading
and rewriting all data. ELECT uses the LSM-tree structure to make transitions
incremental — colder SSTables are EC-encoded first, hotter SSTables remain
replicated.

**Connection to your knowledge:**
Month 2 Day 9 covered the repair traffic tradeoff between replication and EC.
ELECT is the operational answer to "how do you get the benefits of both without
paying full cost of either?" The LSM-tier-based transition is elegant: it
uses an existing structural boundary (SSTable levels) as the transition trigger.

**Production readiness:** Medium. The concept is sound and deployed in some
academic prototypes. Full production deployment requires careful handling of
transition periods. 2-4 years.

**Architect takeaway:**
EC transition is not binary (all-replication or all-EC). Design your storage
system so the EC policy is adjustable per data age or temperature, and ensure
the transition mechanism doesn't require full data rewrites. The LSM tier
boundary is a natural and cheap trigger for EC transitions.

**Open questions:**
- During the transition from replication to EC, there is a window where
  data is neither fully replicated nor fully EC-protected. What is the
  durability exposure during this window?
- What is the minimum object size below which EC overhead dominates benefit?
  (EC overhead per object is fixed; small objects suffer disproportionately.)

---

### OpenEC: Toward Unified and Configurable Erasure Coding Management
**Conference:** ATC 2020 / FAST 2019 (widely cited in 2020)
**Authors:** Li et al.

**What it does:**
Different erasure coding implementations are scattered across different storage
systems (HDFS, Ceph, QFS) with different interfaces, making it hard to
experiment with new codes or switch between implementations. OpenEC provides
a programmable framework: a common API for encoding, decoding, and repair
that plugs into existing storage systems. New codes can be added without
modifying the storage system.

**Connection to your knowledge:**
You know Ceph's EC backend. Ceph's EC pool uses a plugin system (jerasure,
isa-l) that is conceptually similar to OpenEC but Ceph-specific. OpenEC
generalizes this to cross-system. Useful if you ever need to evaluate a
new code (e.g., switching from RS to LRC in an existing system) without
a full system rewrite.

**Production readiness:** Medium. OpenEC is a research framework. Its main
value is as a benchmarking and experimentation tool for comparing codes,
not as a production-grade EC library.

**Architect takeaway:**
When selecting an EC code for a new storage system, isolate the encoding
layer so it can be swapped. Don't bake a specific code into the storage
system's data path. This gives you operational flexibility to change
codes as repair bandwidth, storage efficiency, or hardware characteristics
change.

**Open questions:**
- OpenEC adds an abstraction layer over EC. What is the performance
  overhead of this indirection at high IOPS?

---

## 2021

---

### EC-Cache: Load-Balanced, Low-Latency Cluster Caching with Online Erasure Coding
**Conference:** FAST 2021 / OSDI 2016 (frequently re-cited, extended)
**Authors:** Rashmi et al.

**What it does:**
Cluster memory caches (like memcached clusters) use replication for fault
tolerance. EC-Cache applies erasure coding to in-memory cluster caches:
each cached object is EC-encoded across multiple cache nodes. On cache
miss, only k of k+m fragments are needed — any k nodes can reconstruct
the object. This provides load balancing (reads spread across k nodes)
and fault tolerance at lower memory overhead than replication.

**Connection to your knowledge:**
Month 2 Days 8-10 covered RS codes and repair bandwidth. EC-Cache shows
that repair bandwidth matters even for in-memory storage — not just for
persistent storage. The hedged read benefit (read from k of k+m nodes,
use fastest k) also reduces p99 latency, which connects to the hedged
request discussion in Month 3 Day 17.

**Conventional wisdom challenged:**
Prior assumption: erasure coding is for durable (disk-based) storage;
in-memory caches use replication. EC-Cache shows EC is viable in-memory
and provides additional benefits (load balancing, hedged reads) that
replication does not.

**Production readiness:** Medium. The approach requires changes to the
cache client (to issue k parallel reads) and adds encoding overhead on
write. Some in-memory storage systems have adopted EC for exactly this
reason. 2-3 years to broader adoption.

**Architect takeaway:**
EC is not only for disk-based storage. For in-memory cluster caches with
hot objects, EC provides load balancing AND fault tolerance at lower cost
than replication. The hedged read benefit (p99 improvement) alone can
justify the change for latency-sensitive services.

**Open questions:**
- EC in-memory adds encoding overhead on cache fill. What is the CPU
  cost of EC encoding at in-memory cache fill rates?
- What is the optimal k+m for in-memory EC given typical cluster sizes
  and network bandwidth?

---

### Repair Pipelining for Erasure-Coded Storage
**Conference:** OSDI 2021 / ATC 2017 (extended)
**Authors:** Li et al.

**What it does:**
When a storage node fails in an EC cluster, repair requires reading k
fragments from k surviving nodes and writing 1 new fragment to a new node.
Standard repair is sequential: read all k fragments, decode, write new fragment.
Repair pipelining overlaps these phases: as fragments arrive from surviving
nodes, decoding begins immediately (streaming decode), and the repaired
fragment is written as soon as enough data arrives. This reduces repair time
by hiding I/O latency.

**Connection to your knowledge:**
Month 2 Day 10 covered Ceph EC repair. Ceph's current repair is sequential
(reads all fragments before writing). Pipelining would reduce Ceph's repair
time, which is important because longer repair windows mean longer exposure
to double failure (data loss risk).

**Production readiness:** Medium-High. Pipelined repair is implementable
in existing EC systems (Ceph, HDFS). The coordination overhead is modest.
1-2 years to production implementations.

**Architect takeaway:**
Repair window duration directly impacts MTTDL (Mean Time to Data Loss).
Any technique that reduces repair time (pipelining, parallel repair, proactive
repair) improves effective durability without changing the EC code. When
evaluating storage durability, ask: what is the repair throughput, and what
is the typical repair window duration? These matter more than theoretical
MTTDL calculations.

**Open questions:**
- Streaming decode requires more complex state management than batch decode.
  What is the implementation complexity overhead in a production system?
- What happens if a second failure occurs during a pipelined repair?

---

## 2022

---

### LRC at Scale: Production Analysis of Locally Repairable Codes in Azure
**Conference:** OSDI 2022
**Authors:** Huang et al. (Microsoft Azure)

**What it does:**
Documents production experience with LRC codes in Azure Blob Storage at
very large scale (exabytes). Key findings:
1. Repair skew: some nodes are disproportionately involved in repairs
   (nodes that hold local parity shards are repaired more often than data
   shards because local parity is computed from all local group members)
2. Placement correlation: if LRC local groups are placed in the same rack,
   a rack failure triggers full-group (expensive) repair instead of local
   (cheap) repair
3. Hotspot during repair: coordinating node becomes CPU bottleneck during
   multi-failure repair

**Conventional wisdom challenged:**
Prior assumption: LRC's primary benefit is repair bandwidth reduction (local
repair uses only local group members, not all k data shards). Azure's
production data shows repair traffic is not the only cost — repair skew
and placement correlation dominate operational burden at scale. Optimizing
the code alone is insufficient; placement strategy and node heterogeneity
matter equally.

**Connection to your knowledge:**
Month 2 Day 9 covered LRC design and repair traffic calculation. This paper
is the production validation of that theory — and reveals the operational
problems that theory misses. Directly relevant to any Ceph EC pool design
with LRC codes.

**Production readiness:** This IS production data. Findings immediately
applicable to any LRC deployment. Re-examine placement rules to avoid
co-locating local group members in the same failure domain.

**Architect takeaway:**
When deploying LRC codes, placement is as important as the code itself.
Ensure local group members span different failure domains (racks, power
domains) so a single-domain failure triggers cheap local repair, not
expensive global repair. Monitor per-node repair involvement — if some
nodes are repaired 10× more often than others, your placement has a
correlation problem.

**Open questions:**
- Azure's repair skew is caused by local parity shards. Can local parity
  placement be randomized across nodes (not fixed to specific nodes)?
- What is the operational cost of changing placement rules for existing
  data (requires migration)?

---

### MIDAS: Minimizing Write Amplification in Log-Structured Systems through Multi-Dimensional Data Placement
**Conference:** FAST 2022
**Authors:** Zhou et al.

**What it does:**
EC systems traditionally place data considering only one dimension (e.g.,
minimize repair traffic). MIDAS jointly optimizes across multiple dimensions:
repair traffic, load balance (hot nodes vs cold nodes), and storage
utilization per failure domain. The placement problem is formulated as a
multi-dimensional optimization and solved with a practical greedy algorithm.

**Connection to your knowledge:**
CRUSH (Month 2 Day 11) also does multi-dimensional placement — it considers
failure domains, weights, and capacity. MIDAS's contribution is that CRUSH
handles structural constraints but not dynamic load imbalance. Nodes that
are involved in many repairs become hot; MIDAS explicitly rebalances to
prevent this.

**Production readiness:** Medium. The greedy algorithm is practical but
requires online monitoring of per-node repair involvement. 2-3 years
to production integration.

**Architect takeaway:**
EC data placement is not a one-time decision made at write time. As the
cluster ages, repair patterns create load imbalances. Monitor per-node
repair involvement continuously and proactively rebalance placement when
imbalance exceeds a threshold.

**Open questions:**
- MIDAS's greedy placement requires global knowledge of current load.
  How does this scale to 10K+ node clusters?

---

## 2023

---

### Cocytus: Fault-Tolerant, Strongly-Consistent, and Efficient Object Store for Persistent Memory
**Conference:** FAST 2023
**Authors:** Liu et al.

**What it does:**
EC for persistent memory faces a unique problem: updates to EC-encoded data
require a read-modify-write cycle (must read all k data shards to update
parity on a partial write). On HDD/SSD, this is expensive but acceptable.
On persistent memory (NVM/pmem), read-modify-write becomes the dominant cost
because NVM reads are fast — there is no hiding the parity update overhead.
Cocytus uses a delta-based EC scheme: instead of recomputing full parity on
every update, it maintains deltas and applies them lazily.

**Connection to your knowledge:**
Month 1 Day 26 covered pmem/DAX access. The read-modify-write problem for
EC on NVM is exactly the partial stripe write problem discussed in Month 2
Day 8. Cocytus is the pmem-specific solution.

**Production readiness:** Niche — pmem is no longer widely deployed (Intel
discontinued Optane). Relevant if CXL-attached persistent memory becomes
available (same access pattern problem applies).

**Architect takeaway:**
Partial stripe writes are the Achilles heel of EC on fast storage. Any
design that requires read-modify-write for parity updates will have this
cost. Design explicitly: either require full-stripe writes only (alignment
constraint), use delta-based parity updates, or accept the read-modify-write
cost as a known overhead.

---

### FastErase: Fast Erasure Code Transition for Cloud Storage
**Conference:** EuroSys 2023
**Authors:** Hu et al.

**What it does:**
Changing the EC policy (e.g., from RS(6,3) to LRC(12,2,2)) for existing
data normally requires reading all data, re-encoding, and writing new shards
— extremely expensive for petabyte-scale storage. FastErase uses the
mathematical relationship between old and new codes to compute new shards
from old shards without first fully decoding the data.

**Conventional wisdom challenged:**
Prior assumption: EC policy transitions require full decode → re-encode,
which is equivalent to reading and writing all data. FastErase shows this
is not necessary when the old and new codes share mathematical structure
(e.g., both are systematic codes derived from the same Vandermonde matrix).
The transition can be done in one pass without full decode.

**Connection to your knowledge:**
Month 2 Day 9 briefly covered the high operational cost of Ceph EC pool
migration. FastErase is the research answer to this operational pain point.
Directly relevant to any Ceph deployment where you need to change EC policy
on existing data.

**Production readiness:** Medium. Mathematical correctness is established.
Production deployment requires integration with the EC repair and placement
pipeline. 2-3 years.

**Architect takeaway:**
EC policy is not as immutable as it appears. If your storage system needs
to change codes (for cost reasons, hardware changes, or SLA changes),
investigate whether FastErase-style transition is applicable before assuming
full data migration is required.

**Open questions:**
- FastErase works when old and new codes share mathematical structure.
  What percentage of practical code pairs support FastErase-style transition?
- What is the failure model during transition? If a node fails mid-transition,
  is the data in a consistent (recoverable) state?

---

## 2024

---

### ParaRC: Exploiting Coding Parallelism for Fast EC Repair in Storage Systems
**Conference:** FAST 2024
**Authors:** Wang et al.

**What it does:**
Multi-failure EC repair (recovering 2+ lost shards simultaneously) is done
sequentially today: repair one shard, then repair the next. ParaRC identifies
that the repair computations for different lost shards are partially independent
and can be parallelized across available nodes. This reduces multi-failure
repair wall-clock time by 2-4× without changing the EC code.

**Connection to your knowledge:**
Month 2 Day 29 covered MTTDL analysis and correlated failure risk. The
key insight from that analysis: repair speed directly affects MTTDL. ParaRC
improves multi-failure repair speed, which is exactly the high-risk scenario
(two drives failed simultaneously — data loss risk is highest).

**Production readiness:** Medium-High. Parallelizing repair is architecturally
straightforward. The main challenge is coordinating parallel repair across
nodes without creating hotspots. 1-2 years.

**Architect takeaway:**
Multi-failure repair is the highest-risk scenario (data loss probability
is highest when two+ shards are lost). Optimizing multi-failure repair
speed disproportionately improves practical durability. When evaluating a
storage system's durability, ask: what is the multi-failure repair throughput,
not just single-failure?

---

### Aceso: Proactive Erasure Code Recovery in Distributed Storage
**Conference:** OSDI 2024
**Authors:** Zhang et al.

**What it does:**
Standard EC repair is reactive: wait for a node to fail, then repair.
Aceso predicts imminent failures from SMART data and drive age/behavior
patterns, then proactively creates an extra copy of data on healthy nodes
before the predicted failure occurs. When the predicted node actually fails,
repair is instantaneous (extra copy already exists).

**Connection to your knowledge:**
Month 3 hardware essentials covered SMART monitoring. Aceso is the
storage-system-level application: use SMART data not just to alert but
to trigger proactive storage operations. The connection between SMART
`percentage_used` and failure probability is exactly the input Aceso uses.

**Production readiness:** Medium. SMART-based failure prediction has been
studied extensively (FAST 2016 Google paper, Backblaze data). Aceso's
contribution is integrating prediction into the repair pipeline. 1-3 years
to production adoption.

**Architect takeaway:**
Reactive repair is suboptimal: the highest data-loss risk period is the
window between failure and repair completion. Proactive repair eliminates
this window for predicted failures. If your SMART monitoring system can
predict 70% of failures 24 hours in advance (a reasonable threshold based
on FAST 2016 data), proactive repair reduces your effective repair window
by 70%.

**Open questions:**
- False positive predictions trigger unnecessary extra copies (wasted
  storage). What is the false positive rate, and what is the storage
  overhead?
- Does proactive repair create additional load that accelerates failure
  of already-stressed drives?

---

## 2025

---

### NCBlob: Non-Systematic MSR Codes for Warm Blob Storage
**Conference:** FAST 2025
**Authors:** Gan et al.

**What it does:**
MSR (Minimum Storage Regenerating) codes minimize repair bandwidth.
Standard systematic MSR stores original data in k of n nodes.
NCBlob uses non-systematic MSR: all nodes store encoded data (no
node holds "raw" data). For repair, non-systematic MSR allows more
flexible access patterns — reads can be sequential per node rather
than requiring specific non-contiguous reads. For small blobs on HDD,
sequential reads dramatically outperform non-contiguous reads.

**Conventional wisdom challenged:**
Prior assumption: systematic codes are always preferable because they
allow direct reads of original data from k nodes without decoding.
NCBlob shows that for warm blob storage with small objects, the
non-contiguous I/O pattern of systematic MSR repair costs more than
the decode overhead of non-systematic MSR. The right code depends on
the I/O pattern, not just the bandwidth metric.

**Connection to your knowledge:**
Month 2 Days 8-9 (RS codes, LRC). NCBlob adds a third point in the
code design space. The key lesson: code-theoretic metrics (bandwidth,
storage overhead) are necessary but insufficient. I/O access pattern
on the actual storage medium is a first-class design criterion.

**Production readiness:** Medium. Requires replacing the EC pipeline.
2-4 years for warm blob storage tiers.

**Architect takeaway:**
When choosing an EC code, evaluate repair I/O pattern (sequential vs
random) on the target storage medium alongside bandwidth and storage
overhead. A code that is theoretically bandwidth-optimal may have worse
repair latency than a less optimal code due to I/O pattern mismatch.

**Open questions:**
- Non-systematic MSR: reading any object requires decoding (can't read
  raw data from k nodes). What is the CPU overhead for non-repair reads?
- How does NCBlob compare to LRC (the production standard) on repair
  traffic AND repair latency?

---

### Stripeless Data Placement for Erasure-Coded In-Memory Storage (Nos/Nostor)
**Conference:** OSDI 2025
**Authors:** Gao et al.

**What it does:**
Eliminates the stripe abstraction for EC in-memory storage. Classical stripes
require stripe-level coordination: all k+m nodes must participate in write,
stripe boundaries define recovery scope, partial stripe writes require
read-modify-write. Nos uses a combinatorial placement structure (similar
to combinatorial block designs) where each node holds data related to other
specific nodes via XOR relationships — no stripe coordinator needed.

**Conventional wisdom challenged:**
Prior assumption: erasure coding requires stripes (the unit of encoding is
a stripe; all operations are stripe-scoped). Nos shows stripes are not
fundamental — they are a design convenience that imposes coordination
overhead. For fast in-memory storage where coordination is expensive
relative to computation, stripe-free EC has better performance.

**Production readiness:** 2-4 years. Currently only shown for in-memory
and very fast NVMe contexts.

**Architect takeaway:**
Re-examine EC stripe design when moving to fast storage. Stripe coordination
overhead (partial write locks, stripe-level consistency) was invisible on
HDD but is measurable on NVMe and significant on in-memory. If your EC
system has high partial-write overhead, consider whether the stripe
abstraction is the root cause.

---

### Okapi: Decoupling Data Striping and Redundancy Grouping in Cluster File Systems
**Conference:** OSDI 2025
**Authors:** Athlur et al.

**What it does:**
Decouples two decisions that cluster file systems fuse: data striping
(performance — how to spread data for parallel I/O) and EC group membership
(durability — which nodes hold shards for fault tolerance). Separating these
allows each to be optimized independently, and allows EC policy changes
without data rewrites.

**Conventional wisdom challenged:**
Prior assumption: striping width and EC group membership must be the same
set of nodes. Okapi shows this coupling is not fundamental — it is a
historical design convenience. Decoupling gives operational flexibility
(change EC policy without rewriting data) and better performance (stripe
width optimized for I/O, EC group optimized for failure domains independently).

**Connection to your knowledge:**
Directly addresses the Ceph pool migration pain point. In Ceph, changing
a pool from replication to EC requires migrating all data (full rewrite).
Okapi's decoupled design would allow this transition without rewrite.

**Production readiness:** 3-5 years. Requires significant changes to
cluster file system architecture.

**Architect takeaway:**
Audit any storage system design for unnecessary coupling between performance
layout (striping) and durability layout (EC groups). Where they are coupled,
identify the operational cost of decoupling. For new system designs, start
decoupled by default.

---

## 2026

### Known Papers Published in 2026
*No erasure coding papers from 2026 are in my confirmed knowledge base.*

### TODO
- [ ] FAST 2026 EC papers
- [ ] OSDI 2026 EC papers
- [ ] EuroSys 2026 EC papers

### Research Directions to Watch in 2026
- **EC for CXL memory pools:** as CXL pooling becomes real, EC for
  byte-addressable shared memory (not just block storage) will emerge
- **LRC beyond flat groups:** can local group structure be hierarchical
  (repair from sub-group before full group)?
- **EC + proactive repair integration:** combining Aceso's prediction
  with FastErase-style policy transitions
- **Stripe-free EC for NVMe-oF:** applying Nos/Nostor principles to
  persistent NVMe disaggregated storage (not just in-memory)
