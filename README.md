# bonfyre-example-semantic-search

**Build a local document search engine in 5 minutes.** Embed 20 documents, search by meaning, zero cloud.

## The pitch (for your CEO)

| | Pinecone | Weaviate Cloud | **Bonfyre** |
|---|---|---|---|
| Monthly cost | $70–250/mo | $25–200/mo | **$0** |
| Setup time | 30 min (API keys, SDK, config) | 20 min | **5 min** |
| Data leaves your machine | Yes | Yes | **No** |
| Vendor lock-in | Yes | Yes | **No** |
| Query latency | 50–200 ms (network) | 30–150 ms | **5 ms** (local) |
| Binary size | N/A (cloud) | N/A (cloud) | **2 binaries, 700 KB** |
| Works offline | No | No | **Yes** |

**Annual savings: $300–3,000** per project. Data never leaves your infrastructure.

## Prerequisites

- C compiler (clang/gcc — preinstalled on macOS/Linux)
- SQLite3 headers (`brew install sqlite3` / `apt install libsqlite3-dev`)
- ONNX Runtime (`brew install onnxruntime` / see [install guide](https://github.com/Nickgonzales76017/bonfyre#install))

## Quick start

```bash
git clone https://github.com/Nickgonzales76017/bonfyre-example-semantic-search.git
cd bonfyre-example-semantic-search
./setup.sh          # clones bonfyre, builds embed + vec binaries (~1 min)
./run.sh            # embeds 20 docs, runs interactive search
```

## What you'll see

```
━━━ Indexing 20 documents ━━━

  [1/20] kubernetes-basics.txt          ✓  241 ms
  [2/20] machine-learning-intro.txt     ✓  237 ms
  ...
  Batch mode (all 20 at once):          ✓  386 ms  ← 12× faster

━━━ Search demo ━━━

  Query: "How do containers differ from virtual machines?"

  Results (5 ms):
    1. kubernetes-basics.txt           score=0.8934
    2. docker-containers.txt           score=0.8721
    3. cloud-infrastructure.txt        score=0.7102

  Query: "What is gradient descent?"

  Results (5 ms):
    1. machine-learning-intro.txt      score=0.9201
    2. neural-networks.txt             score=0.8544
    3. data-science-overview.txt       score=0.7891
```

## How it works

```
                    ┌─────────────────────────┐
  20 text files  →  │  bonfyre-embed           │  → 20 vectors (384-dim)
                    │  ONNX Runtime + BERT     │
                    │  --input-dir --insert-db │     ↓
                    └─────────────────────────┘
                                                   SQLite + sqlite-vec
                    ┌─────────────────────────┐     ↓
  "search query" →  │  bonfyre-embed           │  → query vector
                    └─────────┬───────────────┘
                              │
                    ┌─────────▼───────────────┐
                    │  bonfyre-vec search      │  → ranked results
                    │  --exact (NEON SIMD)     │     5 ms
                    └─────────────────────────┘
```

Two binaries. One SQLite file. That's the entire search engine.

## Benchmarks (measured, Apple M-series)

| Operation | Time | Notes |
|---|---|---|
| Single document embed | **237 ms** | ONNX all-MiniLM-L6-v2, 384-dim |
| 20-document batch embed | **~400 ms** | `--input-dir` (one model load) |
| Insert into vector DB | included | `--insert-db` (zero file I/O) |
| Exact search (NEON SIMD) | **5 ms** | Brute-force cosine similarity |
| ANN search (sqlite-vec) | **8 ms** | Approximate nearest neighbors |
| Database size (1000 docs) | **~600 KB** | SQLite + vec0 extension |

## Sample documents included

The `sample-data/` directory contains 20 text documents across different topics:

| # | Document | Topic |
|---|---|---|
| 1 | kubernetes-basics.txt | Container orchestration |
| 2 | machine-learning-intro.txt | ML fundamentals |
| 3 | docker-containers.txt | Containerization |
| 4 | neural-networks.txt | Deep learning |
| 5 | rest-api-design.txt | API architecture |
| 6 | database-indexing.txt | Database performance |
| 7 | cloud-infrastructure.txt | Cloud computing |
| 8 | data-science-overview.txt | Data science |
| 9 | cybersecurity-basics.txt | Security fundamentals |
| 10 | agile-methodology.txt | Project management |
| 11 | microservices-patterns.txt | Software architecture |
| 12 | git-branching.txt | Version control |
| 13 | linux-permissions.txt | System administration |
| 14 | sql-optimization.txt | Database tuning |
| 15 | ci-cd-pipelines.txt | DevOps |
| 16 | oauth-explained.txt | Authentication |
| 17 | dns-how-it-works.txt | Networking |
| 18 | websockets-realtime.txt | Real-time communication |
| 19 | caching-strategies.txt | Performance |
| 20 | testing-pyramid.txt | Quality assurance |

## Customizing

**Use your own documents:**
```bash
# Replace sample-data/ with your own .txt files, then:
./run.sh --reindex
```

**Use the ONNX neural backend** (real semantic similarity):
```bash
# Download the model once (~90 MB)
mkdir -p ~/.cache/bonfyre/models
# See https://github.com/Nickgonzales76017/bonfyre#models for download link

# Then run with --backend onnx (default)
./run.sh --backend onnx
```

**Use the hash backend** (no model needed, deterministic, fast):
```bash
./run.sh --backend hash
```

## File structure

```
bonfyre-example-semantic-search/
├── README.md
├── setup.sh            # Clones + builds only the needed binaries
├── run.sh              # Indexes documents + interactive search
├── search.sh           # One-shot: search.sh "your query here"
├── sample-data/        # 20 sample text documents
│   ├── kubernetes-basics.txt
│   ├── machine-learning-intro.txt
│   └── ... (18 more)
└── output/             # Created at runtime
    └── vectors.db      # SQLite vector database
```

## License

MIT — same as [Bonfyre](https://github.com/Nickgonzales76017/bonfyre).
