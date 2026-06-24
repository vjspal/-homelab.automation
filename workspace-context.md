---
type: concept
title: Workspace Context
ingested_via: put_page
ingested_at: '2026-05-31T18:07:40.081Z'
source_kind: put_page
---

# CONTEXT.md
# Current project state — update this when things change

Last updated: 2026-05-31

## What We're Building

A **centralized agent-agnostic workspace** at `~/workspace/` that serves as the shared
ground truth for all agents (Claude, Codex, Gemini, FCC, and future agents).

The workspace unifies three previously siloed systems:
1. **gbrain** (golden-compass-daemon) — agentic orchestration / shadow self
2. **llm-wiki vault** (Ben-s-vault-template) — Karpathy-style AI-maintained Obsidian knowledge
3. **integrated-humankind** — unified command interface + mobile Obsidian control

## Current Phase: Foundation / Knowledge Ingestion

### Done
- [x] Workspace directory structure created at `~/workspace/`
- [x] Key GitHub repos cloned into `knowledge/`
- [x] AGENTS.md written (cold-start entry point for any agent)
- [x] CONTEXT.md written (this file)

### In Progress
- [ ] Knowledge index (`knowledge/INDEX.md`) — cataloguing all source material
- [ ] Ingesting Google Drive docs (blocked: Chrome extension not connected to server)
- [ ] Ingesting local machine files (blocked: SSH not open on zenwinque)

### Pending
- [ ] HANDOFF.md — task queue system
- [ ] Wire gbrain ↔ vault tandem on this server
- [ ] Set up `~/workspace/knowledge/` as git repo for persistence + sync
- [ ] Enable nimble/llm-wiki at `~/.nimble/memory/`

## Key Decisions Made

- **Workspace root**: `~/workspace/` (not inside any agent's dotdir)
- **Cold-start protocol**: Any agent reads `AGENTS.md` then `CONTEXT.md` first
- **Knowledge format**: Markdown with YAML frontmatter, kebab-case filenames
- **Agent neutrality**: No agent-specific tooling in the shared workspace
- **North star doc**: `knowledge/telos/personal_telos.md` — Vijay's personal purpose file

## What Vijay Wants (from CONTEXT-HANDOFF.md in integrated-humankind)

- Unified over layered — true integration, not stacking
- Mobile accessibility (Obsidian buttons → iOS Shortcuts → server triggers)
- Context continuity — agents must not lose fine details across handoffs
- Everything captured: all insights go somewhere searchable
- Fabric patterns available for AI processing (950+ patterns)

## Complete System Map (from Drive audit)

**OS name:** siedirOS  
**Primary workspace on Windows:** `lifeos` (`C:\Users\vijay\lifeos`) — consolidation target for all Windows workspaces  
**Previous workspace name:** CLAUDESTINE (old laptop, username `hotdog`) — `seidr` is the current equivalent  
**GBrain:** Postgres + pgvector knowledge brain (`garrytan/gbrain`, npm, MCP server)  
  - Config: `~/.gbrain/config.json`  
  - Commands: `gbrain init/import/query/serve/doctor`  
  - v0.3 shipped. `~/memory/` flat files NOT yet ingested into it  
**Obsidian vaults:** providence (7,471 files, 2.3GB, the llm-wiki) + verdigris (barely started)  
**Hermes agent:** Docker container (`nousresearch/hermes-agent:latest`), port 8642  
**OpenClaw/GStack:** orchestration layer that uses GBrain as backend  
**Key identity files:** SOUL.md (empty), USER.md, HEARTBEAT.md, RESOLVER.md  
**Business:** AI Revenue Recovery — local service businesses (HVAC, plumbing, etc.)  
  - Pre-revenue, bartending is income  
  - 90-day target: one paying client, Revenue Recovery Scan must ship first  
  - Gemini analysis: "Cathedral Builder syndrome" — building systems instead of getting clients

## What We Now Know About GBrain

GBrain is a **vector database** living at `~/.gbrain` on the Windows machine (`C:\Users\vijay\`).
It has a `RESOLVER.md` routing table that maps tasks to agents/skills.
The flat `~/memory/` files on Windows are supposed to feed into GBrain embeddings — but haven't been ingested yet.

Windows-side active agent systems: Hermes, Olympian, Claude/gstack, Codex, Gemini, Cline, Copilot, Continue, GBrain, OpenHuman.

The `~/workspace/ai-home-index/CONTEXT.md` referenced in the Windows audit = this workspace on clawhaven.

**To connect the two sides**, need either:
- OpenSSH Server running on Windows + key auth over Tailscale (100.93.204.88)
- Or SSHFS mount once SSH is available

## Blocked / Needs User Input

1. **Google Drive content** — what's there that isn't in GitHub?
   → User to share links or use cowork to push files here

2. **NotebookLM snippets** — are these config templates or synthesized notes?
   → Determines where they live in the knowledge hierarchy

3. **Local machine files** — SSH closed on zenwinque
   → User to either enable SSH or push via cowork

4. **gbrain implementation** — golden-compass-daemon repo has concept but no code
   → Does an implementation exist elsewhere, or do we build it here?
