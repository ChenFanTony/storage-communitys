# File Systems: Local & Distributed — 2020 to 2026

---

## The Arc: 2020–2025

**2020–2021:** NVM (Optane PMEM) motivated new local file system designs that exploit byte-addressable persistence without WAL overhead. Container image distribution drove rethinking of read-only file system design.

**2022–2023:** Distributed file systems increasingly separated metadata plane (consensus-based) from data plane (direct I/O). POSIX consistency began to be relaxed in systems that valued scalability over strict compliance.

**2024–2025:** Trillion-file scale metadata management emerged as the active research frontier. POSIX's suitability at scale was challenged explicitly.

---

## 2020

### CephFS MDS Scalability Analysis
**Conference:** FAST 2020 | **Authors:** Weil et al. (Red Hat)

**What it does:** Systematic analysis of CephFS MDS (Metadata Server) scalability bottlenecks. Key findings: (1) subtree migration cost is high — migrating a hot directory to a different MDS triggers significant I/O and invalidation; (2) directory fragmentation (splitting a large directory across MDS instances) helps for lookup but hurts for rename; (3) single MDS per subtree limits parallelism for hot directories.

**Connection to your knowledge:** Month 2 Day 26 (CephFS MDS architecture). This is the empirical validation of why CephFS MDS is hard to scale. You studied the architecture — this paper identifies specifically which operations fail at scale and why.

**Production readiness:** Production data. Immediately applicable for CephFS deployments.

**Architect takeaway:** CephFS MDS bottlenecks are predictable from directory access patterns. Hot directories with heavy rename traffic are the hardest case (rename requires coordination across MDS instances). Design workloads to avoid heavy rename in hot directories — or accept the MDS bottleneck as a known cost.

---

### WineFS: A Hugepage-Aware File System for Persistent Memory
**Conference:** OSDI 2020 | **Authors:** Panda et al.

**What it does:** Ext4-inspired file system for persistent memory that proactively manages fragmentation. Standard persistent memory file systems (NOVA, PMFS) suffer from fragmentation as files are created and deleted over time — hugepage-aligned allocations become impossible, forcing small-page access which is 2-4× slower. WineFS uses a fragmentation-aware allocator that keeps large contiguous regions available for hugepage-aligned files.

**Connection to your knowledge:** Month 1 Day 26 (pmem/DAX). Hugepage alignment for NVM is important because DAX mmap uses 2MB hugepages — if the file is not hugepage-aligned, DAX falls back to 4KB pages, losing the performance benefit.

**Production readiness:** Low-Medium. Optane discontinued. Relevant when CXL persistent memory becomes available.

**Architect takeaway:** For persistent memory file systems, allocator design determines long-term performance — not just initial performance. Allocators that don't preserve hugepage-aligned regions will degrade over time as fragmentation accumulates. This is the same lesson as ext4's online defragmentation need, but more critical for NVM.

---

## 2021

### EROFS: A Compression-Friendly Readonly File System
**Conference:** FAST 2021 | **Authors:** Gao et al. (Huawei)

**What it does:** Read-only compressed file system designed for container images and firmware packages. Key contributions: inline compression that allows random access to compressed files without decompressing entire files (block-level random access to compressed content), and cache-friendly layout that maximizes page cache hit rates for container startup.

**Connection to your knowledge:** Month 3 Day 23 (container images / FlacIO context). EROFS is the file system layer beneath FlacIO's abstraction. EROFS shows that read-only compressed file systems can achieve near-uncompressed read performance with 2-3× storage reduction — a compelling trade for container images.

**Production readiness:** High. EROFS is mainlined in Linux kernel (5.4+). Used in Android 11+ as system partition file system. Used in container image distribution.

**Architect takeaway:** For read-only workloads (container images, firmware, static datasets), a compressed read-only file system is almost always the right choice — 2-3× storage reduction with near-native read performance and zero write overhead. EROFS is the production-grade option.

---

### Fisc: A Large-scale Cloud-Native-Oriented File System
**Conference:** OSDI 2021 | **Authors:** Li et al. (Alibaba)

**What it does:** Distributed file system that separates control plane (metadata, consensus) from data plane (direct I/O). Metadata operations go through consensus; data reads/writes go directly from client to storage nodes without metadata server involvement. The separation allows data throughput to scale independently of metadata throughput.

**Conventional wisdom challenged:** Prior assumption: file system operations require metadata server involvement on every I/O (for POSIX consistency — every write must update mtime, size, etc.). Fisc shows that metadata updates can be decoupled from data I/O: data goes directly to storage nodes, metadata updates are batched and processed asynchronously.

**Connection to your knowledge:** Month 2 Day 26 (CephFS MDS). Fisc is a more radical decoupling than CephFS's MDS subtree partitioning — it decouples the data I/O path entirely from metadata, not just partitions metadata across multiple servers.

**Production readiness:** Medium-High. Used at Alibaba. 1-2 years for broader adoption patterns.

**Architect takeaway:** Metadata and data planes have different scaling properties. Metadata is consensus-bound (limited throughput). Data is bandwidth-bound (scales with hardware). Separating them allows each to scale independently. This is the right architecture for cloud-scale distributed file systems.

---

## 2022

### CFS: Scaling Metadata Service for Distributed File System via Relaxed POSIX Semantics
**Conference:** OSDI 2022 | **Authors:** Zheng et al. (ByteDance)

**What it does:** Distributed file system that relaxes POSIX semantics for metadata to achieve better scalability. Key relaxations: (1) directory size not always accurate (counted lazily); (2) link count not exact; (3) mtime updates are approximate (batched). These relaxations allow metadata updates to be executed without cross-node coordination, enabling higher metadata throughput.

**Conventional wisdom challenged:** Prior assumption: POSIX compliance requires exact metadata (exact link count, exact mtime, exact directory size). CFS shows these are rarely checked by real applications — relaxing them enables 5-10× metadata throughput improvement. The POSIX standard is more demanding than applications require.

**Connection to your knowledge:** Month 2 Day 26 (when to abandon POSIX). CFS is a concrete example: identify which POSIX semantics your applications actually need, relax the rest. The metadata overhead of strict POSIX is real and measurable.

**Production readiness:** High. Used at ByteDance in production. 1-2 years for patterns to spread.

**Architect takeaway:** Audit which POSIX metadata semantics your applications actually require. Exact link count? Exact mtime? Exact directory size? Most applications don't check these exactly. Relaxing unnecessary semantic guarantees can give 5-10× metadata throughput improvement. This is the same lesson as giving up POSIX rename atomicity for scalability.

---

## 2023

### Kuco: A User-space File System with Kernel Passthrough
**Conference:** OSDI 2023 | **Authors:** Chen et al.

**What it does:** User-space file system (like FUSE) that avoids FUSE's context-switch overhead for hot paths. Kuco routes frequent metadata operations (lookup, getattr) directly from user space to the file system without kernel involvement using a shared-memory ring buffer. Only uncommon operations (create, unlink) go through the kernel.

**Connection to your knowledge:** Month 1 (VFS layer, FUSE overhead). FUSE's context-switch overhead was covered as a known limitation. Kuco is the engineering solution: keep the flexibility of user-space file systems but eliminate the kernel context-switch overhead for hot paths.

**Production readiness:** Medium. Requires a modified FUSE interface. 2-3 years.

**Architect takeaway:** FUSE's 2-4µs overhead per metadata operation is the primary reason custom file systems are implemented in-kernel. Kuco-style shared-memory ring buffers can reduce this to ~0.5µs, making user-space file system development viable for latency-sensitive metadata paths.

---

### ExtFUSE: Application-defined File System Extensions in User Space
**Conference:** EuroSys 2023 / ATC 2019 (widely cited) | **Authors:** Bijlani & Ramachandran

**What it does:** Framework that allows user-space programs to provide per-file or per-directory extensions to kernel file systems — without modifying the kernel. Uses eBPF-like mechanisms to load user-defined handlers for specific file system operations. The hot path (unmodified files) goes through kernel; the cold path (files with extensions) calls user-space handlers.

**Conventional wisdom challenged:** Prior assumption: extending kernel file system behavior requires either kernel module development or full FUSE (with its overhead). ExtFUSE shows a middle path: eBPF-style hooks into the VFS layer allow selective user-space extension without the overhead of full FUSE.

**Connection to your knowledge:** Month 1 (VFS, eBPF from Day 28 context). ExtFUSE is the eBPF approach applied to file system extension — the same philosophy as eBPF for networking (add programmability without rewriting the kernel subsystem).

**Production readiness:** Medium. eBPF is production; eBPF-based VFS hooks are more experimental. 2-4 years.

**Architect takeaway:** Custom file system behavior (encryption, compression, access logging per directory) no longer requires a kernel module or full FUSE. eBPF-based VFS hooks allow targeted extensions with low overhead. Evaluate this for compliance workloads (per-directory audit logging) or data reduction workloads (per-directory compression).

---

## 2024

### LocoFS: A Loosely-Coupled Metadata Service for Distributed File Systems
**Conference:** OSDI 2024 | **Authors:** Li et al.

**What it does:** Distributed file system that relaxes POSIX consistency for metadata across nodes to improve scalability. Unlike CFS (which relaxes specific metadata values), LocoFS relaxes cross-node metadata consistency: metadata operations on different nodes may be temporarily inconsistent, converging eventually. For workloads where cross-directory consistency is not required (each application uses a separate directory), this is safe and provides near-linear metadata scaling.

**Conventional wisdom challenged:** Prior assumption: distributed file systems must provide globally consistent metadata (all nodes agree on directory state at all times). LocoFS shows that for most real workloads (each application uses a private directory, no cross-directory dependencies), per-directory consistency is sufficient. Global consistency is an unnecessary overhead.

**Connection to your knowledge:** Month 2 Day 26 (when to abandon POSIX) + CFS above. LocoFS goes further than CFS: CFS relaxes specific metadata values; LocoFS relaxes cross-node metadata consistency entirely for separate directory subtrees.

**Production readiness:** Medium. Requires careful application auditing to verify workload doesn't rely on cross-directory consistency. 2-3 years.

**Architect takeaway:** Global metadata consistency in distributed file systems is expensive and often unnecessary. If your workloads are directory-isolated (each job uses a private working directory, no cross-directory renames or links), per-directory consistency is sufficient and enables near-linear scaling.

---

## 2025

### Okapi (file system angle)
**Conference:** OSDI 2025 | (see also 02-erasure-coding.md)

**File system contribution:** Okapi demonstrates that cluster file systems have an unnecessary coupling between data layout (striping) and redundancy layout (EC group membership). The file system architectural lesson: performance and durability are separate concerns and should be configurable independently. This is a direct critique of how CephFS, Lustre, and HDFS are designed.

**Architect takeaway for file systems:** When designing a new distributed file system, make striping width and EC group membership independently configurable from day one. Fusing them is a convenience that creates long-term operational rigidity.

---

### FlacIO (file system angle)
**Conference:** FAST 2025 | (see also 04-object-blob-storage.md)

**File system contribution:** Container image file systems should be designed for runtime access patterns (which pages are accessed during startup), not for builder patterns (how layers are constructed). This is the "access pattern determines abstraction" principle applied to file systems.

**Architect takeaway for file systems:** The right file system abstraction is determined by the dominant access pattern, not by the tool that creates the data. Image file systems have a well-defined access pattern (startup: load specific memory pages). Design the FS for that pattern.

---

## 2026

### Known Papers
*No file systems papers from 2026 are in my confirmed knowledge base.*

### TODO
- [ ] FAST 2026 file systems papers
- [ ] OSDI 2026, EuroSys 2026 distributed file systems

### Research Directions to Watch
- **eBPF-based VFS extensions:** maturation of ExtFUSE-style programmable file system extensions
- **CXL-aware distributed file systems:** file systems that exploit CXL memory pooling for metadata caching
- **POSIX relaxation at scale:** where is the line between "relaxed POSIX" and "not a file system anymore"?
- **ZNS for distributed file systems:** Ceph BlueStore + ZNS at scale, Lustre on ZNS
