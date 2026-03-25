# storage-communitys

Storage research review notes for selected papers from:

- FAST 2025
- OSDI 2025
- SOSP 2025

The current material focuses on papers relevant to:

- distributed storage
- cloud and object storage
- disaggregated storage
- erasure coding
- cluster file systems
- LSM-tree and KV storage engines

## Repository Layout

- [`storage-review-2025/README.md`](./storage-review-2025/README.md)
  Entry point for the review pack.
- [`storage-review-2025/01-top5.md`](./storage-review-2025/01-top5.md)
  Shortlist of the five most relevant papers for the storage community.
- [`storage-review-2025/02-detailed-report.md`](./storage-review-2025/02-detailed-report.md)
  Longer technical report with conference-by-conference commentary.
- [`storage-review-2025/03-paper-table.csv`](./storage-review-2025/03-paper-table.csv)
  Flat paper table for filtering and spreadsheet use.
- [`start-codex-with-github-mcp.sh`](./start-codex-with-github-mcp.sh)
  Helper launcher for starting Codex with GitHub MCP token injection.

## Suggested Reading Order

1. Start with [`01-top5.md`](./storage-review-2025/01-top5.md).
2. Continue with [`02-detailed-report.md`](./storage-review-2025/02-detailed-report.md).
3. Use [`03-paper-table.csv`](./storage-review-2025/03-paper-table.csv) as a compact index.

## Notes

- No paper in the current set explicitly mentions `Ceph` in the public title or abstract.
- The clearest explicit `LSM-tree` paper in the set is `AegonKV`.
- The `Mantle` note is partially inference-based because the SOSP accepted-papers page exposes title and authors, but not a public abstract.
