---
type: concept
title: Workspace Agents
ingested_via: put_page
ingested_at: '2026-05-31T18:07:37.248Z'
source_kind: put_page
---

# AGENTS.md
# Who is here, what each can do, and how to find your way

> This is the cold-start entry point for any agent joining this workspace.
> Read this file first. Then read CONTEXT.md.

## The Operator

**Vijay (vjspal@gmail.com)** — homelab builder, AI systems designer, musician (Reaper DAW),
knowledge architect. Local machine hostname: zenwinque. Primary GitHub: github.com/vjspal.

Core philosophy: **unified over layered** — tools should integrate, not stack. 
Mobile accessibility matters. Fine details must not be lost across handoffs.

## Agents Present on This Machine

| Agent | Config path | Primary role |
|---|---|---|
| Claude Code (you) | `~/.claude/` | Engineering, planning, orchestration |
| Free Claude Code | `~/.fcc/` | Proxy server routing requests to multiple LLM providers |
| Codex | `~/.codex/` | OpenAI agent with its own state/skills |
| Gemini | `~/.gemini/` | Google agent via Antigravity IDE |
| Antigravity IDE | `~/.antigravity-ide-server/` | VS Code-compatible IDE server |
| SecureCoder | `~/.securecoder/` | Security-focused agent (currently empty) |

FCC proxy listens on port 8082. Telegram bot ID: 8363190764 (Vijay's phone).

## Infrastructure Context

This is a **Proxmox VE host** (node: "duality", 192.168.1.200 in the homelab network).
Current external IP on LAN: check `hostname -I`.

Key services visible from here:
- `/opt/PegaProx` — Nginx Proxy Manager instance
- `/opt/cronmaster` — cron job manager
- LXC container 333 — runs user `hermes`, part of the Hermes operator concept

## Knowledge Sources (all cloned under ~/workspace/knowledge/)

| Directory | Source repo | What it contains |
|---|---|---|
| `knowledge/homelab` | vjspal/-homelab.automation | Proxmox/Packer/Terraform/Ansible docs, service catalog, architecture |
| `knowledge/telos` | vjspal/telos | Personal + corporate purpose/context framework (Daniel Miessler's Telos) |
| `knowledge/vault` | vjspal/Ben-s-vault-template | Obsidian vault template — the llm-wiki surface |
| `knowledge/golden-compass-daemon` | vjspal/golden-compass-daemon | The gbrain concept: agentic shadow self |
| `knowledge/integrated-humankind` | vjspal/Literally-integrated-humankind-3.0 | Full unified AI life assistant framework spec + Obsidian mobile control |

Additional knowledge pending (not yet on this server):
- Google Drive: previous laptop backup docs + NotebookLM config snippets
- Local machine (zenwinque, 192.168.68.155): user files — SSH not accessible, use cowork

## The Intended Architecture (gbrain ↔ llm-wiki tandem)

```
telos/personal_telos.md          ← north star: who Vijay is + what he's optimizing for
         ↓
golden-compass-daemon            ← gbrain: agentic orchestration layer
         ↓
integrated-humankind             ← unified command interface + sub-agent delegation
         ↓
vault (Ben-s-vault-template)     ← llm-wiki: Obsidian knowledge vault, AI-maintained
         ↑
~/workspace/knowledge/           ← this shared workspace: neutral ground all agents write to
```

## How to Contribute to This Workspace

1. **Tasks**: Drop files in `tasks/inbox/` — any agent picks them up
2. **Knowledge**: Write to `knowledge/` as markdown with YAML frontmatter
3. **Artifacts**: Outputs go in `artifacts/` with a datestamp prefix
4. **Handoff state**: Update `HANDOFF.md` when stopping mid-task
5. **Context updates**: Update `CONTEXT.md` when the project state changes

## Quick Orientation Commands

```bash
# What's here
ls ~/workspace/

# What's pending
ls ~/workspace/tasks/inbox/ ~/workspace/tasks/active/

# Current handoff state
cat ~/workspace/HANDOFF.md

# Knowledge index
cat ~/workspace/knowledge/INDEX.md
```
