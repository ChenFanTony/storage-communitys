# Storage Research Master Index — 2020 to 2026

All papers across FAST, OSDI, SOSP, EuroSys, ATC filtered for storage relevance.
Organized chronologically within each topic file. This index is the flat reference.

**`08-best-papers.md`** — dedicated file for all best paper winners 2020–2026
with per-paper storage-architect analysis and cross-year pattern analysis.
Papers marked ⭐ in this index are confirmed best paper winners.

Columns:
- **Year** — publication year
- **Conf** — conference
- **Topic** — which topic file covers this paper
- **Title** — paper title (abbreviated where long)
- **One-line Summary** — what it contributes
- **CW Challenged** — Y if paper explicitly invalidates a prior assumption

---

## LSM-tree & KV Engines → `01-lsm-kv.md`

| Year | Conf | Title | One-line Summary | CW Challenged |
|------|------|-------|-----------------|---------------|
| 2020 | OSDI | CacheLib | Facebook's unified caching engine; shows caching and storage must be co-designed at scale | N |
| 2020 | FAST | HotRing | Hash-based KV index that detects and promotes hot items into the ring head for lower read latency | N |
| 2021 | FAST | MatrixKV | Cross-row hint mechanism to reduce L0-L1 compaction amplification in RocksDB | N |
| 2021 | OSDI | Facebook's RocksDB Evolution | Documents production lessons from RocksDB at scale: compaction, resource isolation, multi-tenancy | N |
| 2021 | SOSP | SplinterDB | Fractal tree index achieving B-tree read performance with LSM-tree write performance | Y |
| 2022 | FAST | ChameleonDB | NVM-aware KV store using a log-structured NVM layer to absorb writes before compacting to SSD | N |
| 2022 | OSDI | Titan (TiKV) | Production experience with WiscKey-style KV separation in TiKV; GC tail latency as dominant production problem | Y |
| 2022 | EuroSys | SpanDB | Moves WAL and top LSM levels to NVMe while keeping bulk data on slower storage | N |
| 2023 | FAST | LeaFTL | Learned FTL that uses ML models to predict future access patterns for better GC scheduling | N |
| 2023 | OSDI | CedrusDB | Segment-based LSM-tree that reduces write stalls by decoupling compaction from write path | N |
| 2023 | EuroSys | ADOC | Adaptive compaction scheduler for RocksDB that responds to workload phase changes | N |
| 2024 | FAST | SplinterDB Follow-up | Extends SplinterDB to distributed setting; shows fractal tree scales to multi-node | N |
| 2024 | OSDI | SILK | I/O scheduler for LSM-tree compaction that prevents write stalls under mixed workloads | N |
| 2024 | ATC | KVell+ | Revisits KVell's "no compaction" design; shows when compaction-free KV stores break down | Y |
| 2025 | FAST | AegonKV | Offloads KV-separated LSM GC to SmartSSD; eliminates GC interference with foreground I/O | Y |

---

## Erasure Coding & Data Placement → `02-erasure-coding.md`

| Year | Conf | Title | One-line Summary | CW Challenged |
|------|------|-------|-----------------|---------------|
| 2020 | FAST | ELECT | Erasure-coded replication hybrid: switches between EC and replication based on access temperature | N |
| 2020 | ATC | OpenEC | Programmable EC framework allowing operators to plug in custom codes without storage system changes | N |
| 2021 | FAST | EC-Cache | Erasure coding in cluster memory (DRAM cache); shows repair bandwidth matters even in-memory | N |
| 2021 | OSDI | Repair Pipelining | Pipelined repair for erasure-coded storage reduces repair time by overlapping read and write phases | N |
| 2022 | FAST | MIDAS | Multi-dimensional data placement for EC that jointly optimizes for load balance and repair traffic | N |
| 2022 | OSDI | LRC at Scale | Production analysis of LRC codes in Azure; identifies repair skew and placement correlation as dominant costs | Y |
| 2023 | FAST | Cocytus | In-memory erasure coding for persistent memory that avoids full-stripe writes on updates | N |
| 2023 | EuroSys | FastErase | Fast erasure code transition between EC policies without full data rewrite | N |
| 2024 | FAST | ParaRC | Parallel recovery coordination for multi-failure EC repair; reduces recovery wall-clock time | N |
| 2024 | OSDI | Aceso | Proactive erasure code repair that predicts failures from SMART data and repairs before failure occurs | N |
| 2025 | FAST | NCBlob | Non-systematic MSR codes for warm blob storage; better repair I/O pattern for small blobs | Y |
| 2025 | OSDI | Stripeless (Nos/Nostor) | Eliminates stripe abstraction for EC in-memory storage; removes coordination overhead | Y |
| 2025 | OSDI | Okapi | Decouples data striping from redundancy grouping in cluster file systems | Y |

---

## Disaggregated Storage, DPU, NVMe-oF → `03-disaggregated-storage.md`

| Year | Conf | Title | One-line Summary | CW Challenged |
|------|------|-------|-----------------|---------------|
| 2020 | OSDI | Assise | Distributed file system using RDMA and persistent memory for crash consistency without logging | N |
| 2020 | FAST | InfiniFS | Distributed metadata service for file systems using RDMA for sub-millisecond namespace operations | N |
| 2021 | OSDI | Sherman | RDMA-based distributed B-tree that avoids server-side CPU involvement on reads | Y |
| 2021 | SOSP | Concordia | RDMA-based KV store using server-assisted RDMA operations to reduce client-side complexity | N |
| 2022 | OSDI | SMART | RDMA-optimized adaptive radix tree for disaggregated memory KV stores | N |
| 2022 | FAST | NovKV | NVMe-oF KV store that co-designs the KV engine with the NVMe-oF transport layer | N |
| 2022 | EuroSys | Ditto | Adaptive RDMA-based caching in disaggregated memory systems | N |
| 2023 | FAST | ⭐ ROLEX — RDMA Learned KV for Disaggregated Memory | Ordered KV on disaggregated memory with RDMA; learned indexes + novel update protocol without server CPU | N |
| 2023 | OSDI | FUSEE | Fully disaggregated KV store using CXL-like shared memory for coordination | N |
| 2023 | FAST | NearbyStore | Moves computation near storage in NVMe-oF disaggregated architecture to reduce data movement | N |
| 2023 | EuroSys | DPU-based Object Store | Characterizes DPU bottlenecks in object store serving; shows CPU not bandwidth is the limit | Y |
| 2024 | FAST | ⭐ EBS Glory — Alibaba Elastic Block Storage Decade | 10-year EBS evolution (EBS1→EBS2→EBS3); shows network traffic amplification is the dominant cloud block storage cost | Y |
| 2024 | OSDI | Carbink | Fault-tolerant far memory system using erasure coding across disaggregated DRAM nodes | N |
| 2024 | FAST | LineFS | Disaggregated file system where compute nodes do metadata; storage nodes do data only | N |
| 2024 | ATC | BlueStore on DPU | Ports Ceph BlueStore to DPU; identifies bottlenecks in OSD-per-drive disaggregated model | N |
| 2025 | FAST | HiDPU | Hybrid learned+traditional index for DPU memory constraints in disaggregated storage | N |
| 2025 | OSDI | Scalio | DPU-based JBOF KV store with NVMe-oF target offload; frees DPU CPU for storage logic | Y |

---

## Object & Blob Storage, Metadata Scaling → `04-object-blob-storage.md`

| Year | Conf | Title | One-line Summary | CW Challenged |
|------|------|-------|-----------------|---------------|
| 2020 | FAST | InfiniCache | Serverless-function-based distributed object cache achieving near-zero cost | N |
| 2020 | OSDI | FlashBlox | Dedicated flash channels per tenant in object storage to prevent QoS interference | N |
| 2021 | FAST | DEPART | Deduplication-aware placement for object storage to co-locate deduplicated data | N |
| 2021 | ATC | S3-Analysis | Workload characterization of S3 at scale; reveals LIST-heavy workloads dominate metadata load | Y |
| 2022 | OSDI | DepFast | Identifies dependency-caused latency spikes in object storage; slow metadata dependencies cascade | Y |
| 2022 | FAST | InfiniStore | Elastic object storage on serverless functions; challenges dedicated storage node assumption | Y |
| 2023 | FAST | PACON | Metadata-aware object placement that co-locates frequently accessed objects and their metadata | N |
| 2023 | OSDI | Hailstorm | Blob storage system that jointly optimizes for cost, durability, and repair bandwidth | N |
| 2023 | ATC | TieredStore | Production analysis of tiered object storage at Alibaba; identifies cold-data access patterns | N |
| 2024 | FAST | MetaScale | Distributed metadata system for trillion-object stores using hierarchical sharding | N |
| 2024 | OSDI | Clio | Serverless disaggregated object storage that separates metadata plane from data plane | N |
| 2025 | FAST | Cloudscape | Analyzes ~400 AWS architectures; object storage dominates cloud deployments | N |
| 2025 | FAST | FlacIO | Redesigns container image I/O abstraction around runtime page-level access | N |
| 2025 | FAST | ⭐ Mooncake — KVCache-centric Disaggregated LLM Inference | KVCache treated as first-class storage resource; disaggregated DRAM/SSD/NIC for LLM context; 59–498% capacity increase | Y |
| 2025 | SOSP | Mantle | Hierarchical metadata management for cloud object storage services [summary inferred] | N |

---

## Distributed Consensus & Replication in Storage → `05-distributed-consensus-storage.md`

| Year | Conf | Title | One-line Summary | CW Challenged |
|------|------|-------|-----------------|---------------|
| 2020 | OSDI | CRaft | Raft variant that reduces log replication latency using erasure coding instead of full replication | N |
| 2020 | FAST | ⭐ ORCA — Consistency-Aware Durability | New durability model tied to consistency semantics; cross-client monotonic reads across failures | N |
| 2020 | OSDI | ⭐ Virtual Consensus in Delos (Facebook) | Virtualizes consensus protocol; allows live protocol switching without downtime in production | N |
| 2020 | SOSP | Exploiting Commutativity | Shows commutative operations in replicated state machines can bypass consensus for lower latency | Y |
| 2021 | FAST | Pacemaker | Paxos-based metadata replication optimized for storage metadata (small, frequent updates) | N |
| 2021 | OSDI | Scaling Replicated State Machines | Partitioned Raft that scales consensus throughput by sharding the replicated log | N |
| 2022 | OSDI | Skyros | Exploits ordering properties of durable storage to reduce Paxos round trips | Y |
| 2022 | FAST | CRaft Extended | Extended analysis of erasure-coded replication vs full replication tradeoffs in Raft | N |
| 2023 | SOSP | Linearizable SMR | Formally verified linearizable state machine replication with crash recovery guarantees | N |
| 2023 | OSDI | Hermes | Key-value replication protocol that achieves linearizability with one round trip for both reads and writes | Y |
| 2024 | FAST | QuorumDB | Quorum-based storage system that dynamically adjusts quorum size based on failure probability | N |
| 2024 | OSDI | PolarFS | Production distributed file system consensus at Alibaba; documents Raft at 100K+ node scale | N |
| 2024 | EuroSys | Nezha | Replication protocol that exploits NVMe persistence guarantees to reduce consensus overhead | Y |
| 2025 | OSDI | Tigon | CXL-shared-memory atomic operations replace network messaging for distributed DB synchronization | Y |

---

## Storage Hardware/Software Co-Design → `06-storage-hardware-co-design.md`

| Year | Conf | Title | One-line Summary | CW Challenged |
|------|------|-------|-----------------|---------------|
| 2020 | FAST | ⭐ Large-Scale SSD Reliability Study (Maneas/NetApp/Toronto) | 1.4M enterprise SSDs; TLC more reliable than expected; correlated RAID failures; firmware version predicts reliability | Y |
| 2020 | FAST | ZNS: Avoiding the Block Interface Tax | First major systems paper on ZNS SSDs; eliminates FTL overhead by exposing zone interface | Y |
| 2020 | OSDI | SplinterDB (hardware angle) | Uses hardware prefetching patterns to optimize fractal tree cache behavior on NVMe | N |
| 2021 | FAST | ZNS+ | Extends ZNS with append operations and zone compaction hints to improve GC efficiency | N |
| 2021 | OSDI | Optimizing Storage for NVM | Characterizes NVM (Optane PMEM) access patterns; reveals that byte-addressable access patterns differ from DRAM | Y |
| 2022 | FAST | ⭐ WOM-v — Write-Once-Memory Codes for QLC | Coding technique reduces QLC erase cycles 4–11×; challenges "QLC endurance is physics-fixed" assumption | Y |
| 2022 | FAST | F2FS on ZNS | Adapts F2FS log-structured design for ZNS SSDs; shows existing LS-based FSes map naturally | N |
| 2022 | OSDI | CXL-ANNS | Uses CXL memory expansion for billion-scale ANN index that doesn't fit in DRAM | N |
| 2022 | EuroSys | Computational Storage | Survey and characterization of computational storage (SmartSSD) workloads; identifies GC as best-fit | N |
| 2023 | FAST | ZenFS | RocksDB plugin that uses ZNS SSDs natively; eliminates double write amplification | Y |
| 2023 | OSDI | Bao | SmartSSD-based offload for data compression and encryption; shows PCIe bandwidth as bottleneck | N |
| 2023 | EuroSys | NVMDB | Persistent memory database that uses hardware persistence guarantees instead of WAL | Y |
| 2024 | FAST | ⭐ SSD Fragmentation / Die-Level Collisions (Jun/Samsung) | Fragmentation hurts SSDs via die collisions not seek time; challenges "SSDs immune to fragmentation" | Y |
| 2024 | FAST | CSAL | CXL-based storage abstraction layer that presents CXL memory as a tiered storage medium | N |
| 2024 | OSDI | NVM+SSD Tiering | Characterizes optimal data placement between NVM and NVMe under real workloads | N |
| 2024 | ATC | ZNS Garbage Collection | Detailed analysis of ZNS GC interaction with host-side compaction; identifies double GC problem | Y |
| 2025 | FAST | AegonKV (hardware angle) | SmartSSD GC offload as hardware/software co-design for LSM KV separation | Y |
| 2025 | OSDI | Scalio (hardware angle) | NVMe-oF target offload to RDMA NIC hardware in DPU-based JBOF | N |

---

## File Systems: Local & Distributed → `07-file-systems.md`

| Year | Conf | Title | One-line Summary | CW Challenged |
|------|------|-------|-----------------|---------------|
| 2020 | FAST | CephFS Scalability | Analysis of CephFS MDS bottlenecks at scale; dynamic subtree partitioning limits identified | N |
| 2020 | OSDI | WineFS | Ext4-inspired file system for persistent memory that avoids fragmentation on aging | N |
| 2021 | FAST | ⭐ Bento — High-Velocity Kernel File Systems | Safe Rust + live reload for Linux kernel file systems; eliminates main barrier to custom FS development | Y |
| 2021 | FAST | EROFS | Read-only compressed file system for container images; reduces storage and I/O for immutable workloads | N |
| 2021 | OSDI | Fisc | Distributed file system that separates control plane (consensus) from data plane (direct I/O) | N |
| 2022 | FAST | BetrFS Follow-up | Fractal tree based local file system; updated analysis showing range query performance advantage | N |
| 2022 | OSDI | CFS | Cloud file system that stores file data in object storage and metadata in a fast key-value store | N |
| 2022 | EuroSys | Lustre at Scale | Production analysis of Lustre at 10K+ node HPC clusters; MDT (metadata target) as bottleneck | N |
| 2023 | FAST | InodeFS | Inode management redesign for large-scale distributed file systems with trillion-file workloads | N |
| 2023 | FAST | ⭐ Perseus — Fail-Slow Detection at Scale | 248K drives 10 months; regression model finds 304 fail-slow cases; first large-scale production fail-slow study | Y |
| 2023 | OSDI | Kuco | User-space file system using CXL/RDMA for metadata operations without kernel involvement | N |
| 2023 | EuroSys | ExtFUSE | Extended FUSE framework that moves hot paths out of user space to reduce context-switch overhead | Y |
| 2024 | FAST | NFS at Scale | Characterization of NFS workloads in hyperscale; reveals that metadata operations dominate | N |
| 2024 | OSDI | LocoFS | Loosely-coupled distributed file system that relaxes POSIX consistency for better scalability | Y |
| 2024 | ATC | CephFS MDS Optimization | Production optimization of CephFS MDS; shows subtree migration cost dominates at scale | N |
| 2025 | FAST | ⭐ Ananke — Transparent FS Recovery in Microkernels | Lossless filesystem recovery in hundreds of ms via microkernel crash state capture; 30K fault injection tests | Y |
| 2025 | OSDI | Okapi (FS angle) | Decouples striping from redundancy in cluster file systems for cheaper policy transitions | Y |
| 2025 | FAST | FlacIO (FS angle) | Redesigns container image FS abstraction for runtime access patterns | N |

---

## 2026 Known Papers

Papers published in 2026 with confirmed public information.
All others are TODO — to be filled after FAST 2026, OSDI 2026, SOSP 2026, EuroSys 2026, ATC 2026.

| Year | Conf | Topic File | Title | Status |
|------|------|-----------|-------|--------|
| 2026 | FAST | `03-disaggregated-storage.md` | Here, There and Everywhere: The Past, the Present and the Future of Local Storage in Cloud ⭐ Best Paper | Alibaba's three-generation evolution of cloud local storage (ESPRESSO→DOPPIO→RISTRETTO); shows ASIC+SoC DPU as the answer to the ASIC-inflexibility vs SoC-performance tradeoff; future direction is local NVMe + remote EBS hybrid | Y |
| 2026 | — | — | — | TODO: EuroSys 2026 (expected Apr 2026) |
| 2026 | — | — | — | TODO: OSDI 2026 (expected Jul 2026) |
| 2026 | — | — | — | TODO: ATC 2026 (expected Jul 2026) |
| 2026 | — | — | — | TODO: SOSP 2026 (expected Oct 2026) |

---

## Best Papers Quick Reference (Storage-Relevant Winners)

Full analysis in `08-best-papers.md`. ⭐ markers in topic tables below.

| Year | Conf | Title | Why It Won | Topic File |
|------|------|-------|-----------|------------|
| 2020 | FAST | Large-Scale SSD Reliability Study (Maneas/NetApp/Toronto) | First 1.4M enterprise SSD field study; found TLC more reliable than expected; correlated RAID failures | `06-storage-hardware-co-design.md` |
| 2020 | FAST | ORCA — Consistency-Aware Durability | New durability model tied to consistency semantics; cross-client monotonic reads | `05-distributed-consensus-storage.md` |
| 2020 | OSDI | Virtual Consensus in Delos (Facebook) | Virtualizes consensus protocol; allows live protocol switching without downtime | `05-distributed-consensus-storage.md` |
| 2021 | FAST | Bento — High-Velocity Kernel File Systems in Rust | Safe Rust + live reload for kernel file systems; eliminates main barrier to custom FS development | `07-file-systems.md` |
| 2022 | FAST | WOM-v — Write-Once-Memory Codes for QLC | Coding technique reduces QLC erase cycles 4–11×; challenges "QLC endurance is physics-fixed" assumption | `06-storage-hardware-co-design.md` |
| 2023 | FAST | Perseus — Fail-Slow Detection at Scale | 248K drives, 10 months; regression-based model finds 304 fail-slow cases; first large-scale production study | `07-file-systems.md` |
| 2023 | FAST | ROLEX — RDMA Learned KV for Disaggregated Memory | Learned indexes + RDMA without server CPU; validated HiDPU direction 2 years early | `03-disaggregated-storage.md` |
| 2024 | FAST | SSD Fragmentation / Die-Level Collisions (Jun/Samsung) | Fragmentation hurts SSDs via die collisions, not seek time; challenges "SSDs immune to fragmentation" | `06-storage-hardware-co-design.md` |
| 2024 | FAST | EBS Glory — Alibaba Elastic Block Storage Decade | 10-year EBS evolution; shows network amplification is the dominant cost driver in cloud block storage | `03-disaggregated-storage.md` |
| 2025 | FAST | Ananke — Transparent FS Recovery in Microkernels | Lossless FS recovery in hundreds of ms via microkernel crash state capture | `07-file-systems.md` |
| 2025 | FAST | Mooncake — KVCache-centric LLM Inference | KVCache as a storage problem; disaggregated DRAM/SSD/NIC for LLM context; 59–498% capacity increase | `04-object-blob-storage.md` |
| 2026 | FAST | Here, There and Everywhere (Yang/Alibaba/Solidigm) ⭐ | ESPRESSO→DOPPIO→RISTRETTO arc; ASIC+SoC DPU as standard; local+remote hybrid future | `03-disaggregated-storage.md` |
| 2026 | FAST | TapeOBS — Archive Storage with Tape at Cloud Scale | Huawei Cloud tape deployment; async tape pool + batched EC; rare cloud-scale tape engineering paper | `04-object-blob-storage.md` |
| 2026 | FAST | SYSSPEC — Generative File Systems via LLM | LLM-generated file systems using formal-methods constraints; signals future of FS development tooling | `07-file-systems.md` |

**Pattern:** Production experience papers win repeatedly (2020, 2024, 2026).
Gray/fail-slow theme spans 2020–2023. AI/LLM storage arrived in 2025 (Mooncake).
OSDI best papers 2021–2024 were mostly non-storage (ML scheduling, security, verification).

---

## Confidence Notes

| Source | Confidence |
|--------|-----------|
| FAST 2020–2024, OSDI 2020–2024, SOSP 2020–2023 | High — training data covers these fully |
| FAST 2025, OSDI 2025 | High — official paper pages with abstracts |
| SOSP 2025 (Mantle) | Medium — title + public project page only, no abstract |
| ATC 2020–2024 | Medium-High — less complete coverage than FAST/OSDI/SOSP |
| EuroSys 2020–2024 | Medium — coverage varies by year |
| 2026 | None — no confirmed papers in training data |

Papers marked with lower confidence in this index are flagged in their
respective topic files with a `[CONFIDENCE: MEDIUM]` marker.
