# Best Papers in Storage-Related Conferences — 2020 to 2026

Best paper awards are a strong signal: the program committee selected these
as the highest-quality, most impactful papers of the year. Reading the best
papers gives a compressed view of what the community valued most each year.

This file lists **storage-relevant** best papers only. Many OSDI/SOSP best
papers are in unrelated areas (security, ML systems, networking) — those
are omitted. Where a best paper is not storage-relevant, it is noted briefly
for completeness.

---

## Confidence Notes

| Year/Conf | Confidence | Source |
|-----------|-----------|--------|
| FAST 2020–2026 | High | USENIX technical sessions pages, "Awarded Best Paper!" tag |
| OSDI 2020–2024 | High | USENIX technical sessions pages |
| OSDI 2025 | Medium | Program confirmed, checking for storage-relevant winners |
| SOSP 2021–2023 | Medium | Various institutional announcements |
| EuroSys 2020–2025 | Medium | Roger Needham PhD Award + best paper announcements |
| ATC 2020–2025 | Medium | USENIX technical sessions pages, partial coverage |

---

## 2020

### FAST 2020 Best Papers

**Paper 1: A Large-Scale Study of Flash Memory Failures in Production Storage Systems**
Maneas, Mahdaviani (Toronto), Emami (NetApp), Schroeder (Toronto)

The first large-scale field study of NAND SSDs in enterprise storage
systems — 1.4 million SSDs across 3 manufacturers, 18 models, SLC/cMLC/eMLC/3D-TLC.
Key findings: TLC is more reliable than expected in enterprise settings;
firmware version is a major reliability predictor; correlated failures
within RAID groups are more common than independent failure models assume.

**Storage-architect relevance:**
Directly informs drive selection and RAID configuration decisions.
The RAID correlated-failure finding is particularly important: if drives
from the same batch fail together, RAID-6 provides much less protection
than independent failure models predict. Month 3 hardware essentials
SMART monitoring recommendations draw on this paper's methodology.

**Conventional wisdom challenged:**
Prior assumption: TLC drives have poor enterprise reliability vs MLC.
This paper shows TLC enterprise drives perform comparably to MLC in
practice — the NAND cell type is less predictive of reliability than
firmware version and operational age.

---

**Paper 2: ORCA — Consistency-Aware Durability in Distributed Storage**
Ganesan, Alagappan, A. Arpaci-Dusseau, R. Arpaci-Dusseau (Wisconsin)

Introduces "consistency-aware durability" (CAD): a new approach where
durability guarantees are tied to consistency semantics rather than being
independent. Implements cross-client monotonic reads — reads from any
replica are guaranteed to see data at least as recent as a previous read
by any client (across failures and sessions). Built on ZooKeeper.

**Storage-architect relevance:**
The insight that consistency and durability are not independent is
important for distributed storage design. Most systems treat them
as separate knobs; CAD shows they interact in ways that can provide
stronger guarantees at lower cost.

**Topic file:** `05-distributed-consensus-storage.md`

---

### OSDI 2020 Best Papers (storage-relevant)

**Virtual Consensus in Delos**
Howard, Balakrishnan et al. (Facebook)

Virtualizes the consensus layer: storage services can switch consensus
protocols (Raft → Multi-Paxos → shared log) without downtime. The VirtualLog
abstraction separates reconfiguration logic from ordering logic.

**Storage-architect relevance:**
Delos is Facebook's production database. The paper shows that consensus
protocol flexibility is achievable in production — you don't have to
commit to one protocol forever at design time.

**Topic file:** `05-distributed-consensus-storage.md`

*(Other OSDI 2020 best papers: Byzantine Ordered Consensus — not storage-relevant; MAGE secure computation — not storage-relevant)*

---

## 2021

### FAST 2021 Best Paper

**Bento: Safe Rust Abstractions for File System Development in Linux**
Miller, Zhang, Chen, Jennings (UW), Chen (Rice), Zhuo (Duke), Anderson (UW)

Proposes a framework for writing Linux kernel file systems in safe Rust,
enabling: (1) rapid development without kernel crashes from memory bugs;
(2) live reloading of file system code without unmounting; (3) running
the same code in kernel space or user space for testing.

**Storage-architect relevance:**
Addresses the main practical barrier to custom file system development:
kernel development velocity is too slow and too risky. Bento makes
custom file systems a realistic option for production systems teams.

**Conventional wisdom challenged:**
Prior assumption: Linux kernel file system development requires C,
carries high bug risk, and requires reboots to test changes. Bento shows
safe Rust + live reload is achievable in the kernel context.

**Topic file:** `07-file-systems.md`

---

### OSDI 2021 Best Papers (storage-relevant)

*(OSDI 2021 best papers: Pollux (ML scheduling), MAGE (secure computation), DistAI (distributed invariant learning) — none are storage-specific. Noted for completeness.)*

Most impactful storage paper from OSDI 2021 not awarded but widely cited:
Sherman (RDMA B-tree) — covered in `03-disaggregated-storage.md`

---

## 2022

### FAST 2022 Best Paper

**WOM-v: Non-binary Voltage-Based Write-Once-Memory Codes for Improving QLC Drive Lifetime**
Jaffer, Mahdaviani (Toronto/Google), Schroeder (Toronto)

Write-Once-Memory (WOM) codes allow QLC NAND cells to be programmed
multiple times between erases by encoding multiple logical writes into
non-binary voltage states. Reduces erase cycles for QLC drives by 4.4–11.1×
for real-world workloads with minimal performance overhead.

**Storage-architect relevance:**
QLC drives have ~1/10 the endurance of MLC. WOM-v codes are a coding
technique to extend QLC lifetime significantly. This is a hardware/software
co-design solution at the coding layer — no hardware change required, only
a new encoding scheme in the FTL or host driver.

**Conventional wisdom challenged:**
Prior assumption: QLC endurance is fixed by physics (P/E cycle limit) and
can only be managed by over-provisioning or write throttling. WOM-v shows
that coding theory can extend QLC lifetime by treating the SSD as a
Write-Once-Memory — a fundamentally different abstraction.

**Topic file:** `06-storage-hardware-co-design.md`

---

### OSDI 2022 Best Papers (storage-relevant)

*(OSDI 2022 best papers: SOTER (trusted execution), SoCC Bolt (network) — not storage-specific. Storage-relevant paper from OSDI 2022: SMART RDMA adaptive radix tree, covered in `03-disaggregated-storage.md`)*

---

## 2023

### FAST 2023 Best Papers (two awarded)

**Paper 1: Perseus — Detecting Fail-Slow Faults in Cloud Storage with Fuzzy-Logic-Based Gray Failure Detection**
Lu, Xu (SJTU/Alibaba), Zhang (Xiamen Univ.), et al. (Alibaba)

Detects "fail-slow" storage devices — drives that still function but
with degraded performance. Uses a light regression-based model to pinpoint
fail-slow failures at drive granularity. Monitored 248K drives over 10
months, found 304 fail-slow cases.

**Storage-architect relevance:**
Month 3 Day 17 (gray failure detection) is directly informed by this
paper. Perseus is the production-grade implementation of gray failure
detection at scale. The 10-month, 248K drive deployment is the largest
published fail-slow detection study.

**Conventional wisdom challenged:**
Prior assumption: storage reliability monitoring should focus on hard
failures (drive returns errors). Perseus shows fail-slow (degraded
performance, not errors) is a significant and systematically detectable
failure mode that traditional SMART monitoring misses.

**Topic file:** `07-file-systems.md` (reliability section) and
`03-disaggregated-storage.md`

---

**Paper 2: ROLEX — A Scalable RDMA-Oriented Learned Key-Value Store for Disaggregated Memory Systems**
Li, Hua, Zuo, Chen, Sheng (HUST)

Ordered KV store for disaggregated memory systems using RDMA. Combines
learned indexes (compact, fast lookup) with a novel update protocol that
handles concurrent modifications to the learned model without requiring
server-side CPU involvement on reads.

**Storage-architect relevance:**
Learned indexes for disaggregated memory — validates HiDPU's (FAST 2025)
approach 2 years earlier. The RDMA-compatible learned index update protocol
is the key engineering contribution: learned indexes must handle updates,
and updates over RDMA are much harder than updates in local memory.

**Topic file:** `03-disaggregated-storage.md`

---

### OSDI 2023 Best Papers (storage-relevant)

*(Checking for storage-relevant OSDI 2023 best papers)*
Primary OSDI 2023 best papers were in ML systems and OS areas.
Most impactful storage paper: FUSEE (fully disaggregated KV store) —
covered in `03-disaggregated-storage.md`

---

## 2024

### FAST 2024 Best Papers (two awarded)

**Paper 1: An In-Depth Analysis of SSD Performance Degradation due to Fragmentation**
Jun, Park (SKKU), Kang (Samsung), Kim (Ajou), Seo (SKKU)

Investigates SSD performance degradation from file fragmentation across
three levels: kernel I/O path, host-storage interface, and NAND flash
internals. Key finding: contrary to prior literature, the primary cause
of degradation is not request splitting but **die-level collision** —
when file blocks are not placed on consecutive dies, parallel die
operations become serialized, causing severe throughput loss.

**Storage-architect relevance:**
File system fragmentation was believed to have minimal impact on SSDs
(sequential writes are fast, random reads are fast). This paper shows
fragmentation causes die-level collisions that serialize normally-parallel
NAND operations — a 2-5× throughput reduction for fragmented files.
Implication: SSD-aware file layout (contiguous placement, defragmentation)
still matters, for a different reason than it did for HDDs.

**Conventional wisdom challenged:**
Prior assumption: SSDs are immune to fragmentation problems because they
have no seek penalty. This paper shows SSDs have a different but equally
real fragmentation problem: die-level collision caused by non-contiguous
physical placement, not seek time.

**Topic file:** `06-storage-hardware-co-design.md`

---

**Paper 2: What's the Story in EBS Glory: Evolutions and Lessons in Building Cloud Block Storage**
Zhang, Xu, Wang et al. (Alibaba Group)

10-year retrospective on building Alibaba's Elastic Block Storage (EBS)
across three generations (EBS1→EBS2→EBS3):
- EBS1: design simplicity, basic replication
- EBS2: high performance and space efficiency (RDMA, EC)
- EBS3: minimizing network traffic amplification (EC-based replication
  optimization, reducing fan-out)

Key lessons: each generation addressed a different bottleneck; the shift
from "make it work" to "make it efficient" to "reduce network overhead"
is the natural evolution arc of cloud storage systems.

**Storage-architect relevance:**
The EBS paper is the production counterpart to the local storage "Here,
There and Everywhere" paper (FAST 2026). Together they document Alibaba's
full storage stack evolution. The network traffic amplification insight in
EBS3 — reducing the number of replicas/EC shards that must be written per
user write — is directly relevant to any cloud block storage design.

**Conventional wisdom challenged:**
Prior assumption: cloud block storage design is primarily a performance
optimization problem. EBS's decade-long evolution shows it is primarily
an economics problem — network bandwidth cost dominates, and reducing
amplification is the key lever.

**Topic file:** `03-disaggregated-storage.md` and
`04-object-blob-storage.md`

---

### OSDI 2024 Best Papers (storage-relevant)

*(OSDI 2024 best papers include Anvil (cluster management verification) and others — reviewing for storage relevance)*

Most impactful storage papers from OSDI 2024: Carbink (far memory EC),
Clio (disaggregated memory hardware-software co-design) — both covered
in `03-disaggregated-storage.md`

---

## 2025

### FAST 2025 Best Papers (two awarded)

**Paper 1: Ananke — Transparent Recovery from Unexpected Filesystem Failures in Microkernels**
(Authors from IBM research team)

Filesystem microkernel service that provides transparent recovery from
unexpected filesystem failures. Uses microkernel's unique ability to run
recovery code coordinated by the host OS at the moment of process crash.
Records key information not available during full-system crash recovery.
Achieves lossless recovery in >30,000 fault-injection experiments,
recovery in hundreds of milliseconds.

**Storage-architect relevance:**
Filesystem crash recovery time is a production SLA concern. Ananke shows
that microkernel architectures enable faster, more targeted recovery than
monolithic kernel file systems. Relevant for storage systems where file
system failures must not require full service restart.

**Conventional wisdom challenged:**
Prior assumption: filesystem crash recovery requires either full fsck
(slow) or journal replay (fast but loses some data). Ananke shows
microkernel isolation enables lossless recovery in milliseconds by
capturing additional state at failure time.

**Topic file:** `07-file-systems.md`

---

**Paper 2: Mooncake — A KVCache-centric Disaggregated Architecture for LLM Inference**
Qin, Li, He et al. (Moonshot AI / Tsinghua)

The serving platform for Kimi (LLM chatbot). Separates prefill and
decoding clusters, uses underexploited CPU/DRAM/SSD/NIC resources of GPU
clusters to build a disaggregated KVCache. The KVCache (attention key-value
pairs for LLM context) is treated as a first-class storage resource — not
a GPU-local cache. Increases effective request capacity by 59–498% while
maintaining latency SLOs.

**Storage-architect relevance:**
Mooncake is the clearest 2025 signal that AI/LLM inference is becoming
a major storage workload. The KVCache — gigabytes to terabytes of
attention data per inference session — requires storage-system thinking
(placement, tiering, eviction, disaggregation) that GPU teams don't
traditionally have. Storage architects will increasingly be needed
in AI infrastructure teams.

**Conventional wisdom challenged:**
Prior assumption: LLM inference is a GPU compute problem; storage is
just a checkpoint/model-weight concern. Mooncake shows that the KVCache
(inference working state) is a storage problem requiring disaggregation,
tiering, and placement policies — exactly the skills of storage architects.

**Topic file:** `04-object-blob-storage.md` (new AI storage sub-topic)

---

### OSDI 2025 Best Papers

*(OSDI 2025 proceedings confirmed; reviewing for storage-relevant best papers)*
Most storage-relevant OSDI 2025 papers (Scalio, Okapi, Stripeless) are
covered in topic files. Best paper award status for OSDI 2025 to be
confirmed from official announcement.

---

## 2026

### FAST 2026 Best Papers

**Here, There and Everywhere: The Past, the Present and the Future of Local Storage in Cloud** ⭐
Yang (SJTU), Zhou, Zeng, Zhang et al. (Alibaba Group), Barczak, Gao (Solidigm)

*(Full review in `03-disaggregated-storage.md` — 2026 section)*

Three-generation evolution of Alibaba Cloud local storage:
ESPRESSO (user-space SPDK) → DOPPIO (ASIC DPU offload) → RISTRETTO
(ASIC+SoC hybrid). Future: local NVMe + remote EBS hybrid tier.

**Cost-efficient Archive Cloud Storage with Tape: Design and Deployment**
Wang, Yang, Liu, Xiao (Tsinghua/Huawei Cloud) et al.

TapeOBS: archive storage service for Huawei Cloud using tape for
cost-efficient large-scale archival. Addresses tape's limitations
(limited drive count per library) with fully asynchronous tape pool,
batched data scheduling and EC, tape-tailored local storage engine.
Deployed since end of 2022, serving customers since 2024.

**Storage-architect relevance:**
Tape for cloud archive is increasingly relevant as cold data costs
become a significant portion of cloud storage spend. TapeOBS documents
the engineering challenges of tape at cloud scale — a rare published
treatment of this tier.

**Topic file:** `04-object-blob-storage.md` (archive tier sub-topic)

**SYSSPEC: Generative File Systems via LLM-based Formal Specification** ⭐
(Multiple authors)

Framework for generating and evolving file systems from LLM prompts
using formal-methods-inspired specifications (SYSSPEC) instead of
natural language. The LLM generates the file system implementation;
SYSSPEC provides the formal constraint layer that makes generation
reliable.

**Storage-architect relevance:**
Signals a future where file system variants (compression, encryption,
custom metadata) can be generated on-demand rather than requiring
expert kernel development. Currently research; 3-5 years to practical
tools.

**Topic file:** `07-file-systems.md`

---

## Best Paper Pattern Analysis: 2020–2026

Looking across 6 years of best papers, three patterns emerge:

**1. Production experience papers are consistently recognized (2020–2026)**
FAST 2020 (SSD field study), FAST 2024 (EBS decade), FAST 2026
(local storage evolution) — the community values honest, large-scale
production data. Papers that document what actually happens in
production, not just what should happen in theory, repeatedly win.

**2. Gray/fail-slow failures are a growing focus (2020–2023)**
FAST 2020 (SSD correlated failures), FAST 2023 (Perseus fail-slow
detection) — the field progressively moved from "hard failures are
the problem" to "degraded-but-running components are the real problem."

**3. AI/LLM as a new storage workload (2025–2026)**
Mooncake (FAST 2025) is the first best paper win for AI-driven storage.
KVCache disaggregation, inference-time storage SLOs, and DRAM/SSD/NIC
co-design for AI inference will likely dominate storage best papers
through 2026–2028. Storage architects who understand both storage
systems and AI inference requirements will be disproportionately
valuable.
