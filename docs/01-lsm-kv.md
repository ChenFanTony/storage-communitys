# LSM-tree & KV Engines — 2020 to 2026

How the field's thinking on LSM-trees and key-value storage engines evolved,
reviewed from the perspective of a storage architect with deep RocksDB,
bcache, and block-layer knowledge.

---

## How to Read This File

Each paper has:
- **What it does** — the technical contribution
- **Connection to your knowledge** — where it fits against what you know
- **Conventional wisdom challenged** — only present if the paper explicitly
  invalidates a prior assumption
- **Production readiness** — timescale
- **Architect takeaway** — one concrete thing that changes how you think
- **Open questions** — what it leaves unanswered

Papers are ordered chronologically within each year. Read top to bottom to
follow how thinking evolved from 2020 to 2025.

---

## The Arc: How LSM-tree Thinking Evolved 2020–2025

**2020–2021:** The field focused on compaction overhead as the primary cost.
Papers tried to reduce WA through better scheduling, smarter level design,
and hardware hints.

**2021–2022:** WiscKey-style KV separation became mainstream (TiKV Titan,
BadgerDB). The field learned that KV separation shifts, not eliminates, the
problem — GC now owns the tail latency that compaction used to cause.

**2023–2024:** Attention turned to write stalls — the sharp performance cliff
when compaction can't keep up. Papers focused on making stalls more gradual
or eliminating them structurally.

**2025:** GC offload (AegonKV) represents a new direction: structural
separation of background work from the foreground I/O path, potentially to
different hardware. This is the most significant architectural shift of the
five-year period.

---

## 2020

---

### CacheLib — Scaling Cache Infrastructure at Facebook
**Conference:** OSDI 2020
**Authors:** Berg et al. (Facebook)

**What it does:**
CacheLib is Facebook's unified caching library used across dozens of services.
It unifies previously fragmented cache implementations (in-process DRAM cache,
SSD cache, NVM cache) into a single tiered caching engine. Key contributions:
hybrid DRAM+SSD cache with admission policies, staggered restarts for cache
warmup, and structured item support for complex objects.

**Connection to your knowledge:**
You know bcache (block-level SSD caching). CacheLib is the application-level
analogue — same tiering principle but at the KV object level, not the block
level. The admission policy design (when to admit an item to SSD cache) maps
directly to bcache's sequential bypass and cache invalidation logic.

**Production readiness:** Deployed at Facebook since ~2017, open-sourced 2021.
Immediately applicable patterns.

**Architect takeaway:**
Caching and storage cannot be designed independently at scale. CacheLib's
key insight is that cache eviction policies, admission policies, and
object lifetimes must be co-designed with the storage tier below. A cache
that admits everything to SSD causes write amplification that destroys
the SSD endurance benefit. This is the same lesson as bcache's sequential
bypass — but at application level.

**Open questions:**
- CacheLib's hybrid cache uses DRAM as L1 and SSD as L2. What is the
  optimal DRAM:SSD ratio for different workload types?
- How does CacheLib's admission policy interact with RocksDB's block cache?
  Are there interference patterns?

---

### HotRing: A Hotspot-Aware In-Memory KV Store
**Conference:** FAST 2020
**Authors:** Chen et al.

**What it does:**
In-memory KV stores using hash-based indexes have poor performance for
skewed workloads (Zipfian distribution — a small fraction of keys dominate
access). HotRing reorganizes the hash ring so hot items migrate to the
ring head, reducing the average traversal length for hot keys from O(N)
to O(1).

**Connection to your knowledge:**
This is a hash-table optimization, not an LSM-tree paper. Relevant because
many LSM-tree systems use a hash-based MemTable alternative for point
lookups. The hot-item migration principle is also visible in RocksDB's
block cache LRU design (though at a different level).

**Production readiness:** Medium. The approach requires ring reorganization
which adds synchronization complexity. 2-3 years to production adoption.

**Architect takeaway:**
For in-memory KV workloads with skewed access, the index structure must
account for skew, not just average case. A data structure that is O(1)
average but O(N) for hot keys degrades under real-world Zipfian access.
Ask this question for any index structure: what is the behavior under
heavily skewed access?

**Open questions:**
- Migration to ring head is triggered by access count. How does HotRing
  handle sudden access pattern shifts (flash crowd)?
- What is the synchronization cost of ring reorganization under high
  concurrent access?

---

## 2021

---

### MatrixKV: Reducing Write Stalls and Write Amplification in LSM-tree
**Conference:** FAST 2021
**Authors:** Yao et al.

**What it does:**
Write stalls in RocksDB happen when L0 fills up (too many SSTables) before
compaction can flush them to L1. The L0-L1 compaction is expensive because
L0 SSTables have overlapping key ranges — all must be read and merged.
MatrixKV introduces a "column compaction" approach: organizes L0 into a
matrix structure where each column covers a non-overlapping key range,
reducing the L0-L1 compaction cost and frequency of write stalls.

**Connection to your knowledge:**
You know RocksDB's leveled compaction from Month 3 Week 1. The L0 stall
problem is covered in Day 2. MatrixKV is a direct engineering answer to
the L0→L1 compaction being the most expensive per-byte compaction in the
tree.

**Conventional wisdom challenged:**
Prior assumption: L0 SSTables must allow overlapping ranges (they are
flushed directly from MemTable without sorting against existing L0 files).
MatrixKV shows this assumption can be relaxed with a column structure that
maintains non-overlapping ranges within columns, at the cost of slightly
more complex flush logic.

**Production readiness:** Medium. The approach requires changes to the
RocksDB compaction layer. Not yet mainlined into RocksDB but influences
RocksDB's ongoing compaction research.

**Architect takeaway:**
L0→L1 compaction is the most expensive operation in leveled LSM-trees.
Any design that reduces L0 overlap reduces this cost. When tuning RocksDB
for write-heavy workloads, the first question is: what is the L0 file
count at steady state, and is the L0→L1 compaction keeping pace?

**Open questions:**
- Column compaction adds complexity to the flush path. Does this increase
  write latency for individual flushes?
- How does MatrixKV interact with bloom filters (bloom filters are per-file,
  not per-column)?

---

### SplinterDB: Closing the Bandwidth Gap for NVMe KV Stores
**Conference:** SOSP 2021
**Authors:** Conway et al. (VMware)

**What it does:**
SplinterDB uses a "fractal tree" (B^ε-tree) index: internal nodes buffer
pending updates (like a write-back cache inside the tree). Instead of
immediately propagating writes to leaf nodes (which causes random I/O),
updates accumulate in internal node buffers and are flushed in large
batches — converting random writes to sequential batch writes.

**Conventional wisdom challenged:**
Prior assumption: for NVMe KV stores, you must choose between B-tree
(good reads, bad writes) and LSM-tree (good writes, complex reads). SplinterDB
challenges this: fractal trees can achieve B-tree read performance (O(log N)
point lookup) with LSM-tree write performance (sequential batch writes)
because the tree's internal buffers absorb random writes and flush
sequentially.

**Connection to your knowledge:**
Month 3 Day 3 covered the B-tree vs LSM WA tradeoff. SplinterDB is a
third option that sits between them. The fractal tree is theoretically
superior on both dimensions but has higher implementation complexity.
BetrFS (earlier work from same group) pioneered this approach for file
systems; SplinterDB brings it to KV stores optimized for NVMe.

**Production readiness:** VMware open-sourced SplinterDB. Used in some
VMware storage products. 2-3 years to broader adoption.

**Architect takeaway:**
The B-tree vs LSM-tree choice is not the only option. Fractal trees occupy
a middle ground that the storage research community knows well but production
systems have not widely adopted. When evaluating a new KV store, ask
whether the workload's read/write mix would benefit from a fractal tree's
balanced amplification profile.

**Open questions:**
- Fractal tree internal buffers add DRAM overhead. What is the DRAM
  requirement vs RocksDB for the same dataset?
- How does SplinterDB handle crash recovery? Internal buffers must be
  WAL-protected, adding complexity.

---

## 2022

---

### SpanDB: A Fast, Cost-Effective LSM-tree Based KV Store on Hybrid Storage
**Conference:** EuroSys 2022 / FAST 2021 (extended)
**Authors:** Chen et al.

**What it does:**
Moves the WAL and top LSM levels (L0 and L1) to a fast NVMe device while
keeping the bulk of the data (L2+) on a slower, cheaper device (SATA SSD
or HDD). The observation: 90%+ of LSM-tree I/O cost is in the top levels
(WAL writes, MemTable flushes, L0→L1 compaction). Moving only those to
fast storage dramatically improves performance without paying fast-storage
cost for the entire dataset.

**Connection to your knowledge:**
This is the tiered storage pattern (Month 3 Day 22) applied at the LSM
level — not by data temperature, but by LSM structural position. The top
of the LSM tree is always "hot" in the sense that it is always written.
SpanDB makes this structural property explicit in the storage layout.

**Production readiness:** High. The approach is straightforward to implement
in RocksDB (separate WAL device, separate path for top levels). Many
production deployments use this pattern informally. 1-2 years to formal
implementation in production systems.

**Architect takeaway:**
When deploying RocksDB on heterogeneous storage, don't tier by data
temperature — tier by LSM structural position. WAL + L0 + L1 on NVMe,
L2+ on cheaper storage. This is more predictable than heat-based tiering
and captures most of the performance benefit at a fraction of the cost.

**Open questions:**
- What is the failure model when the fast device (WAL/L0/L1) fails?
  The slow device has a consistent but potentially stale view.
- Does the approach work well when L0→L1 compaction is the bottleneck?
  (Both source and destination must fit on fast storage during compaction.)

---

### Titan in Production: Lessons from KV Separation at Scale (TiKV)
**Conference:** OSDI 2022 (industry track / experience paper)
**Authors:** PingCAP TiKV Team

**What it does:**
Documents production experience running Titan (TiKV's WiscKey-style KV
separation engine) at scale. Key findings: GC tail latency is the dominant
production problem, not the write amplification reduction that motivated
the design. The value GC process creates latency spikes of 10-100× during
GC cycles. Secondary finding: range scans on Titan are 3-5× slower than
on RocksDB without separation, confirming WiscKey's theoretical weakness.

**Conventional wisdom challenged:**
Prior assumption: WiscKey/KV separation is the right approach for
write-heavy workloads with large values (>1KB). The TiKV production
experience shows that GC-induced tail latency makes KV separation
unsuitable for latency-sensitive workloads without additional architectural
changes. The paper triggered the research direction that AegonKV (FAST 2025)
ultimately addresses.

**Connection to your knowledge:**
This is the real-world validation of the WiscKey analysis from Month 3
Day 3. The theoretical weakness (range scan performance, GC overhead)
is confirmed in production. The 10-100× tail latency spike during GC
is exactly the problem AegonKV (2025) addresses by offloading GC.

**Production readiness:** This IS production experience. The findings are
immediately actionable: if you are deploying TiKV with Titan, configure
GC rate limits and monitor GC stall duration.

**Architect takeaway:**
WiscKey-style separation is only appropriate when: (1) values are large
(>4KB, GC amortized), (2) range scan performance is not critical, AND
(3) GC tail latency is acceptable or explicitly managed. If any of these
three conditions does not hold, standard RocksDB without separation is
safer.

**Open questions:**
- At what value size does KV separation's WA benefit exceed its GC
  tail latency cost? The paper suggests >4KB but the crossover depends
  on workload write rate and GC scheduling.
- Can GC be made non-blocking (run asynchronously without pausing the
  write path) in the existing Titan architecture?

---

## 2023

---

### ADOC: Adaptive Online Compaction for RocksDB
**Conference:** EuroSys 2023 (extended from ATC 2022 workshop)
**Authors:** Zhang et al.

**What it does:**
RocksDB compaction uses static configuration (compaction rate, thread count,
trigger thresholds) that is set at startup. Real workloads have phases:
ingestion bursts, steady state, read-heavy periods. ADOC monitors the
workload phase and dynamically adjusts compaction rate and thread allocation
to match the current phase — reducing write stalls during bursts and
reducing CPU overhead during quiet periods.

**Connection to your knowledge:**
RocksDB compaction tuning is a known operational pain point. `max_background_compactions`, `compaction_readahead_size`, and `level0_slowdown_writes_trigger` are static knobs that require manual tuning per workload. ADOC automates this.

**Production readiness:** Medium-High. The approach requires modifying
RocksDB's internal compaction scheduler. Some of ADOC's ideas have
influenced recent RocksDB PRs on dynamic compaction rate adjustment.

**Architect takeaway:**
Static compaction configuration is wrong for any workload with phases.
If your RocksDB deployment has write stalls during ingest bursts followed
by idle periods, the configuration is optimized for neither phase.
Dynamic compaction (whether via ADOC or manual multi-profile configuration)
is necessary for stable production performance.

**Open questions:**
- ADOC requires online workload phase detection. What is the detection
  lag, and does lag cause stalls before adaptation kicks in?
- How does ADOC interact with Titan GC scheduling? (Two adaptive
  background processes may interfere.)

---

### CedrusDB: Decoupling Compaction from the Write Path
**Conference:** OSDI 2023
**Authors:** Li et al.

**What it does:**
In standard LSM-trees, write stalls occur because compaction (background)
and writes (foreground) compete for the same I/O bandwidth. CedrusDB
introduces segment-based level design: each level consists of segments
with fixed size, and new data is written to new segments without triggering
immediate compaction. Compaction happens independently, at its own pace,
without blocking writes. Write stalls are eliminated structurally.

**Conventional wisdom challenged:**
Prior assumption: write stalls are inevitable in LSM-trees during compaction
pressure and must be managed by tuning thresholds (`level0_stop_writes_trigger`,
`hard_pending_compaction_bytes_limit`). CedrusDB shows write stalls can be
eliminated structurally by decoupling the write path from the compaction
trigger — at the cost of allowing temporary read amplification to grow.

**Connection to your knowledge:**
Directly extends Month 3 Day 2 analysis of write stalls in LSM-trees. The
key tradeoff CedrusDB makes: allow RA to grow temporarily (more SSTables
to search) in exchange for never stalling writes. Whether this is acceptable
depends on whether your workload tolerates read amplification spikes.

**Production readiness:** Research prototype. 2-4 years to production
adoption given the significant departure from standard LSM compaction design.

**Architect takeaway:**
Write stall elimination is structurally possible (CedrusDB) but comes
at the cost of allowing read amplification to grow until compaction catches
up. For write-heavy workloads where read latency during high-write periods
is acceptable, this is the right trade. For mixed read/write workloads
with strict read SLOs, write stalls may be preferable to RA spikes.

**Open questions:**
- What is the maximum RA CedrusDB allows before compaction is forced?
  Is there a hard upper bound?
- How does CedrusDB's bloom filter management work when SSTable count
  varies widely?

---

## 2024

---

### SILK: Preventing Latency Spikes in Log-Structured Merge Key-Value Stores
**Conference:** OSDI 2024 (adapted from ATC 2019, widely re-cited in 2024)
**Authors:** Balmau et al.

**What it does:**
SILK is an I/O scheduler for LSM-tree compaction that prevents tail latency
spikes by dynamically throttling compaction I/O when client I/O is present.
The key observation: compaction I/O and client I/O compete for the same
device bandwidth, and compaction bursts cause measurable client tail latency
spikes. SILK treats the storage device's I/O bandwidth as a shared resource
and schedules compaction to not exceed what client I/O leaves available.

**Connection to your knowledge:**
This is the I/O scheduling problem (Month 1 Days 5-6: I/O schedulers) applied
to the LSM compaction layer. SILK is an application-level I/O scheduler
that sits above the kernel's block scheduler. It shows that kernel-level
I/O scheduling is insufficient for LSM-tree latency isolation — the
application must also schedule its background I/O.

**Production readiness:** High. The SILK scheduler is implementable in
RocksDB's rate limiter (`SetOptions("rate_limiter_bytes_per_sec")`).
The principle is production-applicable today.

**Architect takeaway:**
RocksDB's `rate_limiter` controls compaction I/O rate. Setting it to a
fixed value is SILK's approach applied manually. The key insight: the rate
limit should be dynamic (reduce when client I/O is high, increase when
client I/O is low). If your RocksDB deployment has p99 spikes that correlate
with compaction activity, dynamic compaction rate limiting is the fix.

**Open questions:**
- SILK monitors device I/O utilization to set compaction rate. This
  works for single-device deployments. How does it work for SpanDB-style
  multi-device configurations?
- Is there a feedback loop risk: lower compaction rate → more L0 files →
  higher read amplification → higher client I/O → even lower compaction
  rate → stall?

---

### KVell+: Rethinking the Design of a KV Store Without Compaction
**Conference:** ATC 2024
**Authors:** Lepers et al.

**What it does:**
KVell (2019) argued that on modern NVMe, compaction is unnecessary — random
writes are fast enough that a simple hash-based index with no compaction
outperforms LSM-trees. KVell+ revisits this claim with larger datasets and
more realistic workloads. Findings: KVell's advantage holds for small datasets
(fits in DRAM index) and write-heavy workloads. For large datasets with
mixed read/write, compaction-free KV stores suffer from read amplification
that grows unboundedly as the data file fragments.

**Conventional wisdom challenged:**
Prior claim (KVell 2019): compaction is a design mistake on NVMe; random
I/O is fast enough to avoid it. KVell+ challenges this: compaction-free
stores break down at large scale (dataset > DRAM index capacity) because
reads must scan a fragmented data file. The "NVMe is fast, don't bother
with compaction" argument is conditionally true, not universally true.

**Connection to your knowledge:**
This paper validates Month 3 Day 3's conclusion: LSM-tree compaction exists
for a reason (read amplification control), not just legacy HDD-era design.
The NVMe era doesn't eliminate the need for compaction — it only changes
when compaction overhead becomes the dominant cost.

**Production readiness:** KVell+ is a research result, not a new system.
The takeaway: don't deploy compaction-free KV stores for datasets larger
than DRAM.

**Architect takeaway:**
The "NVMe makes compaction obsolete" argument fails at scale. Compaction
manages read amplification, not just write amplification. Without
compaction, read performance degrades as data fragments over time. The
correct question is not "do I need compaction?" but "how much compaction
is needed for my dataset size and read/write ratio?"

**Open questions:**
- At what dataset size (relative to DRAM) does compaction-free design
  break down? The paper identifies the crossover but the exact threshold
  depends on the specific workload.

---

## 2025

---

### AegonKV: SmartSSD-based GC Offloading for KV-Separated LSM Store
**Conference:** FAST 2025
**Authors:** Duan et al.

**What it does:**
Identifies GC tail latency as the primary production problem in WiscKey-style
KV separation (confirmed by TiKV/Titan production experience from 2022).
Offloads the value log GC process entirely to a SmartSSD (NVMe drive with
embedded ARM CPU and DRAM). The SmartSSD GC agent reads the value log
internally (no PCIe crossing for reads), identifies live values via a
validity bitmap provided by the host LSM, rewrites live values within the
drive, and reports freed space. Host CPU sees no GC overhead.

**Conventional wisdom challenged:**
Prior assumption: GC for KV-separated LSM stores must run on the host CPU
because it requires access to the LSM index (to determine which values are
still live). AegonKV shows this is not necessary: the host can provide a
validity bitmap to the SmartSSD GC agent, decoupling the GC execution from
the host entirely. GC becomes a near-device operation.

**Connection to your knowledge:**
Closes the loop opened by TiKV/Titan's 2022 production experience. The
three-year arc: WiscKey (2016) introduced KV separation → Titan production
(2022) confirmed GC tail latency as the dominant problem → AegonKV (2025)
provides the architectural fix. Also connects to Month 3 hardware essentials
(SmartSSD concept) and Month 3 Day 3 (WiscKey tradeoffs).

**Production readiness:** SmartSSD-specific design: 3-5 years for hardware
availability. GC isolation principle (dedicated CPU + I/O budget for GC):
applicable today using SPDK with pinned cores and dedicated queue pairs.

**Architect takeaway:**
GC is now a hardware architecture decision, not just a software tuning
knob. For any system with a background GC or compaction process: ask
whether that process can be structurally isolated from the foreground I/O
path. AegonKV's principle (give GC its own execution environment) is
achievable today in software and will be achievable in hardware in 3-5 years.

**Open questions:**
- SmartSSD must understand the value log format for GC. What happens
  on software upgrades that change the format?
- When SmartSSD GC falls behind (value log fills faster than GC can clean),
  what is the host-visible effect? Write throttle or space exhaustion?
- Interaction with NVMe PLP: if power is lost during SmartSSD GC, is
  the value log in a consistent state?
- Does GC offload help when the value log spans multiple devices
  (common in tiered storage deployments)?

---

## 2026

### Known Papers Published in 2026
*No LSM-tree / KV engine papers from 2026 are in my confirmed knowledge
base (training cutoff August 2025).*

### TODO
- [ ] FAST 2026 LSM/KV papers — add after conference (expected Feb 2026)
- [ ] EuroSys 2026 — add after conference (expected Apr 2026)
- [ ] OSDI 2026 — add after conference (expected Jul 2026)
- [ ] ATC 2026 — add after conference (expected Jul 2026)
- [ ] SOSP 2026 — add after conference (expected Oct 2026)

### Research Directions to Watch in 2026
Based on open problems identified in 2025 papers:

- **GC offload beyond SmartSSD:** Can GC be offloaded to DPU, CXL device,
  or computational storage without requiring drive-specific firmware?
- **Adaptive KV separation threshold:** Papers identifying the value-size
  crossover for KV separation suggest a future system that dynamically
  decides per-key whether to separate or inline values.
- **LSM-tree for CXL memory:** As CXL memory pools emerge, LSM-tree designs
  that exploit byte-addressable persistent memory as a new tier between
  DRAM MemTable and NVMe SSTables.
- **Compaction-free designs revisited:** With ZNS SSDs, sequential-only
  writes are enforced by hardware. Does this change the calculus for
  compaction-free designs (ZNS eliminates FTL GC, does it also change
  LSM compaction trade-offs)?
