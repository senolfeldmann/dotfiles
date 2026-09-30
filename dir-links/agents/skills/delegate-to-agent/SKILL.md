---
name: delegate-to-agent
description: Consults another ~/agents agent mid-session by spawning a fresh subagent loaded with that agent's full persona, then relays its answer back. Use when Şenol, while talking to one agent, wants another agent's input without leaving the current session (e.g. "ask Peter what he thinks", "get Frieda's take"). Synchronous consult, not a permanent switch (that is enable-agent).
---

# Delegate to another agent

Get another agent's input in the current session by spawning a **fresh subagent** that carries the target agent's full persona, as if Şenol had cleanly started a new session with that agent. The subagent answers in its own context and the result is relayed back into this session.

This is the manual, synchronous slice of the delegation layer (roadmap Phase 3.3, variant b). No agent registry is required: the persona is flattened from source at spawn time, so there is no second hand-maintained copy to drift.

## When to use vs. not

- **Use** when you need another agent's judgment *now*, in this session, without abandoning the current thread. The subagent is ephemeral; its answer comes back to you.
- **Not** for permanently switching the active agent of a project — that is `enable-agent` (+ `/clear`).
- **Not** the crosstalk inbox. The inbox is for *asynchronous, durable* agent-to-agent facts picked up at a later session start. A synchronous "what does Peter think" routed through a mailbox mislabels provenance (the originator is Şenol, not the relaying agent) and leaves an ephemeral subagent to archive a file nobody owns. Transport goes in the prompt; the inbox is only for durable spillover (see step 5).

## Workflow

### 1. Resolve the target agent

The target must exist: `~/agents/<target>/persona.md`. If not, list available agents (directories under `~/agents/` containing a `persona.md`) and stop. The target should differ from the currently active agent.

### 2. Flatten the target persona from source

Read and concatenate, in this order, resolving `@import` lines to their file contents:

1. `~/agents/<target>/persona.md`
2. each file it imports: `_shared/user.md`, `_shared/conventions.md`
3. `~/agents/<target>/memories/MEMORY.md`, and the **eager** memories it `@`-imports (the "Eager (always loaded)" section). Lazy memories stay as pointer lines; the subagent reads them on demand if its task needs them, exactly as a real session would.

This reproduces what a clean session in the target's folder loads. Flatten fresh each time; never persist the blob.

### 3. Distill the brief

Write a tight statement of what the target needs to answer:
- the question or task,
- only the context the target needs to judge it.

Do **not** paste the whole current transcript. The point of a fresh subagent is an uncontaminated context; dumping the relaying agent's thread back in defeats it and wastes tokens. Summarize the relevant facts.

### 4. Spawn the subagent

Use the Agent tool (general-purpose) with a prompt shaped as:

```
You are <target>, <one-line role>. The following is your full persona and standing context; adopt it as your own:

<flattened persona blob from step 2>

---

Şenol is in a session with <active agent> and is consulting you. Answer as <target>, in your own voice and judgment.

<distilled brief from step 3>
```

Fidelity note: the persona lands in the subagent's first user turn, not its system prompt (the Agent tool takes no custom system prompt). For a consult in fresh context this is sufficient; a true system-prompt load would need registered `.claude/agents/*` definitions (roadmap Phase 3.2), deferred until automation warrants it.

### 5. Relay, and handle durable spillover

- Relay the subagent's answer back into the session, attributed to the target agent, so Şenol sees whose judgment it is.
- If the consult surfaced a **durable, genuinely cross-agent fact** (something the target or the active agent should still know in a future, unrelated session), that is the legitimate use of the crosstalk inbox: write it to the recipient's `crosstalk/` per `_shared/inbox-convention.md`. Do not write the transient question there.
