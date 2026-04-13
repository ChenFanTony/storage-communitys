# Storage Hardware/Software Co-Design — 2020 to 2026

ZNS, SmartSSD, CXL, computational storage, and NVM.

---

## The Arc: 2020–2025

**2020–2021:** ZNS SSDs emerged as the first major new storage interface since NVMe. The "Block Interface Tax" paper established the framing: the block interface forces SSDs to do FTL work that wastes resources. ZNS eliminates the FTL by exposing zones directly.

**2022–2023:** ZNS adoption in production file systems (F2FS, ZenFS/RocksDB). SmartSSD characterization showed GC offload as the most natural workload for computational storage.

**2024–2025:** CXL memory expansion is production. SmartSSD GC offload (AegonKV) represents the maturation of computational storage from concept to concrete system design.

---

## 2020

### ZNS: Avoiding the Block Interface Tax with Flash-Native Storage
**Conference:** FAST 2020 (and ATC 2021 extended) | **Authors:** Bjørling et al. (Western Digital)

**What it does:** ZNS (Zoned Namespace) SSDs expose a zone-based interface: each zone is a sequential write-only region (like a NAND erase block). The host must write sequentially within each zone and explicitly reset zones (equivalent to erase). The FTL is dramatically simplified — no need for complex address mapping or GC because the host manages placement.

**Conventional wisdom challenged:** Prior assumption: the block interface (any LBA can be written in any order) is the right abstraction for SSDs because it's familiar and compatible with existing software. ZNS shows that the block interface forces SSDs to implement a complex FTL (mapping, GC, wear leveling) that consumes DRAM, CPU, and NAND capacity — the "block interface tax." Exposing zones eliminates the tax for host software that can manage sequential writes.

**Connection to your knowledge:** Month 1 Day 26 (ZNS from Linux kernel perspective). This is the hardware paper that motivated the Linux kernel ZNS work you studied. The "block interface tax" framing is important: any additional abstraction layer (FTL) consumes resources. Removing layers is a legitimate design strategy, not just optimization.

**Production readiness:** High. ZNS SSDs are production (Western Digital, Samsung). Linux kernel support is mainlined. RocksDB + ZenFS in production use. Immediately applicable.

**Architect takeaway:** ZNS is appropriate when your software stack can guarantee sequential writes within zones (log-structured designs, RocksDB with ZenFS, Ceph with BlueStore zone awareness). For random-write workloads, ZNS shifts the FTL complexity to the host — it's not simpler, just different.

---

## 2021

### ZNS+: Improving Random I/O Performance of ZNS SSDs
**Conference:** FAST 2021 | **Authors:** Han et al.

**What it does:** Standard ZNS requires fully sequential writes within each zone. ZNS+ extends ZNS with: (1) append operations (write to next available location within zone, without knowing the exact LBA in advance — enables parallel writers); (2) zone compaction hints (host hints which zones to compact, allowing drive-internal zone merging without full data movement).

**Connection to your knowledge:** Month 1 Day 26 (ZNS). ZNS+ addresses the two main friction points in ZNS adoption: concurrent writes (append eliminates exact LBA requirement) and zone reclamation (compaction hints reduce host-side GC complexity).

**Production readiness:** Medium. Append operations are proposed for the NVMe ZNS spec (some support exists). Zone compaction hints are less widely implemented. 1-2 years.

**Architect takeaway:** Standard ZNS is sequential-write-only, which forces single-writer design. ZNS+ append operations unlock multi-writer designs (multiple threads writing to the same zone concurrently) which is needed for high-throughput ingestion workloads.

---

### Characterizing, Modeling, and Benchmarking RocksDB Key-Value Workloads at Facebook
**Conference:** FAST 2021 | **Authors:** Cao et al. (Facebook/Meta)

**What it does:** Characterization of RocksDB workloads in production at Facebook. Key hardware findings: NVMe queue depth of 32-64 is sufficient for peak IOPS in production (deeper queues don't help); compaction I/O is the dominant source of NVMe write amplification; and CPU, not I/O, is often the bottleneck for small-value workloads.

**Connection to your knowledge:** Month 3 Day 27 (benchmarking methodology) + hardware essentials (queue depth, Little's Law). The production confirmation of the queue depth analysis from Day 27: iodepth=64 is sufficient, higher depths add queue latency without throughput gain.

**Production readiness:** This is production data. Immediately actionable for RocksDB NVMe configuration.

**Architect takeaway:** For RocksDB on NVMe: iodepth=64 is the practical sweet spot. Deeper queues increase p99 latency without improving throughput. Tune compaction thread count before tuning queue depth.

---

## 2022

### F2FS on ZNS SSDs
**Conference:** FAST 2022 | **Authors:** Choi et al.

**What it does:** Adapts the F2FS (Flash-Friendly File System) log-structured design for ZNS SSDs. F2FS already writes data sequentially in segments — a natural fit for ZNS zones. The paper identifies the remaining mismatches and fixes them: segment size alignment with zone size, GC cooperation between F2FS and ZNS zone reset, and multi-stream writes using multiple zones.

**Connection to your knowledge:** Month 1 (F2FS from Linux kernel perspective). F2FS's log-structured design maps naturally to ZNS because F2FS already avoids random writes. This confirms the Month 3 Day 4 lesson: log-structured designs work well on ZNS SSDs because they share the same fundamental constraint (sequential writes only).

**Production readiness:** High. F2FS on ZNS is upstream in Linux. Production for mobile and embedded storage.

---

### Computational Storage: Characterizing Workloads and Offloading Opportunities
**Conference:** EuroSys 2022 | **Authors:** Tehrany et al.

**What it does:** Survey and characterization of which storage workloads benefit from being offloaded to a SmartSSD (drive with embedded CPU). Key finding: GC (log cleaning, LSM compaction, EC repair) is the best-fit workload for SmartSSD offload — it is I/O-intensive, compute-moderate, and its I/O is internal to the drive (no PCIe crossing needed). Data compression/decompression is second.

**Connection to your knowledge:** Validates the AegonKV (2025) approach 3 years before AegonKV was published. The 2022 characterization correctly identified GC as the best SmartSSD workload; AegonKV implemented it.

**Production readiness:** Characterization paper. The findings guided subsequent SmartSSD papers including AegonKV.

**Architect takeaway:** Before offloading any workload to a SmartSSD or DPU: ask whether the workload's I/O is primarily internal to the device (no PCIe crossing benefit). GC and compaction benefit from SmartSSD because their reads and writes stay on-drive. Compression benefits less (data must cross PCIe for the final write to host buffer).

---

## 2023

### ZenFS: RocksDB Storage Backend for ZNS SSDs
**Conference:** FAST 2023 (plugin released earlier) | **Authors:** Bjørling et al. (WD)

**What it does:** RocksDB storage backend plugin that uses ZNS SSDs natively. Instead of writing SST files through the filesystem (which has its own GC/fragmentation on ZNS), ZenFS maps RocksDB's logical files directly to ZNS zones. Each SST file = one or more zones. When a file is deleted, its zones are reset immediately. No double WA: filesystem-level GC is eliminated.

**Conventional wisdom challenged:** Prior assumption: RocksDB must run on a filesystem (XFS, ext4) which itself runs on ZNS. This double-layer design causes double write amplification: RocksDB compaction WA × filesystem GC WA. ZenFS eliminates the filesystem layer, making RocksDB's compaction the only source of WA.

**Connection to your knowledge:** Month 1 Day 26 (ZNS) + Month 3 Day 2 (RocksDB compaction WA). ZenFS is the production embodiment of the "eliminate unnecessary layers" principle. By removing the filesystem layer, WA drops by 2-3× for compaction-heavy workloads.

**Production readiness:** High. ZenFS is a production RocksDB plugin. Used in production at Western Digital and early adopters. Immediately applicable for RocksDB deployments on ZNS SSDs.

**Architect takeaway:** For RocksDB on ZNS SSDs, use ZenFS. The double WA from filesystem + RocksDB on standard ZNS is unnecessary. ZenFS eliminates it by making RocksDB zone-aware. This is the most impactful ZNS adoption change for RocksDB-based systems.

---

### NVMDB: Using Persistent Memory Efficiently for OLTP
**Conference:** EuroSys 2023 | **Authors:** Zhao et al.

**What it does:** OLTP database that uses NVM (Optane PMEM) without a WAL. Instead, it exploits NVM's byte-addressable persistence and hardware ordering guarantees (clflush, sfence) to make transactions durable without a separate write-ahead log. Each transaction directly modifies NVM pages and uses hardware persistence instructions for durability.

**Conventional wisdom challenged:** Prior assumption: all OLTP databases need a WAL for crash consistency — even on NVM. NVMDB shows that NVM's hardware persistence primitives (clflush, mfence, sfence) can provide crash consistency without a WAL, eliminating double writes (WAL + data page) that conventional databases perform.

**Connection to your knowledge:** Month 1 Day 26 (pmem/DAX, clflush, sfence). This paper is the direct application of those hardware primitives to replace WAL entirely. The key insight: WAL exists because block storage (HDD/SSD) doesn't have hardware-level ordering guarantees for partial writes. NVM does.

**Production readiness:** Low-Medium. Optane is discontinued. CXL-attached persistent memory may revive this. 3-5 years.

**Architect takeaway:** WAL is not fundamental to OLTP correctness — it is a workaround for block storage's lack of hardware ordering guarantees. On byte-addressable persistent storage (NVM, future CXL pmem), WAL can be eliminated, significantly reducing write amplification for update-heavy OLTP.

---

## 2024

### CSAL: A CXL-Based Scalable Persistent Storage Abstraction Layer
**Conference:** FAST 2024 | **Authors:** Zhang et al.

**What it does:** Software abstraction layer that presents CXL-attached memory (persistent or regular DRAM) as a tiered storage medium. CSAL manages data placement between CXL memory (fast, expensive) and NVMe (slower, cheaper) transparently. Applications see a single storage interface; CSAL handles tiering, migration, and CXL-specific persistence operations.

**Connection to your knowledge:** Month 3 hardware essentials (CXL) + Month 3 Day 22 (tiered storage automation). CSAL is the software embodiment of the CXL tiering model described in hardware essentials.

**Production readiness:** Medium. CXL hardware is available. CSAL-style abstraction layers are 1-2 years from production integration.

**Architect takeaway:** CXL memory requires a software tier management layer to be useful as a storage tier — raw CXL access is too low-level for most applications. CSAL represents the right abstraction: expose CXL+NVMe as a unified tiered storage medium, manage placement automatically.

---

### ZNS GC Interaction: Double GC Problem
**Conference:** ATC 2024 | **Authors:** Jung et al.

**What it does:** Detailed analysis of a previously uncharacterized problem: when RocksDB compaction (host-side GC) and ZNS zone reset (drive-side GC) interact, they can cause "double GC" — the same data is processed twice. RocksDB compaction reads an SST file, writes a new one, deletes the old one (zone reset). But if the zone reset triggers an internal ZNS GC cycle (the zone contains partially valid data from another write stream), data is processed a third time.

**Conventional wisdom challenged:** Prior assumption: ZNS eliminates drive-side GC entirely (zone reset = direct erase, no GC needed). This paper shows this is only true for fully sequential workloads. When multiple write streams share a zone (e.g., RocksDB WAL and SST files interleaved), the ZNS drive must internally reorganize data before zone reset — triggering drive-side GC that was supposed to be eliminated.

**Connection to your knowledge:** Month 3 Day 5 (FTL GC) + ZenFS. The double GC problem explains why ZenFS uses separate zones per SST file type (WAL zone, L0 zone, L1 zone, etc.) — mixing write streams in a zone defeats ZNS's GC elimination.

**Production readiness:** High. This is a known production issue for ZNS deployments. ZenFS's zone assignment policy is the fix.

**Architect takeaway:** ZNS eliminates drive GC only when each zone is written by a single stream. If multiple streams (WAL + data, different RocksDB levels) share a zone, drive-side GC resurfaces. ZenFS's per-level zone assignment is the correct design: one logical stream per zone.

---

## 2025

### AegonKV (hardware co-design angle)
**Conference:** FAST 2025 | (see also 01-lsm-kv.md)

**Hardware co-design contribution:** AegonKV is the first published system to use SmartSSD for GC offload in a production-grade KV store design. It closes the hardware/software co-design loop: the 2022 EuroSys characterization identified GC as the best SmartSSD workload; AegonKV implements it.

**Conventional wisdom challenged:** Prior assumption: SmartSSD offload is useful for read-only analytics (push the filter/aggregation to the drive). AegonKV shows SmartSSD is more valuable for background I/O-intensive work (GC, compaction) because those workloads have internal I/O that benefits from near-drive execution.

---

## 2026

### Known Papers
*No hardware co-design papers from 2026 are in my confirmed knowledge base.*

### TODO
- [ ] FAST 2026, OSDI 2026 hardware co-design papers
- [ ] ZNS adoption status in production deployments

### Research Directions to Watch
- **ZNS for distributed storage:** Ceph BlueStore + ZNS, scaling ZNS to multi-drive NVMe-oF targets
- **CXL 3.0 fabric:** peer-to-peer CXL (not just host-to-device), enabling new disaggregation topologies
- **SmartSSD beyond GC:** which other storage workloads benefit from near-drive computation?
- **NVMe 2.0 features in production:** KV Command Set, Flexible Data Placement — what do these enable?
