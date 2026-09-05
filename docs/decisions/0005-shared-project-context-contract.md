# Shared project context contract

## Status

Accepted on 2026-09-05 at Michael's request.

## Context

Claude and Codex need consistent project knowledge across the Air, mini, and Omarchy laptop.
Existing repositories contain useful guidance but use inconsistent entry points and continuation records.
Some internal records are intentionally excluded from Git.

## Decision

Use the [shared project context standard](../project-context-standard.md) for existing and new projects.
Keep global rules in codex/AGENTS.md and project-specific rules in each root AGENTS.md.
Make CLAUDE.md import or link to that same project instruction file.
Use a document index, current state, structure, operations, decision records, and handoff guidance as the common documentation layer.
Preserve existing application layouts, runtime paths, and privacy boundaries.

## Rationale

Git can transfer reviewed context with its related code and preserve the reason for changes.
Explicit reading instructions make useful context available without requiring shared chat histories.
Synchronizing complete agent directories would mix credentials, machine-specific state, and independent sessions.
Renaming all source directories would introduce unrelated runtime and deployment risk.

## Consequences

Agents must record verified facts, operating changes, durable decisions, and unfinished work in the appropriate records.
Fresh clones receive tracked context; local-only exceptions need safe startup instructions in their tracked README.
Private context transfer and native platform verification remain separate work.
Confluence remains the high-level operator guide and Linear remains the task tracker where configured.

## Revisit triggers

Review the contract if instruction limits truncate required rules, repeated context gaps appear, or privacy boundaries change.
Update existing guidance rather than creating competing context stores.
