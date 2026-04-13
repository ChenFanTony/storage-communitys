# Disaggregated Storage, DPU & NVMe-oF — 2020 to 2026

System architecture: how compute and storage are separated, and how that separation is managed.

---

## The Arc: 2020–2025

**2020–2021:** RDMA-based disaggregation was the primary research topic. Papers focused on making distributed data structures (B-trees, KV stores) work efficiently over RDMA without server-side CPU involvement on reads.

**2022–2023:** DPU-based storage nodes emerged. The DPU CPU became the new bottleneck — data plane (NVMe I/O) saturated it before media bandwidth was exhausted. Papers shifted from "how to use RDMA" to "how to offload control plane work."

**2024–2025:** NVMe-oF target offload (Scalio) and learned index structures for DPU-constrained nodes (HiDPU) represent maturation. The question moved from "can disaggregation work?" to "how do we operate it efficiently at scale?"

---

## 2020

### Assise: Performance and Availability via Client-local NVM in a Distributed File System
**Conference:** OSDI 2020 | **Authors:** Clements et al.

**What it does:** Distributed file system that stores file data in client-local NVM (persistent memory) rather than remote storage. File writes go to client-local NVM first (for durability), then replicate asynchronously to remote nodes. Reads are always local. Crash consistency is achieved without a remote log.

**Connection to your knowledge:** This inverts the standard disaggregation model (data lives on storage nodes) by putting durability on the compute node. The NVM provides persistence, eliminating the need for remote writes on the critical path. Connects to Month 1 Day 26 (pmem/DAX) and the question of where durability lives in disaggregated systems.

**Conventional wisdom challenged:** Prior assumption: distributed file systems must write to remote storage nodes for durability. Assise shows that client-local NVM can provide durability, making the remote write asynchronous and off the critical path.

**Production readiness:** Low-Medium. Client-local NVM (Optane DIMM) was the assumed substrate; Intel discontinued Optane. CXL-attached persistent memory could revive this model. 3-5 years.

**Architect takeaway:** The question "where does durability live?" has more than one answer. Client-local NVM durability with async remote replication can achieve both low write latency AND fault tolerance — at the cost of requiring NVM on compute nodes.

**Open questions:** What happens when a client node fails before async replication completes? Is there a data loss window?

---

### InfiniFS: An Efficient Metadata Service for Large-Scale Distributed Filesystems
**Conference:** FAST 2020 | **Authors:** Lv et al.

**What it does:** Distributed metadata service for file systems using RDMA for metadata operations. Key design: metadata is partitioned across nodes by directory path; RDMA allows direct reads of metadata without metadata server CPU involvement on the critical read path.

**Connection to your knowledge:** Month 2 Day 26 (CephFS MDS bottleneck). CephFS MDS is CPU-bound at scale because all metadata operations go through the MDS process. InfiniFS bypasses MDS CPU for reads using RDMA — same principle as Sherman (2021) but applied to file system metadata.

**Production readiness:** Medium. RDMA-capable networks are required. 2-4 years.

**Architect takeaway:** File system metadata servers are CPU-bottlenecked because they mediate all operations. RDMA can bypass the server CPU for reads, converting the metadata path from CPU-bound to bandwidth-bound. This is a 2-3× throughput improvement for read-heavy metadata workloads.

---

## 2021

### Sherman: A Write-Optimized Distributed B-Tree Index on Disaggregated Memory
**Conference:** OSDI 2021 | **Authors:** Wang et al.

**What it does:** RDMA-based distributed B-tree where read operations bypass server-side CPU entirely — clients use RDMA READ to fetch B-tree nodes directly from server memory. Writes require server CPU involvement (to maintain tree consistency) but reads are zero-CPU on the server side.

**Conventional wisdom challenged:** Prior assumption: distributed B-tree operations require server CPU involvement for every operation (to maintain consistency). Sherman shows that read-only tree traversal can be done with RDMA READ (client reads server memory directly) if the tree structure provides enough information to determine the next pointer without server involvement.

**Connection to your knowledge:** Month 2 Day 1 covered RDMA programming model. Sherman is a concrete application: the B-tree's read path (root → internal nodes → leaf) can be expressed as a sequence of RDMA READs if node pointers are stable enough. The key challenge: concurrent writes may change nodes while a client is traversing — Sherman's consistency protocol handles this.

**Production readiness:** Medium. Requires RDMA network. Used in academic prototypes for disaggregated memory KV stores. 2-4 years.

**Architect takeaway:** For read-heavy distributed indexes over RDMA, design the data structure so read-only traversal requires no server CPU. This is possible for B-trees (pointer chasing via RDMA READ) but harder for LSM-trees (reads require bloom filter checks that depend on server-side state).

---

### Concordia: Resource-Efficient, QoS-Aware KV-Store via Memory Disaggregation
**Conference:** SOSP 2021 | **Authors:** Wang et al.

**What it does:** RDMA-based KV store that uses a hybrid approach: client-side RDMA for common operations (GET) and server-assisted RDMA for complex operations (transactions, range scans). Unlike pure client-side RDMA (which requires complex client logic), Concordia offloads complexity to a lightweight server agent while keeping the common path client-driven.

**Connection to your knowledge:** Complements Sherman. Sherman is "maximize server bypass." Concordia is "bypass where it's simple, use server where it's complex." The pragmatic middle ground between pure client-side RDMA (hard to get right) and traditional server-mediated access (CPU bottleneck).

**Production readiness:** Medium. 2-3 years.

**Architect takeaway:** Full server bypass via RDMA works for simple operations (point lookups) but adds client complexity for anything requiring server state (transactions, consistency checks). Design for a hybrid: RDMA for the hot, simple path; server CPU for the complex path.

---

## 2022

### SMART: A High-Performance Adaptive Radix Tree for Disaggregated Memory
**Conference:** OSDI 2022 | **Authors:** Luo et al.

**What it does:** Adaptive radix tree (ART) optimized for disaggregated memory with RDMA. ART provides better cache efficiency than B-trees for string keys. SMART makes ART work over RDMA by: reducing the number of RDMA RTTs per operation (compress multi-level traversal), and handling concurrent modifications via a novel lock protocol that works with RDMA's one-sided operations.

**Connection to your knowledge:** Connects to Month 3 Day 25 (vector stores and ANN indexes). ART is used in databases as an in-memory index structure (HyPer, Umbra). SMART's RDMA adaptation shows that in-memory index structures designed for single-machine can be adapted for disaggregated memory with careful redesign.

**Production readiness:** Medium. 2-3 years.

**Architect takeaway:** Moving an index structure from co-located to disaggregated memory requires redesigning the concurrency control, not just the access protocol. RDMA one-sided operations cannot atomically update multi-word state — any index with multi-word atomic updates needs a new approach.

---

### NovKV: Rethinking KV Store Architecture for NVMe-oF
**Conference:** FAST 2022 | **Authors:** Xu et al.

**What it does:** KV store that co-designs the storage engine with the NVMe-oF transport layer. Standard approach: run an existing KV store (RocksDB) on top of NVMe-oF block devices. NovKV instead designs the KV engine to be aware of NVMe-oF topology: routes writes to specific NVMe-oF targets based on key range, avoids redundant network hops, and uses NVMe-oF's namespace semantics directly.

**Connection to your knowledge:** Month 1 (NVMe-oF) + Month 3 (LSM-tree). NovKV is the "no unnecessary layers" design philosophy: if you're running a KV store over NVMe-oF, the KV engine should know it's over NVMe-oF and optimize accordingly rather than treating NVMe-oF as a transparent block device.

**Production readiness:** Medium. Co-design reduces portability. 2-4 years.

**Architect takeaway:** Transparent storage layers are convenient but leave performance on the table. If your KV store runs exclusively on NVMe-oF, consider a co-designed approach that exploits NVMe-oF semantics (namespace routing, multi-path, target affinity) rather than treating NVMe-oF as a generic block device.

---

## 2023

### FUSEE: A Fully Memory-Disaggregated Key-Value Store
**Conference:** OSDI 2023 | **Authors:** Chen et al.

**What it does:** Fully disaggregated KV store where both data and index are stored in remote memory (CXL-like shared memory or RDMA-accessible memory). No local caching on compute nodes. All state is in the shared memory pool. Achieves strong consistency using atomic operations on shared memory rather than distributed consensus.

**Conventional wisdom challenged:** Prior assumption: KV stores must keep hot data locally cached on compute nodes for performance. FUSEE shows that with fast enough memory interconnect (CXL), fully remote storage is feasible without sacrificing performance — the interconnect latency is low enough that local caching provides marginal benefit.

**Connection to your knowledge:** Connects directly to Tigon (OSDI 2025) — FUSEE is the KV store predecessor to Tigon's distributed database. Both use CXL/shared-memory atomics instead of network messaging for consistency.

**Production readiness:** Low-Medium. Requires CXL memory pooling hardware which is still emerging. 3-5 years.

**Architect takeaway:** As CXL memory pooling matures, the "always cache locally" assumption becomes questionable. Monitor CXL latency vs RDMA latency benchmarks — when CXL latency drops below ~200ns, fully remote storage becomes competitive with locally cached designs.

---

### DPU-based Object Store: Characterizing DPU Bottlenecks
**Conference:** EuroSys 2023 | **Authors:** Anonymous (Industry)

**What it does:** Characterization study of DPU-based object store serving. Runs object storage workloads on DPU-equipped servers (NVIDIA BlueField-2). Key finding: at moderate IOPS, DPU CPU is 100% utilized while NVMe drives are <40% utilized. The DPU CPU — not storage bandwidth — is the bottleneck. Further: DPU CPU bottleneck appears at lower IOPS than expected because DPU cores are slower than server cores and DPU software stack (SPDK, network processing) is not fully optimized.

**Conventional wisdom challenged:** Prior assumption: moving storage processing to DPU frees server CPU without introducing new bottlenecks. This paper shows DPU creates a new bottleneck: DPU CPU capacity is insufficient for high-IOPS object storage. You shifted the bottleneck, not eliminated it.

**Connection to your knowledge:** Month 3 hardware essentials (SPDK, DPU). This is the production validation of why Scalio (2025) was necessary: the DPU CPU bottleneck was identified empirically before the architectural solution was published.

**Production readiness:** This is deployment data. Immediately relevant to anyone evaluating DPU-based storage nodes.

**Architect takeaway:** When designing DPU-based storage nodes, profile DPU CPU utilization under target IOPS before assuming DPU capacity is sufficient. DPU cores are typically 5-10× slower than server cores. A workload that uses 10% of a server CPU may use 80% of a DPU CPU.

---

## 2024

### LineFS: Efficient SmartNIC Offload of a Distributed File System with Pipeline Parallelism
**Conference:** FAST 2024 | **Authors:** Kim et al.

**What it does:** Distributed file system where the data path is offloaded to SmartNIC (DPU). Compute nodes issue file operations; the SmartNIC handles network-to-storage data movement, replication, and consistency. Pipeline parallelism: the SmartNIC overlaps network receive, replication, and NVMe write phases.

**Connection to your knowledge:** Month 1 (NVMe driver, block layer) + NVMe-oF. LineFS is the "full DPU offload" approach: unlike Scalio (which offloads only the NVMe-oF target I/O path), LineFS offloads the entire file system data path to the SmartNIC.

**Production readiness:** Medium. SmartNIC file system offload adds complexity to failure handling. 2-3 years.

**Architect takeaway:** Pipeline parallelism (overlap network, replication, and storage phases) is a general technique for reducing latency in storage data paths. It requires careful failure handling (what if one pipeline stage fails?) but can reduce end-to-end latency by 2-3× compared to sequential execution.

---

### Carbink: Fault-Tolerant Far Memory
**Conference:** OSDI 2024 | **Authors:** Zhou et al.

**What it does:** Far memory system (remote DRAM accessed over RDMA) that uses erasure coding across multiple remote memory nodes for fault tolerance. Instead of replicating far memory pages (2× overhead), Carbink uses EC for durability at lower overhead.

**Connection to your knowledge:** Month 2 erasure coding applied to DRAM-tier storage. Carbink extends the "EC everywhere" principle to disaggregated memory — not just block storage. The repair latency for in-memory EC is critical (DRAM-speed access expected), making repair pipelining techniques important.

**Production readiness:** Medium. Far memory systems (RDMA-accessed remote DRAM) are used at Google and Meta. EC for far memory reduces overhead vs replication. 2-3 years.

**Architect takeaway:** As far memory (RDMA DRAM) becomes a standard tier in hyperscale architectures, the fault tolerance mechanism for that tier matters. EC provides better space efficiency than replication at the cost of higher repair complexity — the same tradeoff as for block storage, but with much tighter latency constraints.

---

## 2025

### HiDPU: DPU-Oriented Hybrid Indexing for Disaggregated Storage
**Conference:** FAST 2025 | **Authors:** Zhu et al.

**What it does:** Hybrid index for DPU-based disaggregated storage that combines a learned index (compact, fits in DPU DRAM) with a traditional B-tree (for cold mappings, stored on SSD). Hot address translations use the learned model (sub-microsecond lookup); cold translations use B-tree lookup on SSD. Sized specifically for DPU memory and CPU constraints.

**Connection to your knowledge:** Month 3 Day 6 (learned indexes) + Month 2 Day 26 (metadata at scale). HiDPU is the production-context application of learned indexes: the resource constraints of DPU hardware make learned indexes practically necessary, not just theoretically interesting.

**Production readiness:** Medium. 1-3 years. DPU storage is production today; DPU-optimized index structures will follow.

**Architect takeaway:** When designing for resource-constrained nodes (DPU, SmartSSD, embedded controller), index structure must fit the node's resource profile. A standard B-tree may be too large for DPU DRAM. Learned indexes provide a 5-10× memory reduction for hot mappings at the cost of prediction errors requiring a fallback lookup.

**Open questions:** How does the learned model handle write-heavy workloads where the mapping distribution changes continuously?

---

### Scalio: DPU-based JBOF KV Store with NVMe-oF Target Offload
**Conference:** OSDI 2025 | **Authors:** Sun et al.

**What it does:** DPU-based JBOF (Just a Bunch of Flash) KV store that offloads the NVMe-oF target I/O path to RDMA NIC hardware, freeing DPU CPU for KV logic and index operations. Hot cached data served via RDMA direct reads (DPU CPU not involved). RDMA-based consistency protocol maintains linearizability.

**Conventional wisdom challenged:** Prior assumption: DPU handles the entire storage node software stack (NVMe-oF target + KV logic). Scalio shows the DPU CPU is insufficient for both simultaneously — the NVMe-oF target I/O path must be further offloaded to dedicated hardware (RDMA NIC with target offload capability). DPU is a waypoint, not the final destination.

**Connection to your knowledge:** Month 1 (NVMe-oF, SPDK) + Month 3 (hardware essentials). Scalio is the architectural answer to the DPU CPU bottleneck identified in the 2023 characterization paper above.

**Production readiness:** High. 1-2 years. NVIDIA BlueField-3 and ConnectX-7 both support NVMe-oF target offload. The design is directly implementable on shipping hardware.

**Architect takeaway:** DPU CPU is not the final offload destination — it is one layer in an offload stack. For high-IOPS storage nodes: NVMe-oF target I/O → RDMA NIC hardware; KV index operations → DPU CPU; complex operations (transactions) → host server CPU. Profile each layer's utilization before declaring the system fully optimized.

---

## 2026

---

### Here, There and Everywhere: The Past, the Present and the Future of Local Storage in Cloud
**Conference:** FAST 2026 ⭐ Best Paper
**Authors:** Leping Yang (SJTU), Yanbo Zhou, Gong Zeng et al. (Alibaba Group), Mariusz Barczak, Wayne Gao (Solidigm), Ruiming Lu, Erci Xu, Guangtao Xue (SJTU)

**What it does:**
Documents the full evolutionary arc of cloud local storage at Alibaba Cloud
across three hardware generations, providing the most complete public account
of how a hyperscaler actually builds and iterates local storage infrastructure.
The paper is organized around a taxonomy of limitations (LDL = Local Disk
Limitations, SWL = Software Limitations, HWL = Hardware Limitations) and
shows how each generation addressed the previous generation's dominant
bottleneck.

Three generations:

**ESPRESSO (user-space stack, baseline):**
Moved the I/O stack from kernel to user space (SPDK-based). Eliminated kernel
overhead, enabled SR-IOV for VM direct device assignment. Bottleneck: host
CPU still handles all I/O processing — at high IOPS, host CPU becomes the
limit (SWL_1: host CPU overhead).

**DOPPIO (ASIC-based DPU offload):**
Offloads the entire I/O stack to a custom ASIC DPU plugged into the host PCIe
bus. Each DPU manages two PCIe Gen3 NVMe SSDs via on-chip PCIe Root Complex.
NVMe namespaces registered as VFs (SR-IOV), assigned directly to VMs.
Result: host CPU freed entirely. Performance ceiling: one DPU per two Gen4
SSDs achieves max ~1.3M IOPS — DPU ASIC becomes the bottleneck (HWL_2:
ASIC is inflexible, hard to add emerging features, limits IOPS at scale).

**RISTRETTO (ASIC + SoC DPU, hybrid):**
PCIe extension card with multiple NVMe SSDs installed. DPU now has both an
ASIC (for fixed-function high-throughput I/O) and an ARM Cortex-A72 SoC
(for flexible software-defined features). SPDK poller on SoC handles block
abstraction, LVM, RAID, caching, and FTL for ZNS SSDs. ASIC handles DMA
and on-chip memory for offload and acceleration. Result: 8× NVMe SSDs,
30.72TB capacity, 48GB/s throughput, 7.2M IOPS total — 80% per-VD IOPS
increase over DOPPIO. Deployed to several thousand nodes as of 2023.

**Future direction (EBSX hybrid):**
Integrating Elastic Block Storage (EBS — Alibaba's disaggregated remote block
storage) as a fallback/overflow tier behind local storage. Local NVMe for
hot/latency-sensitive I/O; EBS (30µs latency, 6GB/s, up to 1M IOPS via
PMem + 100Gbps network) for availability and elasticity. This hybrid gives
the performance profile of local storage with the availability/scalability
guarantees of disaggregated storage — addressing LDL_1-3 (availability,
scalability, accessibility) that local storage inherently cannot provide.

**Conventional wisdom challenged:**
Prior assumption: the DPU offload architecture question is "ASIC vs SoC" —
pick one based on performance vs flexibility tradeoff. Alibaba's experience
shows neither is sufficient alone. ASIC (DOPPIO) is fast but inflexible —
new features (ZNS, encryption policy changes, new FTL designs) require ASIC
respins. SoC (ARM CPU) is flexible but not fast enough at peak IOPS.
RISTRETTO shows the answer is ASIC + SoC together: ASIC for the fixed
high-throughput data path, SoC for programmable control and feature logic.
This is a hardware architecture lesson, not just a storage lesson.

**Connection to your knowledge:**
This paper is the production validation and synthesis of multiple threads
from the storage research track:
- Month 3 hardware essentials (SPDK, NVMe-oF, DPU concepts) — ESPRESSO
  is exactly the SPDK user-space stack you studied
- The EuroSys 2023 DPU characterization paper above (DPU CPU bottleneck
  confirmed) — DOPPIO hit exactly this wall at 1.3M IOPS per DPU
- Scalio (OSDI 2025) — independently arrives at similar conclusions
  about DPU CPU as bottleneck, proposes RDMA NIC offload; RISTRETTO's
  ASIC handles the same problem differently (custom silicon vs commodity NIC)
- Month 3 Day 22 (tiered storage, EBSX hybrid) — the future direction
  is the tiered local+remote design you designed in the lab scenario

This is the best single paper to read to understand where cloud local storage
is architecturally in 2026 and why each design decision was made.

**Production readiness:** This IS production. RISTRETTO is deployed at
several thousand nodes. EBSX hybrid is the stated future direction.
Immediately applicable as a reference architecture for cloud local storage.

**Architect takeaway:**
The local storage architecture evolution shows a consistent pattern:
each generation optimizes the dominant bottleneck of the previous generation,
only to reveal the next bottleneck. ESPRESSO revealed CPU bottleneck →
DOPPIO offloaded CPU → DOPPIO revealed ASIC inflexibility bottleneck →
RISTRETTO added SoC for flexibility. The architectural lesson: identify
your current dominant bottleneck, solve it structurally (not by tuning),
and expect a new bottleneck to emerge one layer deeper.

The EBSX hybrid future direction is the most important architectural
signal: pure local storage and pure disaggregated storage are converging.
The right long-term architecture is a hybrid: local NVMe for the hot
latency-sensitive path, remote EBS for availability and elasticity.
This is not a compromise — it is the correct architecture for both
performance and operational requirements simultaneously.

**Open questions:**
- RISTRETTO's ASIC + SoC split: when a new storage feature is needed,
  who decides if it goes in ASIC (requires respin) vs SoC (software update)?
  What is the criteria for ASIC vs SoC placement of a new function?
- EBSX hybrid: the paper describes local + remote as the future but does
  not detail the failover policy. When does I/O switch from local NVMe to
  EBS? On local failure only, or also on local congestion?
- ZNS SSD support in RISTRETTO (via SoC FTL): does the FTL on SoC add
  latency compared to native ZNS operation? What is the overhead?
- At several thousand nodes, RISTRETTO is large but not hyperscale
  (Google/Meta have millions of nodes). Does the ASIC+SoC approach
  scale without ASIC respin as NVMe generations change (Gen4 → Gen5)?

---

### TODO
- [ ] OSDI 2026, EuroSys 2026, ATC 2026 disaggregated storage papers

### Research Directions to Watch
- **ASIC+SoC DPU as the standard:** RISTRETTO's hybrid ASIC+SoC model
  will likely become the reference architecture for cloud local storage DPUs
- **Local + remote hybrid:** EBSX-style hybrid (local NVMe + remote EBS
  as availability tier) as the standard cloud local storage architecture
- **CXL pooling + storage:** CXL 2.0 memory pooling combined with local NVMe
- **Multi-tenant RISTRETTO-class storage:** per-tenant isolation on
  ASIC+SoC DPU nodes (NVM Sets, per-tenant QoS at ASIC level)
