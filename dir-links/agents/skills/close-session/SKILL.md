---
name: close-session
description: Distills the important, non-obvious learnings of the current session into long-term agent memories under ~/agents/<agent>/memories, following the repo memory convention. Use when the user wants to close, wrap up, or end a session, persist what was learned, capture takeaways, or save to an agent's long-term memory.
---

# Close session into long-term memory

At the end of a working session, extract what is worth remembering, propose it to Şenol, and on his approval write it as memory files for the active agent, so the next session starts informed instead of cold.

Read `~/agents/_shared/memory-convention.md` first. It defines the file format, the four types, and the storage layout. This skill is the workflow for applying it at session close.

## What this produces

This skill distills the session into semantic memory: the durable facts, rules, and state, written as the four typed files (`user` / `feedback` / `project` / `reference`). It answers "what is true, and what do I do next."

Dated provenance ("when did we touch X, where did a fact come from") lives in git history; at the end you propose a good commit message for the session's changes (step 7). The value of a session is its conclusions, not its play-by-play; never persist the narrative.

## What to persist (and what not)

Persist the non-obvious and durable:
- **feedback**: a rule or correction Şenol gave about how to work, stated operationally.
- **project**: ongoing work, goals, constraints, incidents not derivable from code or git.
- **user**: a durable fact about Şenol (role, preference, background) newly learned.
- **reference**: a pointer to an external resource (dashboard, ticket, doc).

Do NOT persist:
- What the repo, code, git history, or CLAUDE.md already records.
- One-off task detail that only mattered this session.
- Anything you cannot tie to a future use.
- Small tool/setup facts (a keybinding, a config flag and why). These belong as a comment in the config file itself, not a memory: they orphan silently the day Şenol switches tools, and he will not flag it for an update.

The test: "Would a fresh session of this agent be meaningfully worse off without this?" If no, do not write it. A few high-value memories beat many shallow ones. Every memory must also pass the scrutiny test in `memory-convention.md`.

### A semantic memory is a standing rule: weigh the consequence before writing one

A `feedback` memory is not a note that something happened; it is a standing instruction reloaded into context every future session, shaping all later behavior. That power cuts both ways: a wrong or over-broad rule silently distorts every session afterward, which is worse than no rule. Before writing one, calibrate:

- **One-off vs durable.** A single, situational correction is not yet a rule. Şenol pushing back on X once, in one context, does not mean "never do X." Do not harden a one-time reaction into doctrine. Wait for a real pattern, scope the rule tightly to the situation it came from, or leave it unwritten.
- **No absolute wording.** "Always / never / nothing else / do only what is asked" rules strip out the judgment the agent needs to do follow-ups, think ahead, and work (semi-)autonomously, which is wanted behavior. Phrase a rule with its boundaries: when it applies and when it does not.
- **Ask when uncertain.** If it is unclear whether something should be recorded, what type it is, or how absolutely to phrase it, ask Şenol before writing. He would rather be asked than have a one-off correction frozen into a permanent rule he later has to hunt down and delete.

## Workflow

```
- [ ] 1. Identify the active agent (whose memory tree?)
- [ ] 2. Scan the session for durable learnings
- [ ] 3. Dedup against existing memories
- [ ] 4. Present each candidate and ask: save it? eager or lazy? (with your recommendation)
- [ ] 5. Write the approved memories and update MEMORY.md
- [ ] 6. Confirm what was saved, one line each
- [ ] 7. Propose a good commit message in chat
```

### 1. Active agent

Determine whose memories these are. If a persona is loaded (peter, frieda, ...), it is that agent; the target is `~/agents/<agent>/memories/`. If no agent is clearly active and you cannot determine which one the memory belongs to, ask before writing. A misrouted memory is invisible to the agent it describes, which is worse than not writing it.

### 2. Scan for learnings

Review the session for: corrections Şenol made, preferences he stated, decisions reached and their rationale, project context that will outlive the session, external resources mentioned. Note candidates before writing any file.

### 3. Dedup against existing

Read the agent's existing memories (the `MEMORY.md` index lists them). If a learning extends an existing memory, update that file rather than create a near-duplicate. If it contradicts one, correct the old file. Plan `[[name]]` links to related memories.

### 4. Present each candidate in CHAT, then ask only for the decision

Write nothing yet. **Present the candidates as normal chat text, in the
message that ENDS your turn**: per candidate, the filename and whether it is
new or an update, the occasion that produced it in plain words so he can
judge whether it is worth a standing rule, the complete file content in a
fenced block exactly as it would land on disk, and your load-mode
recommendation with its reason.

**Then, and only then, call AskUserQuestion for the decision alone** - one
question per candidate, batched into a single call (up to four; further
batches if there are more), with NO `preview` fields. The question text is
just the filename and "speichern?".

Present candidates in chat so their context and complete text are readable.
**End the turn with that message:** text between tool calls in the same
turn may not render; a turn-ending message does.

**Keep the episode OUT of the file.** The occasion belongs in the chat, as
decision material; the memory body carries the rule, its handle and its
boundary (see `memory-convention.md`: an optional `Why:` states the
principle, not the origin episode). A body that narrates what happened is a
journal entry in the wrong place.

Per candidate, offer:
- **<your recommended mode> speichern (empfohlen)**, your pick, with the
  load-mode why in the option description (per `memory-convention.md`
  "Load mode": eager = always-relevant behavioral rule or core identity;
  lazy = topical, fires when its `description` hook matches),
- **<the other mode> speichern**,
- **Nicht speichern**.

This puts both decisions (save at all, and eager vs lazy) into one answer,
with your recommendation as the default. Write only what he approves, in
the mode he chose; drop what he declines.

### 5. Write the approved memories and update the index

For each approved candidate, one fact per file. Filename: type-prefixed kebab-case, e.g. `feedback_<slug>.md`, `project_<slug>.md`. Frontmatter per the convention:
```
---
name: <human-readable title>
description: <one-line, specific, ~150 chars, for relevance triage>
type: user | feedback | project | reference
---
```
Body structure (rule-vs-state per type, optional Why, linguistic minimum) and typography follow `memory-convention.md` and `conventions.md`. Convert relative dates to absolute.

Per-agent memories live in `~/agents/<agent>/memories/`; only use the Claude Code auto-memory path when the content is genuinely repo-wide and agent-independent (rare). Then register each file in `~/agents/<agent>/memories/MEMORY.md`, in the section matching the mode Şenol chose (eager `@import` vs lazy pointer line).

### 6. Confirm

List what you saved or updated, one line each, in the chosen mode. Do not restate the file bodies.

### 7. Propose a commit message

Propose one good commit message in chat for the session's memory changes: a concise subject line, plus a short body listing the key changes if more than one. This is the dated record. Write commit messages in English, regardless of the conversation language, unless Şenol explicitly asks for another language. Do not commit unless Şenol asks.
