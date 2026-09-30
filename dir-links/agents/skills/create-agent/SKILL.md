---
name: create-agent
description: Scaffolds a new named agent in the ~/agents framework with the correct three-layer structure (persona.md, CLAUDE.md, memories/ with proper @imports). Use when the user wants to add, create, or scaffold a new agent, virtual employee, advisor, or persona in the agents repo.
---

# Create a new agent

Scaffold a new named agent in the `~/agents` framework. An agent is a Markdown persona plus a memory tree, opted into a project via `@import` in that project's `CLAUDE.md`.

Read `~/agents/ARCHITECTURE.md` and `~/agents/_shared/conventions.md` before writing, so the new agent fits the three-layer model instead of duplicating shared content.

## The three layers (what goes where)

Every agent inherits three layers. Each fact belongs in exactly one:

- **`_shared/user.md`**: who Şenol is (facts). Never edit per agent.
- **`_shared/conventions.md`**: how all agents work and communicate (universal directives: tone, explanation, decisions, output, coding, typography, language, voice-to-text). Inherited by import; the persona must NOT restate any of it.
- **`<agent>/persona.md`**: only what is specific to this agent: role, background, scope, scope of authority, domain operating principles, voice register, domain code-switching examples, persona-specific things to avoid.

The single most common mistake is copying universal directives (no flattery, recommend a path, state uncertainty, ASCII typography, default German) into the persona. They are already inherited. Write only the delta.

## Workflow

Copy this checklist and track progress:

```
- [ ] 1. Capture intent: name, role, scope, authority zones
- [ ] 2. Create directory structure (incl. drop/ + crosstalk/ inboxes) and import block
- [ ] 3. Fill persona.md (skeleton first, see rule below)
- [ ] 4. Seed memories/MEMORY.md and .gitkeep
- [ ] 5. Wire CLAUDE.md
- [ ] 6. Register: README agent list and Frieda's team-roster
- [ ] 7. Verify imports resolve and typography is clean
```

### 1. Capture intent

Ask only what you cannot infer:
- Agent name: lowercase, one word. A human first name fits the existing set (peter, frieda).
- Role, in one sentence.

### 2. Directory structure and imports

Create under `~/agents/<agent>/`:
```
<agent>/
├── CLAUDE.md
├── persona.md
├── drop/                 # Şenol -> agent inbox (see _shared/inbox-convention.md)
│   └── archive/
│       └── .gitkeep
├── crosstalk/            # agent -> agent inbox
│   └── archive/
│       └── .gitkeep
└── memories/
    ├── MEMORY.md
    └── .gitkeep
```

The two inboxes are the framework standard (`_shared/inbox-convention.md`). The session-start pickup rule is universal and lives in `_shared/conventions.md`, inherited through the persona import below. Do **not** add an inbox section to the persona; that would duplicate a shared rule per agent.

Persona import block, in this order:
```
@../_shared/user.md
@../_shared/conventions.md
@./memories/MEMORY.md
```

### 3. Fill persona.md

Use `persona-skeleton.md` (in this skill's directory) as the section structure. Its import paths are already written for the target location `~/agents/<agent>/persona.md`.

**Skeleton rule (important):** persona content is Şenol's voice. Offer him the explicit choice between a skeleton (section headers only, he writes the body) and a starter draft he edits. He has consistently chosen the skeleton for voice files. Default to the skeleton; do not fill in plausible persona prose he will only rewrite. Derivable, non-voice content (the import block, directory layout) you fill in normally.

Persona sections:
- **Role**: who the agent is to Şenol, in peer terms.
- **Background**: the experience that grounds the role and its judgment.
- **Scope / specialization**: what it covers.
- **Scope of authority**: named zones (high / medium / low, or a four-zone variant), where the agent's voice carries weight versus where Şenol decides. Model on Peter's or Frieda's zones.
- **Operating principles**: domain-specific judgment rules. NOT the universal ones from conventions.
- **Tone**: the agent's voice register, and any domain code-switching examples (e.g. Ausfallsicherheit/fault tolerance).
- **Things to avoid**: persona-specific only; do not relist conventions.

### 4. Seed the memory index

`memories/MEMORY.md` is the **two-section** index defined in `~/agents/_shared/memory-convention.md` ("Load mode"): **eager** memories are `@`-imported and always in context (always-relevant behavioral rules + core identity); **lazy** memories are pointer lines read on demand when their `description` hook matches the topic. A new agent starts with both sections empty:
```
# <Agent>'s cross-project memories

Two sections (see `memory-convention.md` "Load mode").

**Eager** memories are `@`-imported and always in context: always-relevant behavioral rules and core identity. **Lazy** memories are pointer lines only; read the file on demand when its hook matches the current topic.

## Eager (always loaded)

_none yet_

## Lazy (read the file on demand when the hook matches)

_none yet_
```
Add an empty `.gitkeep` so the directory is tracked while empty.

### 5. Wire CLAUDE.md

```
@./persona.md
```
This is the entry point when Claude Code starts inside the agent's folder.

### 6. Register the agent

- Add the agent to the README agent list if it lists them.
- Update Frieda's roster at `~/agents/frieda/memories/team-roster.md`: role, core tasks, routing triggers, boundaries. Frieda routes by this file; a new agent invisible to her is a routing gap.

### 7. Verify

- Every `@import` path resolves to a real file.
- Both inboxes exist: `drop/archive/.gitkeep` and `crosstalk/archive/.gitkeep`. The persona carries no inbox section (the rule is inherited from `conventions.md`).
- Typography is clean: no em-dashes, en-dashes, smart quotes, ellipses, non-breaking spaces. German umlauts stay as umlauts (never ae/oe/ue). A linter may exist under `~/agents/tools/`; use it if present.
- The persona restates nothing from `conventions.md` or `user.md`. If a line would be true for every agent, it does not belong in the persona.
