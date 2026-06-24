---
type: concept
title: Workspace Windows Agent
ingested_via: put_page
ingested_at: '2026-05-31T18:07:43.530Z'
source_kind: put_page
---

# WINDOWS-AGENT.md
# Handoff doc for Claude Code running on the Windows machine (vijay @ zenwinque)

Last updated: 2026-05-30

## Your role

You are the Windows-side node of siedirOS. The **primary workspace on this machine is
`lifeos`** (`C:\Users\vijay\lifeos`). Start there. Other workspaces (`seidr`,
`omarchyworkspace`, `Personal_AI_Infrastructure`) exist and will be consolidated into
`lifeos` once the SSH bridge to clawhaven is stable.

The server-side node (clawhaven) has a shared workspace at `~/workspace/` — read
AGENTS.md and CONTEXT.md there for the full picture.

The `gstack-brain-init` startup warning you may see is non-fatal — ignore it for now.
It's a hook calling a command not on PATH. Fix later via `~/.claude/settings.json`.

## Shared workspace (on clawhaven server)

The server at 192.168.68.69 has a fully populated knowledge base at `~/workspace/`.
Once SSH is wired up, you can mount it or push/pull files via scp.

Key docs already written there:
- `~/workspace/AGENTS.md` — all agents, their roles, cold-start protocol
- `~/workspace/CONTEXT.md` — current system state
- `~/workspace/knowledge/siediros.md` — full siedirOS architecture
- `~/workspace/knowledge/gbrain.md` — GBrain spec + CLI reference
- `~/workspace/knowledge/windows-audit.md` — audit of this machine

## Immediate task: authorize the server's SSH key

**Linear issue:** STA — "Wire clawhaven SSH key auth to Windows machine"

OpenSSH Server is already installed and running on this machine. The server's public key
needs to be in the correct file for admin users.

Run this in PowerShell **as Administrator**:

```powershell
New-Item -Path "C:\ProgramData\ssh" -ItemType Directory -Force
Set-Content "C:\ProgramData\ssh\administrators_authorized_keys" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsO1jrV6x7TbiitbQBpP73g0mam9hYDidNuiTnqW/JO clawde@clawhaven"
icacls "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "SYSTEM:(F)" /grant "Administrators:(F)"
Get-Content "C:\ProgramData\ssh\administrators_authorized_keys"
```

The key should echo back. Test from clawhaven:
```bash
ssh vijay@192.168.68.155 "whoami"
```

## What lives on this machine that agents need

| Path | What it is |
|---|---|
| `~/.gbrain/config.json` | GBrain config (Supabase connection) |
| `~/memory/` | Flat memory files — NOT yet ingested into GBrain |
| `~\.gbrain\` | GBrain install |

**Note:** CLAUDESTINE workspace (ORCHESTRATOR.md, TELOS, providence vault) was on the
previous laptop (username: hotdog). It does NOT exist on this machine yet. The canonical
copy is in Google Drive — needs to be restored here or rebuilt from Drive backup.

## After SSH works — next actions

1. Server mounts `~/mnt/windows` via SSHFS
2. Ingest `~/memory/` flat files into GBrain (`gbrain import ~/memory/`)
3. Write SOUL.md — agent identity file (currently empty, blocks all persona-aware work)
4. Verify GBrain health (`gbrain doctor --json`)
5. Wire GBrain MCP into Claude Code config on both machines

## GBrain quick reference

```bash
gbrain doctor --json       # health check
gbrain stats               # page count, embed coverage
gbrain import <dir>        # ingest markdown directory
gbrain query "question"    # hybrid search
gbrain serve               # start MCP server
```

Config: `~/.gbrain/config.json`

## System name

siedirOS. You are a node in it. The full spec (ORCHESTRATOR.md) is in Google Drive —
it was not migrated to this machine yet. Read `~/workspace/knowledge/siediros.md` on
clawhaven for the architecture summary.
