# Agent Workspace

Multi-agent system powered by markdown files and Claude Code.

## Quick Navigation

| Agent | Path | Purpose |
|-------|------|---------|
| Standard Template | `agents/standard-agent/` | Copy this to create any new agent |

## Key Directories

- `knowledge/` — Static reference (brand voice, strategy, audience profiles)
- `journal/` — Living memory (events, decisions, learnings)
- `templates/` — Agent creation templates
- `orchestrator/` — Cross-agent coordination
- `examples/` — Example agents to learn from

## Agent Structure

Every agent folder contains:
- `AGENT.md` — Goals, KPIs, skills list, constraints
- `skills/` — One markdown per skill
- `HEARTBEAT.md` — Cron schedule and triggers
- `MEMORY.md` — Agent-local learnings
- `RULES.md` — Boundaries, handoff rules

## Key Files

- `AGENT_REGISTRY.md` — Master list of all agents and their status
- `CONVENTIONS.md` — Naming rules and structure requirements
- `NEW_AGENT_BOOTSTRAP.md` — Steps to create a new agent
- `AGENT_CREATION_CHECKLIST.md` — Verify new agents are complete

## Conventions

- Agent folders: lowercase, hyphen-separated under `agents/`
- Output files: `YYYY-MM-DD_agent-name_description.md`
- Agents read from `knowledge/` and `journal/`, write to `journal/` only
- Knowledge files are static — agents propose changes but never edit directly
