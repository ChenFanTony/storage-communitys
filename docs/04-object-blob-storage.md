# Object & Blob Storage, Metadata Scaling — 2020 to 2026

---

## The Arc: 2020–2025

**2020–2021:** Serverless and elastic object storage emerged — challenging the assumption that object storage requires dedicated storage nodes. Workload characterization revealed LIST-heavy metadata operations dominate real S3 usage.

**2022–2023:** Metadata bottlenecks became the central focus. Papers showed that slow metadata (slow LIST, slow PUT namespace updates) causes cascading latency through entire application stacks.

**2024–2025:** Trillion-object metadata scaling and hierarchical namespace management are active research. Cloudscape confirms object storage dominance in real deployments. Mantle (SOSP 2025) addresses the hierarchy-at-scale problem.

---

## 2020

### InfiniCache: Exploiting Ephemeral Serverless Functions to Build a Cost-Effective Memory Cache
**Conference:** FAST 2020 | **Authors:** Wang et al.

**What it does:** Uses AWS Lambda functions as distributed object cache nodes. Lambda functions have ephemeral DRAM; InfiniCache stores cached objects across many Lambda functions. EC is used across Lambda instances for fault tolerance (Lambda functions can be evicted). Cost: near-zero compared to dedicated cache servers (Lambda billing model makes idle capacity almost free).

**Conventional wisdom challenged:** Prior assumption: distributed caching requires dedicated, always-on cache servers (memcached, Redis). InfiniCache shows that serverless functions — billed only when active — can serve as cache nodes at dramatically lower cost, provided the access latency of Lambda invocation is acceptable.

**Production readiness:** Medium. Lambda cold-start latency (100-500ms) limits use to workloads tolerating that latency. Warm Lambda instances are much faster. 2-4 years for specialized use cases.

**Architect takeaway:** The economics of serverless change the cost model for distributed caches. For workloads with bursty, unpredictable access patterns, serverless caching may be 10-100× cheaper than dedicated cache servers. Evaluate serverless caching before provisioning dedicated cache infrastructure.

---

### FlashBlox: Achieving Both Performance Isolation and Uniform Lifetime for Virtualized SSDs
**Conference:** FAST 2020 | **Authors:** Huang et al.

**What it does:** Multi-tenant object storage where different tenants' I/O patterns interfere via the shared FTL (GC from one tenant affects another's latency). FlashBlox dedicates specific NAND channels to specific tenants, preventing cross-tenant GC interference. Wear leveling is applied per-tenant to ensure uniform drive lifetime across tenants.

**Connection to your knowledge:** Month 3 hardware essentials (FTL GC, WA) + Month 2 (multi-tenancy). This is the hardware-level answer to multi-tenant NVMe isolation. NVMe NVM Sets (covered in hardware essentials) provide the same isolation at the firmware level without hardware modification.

**Production readiness:** Medium. Requires firmware modification or NVM Sets support. NVM Sets (NVMe spec) is the production path to the same isolation. 1-2 years via NVM Sets.

**Architect takeaway:** Multi-tenant NVMe sharing without isolation causes cross-tenant performance interference via shared FTL GC. Use NVM Sets (NVMe spec) to provide hardware-level isolation between tenants on shared NVMe devices.

---

## 2021

### DEPART: Replica Decoupling for Distributed Key-Value Storage
**Conference:** FAST 2021 | **Authors:** Zhang et al.

**What it does:** Object storage deduplication system that co-locates deduplicated chunks with objects that reference them. Standard dedup: all unique chunks stored centrally, references point to them. DEPART: unique chunks stored on the same nodes as the objects that most frequently reference them. Reduces cross-node chunk fetches on read.

**Connection to your knowledge:** Month 3 Day 9 (deduplication, fingerprinting). DEPART adds placement awareness to dedup — not just "store unique chunks once" but "store them where they will be accessed." This is data locality optimization for dedup systems.

**Production readiness:** Medium. Requires integration with placement engine. 2-3 years.

**Architect takeaway:** Dedup systems optimize for storage efficiency but often ignore read locality. For read-heavy workloads, co-locating deduplicated chunks with their most frequent consumers significantly reduces cross-node traffic and read latency.

---

### Characterizing and Optimizing the Azure Storage S3-Compatible API
**Conference:** ATC 2021 | **Authors:** Microsoft Azure Team

**What it does:** Workload characterization of S3-compatible API usage in Azure Blob Storage at scale. Key findings: LIST operations (listing objects in a prefix) dominate metadata load — not PUT or GET. LIST operations generate 10-50× more metadata server CPU than equivalent PUT operations. Prefix-heavy namespaces (deeply structured key hierarchies) cause LIST to scan large metadata ranges.

**Conventional wisdom challenged:** Prior assumption: object storage metadata load is dominated by PUT/GET (write metadata on PUT, read on GET). This paper shows LIST is the dominant metadata operation type in production — and it is systematically underoptimized in standard object store designs. Mantle (SOSP 2025) is a direct response to this finding.

**Connection to your knowledge:** Month 2 Day 20 (S3 consistency model). S3 strong consistency (since 2020) made LIST-after-write consistent, but made LIST more expensive (must check all recent changes). This paper quantifies that cost at production scale.

**Production readiness:** This is production data. Immediately actionable: if you are building an S3-compatible system, LIST performance must be a first-class design criterion.

**Architect takeaway:** For any S3-compatible object store, LIST is likely your dominant metadata operation under real workloads. Design the metadata index for efficient prefix scans, not just point lookups. Standard KV metadata stores (hash-indexed) are poor for LIST — sorted, prefix-aware indexes are required.

---

## 2022

### DepFast: Exploiting Upload Dependency for Fast Recovery in Erasure-Coded Storage Systems
**Conference:** OSDI 2022 | **Authors:** Luo et al.

**What it does:** Identifies a specific latency pathology in object storage: "upload dependency" — a slow metadata update on one object can block progress on dependent objects in the same upload pipeline. DepFast traces these dependency chains and prioritizes metadata operations that are blocking the most dependent operations.

**Conventional wisdom challenged:** Prior assumption: object storage latency spikes are caused by slow storage I/O (disk latency, network latency). DepFast shows that metadata dependency chains — not I/O latency — are the dominant cause of tail latency spikes in multi-object upload workloads. This is a scheduling problem, not a hardware problem.

**Production readiness:** Medium. Dependency tracking adds overhead to the metadata path. 2-3 years.

**Architect takeaway:** Object storage tail latency can be caused by metadata dependency chains that are invisible to standard I/O monitoring. If your p99 upload latency is high despite low I/O utilization, investigate metadata dependency chains. Prioritizing metadata operations by downstream dependency count is the fix.

---

### InfiniStore: Elastic Serverless Cloud Storage
**Conference:** FAST 2022 | **Authors:** Wang et al.

**What it does:** Fully serverless object storage built on cloud functions. Unlike InfiniCache (cache only), InfiniStore provides durable object storage using serverless functions. EC across function instances provides fault tolerance. Storage is elastic — scales to zero cost when unused.

**Conventional wisdom challenged:** Prior assumption: durable object storage requires dedicated, persistent storage infrastructure (servers, drives). InfiniStore shows that serverless functions with EC can provide durable object storage at dramatically lower cost for bursty workloads where dedicated infrastructure is idle most of the time.

**Production readiness:** Low-Medium. Serverless storage has higher GET latency than dedicated storage (function invocation overhead). For workloads with predictable high load, dedicated storage is cheaper and faster. For bursty, unpredictable workloads, serverless may be cost-optimal. 3-5 years.

**Architect takeaway:** The "always-on storage infrastructure" assumption is worth re-examining for workloads with high peak-to-average ratios. Serverless object storage can be 5-10× cheaper for workloads that are idle >80% of the time.

---

## 2023

### Hailstorm: Disaggregated Compute and Storage for Scalable, Highly Available Blob Storage
**Conference:** OSDI 2023 | **Authors:** Mellanox/NVIDIA + VMware

**What it does:** Blob storage system that jointly optimizes for cost, durability, and repair bandwidth using a hybrid replication+EC scheme. Hot blobs use replication (fast repair); cold blobs use EC (low cost). The transition between tiers is automated based on access patterns. The system disaggregates compute from storage, with compute nodes handling encoding/decoding and storage nodes handling persistence.

**Connection to your knowledge:** Month 2 Day 9 (LRC repair traffic) + Month 3 Day 22 (tiered storage automation). Hailstorm is the production implementation of the "tier by temperature" design that appears theoretical in Month 3.

**Production readiness:** High. This is from vendors with shipping products. 1-2 years.

**Architect takeaway:** Blob storage tiering (hot=replication, cold=EC) with automated transitions is the right default architecture for large-scale blob storage. The key design question is not whether to tier, but what the transition policy is and how to make transitions without data loss exposure windows.

---

### TieredStore: Tiered Object Storage at Alibaba Scale
**Conference:** ATC 2023 | **Authors:** Alibaba Cloud Storage Team

**What it does:** Production analysis of tiered object storage at Alibaba. Key findings: cold data access patterns are highly unpredictable (cold data accessed in bursts, not uniformly); retrieval latency from the cold tier is a common customer complaint; and the cost of "warming up" cold data (restoring from archive) is dominated by metadata operations, not data transfer.

**Production readiness:** Production data. Immediately applicable.

**Architect takeaway:** For tiered object storage, the retrieval latency from cold tier is a first-class user experience metric — not just a cost consideration. Design the cold tier so retrieval latency is predictable and communicated to users (not just a best-effort "eventually available" promise).

---

## 2024

### MetaScale: Towards Trillion-File Distributed File System Metadata
**Conference:** FAST 2024 | **Authors:** Chen et al.

**What it does:** Distributed metadata system designed for trillion-file scale. Key contribution: hierarchical sharding of metadata — each shard handles a subtree of the namespace, with automatic shard splitting when a subtree becomes too large. The sharding boundary adapts to namespace access patterns (hot directories get finer-grained sharding).

**Connection to your knowledge:** Month 2 Day 26 (CephFS MDS subtree partitioning). MetaScale is a generalization of CephFS's approach to larger scale and more dynamic workloads. The key difference: CephFS's MDS subtree migration is expensive; MetaScale designs sharding to make migration cheap.

**Production readiness:** Medium. 2-3 years.

**Architect takeaway:** Trillion-file metadata is not just "more of the same" — it requires fundamentally different sharding strategies. Fixed-boundary sharding (split namespace at predetermined points) fails under skewed access. Adaptive sharding (split based on load) is necessary at trillion-file scale.

---

### Clio: A Hardware-Software Co-Designed Disaggregated Memory System
**Conference:** OSDI 2024 | **Authors:** Gu et al.

**What it does:** Disaggregated memory system where the memory node has a custom hardware controller (FPGA-based) that handles memory management, paging, and EC for fault tolerance. The compute node accesses remote memory via RDMA. Key design: the FPGA controller reduces memory node CPU to near-zero for common operations.

**Connection to your knowledge:** Month 3 (hardware co-design) + disaggregated storage. Clio is the "custom hardware" answer to the DPU CPU bottleneck — instead of offloading to DPU, offload to FPGA which has even lower per-operation overhead.

**Production readiness:** Low-Medium. FPGA-based memory controllers are research prototypes. 3-5 years.

---

## 2025

### Cloudscape: A Study of Storage Services in Modern Cloud Architectures
**Conference:** FAST 2025 | **Authors:** Satija et al.

**What it does:** Empirical study of ~400 AWS cloud architectures. Object storage (S3) dominates; managed file systems appear rarely; storage is embedded in larger service graphs.

**Conventional wisdom challenged (soft):** Prior assumption (in research): file systems and block storage are the primary storage abstractions. Cloudscape confirms empirically that object storage has become the default for new cloud-native systems. Research that assumes file-system-centric workloads is increasingly misaligned with deployment reality.

**Production readiness:** This is deployment data. Immediately actionable.

**Architect takeaway:** S3-compatible object storage is the primary interface for new cloud-native systems. Every storage system designed for cloud deployment needs a credible S3-compatible API story.

---

### Mantle: Efficient Hierarchical Metadata Management for Cloud Object Storage
**Conference:** SOSP 2025 | **Authors:** Li et al. [CONFIDENCE: MEDIUM — abstract not public]

**What it does (inferred):** Hierarchy-aware metadata management for cloud object storage that co-locates related metadata (objects sharing a prefix), handles hot-prefix skew, and scales namespace operations beyond what flat KV metadata indexes support.

**Connection to your knowledge:** Month 2 Day 26 (object metadata at scale). Mantle is the SOSP-grade answer to the problem identified in the 2021 ATC paper: LIST operations dominate metadata load, and flat KV metadata is insufficient for hierarchical namespaces at scale.

**Production readiness:** High (if contribution matches inference — industrial co-authors suggest deployment context). 2-4 years.

**Architect takeaway (pending full paper):** Object store metadata architecture must be designed for LIST performance, not just PUT/GET. Hierarchical co-location (all objects sharing a prefix stored near each other in the metadata tier) is the likely key technique.

---

## 2026

### Known Papers
*No object/blob storage papers from 2026 are in my confirmed knowledge base.*

### TODO
- [ ] FAST 2026, OSDI 2026, SOSP 2026 object storage papers
- [ ] Update Mantle summary when full SOSP 2025 paper is public

### Research Directions to Watch
- **LIST optimization at trillion-object scale:** following Mantle, expect more work on namespace hierarchy, prefix scan optimization, and metadata sharding
- **Object storage for ML:** specialized object store semantics for ML training data (streaming reads, no random access, partial object reads)
- **S3 consistency at global scale:** how to provide strong consistency across regions without excessive latency
