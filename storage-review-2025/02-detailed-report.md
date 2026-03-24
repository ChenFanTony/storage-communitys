# Storage Research Report: FAST/OSDI/SOSP 2025

This note filters 2025 papers from FAST, OSDI, and SOSP using a storage-research lens, with emphasis on:

- distributed storage
- cloud/object/blob storage
- disaggregated storage
- erasure coding / cluster file systems
- LSM-tree and key-value storage engines

Ceph-specific result:

- I did not find a 2025 FAST/OSDI/SOSP paper whose title or public abstract explicitly mentions `Ceph`.

LSM-tree-specific result:

- The clearest explicit match is `AegonKV`, which directly targets a KV-separated LSM store.

## Cross-Cutting Technology Themes

Across the three conferences, the strongest storage trends are:

1. `Disaggregation becomes a first-class storage design point.`
   FAST and OSDI both include multiple papers that assume storage is no longer tightly coupled to the host CPU. DPUs, SmartSSDs, JBOF, and NVMe-oF are treated as practical system building blocks rather than exotic accelerators.

2. `Metadata and indexing are becoming the main bottlenecks.`
   Several papers attack translation, indexing, or namespace management directly: HiDPU targets address translation in disaggregated storage, Mantle targets object-store metadata hierarchy, and Okapi explicitly revisits the long-standing coupling between layout and redundancy metadata.

3. `Storage efficiency is no longer just about capacity.`
   The papers increasingly optimize for a three-way balance: throughput, tail latency, and storage/space efficiency. AegonKV is the cleanest example of this framing.

4. `Erasure coding is being redesigned for modern fast storage.`
   The classical stripe abstraction becomes more questionable when the medium is in-memory or very fast flash. Nos/Nostor and Okapi both revisit old redundancy assumptions under new performance regimes.

5. `Cloud object/blob storage remains a systems-rich area.`
   Cloudscape, NCBlob, and Mantle show that cloud storage research is not saturated: deployment studies, repair optimization, and metadata scalability all remain open and practically important.

## FAST 2025

### Cloudscape: A Study of Storage Services in Modern Cloud Architectures
Authors: Sambhav Satija, Chenhao Ye, Ranjitha Kosgi, Aditya Jain, Romit Kankaria, Yiwei Chen, Andrea C. Arpaci-Dusseau, Remzi H. Arpaci-Dusseau, Kiran Srinivasan

Technical reading:

- This is a measurement-and-characterization paper rather than a new storage engine.
- Its value is that it grounds systems storage research in real cloud deployment behavior instead of assumed workloads.
- The paper studies nearly 400 AWS cloud architectures and shows that object storage, especially S3, dominates modern deployments, while managed file system services appear much less frequently.
- A storage researcher should care because this kind of evidence helps calibrate what abstractions matter in practice: object storage is central, heterogeneity is normal, and storage services are often embedded inside larger analytics/ML/service graphs.
- The research implication is that work on object storage interfaces, metadata paths, and multi-service composition is likely better aligned with actual cloud practice than file-system-centric assumptions.

### FlacIO: Flat and Collective I/O for Container Image Service
Authors: Yubo Liu, Hongbo Li, Mingrui Liu, Rui Jing, Jian Guo, Bo Zhang, Hanjun Guo, Yuxin Ren, Ning Jia

Technical reading:

- The paper starts from a practical pain point: container image services create substantial I/O amplification and network overhead.
- The main argument is that existing image abstractions are too storage-oriented and too global, which is the wrong abstraction boundary for runtime startup paths.
- FlacIO introduces a `runtime image`, representing the memory state of the root file system seen by the service, then pairs it with a runtime page cache to optimize transfer and reconstruction.
- This is interesting for storage researchers because it is not merely a cache policy tweak; it is an example of changing the storage abstraction itself to fit the service access path.
- The broader lesson is that image distribution, object storage access, and startup-time storage paths should probably be co-designed rather than treated as independent layers.

### Revisiting Network Coding for Warm Blob Storage
Authors: Chuang Gan, Yuchong Hu, Leyan Zhao, Xin Zhao, Pengyu Gong, Dan Feng

Technical reading:

- The paper revisits MSR codes for blob storage but questions the usual systematic form.
- The key systems point is that bandwidth-optimal repair can still perform poorly in practice if the repair path induces non-contiguous I/O, especially for small blobs.
- NCBlob uses non-systematic MSR/network coding to improve repair I/O efficiency in warm blob storage, where small objects dominate and repair performance matters.
- This matters because it is a good reminder that coding optimality on paper does not imply storage-system optimality on real devices.
- The paper is especially relevant if you care about object/blob stores, repair economics, and the mismatch between code-theoretic metrics and actual storage-engine behavior.

### HiDPU: A DPU-Oriented Hybrid Indexing Scheme for Disaggregated Storage Systems
Authors: Wenbin Zhu, Zhaoyan Shen, Qian Wei, Renhai Chen, Xin Yao, Dongxiao Yu, Zili Shao

Technical reading:

- The paper argues that in disaggregated storage systems, address translation itself becomes a visible systems bottleneck.
- It further points out that indexing structures can become too memory-hungry at scale, which is especially problematic on resource-constrained DPUs.
- HiDPU responds with a hybrid multi-level index using different segment types and a layered learned-index design, while keeping small upper-level indexes and hot metadata on the DPU.
- The interesting part is not just “use learned indexes,” but how the indexing hierarchy is adapted to the DPU/host split and limited DPU memory.
- This is a good paper to read if you care about the control-plane cost of disaggregation, not just the data path.

### AegonKV: A High Bandwidth, Low Tail Latency, and Low Storage Cost KV-Separated LSM Store with SmartSSD-based GC Offloading
Authors: Zhuohui Duan, Hao Feng, Haikun Liu, Xiaofei Liao, Hai Jin, Bangyu Li

Technical reading:

- This is the strongest explicit `LSM-tree` paper in the set.
- The starting point is familiar: KV separation reduces write amplification in LSM trees, but pushes substantial pain into value-region garbage collection.
- The paper argues that previous solutions still force a CPU-vs-I/O tradeoff and therefore fail to jointly optimize throughput, tail latency, and space usage.
- AegonKV offloads GC to SmartSSD so that GC can proceed asynchronously without directly competing with foreground LSM read/write traffic for host CPU or bandwidth.
- The design significance is that GC is treated as a data-movement and placement problem that can be structurally removed from the host critical path, not merely optimized in software.
- If you work on RocksDB-style systems, WiscKey-like separation, or tail-latency-aware storage engines, this is a high-priority read.

## OSDI 2025

### Scalio: Scaling up DPU-based JBOF Key-value Store with NVMe-oF Target Offload
Authors: Xun Sun, Mingxing Zhang, Yingdi Shan, Kang Chen, Jinlei Jiang, Yongwei Wu

Technical reading:

- Scalio targets DPU-based JBOF systems, which are attractive for storage density and efficiency but often bottleneck on the DPU CPU.
- The main move is to push SSD I/O handling onto network-facing hardware paths, including NVMe-oF Target Offload, rather than burning general-purpose DPU CPU on storage plumbing.
- The design also keeps hot read paths compact in memory and introduces an RDMA-based cache consistency protocol to maintain linearizability across a disaggregated architecture.
- What makes this paper important is that it treats “storage node CPU overhead” as the key scalability limiter in high-density flash systems.
- This is relevant beyond JBOF: many storage appliances will face similar control/data-path tension as offload hardware becomes stronger than the embedded CPUs managing it.

### Stripeless Data Placement for Erasure-Coded In-Memory Storage
Authors: Jian Gao, Jiwu Shu, Bin Yan, Yuhao Zhang, Keji Huang

Technical reading:

- The paper takes aim at the stripe abstraction itself.
- Classical stripe-based erasure coding works, but stripes impose coordination and placement overheads that become relatively expensive when the storage substrate is very fast or in-memory.
- The proposed `Nos` scheme avoids stripes by letting nodes independently replicate and encode with XOR according to a combinatorial placement structure; `Nostor` then uses this as the basis for a distributed in-memory KV store.
- The systems lesson is that redundancy layout needs to be rethought when metadata, placement coordination, and fast-path overheads dominate.
- This is a strong paper for researchers interested in the future of erasure coding under low-latency storage assumptions.

### Okapi: Decoupling Data Striping and Redundancy Grouping in Cluster File Systems
Authors: Sanjith Athlur, Timothy Kim, Saurabh Kadekodi, Francisco Maturana, Xavier Ramos, Arif Merchant, K. V. Rashmi, Gregory R. Ganger

Technical reading:

- Existing cluster file systems often couple striping and erasure-coding group formation, which is convenient architecturally but constraining operationally.
- Okapi argues these two decisions solve different problems and should be configured independently: striping for performance, redundancy grouping for durability and space efficiency.
- The practical payoff is not only better throughput and lower seek overhead, but also cheaper transitions between EC policies because data need not be rewritten wholesale.
- For storage researchers, this is a strong example of revisiting a deeply embedded systems coupling and showing it is not fundamental.
- The paper is especially useful for thinking about hot/cold data transitions, changing reliability targets, and online redundancy reconfiguration.

### Tigon: A Distributed Database for a CXL Pod
Authors: Yibo Huang, Haowei Chen, Newton Ni, Yan Sun, Vijay Chidambaram, Dixin Tang, Emmett Witchel

Technical reading:

- Tigon is not a storage paper in the narrow file/object-store sense, but it is relevant to distributed state management and storage-adjacent data systems.
- Its central claim is that cross-host synchronization for a distributed in-memory database can move from network messaging to atomic operations on CXL memory.
- The system then has to confront CXL’s own limitations: higher latency and lower bandwidth than local DRAM, plus weak support for cross-host coherence.
- The reason it matters to storage researchers is that emerging memory/storage disaggregation blurs the line between “database synchronization problem” and “distributed storage placement problem.”
- If CXL pods become practical, storage and database systems may start sharing a much more similar design space.

## SOSP 2025

### Mantle: Efficient Hierarchical Metadata Management for Cloud Object Storage Services
Authors: Jiahao Li, Biao Cao, Jielong Jian, Cheng Li, Sen Han, Yiduo Wang, Yufei Wu, Kang Chen, Zhihui Yin, Qiushi Chen, Jiwei Xiong, Jie Zhao, Fengyuan Liu, Yan Xing, Liguo Duan, Miao Yu, Ran Zheng, Feng Wu, Xianjun Meng

Technical reading:

- The SOSP accepted-papers page exposes title and authors but not the public abstract, so the technical characterization here is necessarily conservative.
- From the title and available public metadata, Mantle is clearly about hierarchical metadata management for cloud object storage services.
- That alone makes it notable: object-store metadata paths remain one of the hardest real-world scaling problems, especially when namespace depth, small-object skew, and contention all interact.
- The most likely contribution shape is a better metadata hierarchy or hierarchy-aware management mechanism that reduces contention and improves namespace operation scalability.
- Even without the full public abstract, this is a paper storage researchers should track because object-store metadata remains a major gap between simple key-object abstractions and real production systems.

## Suggested Reading Order

If your focus is `LSM-tree / KV storage engines`:

1. AegonKV
2. Scalio
3. Stripeless Data Placement for Erasure-Coded In-Memory Storage

If your focus is `cloud/object/blob storage`:

1. Cloudscape
2. Mantle
3. Revisiting Network Coding for Warm Blob Storage
4. FlacIO

If your focus is `future storage architecture / disaggregation`:

1. HiDPU
2. Scalio
3. Okapi
4. Tigon

## Sources

- FAST 2025 technical sessions: https://www.usenix.org/conference/fast25/technical-sessions
- OSDI 2025 technical sessions: https://www.usenix.org/conference/osdi25/technical-sessions
- SOSP 2025 accepted papers: https://sigops.org/s/conferences/sosp/2025/accepted.html
- FAST 2025 paper pages:
  - https://www.usenix.org/conference/fast25/presentation/satija
  - https://www.usenix.org/conference/fast25/presentation/liu-yubo
  - https://www.usenix.org/conference/fast25/presentation/gan
  - https://www.usenix.org/conference/fast25/presentation/zhu
  - https://www.usenix.org/conference/fast25/presentation/duan
- OSDI 2025 paper pages:
  - https://www.usenix.org/conference/osdi25/presentation/sun
  - https://www.usenix.org/conference/osdi25/presentation/gao
  - https://www.usenix.org/conference/osdi25/presentation/athlur
  - https://www.usenix.org/conference/osdi25/presentation/huang-yibo
- Mantle metadata pages:
  - https://madsys.cs.tsinghua.edu.cn/publication/mantle-efficient-hierarchical-metadata-management-for-cloud-object-storage-services/
  - https://jglobal.jst.go.jp/en/public/202602226180963988

## Confidence Notes

- FAST and OSDI entries are based on official conference paper pages with public abstracts.
- SOSP `Mantle` is based on the accepted-papers page plus public metadata pages; the detailed technical reading for that paper should be treated as informed inference rather than a direct abstract summary.
