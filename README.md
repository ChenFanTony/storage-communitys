# storage-communitys

Storage research review notes for selected papers from FAST 2025, OSDI 2025, and SOSP 2025.

The current review pack focuses on papers relevant to:

- distributed storage
- cloud and object storage
- disaggregated storage
- erasure coding
- cluster file systems
- LSM-tree and KV storage engines

## Quick Start

If you only want the shortest high-signal path:

1. Read [`storage-review-2025/01-top5.md`](./storage-review-2025/01-top5.md).
2. Continue with [`storage-review-2025/02-detailed-report.md`](./storage-review-2025/02-detailed-report.md).
3. Use [`storage-review-2025/03-paper-table.csv`](./storage-review-2025/03-paper-table.csv) for filtering and spreadsheet work.

## Repository Layout

- [`storage-review-2025/`](./storage-review-2025/)
  Main review pack for the 2025 paper set.
- [`storage-review-2025/README.md`](./storage-review-2025/README.md)
  Entry point for the review pack.
- [`storage-review-2025/01-top5.md`](./storage-review-2025/01-top5.md)
  Five papers most worth tracking for the storage community.
- [`storage-review-2025/02-detailed-report.md`](./storage-review-2025/02-detailed-report.md)
  Longer technical report with per-paper commentary.
- [`storage-review-2025/03-paper-table.csv`](./storage-review-2025/03-paper-table.csv)
  Compact paper table with conference, category, authors, and summary.
- [`scripts/start-codex-with-github-mcp.sh`](./scripts/start-codex-with-github-mcp.sh)
  Helper launcher for starting Codex with GitHub MCP token injection.

## Scope Notes

- No paper in the current set explicitly mentions `Ceph` in the public title or abstract.
- The clearest explicit `LSM-tree` paper in the set is `AegonKV`.
- The `Mantle` note remains partially inference-based because the SOSP accepted-papers page exposes title and authors, but not a public abstract.

## License

This repository is released under the MIT License. See [`LICENSE`](./LICENSE).
