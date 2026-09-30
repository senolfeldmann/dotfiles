---
name: repo-deep-scan
description: Extract deep, durable knowledge from an existing software repository into a dossier, a reference Guide, a requirements baseline, and derived instruments, at serious-documentation depth. Use when Şenol wants a repo mined into reusable knowledge, a requirements catalog derived from an existing codebase, or the same deep scan run on another repo (his own or an open-source project he contributes to). Not for a quick README or a single-file explanation.
---

# Deep-scan a repository into durable knowledge

The reproducible method for turning a repository into durable knowledge: mirror the task, capture everything into a dossier by parallel fan-out, interview the owner where reachable, then render finished deliverables from the dossier with a persisted reproducible build.

**Read `~/agents/_shared/prompts/repo-deep-scan-prompts.md` first** (German: `.de.md`). It carries the mandatory BASE block and the stackable OUTPUT blocks A-G verbatim; those blocks are the payload. This skill is the workflow for wielding them - do not restate their content, pull the file into context and work from it.

## Workflow

```
- [ ] 1. Confirm the target: repo path + any auxiliary artifact troves (issue/PR export, stress-test data, design docs)
- [ ] 2. Ask which output blocks to include (AskUserQuestion, below), resolve the constraints
- [ ] 3. Paste BASE + the resolved blocks; run it as a phased program (ROADMAP, fan-out, owner-interview gate)
```

## Step 2: the block-selection question

The BASE block is always included (it produces the dossier every output block consumes, and is sufficient alone if Şenol only wants the knowledge captured). Ask with AskUserQuestion which OUTPUT blocks to add. Two questions:

**Q1 (multiSelect) - "Which deliverables beyond the dossier?"**
- The Guide (A) - full as-built walkthrough with figures
- Requirements catalog - normative baseline, stable REQ-ids
- Derived instruments (C/G) - Day-0 bootstrap checklist + conformance audit rubric
- Standalone prompt-pack (D) - `prompts-product-baseline.md`, condensed Cores

**Q2 (single-select, only if the catalog or anything that needs it was picked) - "Provenance for the catalog and derived instruments?"**
- Sourced (recommended when it is Şenol's own repo) - keeps product/repo/author names, PR numbers, `path:line` evidence -> catalog is BLOCK B, derived is BLOCK C
- Source-blind, stack kept -> catalog is BLOCK E, derived is BLOCK G
- Source-blind and technology-agnostic -> catalog is BLOCK F, derived is BLOCK G

## Mapping answers to blocks (resolve these constraints)

- **The Guide** picked -> BLOCK A.
- **Requirements catalog** picked -> exactly one of B / E / F per the Q2 answer. E and F *replace* B; never include more than one catalog block.
- **Derived instruments** picked -> C if provenance is sourced, else G. C/G derive *from* the catalog, so they require a catalog block: if derived is picked but the catalog is not, include the matching catalog block (B/E/F) as their input and say so. G derives from E or F (never B).
- **Prompt-pack (D)** picked -> D. It condenses the catalog, so it likewise requires a catalog block; include the matching one if not already selected.
- The prompt-pack file BLOCK D emits is generic `prompts-product-baseline.md`; do not confuse it with Şenol's existing `~/agents/_shared/prompts/product-baseline-saas.md` block.

## Running it

- **Phased program, not one-shot.** Track in a living `ROADMAP.md` with gates: extraction (BASE -> dossier), owner-interview gate, then each output block as its own phase. Report at each boundary; keep it resumable.
- **Fan-out at every large step.** Extraction and each big document are produced by parallel per-domain / per-chapter workers writing to one shared brief, each returning only a short summary to protect the orchestrator's context, then an assembler owns the spine, voice, cross-references, and the reproducible build. Per `feedback_limit_resilient_bulk_runs`, make long bulk runs limit-resilient (each worker writes its own file, restartable).
- **Owner-interview gate.** BASE already asks (via AskUserQuestion) whether Şenol owns/maintains the repo or it is third-party. Owned -> run the interview, capture reconstructed ADRs before writing any deliverable. Third-party (open-source he contributes to) -> skip it, keep every "why" as marked inference.
- **HTML house style is a separate building block.** The prompts deliberately do not embed the visual spec. Apply the current house-style block `~/agents/_shared/prompts/html-dokumente.md` and its `~/agents/tools/md2html/` tool for every HTML edition; verify the built HTML (audit + figure-overflow) before delivery.
- **Output language:** EN + DE for every finished document, EN as source of truth (per conventions).
