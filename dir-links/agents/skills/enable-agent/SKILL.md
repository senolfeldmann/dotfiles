---
name: enable-agent
description: Permanently enables an existing ~/agents agent in a project by symlinking the agent's compiled AGENTS.md into it (read by opencode/Codex and other AGENTS.md harnesses), enforcing one-persona-per-project. Use when Şenol wants to enable, wire, or turn on an agent (Peter, Frieda, ...) for a repo or working directory so it loads there. Inverse is disable-agent.
---

# Enable an agent in a project

Wire an existing agent into a project by symlinking the agent's **compiled** `AGENTS.md` into the project root, so the harness loads the agent's full persona stack on the next session start.

opencode, Codex and other AGENTS.md harnesses cannot resolve @-imports, so the wiring points at a self-contained flatten of the persona stack - produced by `~/agents/tools/agents-compile` and kept fresh by its pre-commit hook. This is a trigger over the one faithful load path, not a second source of truth: the persona stack is authored once under `~/agents/<name>/`, and the symlink points back to it.

Read `~/agents/ARCHITECTURE.md` ("Activation discipline") if the one-persona rule below is unclear.

## What this is not

- Not a runtime reframe. `AGENTS.md` is read once at session start; there is no hot-reload. Takes effect only on the next session start or restart in the target directory.
- Not for enabling an agent *inside* the `~/agents` repo itself. There, start the harness in the agent's folder. Refuse if the target is under `~/agents/`.
- Not delegation. For "I need agent Y's input in this session without switching", use `delegate-to-agent`.

## Workflow

### 1. Resolve inputs

- **Agent name** (required): must be an existing agent, i.e. `~/agents/<name>/persona.md` exists. If not, list the available agents (directories under `~/agents/` with a `persona.md`) and stop.
- **Target project** (optional): default to the current working directory; else the path Şenol names.
- Refuse if the target resolves under `~/agents/` (see above); tell him to start the harness in the agent folder instead.

### 2. Enforce one persona per project

Inspect `<project>/AGENTS.md`:

- **A symlink to a different agent's** `~/agents/<other>/AGENTS.md` → refuse. Report which agent, and that a second persona blends two voices and directives. Offer to `disable-agent` the current one first.
- **Already our symlink to this agent** → no-op; report it is already enabled.
- **A real `AGENTS.md`** (a regular file, or a symlink pointing outside `~/agents/`) → refuse and do **not** touch it. The project has its own `AGENTS.md`; opencode cannot additively import a persona, so composing the two needs a manual decision. Stop and say so.
- **No `AGENTS.md`** → proceed.

### 3. Write the wiring

If the compiled `~/agents/<name>/AGENTS.md` is missing, run `~/agents/tools/agents-compile <name>` first.

Create a symlink at `<project>/AGENTS.md` whose target is the absolute path to `~/agents/<name>/AGENTS.md`.

### 4. Report activation requirement

Tell Şenol the agent is wired, and that it loads only on the **next session start or restart** in that directory (no mid-session hot-reload).
