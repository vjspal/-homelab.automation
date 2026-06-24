---
type: concept
title: siedirOS — Personal AI Operating System
source: 'Google Drive (ORCHESTRATOR.md, TELOS.md, project_architecture.md)'
status: 'active, v1 architecture defined'
ingested_via: put_page
ingested_at: '2026-05-31T18:07:26.622Z'
source_kind: put_page
tags:
  - memory
  - orchestrator
  - siediros
  - telos
  - workspace
---

# siedirOS

The personal AI operating system. Not an app — an agent-first workspace with defined
SOPs, memory protocol, and progressive disclosure routing.

## System components

| Component | What it is |
|---|---|
| **ORCHESTRATOR.md** | The constitution. First agent loaded. Routes all work. |
| **TELOS.md** | Context index. Progressive disclosure. Orchestrators read this. |
| **MEMORY.md** | Persistent cross-session memory (qualifying events only) |
| **SOUL.md** | Agent identity/vibe (currently empty — needs writing) |
| **USER.md** | User context for sub-agents |
| **HEARTBEAT.md** | Operational cadence |
| **GBrain** | Knowledge backend (Postgres + pgvector) |
| **Providence vault** | Obsidian wiki (7,471 files, 2.3GB) — the llm-wiki surface |
| **Verdigris vault** | Second Obsidian vault (barely started) |

## Orchestrator SOPs

**Session Start:**
1. Read `MEMORY.md`
2. Read `TELOS/TELOS.md`
3. Identify task type → check Disclosure Map → load only those files
4. Route to workstation or handle directly
5. Begin — do not announce the steps

**Memory criteria (must meet at least one):**
- Decision with stakes (write WHY, not just what)
- Status change (project moved, goal hit, client signed)
- New permanent context (person, tool, relationship)
- Explicit instruction ("remember this")
- Lesson from failure or surprise

**Spawning sub-agents:**
- Check Disclosure Map → load only specified files
- Never pass ORCHESTRATOR.md, full TELOS index, or MEMORY.md unless explicitly required

## TELOS Disclosure Map

| Task type | Load these files |
|---|---|
| Sales, outreach, client conversations | CORPORATE_TELOS.md, STRATEGIES.md, NARRATIVES.md |
| Planning, prioritization | GOALS.md, PROJECTS.md, CHALLENGES.md |
| Writing in V's voice | NARRATIVES.md, BELIEFS.md, voice-principles.md |
| Evaluating tool/system/idea | MODELS.md, BELIEFS.md, STRATEGIES.md |
| Reflection/retrospective | LEARNED.md, MODELS.md, BELIEFS.md |
| Full strategic context | MISSION.md, GOALS.md, STRATEGIES.md, CHALLENGES.md |
| Idea capture | IDEAS.md |

## Decision authority

**Act without asking:** Read files, draft content, update MEMORY.md, suggest structural changes  
**Do then report:** Create files/folders, update reference files, restructure drafts  
**Confirm before doing:** Workspace structure changes, overwriting files, edits to ORCHESTRATOR.md  
**Never:** Publish, send, post, fabricate stats, make unilateral business decisions

## The workspace hierarchy

Previous laptop username: `hotdog` → current machine username: `vijay`

**The siedirOS workspace on the current machine is `seidr` (`C:\Users\vijay\seidr`),
not CLAUDESTINE.** CLAUDESTINE was on the old laptop (hotdog). The current machine has
a different workspace name.

What CLAUDESTINE contained (from Drive backup — may be in seidr now):
```
CLAUDESTINE/
├── ORCHESTRATOR.md
├── CLAUDE.md
├── MEMORY.md
├── telos/                  ← 10 TELOS files (all populated as of 2026-04-25)
├── memory/                 ← 5 persistent memory files
├── drafts/                 ← business content
└── LLM WIKIs/
    ├── providence/         ← full Obsidian vault (7,471 files) — the llm-wiki
    └── verdigris/          ← barely started
```

**Pending:** Restore CLAUDESTINE from Drive to `C:\Users\vijay\CLAUDESTINE\` on current machine.

## Current TELOS state (as of 2026-05-07)

**Identity:** V is a solo operator building AI Revenue Recovery targeting local service
businesses (HVAC, plumbing, roofing, cleaning). Pre-revenue — bartending is income.

**Active focus:**
1. Revenue Recovery Scan — must ship before outreach starts
2. First paying client — target 2026-05-31
3. Vault/PAI build — this system

**Core beliefs:** AI-human integration is inevitable. Sovereignty over convenience.
Systems compound. Act → Report (not Ask → Act).

**Known blockers:** No clients. Offer untested. Geographic focus undefined.
Scan not finalized.

## Key insight from Gemini analysis

"Cathedral Builder syndrome" — elite system design capability + recurring execution
stalling. Framework stacking (TELOS + OKRs + RPG metaphors) creates cognitive overhead
rather than momentum. The vault is a support system for a business that doesn't have
clients yet.

**90-day plan bottom line:** One paying client by Day 90. Stop building the vault as
if it's the business.

## This server's role in siedirOS

`~/workspace/` on clawhaven = the `~/workspace/ai-home-index/` referenced in the
Windows audit. This is the server-side node of siedirOS — where agents that run
here can read/write shared state.

Next: wire GBrain MCP into Claude Code config on this server, mount Windows files
via SSHFS over Tailscale, ingest ~/memory/ flat files into GBrain.
