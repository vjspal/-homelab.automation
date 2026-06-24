---
type: concept
title: GBrain — Postgres-Native Personal Knowledge Brain
source: Google Drive (garrytan/gbrain)
status: 'v0.3 shipped, active development'
ingested_via: put_page
ingested_at: '2026-05-31T18:07:30.838Z'
source_kind: put_page
tags:
  - gbrain
  - knowledge
  - mcp
  - pgvector
  - postgres
  - rag
---

# GBrain

Personal knowledge brain built on Postgres + pgvector. Not a note-taking app — a compiled
intelligence system. Every page is an intelligence assessment with two layers:
- **COMPILED TRUTH** — current best understanding, rewritten when evidence changes
- **TIMELINE** — append-only evidence trail, never edited

Core insight: personal knowledge at scale is an intelligence problem, not a storage problem.

## Why it exists

A 7,471-file / 2.3GB markdown wiki was choking git. GBrain ports proven RAG patterns
(3-tier chunking, hybrid search with RRF, multi-query expansion, 4-layer dedup) to a
standalone Bun + TypeScript tool backed by Postgres.

## Stack

| Layer | Choice |
|---|---|
| Database | Postgres + pgvector (Supabase Pro, $25/mo, 8GB) |
| Runtime | Bun + TypeScript |
| Embeddings | OpenAI text-embedding-3-large (1536 dims) |
| LLM | Claude Haiku (chunking/query expansion) |
| Background jobs | Trigger.dev |
| Distribution | npm package + compiled binary + MCP server |

## Installation

```bash
# Option A: standalone CLI
npm install -g gbrain
gbrain init --supabase
gbrain import /path/to/markdown/wiki/

# Option B: via ClawHub (OpenClaw integration)
clawhub install gbrain

# Option C: MCP server for Claude Code
# Add to ~/.config/claude/mcp.json:
# { "mcpServers": { "gbrain": { "command": "gbrain", "args": ["serve"] } } }
```

Config lives at: `~/.gbrain/config.json` (0600 permissions)

## Key CLI commands

```bash
gbrain init --supabase        # create brain + run schema migration
gbrain import <dir>           # import markdown directory (auto-chunk + embed)
gbrain query <question>       # hybrid search (RRF + multi-query expansion)
gbrain search <query>         # keyword search (tsvector)
gbrain get <slug>             # read a page
gbrain put <slug>             # write/update a page
gbrain serve                  # start MCP server (stdio)
gbrain doctor --json          # health check
gbrain stats                  # page count, embed coverage, links, timeline
gbrain health                 # brain health dashboard
gbrain embed --stale          # backfill missing embeddings
gbrain graph <slug> --depth 5 # graph traversal (recursive CTE)
gbrain extract links --source db  # backfill link graph
gbrain extract timeline --source db  # backfill timeline entries
```

## Search architecture

Query → multi-query expansion (Claude Haiku) → embed all expansions →
vector search (HNSW cosine) + keyword search (tsvector) → RRF fusion →
4-layer dedup → stale alerts → results

## Skills (fat markdown, no code)

| Skill | Purpose |
|---|---|
| `skills/ingest/SKILL.md` | Meetings, docs, articles → compiled truth + timeline |
| `skills/query/SKILL.md` | 3-layer search + synthesized answer with citations |
| `skills/maintain/SKILL.md` | Contradictions, stale info, orphans, dead links, dream cycle |
| `skills/enrich/SKILL.md` | Enrich from external APIs |
| `skills/briefing/SKILL.md` | Daily briefing: meetings, deals, open threads |
| `skills/migrate/SKILL.md` | Import from Obsidian, Notion, Logseq, plain markdown |
| `skills/meeting-ingestion/SKILL.md` | Meeting transcript → brain |
| `skills/minion-orchestrator/SKILL.md` | Spawn background agents |
| `skills/soul-audit/SKILL.md` | Agent identity / SOUL.md |

## Skill Resolver (RESOLVER.md)

The dispatcher. Key routing rules:
- Every message → `skills/signal-detector/SKILL.md` (parallel, non-blocking)
- Any brain read/write → `skills/brain-ops/SKILL.md`
- "What do we know about..." → `skills/query/SKILL.md`
- Sharing a link/article → `skills/idea-ingest/SKILL.md`
- Video/audio/PDF → `skills/media-ingest/SKILL.md`
- Always-on identity files: SOUL.md (identity), USER.md (user context), HEARTBEAT.md (cadence)

## Identity files

| File | Purpose |
|---|---|
| `SOUL.md` | Agent identity and vibe (currently empty — needs writing) |
| `USER.md` | User context for the agent |
| `HEARTBEAT.md` | Operational cadence — what to check and when |
| `ACCESS_POLICY.md` | Who can send messages |

## Database schema (9 tables)

- `pages` — compiled_truth, timeline, frontmatter (JSONB), search_vector (tsvector)
- `content_chunks` — embedding (1536 dim vector), chunk_text
- `links` — typed edges (knows, invested_in, works_at, etc.)
- `tags` — page tags
- `timeline_entries` — append-only evidence trail
- `raw_data` — source JSONB
- `page_versions` — version history (gbrain history/diff/revert)
- `ingest_log` — audit trail
- `config` — key-value config

## Current status (2026-05-30)

- v0.3 shipped (hybrid search, contract-first arch, ClawHub bundle)
- Lives at `garrytan/gbrain` on GitHub
- On Windows machine: `~/.gbrain/config.json` exists (installed)
- Brain repo: 7,471+ markdown files, ~750MB estimated DB size
- Windows audit flagged: `~/memory/` flat files NOT yet ingested into GBrain

## Integration with OpenClaw / GStack

GBrain is the knowledge backend for OpenClaw (the orchestration layer).
GStack thinking skills (office-hours, ceo-review, investigate, retro) chain with GBrain.
`bun add gbrain` → `import { PostgresEngine } from 'gbrain'`
