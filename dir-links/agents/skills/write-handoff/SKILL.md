---
name: write-handoff
description: Generates a self-contained HANDOFF.md that distills the current session into a tight event-and-outcome protocol, so a fresh session can resume without losing the thread and without carrying every detail. Use when the user asks for a handoff, wants to start a new session from a clean summary, or needs a compact context transfer tighter than compaction.
---

# Write a handoff document

Produce a `HANDOFF.md` that lets a fresh session pick up exactly where this one left off. It is curated, not dumped: a mix of event log and outcome protocol, self-contained, tighter than compaction. Where compaction keeps a long, detail-heavy summary inside the same session, a handoff is a standalone document that seeds a brand new session.

The discipline that defines quality: **write from the receiver's perspective.** Ask "what would I need to know if I picked this up cold, and what would only mislead me?"

## What goes in (and what stays out)

Include:
- **Objective**: what the work is trying to achieve, stated directly (not "continue what we discussed").
- **Constraints and conventions**: rules, standards, decisions the next session must respect. Link the governing docs.
- **Decisions and rationale**: what was decided and why. The highest-value part: it stops the next session relitigating settled questions.
- **Current state**: what exists now: files created or changed, what is done, what is verified, committed versus not. Determine this fresh by running `git status` (and `git log` if useful); do not trust the conversation or your memory of it. The state can shift mid-session, for example if the user committed since the last summary.
- **Next steps**: remaining work in priority order, plus open questions and known risks.

Leave out:
- Full conversation history and turn-by-turn narration.
- Dead ends and rejected approaches, unless naming one prevents a retry.
- Internal reasoning chains that already resolved into a decision.
- Anything the receiver can read directly from the files; point to the files instead.

The failure mode is the context dump: pasting raw history wastes the fresh context, and old hypotheses misdirect the receiver into work already abandoned.

## Workflow

```
- [ ] 1. State the objective in one or two sentences
- [ ] 2. List decisions made and their rationale
- [ ] 3. Check the state fresh (git status), then capture it with concrete file pointers
- [ ] 4. List next steps in priority order, plus open questions
- [ ] 5. Cut everything the receiver does not need cold
- [ ] 6. Write HANDOFF.md, then reread it standalone
```

Use `handoff-template.md` (in this skill's directory) as the structure. Fill every section or mark it "none". A silently missing section is how context goes lost.

## Where it goes

Write `HANDOFF.md` into the home of the session's **primary work** - the work a next session would resume. Neither the cwd nor "work happened there" is the criterion. Concretely:

- Primary work is a project (a repo, a Nextcloud project folder): supersede THAT project's `HANDOFF.md`.
- Repos or folders touched only secondarily in the session (skills, the agents repo, a neighboring project): supersede their own project-local `HANDOFF.md` if one exists, but never create a new one for them, and never create an additional session-level document on top - the primary project's handoff is the session handoff.
- The agents repo gets a `HANDOFF.md` only when the agents repo itself IS the primary work (e.g. a modernization roadmap for the repo), never because doctrine/skills/memories were edited alongside a project.
- If the primary work's home is genuinely ambiguous, ask Şenol where the handoff should live instead of defaulting.

If a `HANDOFF.md` already exists, read it first and supersede it in place rather than appending; a handoff describes the present state, not a log of past handoffs.

## Self-containment check

Before finishing, reread `HANDOFF.md` as if you have no other context. If any reference is dangling ("the file we changed"), name it concretely. If a decision lacks its why, add it. The document passes when a cold reader could resume without asking a question. Keep Şenol's typography: ASCII punctuation, German umlauts intact.
