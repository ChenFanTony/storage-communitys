# Distributed Consensus & Replication in Storage — 2020 to 2026

New consensus research applied to storage correctness and performance.

---

## The Arc: 2020–2025

**2020–2021:** Papers focused on reducing Raft/Paxos overhead for storage-specific workloads. The observation: storage operations have properties (commutativity, durability guarantees) that general consensus protocols don't exploit.

**2022–2023:** A wave of papers challenged the "you always need a full consensus round trip" assumption. Several showed that specific storage access patterns can achieve linearizability with fewer round trips.

**2024–2025:** CXL-based shared memory begins to offer an alternative to network-based consensus for co-located nodes (Tigon). NVMe persistence guarantees are exploited to reduce consensus overhead (Nezha).

---

## 2020

### CRaft: An Erasure-Coding-Based Raft for Efficient Large-Scale State Machine Replication
**Conference:** OSDI 2020 (and FAST 2020 related) | **Authors:** Lv et al.

**What it does:** Standard Raft replicates the full log entry to all followers. For large log entries (e.g., Raft used as the replication layer for a storage system), this is expensive: every write is replicated 3× or 5× in full. CRaft uses erasure coding instead: the leader encodes the log entry into k+m shards, sends each follower one shard. Commit requires acks from a quorum of k (majority of k+m).

**Conventional wisdom challenged:** Prior assumption: Raft log entries must be fully replicated to each follower. CRaft shows that EC-based replication can reduce network bandwidth by 2-3× (for RS(k,m) with k=majority) while maintaining the same fault tolerance and linearizability guarantees.

**Connection to your knowledge:** Month 2 Day 2 (Raft) + Month 2 Day 8 (RS codes). CRaft is the intersection: apply EC to the Raft log replication path. The tradeoff: lower network bandwidth but higher CPU (encoding/decoding on each write). For storage systems where writes are large (>1MB), the bandwidth saving dominates the CPU cost.

**Production readiness:** Medium. Requires changes to the Raft library. Applied in research prototypes for large-entry Raft systems. 2-3 years.

**Architect takeaway:** For Raft-based storage systems with large write entries (database pages, object chunks), EC-based replication can reduce replication bandwidth by 2-3× without sacrificing correctness. Evaluate this when network bandwidth, not CPU, is your replication bottleneck.

---

### Exploiting Commutativity for Consistent and Fast Replication
**Conference:** SOSP 2020 | **Authors:** Mu et al.

**What it does:** In replicated state machines (Raft, Paxos), all operations go through a total order — even when two operations are commutative (their result is the same regardless of order, e.g., two INSERTs to different keys). The paper shows that commutative operations can bypass the serialization bottleneck: instead of waiting for a global order, commutative operations can be applied in parallel as long as they don't conflict.

**Conventional wisdom challenged:** Prior assumption: linearizable replication requires total ordering of all operations. This paper shows total ordering is only necessary for non-commutative operations. Commutative operations can be replicated concurrently, reducing the single-leader bottleneck.

**Connection to your knowledge:** Month 2 Day 1 (linearizability). This paper refines the linearizability definition: the same outcome with a different execution order is still linearizable if the operations commute. For storage systems with mostly non-conflicting operations (e.g., writes to different keys), this unlocks significant throughput improvement.

**Production readiness:** Medium. Requires a commutativity analysis layer above the consensus protocol. 2-4 years.

**Architect takeaway:** If your replicated storage system handles operations that mostly don't conflict (different keys, non-overlapping ranges), commutativity-based optimization can give 2-5× throughput improvement over standard Raft/Paxos. This is the theoretical basis for why CockroachDB and TiKV use MVCC — it's a practical form of commutativity exploitation.

---

## 2021

### Pacemaker: Avoiding Contention in Distributed Transactions with Futures
**Conference:** FAST 2021 | **Authors:** Lim et al.

**What it does:** Metadata replication for storage systems (inode updates, directory changes) using a modified Paxos that reduces round-trip latency by pipelining dependent metadata operations. Standard Paxos: each metadata update requires 2 round trips. Pacemaker uses "futures" (like async/await): a dependent operation can begin before its predecessor completes, using the predicted result.

**Connection to your knowledge:** Month 2 Day 5 (Paxos Made Simple). Pacemaker is a storage-specific Paxos optimization: metadata operations often have predictable results (inode count++, mtime update) that can be predicted before the consensus round completes. The optimization reduces perceived latency for dependent metadata chains.

**Production readiness:** Medium. 2-3 years. Applicable to any metadata-heavy distributed file system.

**Architect takeaway:** Storage metadata operations often have predictable, deterministic results. "Futures" — beginning the next operation before the current consensus round completes — is a sound optimization when the predicted result is almost always correct. Design metadata replication to exploit predictability.

---

## 2022

### Skyros: Exploiting the Ordering Properties of Durable Storage for Faster Distributed Transactions
**Conference:** OSDI 2022 | **Authors:** Eldeeb & Bernstein

**What it does:** Standard Paxos requires 2 round trips per consensus decision (prepare + accept). Skyros shows that if the storage layer provides durability guarantees (each write is durable before ack), the prepare phase can be eliminated for non-conflicting operations. Result: single-round-trip consensus for the common case.

**Conventional wisdom challenged:** Prior assumption: Paxos always requires 2 round trips (prepare + accept) to achieve linearizability. Skyros shows this is only necessary when you can't rely on the storage medium's ordering guarantees. If the storage layer guarantees writes are applied in order and durably, the prepare phase is redundant for non-conflicting operations — the storage ordering IS the prepare.

**Connection to your knowledge:** Month 2 Day 5 (Paxos phases) + Month 1 (NVMe persistence guarantees). NVMe provides durable ordering (once a write is acknowledged, it is persistent and ordered). Skyros exploits this to skip one Paxos round trip.

**Production readiness:** Medium. Requires close integration between consensus protocol and storage layer. 2-4 years.

**Architect takeaway:** The storage layer's durability guarantees can substitute for consensus protocol phases. If your storage layer guarantees ordered durable writes (NVMe + PLP), you may be able to eliminate one round trip from your consensus protocol. This is the principle behind Nezha (2024) and NovKV's co-design philosophy.

---

## 2023

### Hermes: A Fast, Fault-Tolerant and Linearizable Replication Protocol
**Conference:** OSDI 2023 | **Authors:** Katsarakis et al.

**What it does:** Replication protocol that achieves linearizability with a single round trip for both reads AND writes in the common case (no failures). Standard Raft: writes = 1 round trip to leader + leader broadcasts to followers (2 hops total); reads from leader = 0 extra round trips but only served by leader. Hermes: both reads and writes use 1 broadcast round trip; any replica can serve reads after it receives the write broadcast.

**Conventional wisdom challenged:** Prior assumption: linearizable reads in Raft must go through the leader (or use Read Index which requires a round trip). Hermes shows that any replica can serve linearizable reads after receiving the write invalidation broadcast — similar to how hardware cache coherence works (invalidate all copies, then serve from any).

**Connection to your knowledge:** Month 2 Days 2-4 (Raft details). Hermes is an alternative to Raft for storage systems that want both high write throughput AND high read throughput across all replicas. The hardware cache coherence analogy is important: Hermes is essentially MESI protocol for distributed storage.

**Production readiness:** Medium. Requires replacing the replication layer. 2-4 years.

**Architect takeaway:** Raft's leader bottleneck for reads is not fundamental to linearizability — it's a design choice in Raft. Protocols like Hermes show linearizable reads from any replica are achievable with the same round trip count as Raft writes. If your Raft-based storage system's read throughput is bottlenecked by the leader, Hermes-style invalidation replication is worth investigating.

---

## 2024

### PolarFS: An Ultra-Low Latency and Failure Resilient Distributed File System for Shared Storage Cloud Database
**Conference:** OSDI 2024 (production paper) | **Authors:** Alibaba Cloud

**What it does:** Documents the Raft implementation in Alibaba's PolarDB shared storage. Key production findings at 100K+ node scale: Raft leader election latency is dominated by log replay time (not networking); at scale, straggler followers cause write amplification in the leader's retry path; and the standard Raft approach to member changes is too slow for dynamic cloud environments.

**Connection to your knowledge:** Month 2 Days 2-4 (Raft production failure modes). PolarFS provides the 100K-node production validation of the failure modes covered in those days. Confirms: pre-vote is necessary at scale (disruptive elections are frequent), leader lease is necessary for read performance, and check-quorum prevents stale leaders from serving reads.

**Production readiness:** This IS production data. Immediately applicable.

**Architect takeaway:** At 100K+ nodes, Raft optimizations (pre-vote, leader lease, check-quorum) are not optional. They are required for stable operation. The base Raft algorithm without these optimizations will have visible availability problems at scale.

---

### Nezha: Deployable and High-Performance Consensus Using Synchronized Clocks
**Conference:** EuroSys 2024 | **Authors:** Ding et al.

**What it does:** Consensus protocol that exploits synchronized clocks (hardware-based, GPS/PTP) and NVMe persistence guarantees to reduce consensus latency. If all nodes have synchronized clocks within a bounded skew, and writes to NVMe are durable before ack, then the standard 2-round-trip Paxos/Raft can be reduced to 1 round trip for the common case.

**Conventional wisdom challenged:** Prior assumption: clock synchronization is not safe to rely on for correctness in consensus protocols (clock skew can cause split brain). Nezha shows that with tight clock synchronization (PTP: <1µs skew) and NVMe persistence, clock-based ordering is safe and eliminates a round trip.

**Connection to your knowledge:** Month 2 Day 4 (Raft leader lease — leader lease is the most common clock-based optimization). Nezha generalizes this: if clocks are tight enough and storage is durable enough, more of the consensus protocol can use clock-based ordering rather than message-based ordering.

**Production readiness:** Medium. Requires PTP hardware clock synchronization. Available in cloud datacenters (AWS Time Sync, Google Spanner TrueTime). 2-3 years.

**Architect takeaway:** Clock synchronization (PTP, GPS) enables consensus optimizations that are unsafe with loose clocks. If your deployment has tight clock sync (data center or cloud with hardware time sync), clock-based consensus optimizations can reduce latency by 1 round trip. This is how Google Spanner achieves external consistency.

---

## 2025

### Tigon: A Distributed Database for a CXL Pod
**Conference:** OSDI 2025 | **Authors:** Huang et al.

**What it does:** Distributed in-memory database where cross-node synchronization uses atomic operations on CXL-shared memory instead of network messaging. Multiple hosts share a physical memory pool via CXL switch; distributed locking and coordination use CAS (compare-and-swap) on that shared memory — no network round trip.

**Conventional wisdom challenged:** Prior assumption: distributed synchronization requires network messaging (even with RDMA, a message must be sent). Tigon shows that CXL-shared memory enables synchronization via shared-memory atomics — as fast as multi-socket NUMA synchronization, not network synchronization. This collapses the distributed storage synchronization problem into a shared-memory synchronization problem for co-located nodes.

**Connection to your knowledge:** Month 2 Day 2 (consensus, round trips) + Month 3 hardware essentials (CXL). Tigon is the concrete realization of why CXL.mem matters: if nodes share physical memory, consensus doesn't need network messages — it needs shared-memory atomics.

**Production readiness:** Low (2-4 years). CXL 2.0 pooling hardware is still early. But this is the right architectural direction for in-rack distributed storage.

**Architect takeaway:** CXL memory pooling will eventually make some distributed consensus problems into shared-memory problems. For storage systems deployed within a rack (intra-rack disaggregation), plan for a CXL-based synchronization tier that is faster than RDMA. Design your synchronization layer to be swappable between network-based (today) and shared-memory-based (CXL, future).

---

## 2026

### Known Papers
*No distributed consensus / storage replication papers from 2026 are in my confirmed knowledge base.*

### TODO
- [ ] OSDI 2026, SOSP 2026, EuroSys 2026 consensus papers

### Research Directions to Watch
- **CXL consensus:** protocols specifically designed for CXL-shared memory (lower latency than RDMA, different failure model)
- **Consensus with heterogeneous storage:** Raft replicas on different storage tiers (NVMe vs HDD vs NVM) have different durability latencies — how to handle?
- **Geo-distributed consensus for object storage:** consistent global object storage across regions without blocking latency
