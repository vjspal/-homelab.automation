---
type: concept
title: 'Home Directory Audit — vijay (C:\Users\vijay\)'
date: '2026-05-31T00:00:00.000Z'
source: Google Drive (original) + screenshot confirmed 2026-05-31
ingested_via: put_page
ingested_at: '2026-05-31T18:07:34.359Z'
source_kind: put_page
tags:
  - agent-infrastructure
  - audit
  - gbrain
  - windows
---

# Home Directory Audit Summary — vijay (2026-05-31)

## Confirmed Home Directory Contents (screenshot 2026-05-31)

| Directory | What it is |
|---|---|
| `.gbrain` | GBrain installed ✓ (config + DB connection) |
| `.gemini` | Gemini agent config |
| `.openhumane` | OpenHuman agent |
| `.securecoder` | SecureCoder agent |
| `.specstory` | Spec story / Copilot history |
| `.ssh` | SSH config (key auth setup in progress — STA-79) |
| `seidr` | **siedirOS workspace root** — the PAI (NOT CLAUDESTINE) |
| `memory` | Flat memory files — NOT yet ingested into GBrain |
| `llm_wiki_tool` | LLM wiki tool |
| `olympian-agent-os` | Olympian agent OS workspace |
| `omarchyworkspace` | Omarchy workspace |
| `Personal_AI_Infrastructure` | PA infrastructure files |
| `lifeos` | Life OS system |
| `hermes-backups` | Hermes Docker backup files |
| `hermes-config` | Hermes config |
| `hermes-workspace` | Hermes workspace |
| `plans` | Plans directory |
| `workspace` | Additional workspace directory |
| `Claude` | Claude-related files |
| `CC-Switch-v3.15.0-Windows-Portable` | CC-Switch portable app |

**Critical correction:** CLAUDESTINE does NOT exist on this machine.
The siedirOS workspace is `seidr` (`C:\Users\vijay\seidr`).
Claude Code v2.1.158 is installed and running (Sonnet 4, Claude Pro).
Startup hook `gstack-brain-init` fails on launch (non-fatal) — not on PATH.

## Overview
Audit of AI/agent infrastructure across C:\Users\vijay\ to identify interconnection gaps
and agent-agnostic principle violations.

## Active Systems (on Windows machine)

Hermes, Olympian, Claude/gstack, Codex, Gemini, Cline, Copilot, Continue, **GBrain**, OpenHuman

## Working Connections
- Hermes ↔ Olympian gateway integration
- Hermes ↔ Swarm worker dispatch
- **GBrain ↔ RESOLVER.md routing table**
- Claude/gstack ↔ CLAUDE.md hierarchy

## Critical Gaps
- `.agents/skills/` and `.codex/skills/` are empty — isolated agents can't access shared skills
- `plans/` directory unused despite Olympian references
- Memory fragmentation: flat `~/memory/` files not ingested into GBrain vector database
- "Hermes SOUL.md is empty" — persona framework undefined
- Multiple agent systems siloed without GBrain or RESOLVER.md integration

## Priority Actions (from audit)
1. Create `~/workspace/ai-home-index/CONTEXT.md` (referenced but missing)
2. Ingest `~/memory/` files into GBrain embeddings
3. Write Hermes SOUL.md persona definition
4. Normalize RESOLVER.md to only list existing skills
5. Create `~/skills/manifest.json` for machine-readable skill discovery

## Agent-Agnostic Rating
**Overall: 🟡 Fragmented** — Functional skeleton exists (GBrain + RESOLVER.md + shared
skills directory) but lacks connective tissue and enforcement mechanisms across runtimes.

## What This Tells Us About GBrain

GBrain is a **vector database** on the Windows machine at `C:\Users\vijay\.gbrain` (or `~/.gbrain`).
It has a RESOLVER.md routing table. The flat `~/memory/` files are meant to feed into it
but haven't been ingested yet.

The server-side workspace (`~/workspace/` on clawhaven) is the equivalent of
`~/workspace/ai-home-index/` referenced in this audit.
