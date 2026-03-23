# Pertti Workflow Rules

1. GitHub is the source of truth.
   - Chat is for thinking, drafting, review, and prompt writing.
   - GitHub is for accepted architecture, state, docs, code, and milestones.

2. Do not rely on chat history as durable project memory.
   - Important accepted work must be written to GitHub.

3. Checkpoint major progress before moving to the next layer.
   - Update `state/current-state.md`
   - Update `projects/pertti.md` when needed
   - Add/update docs in `docs/pertti/`
   - Save contract/code truth in `src/types/`

4. Use Codex only with tightly scoped prompts.
   - Follow Codex Prompt Pack v1 whenever possible.

5. New conversations must restart from GitHub truth.
   - Re-anchor work to:
     - `meterionops/pertti`
     - `meterionops/meterion-hq / codex`

6. Folder roles must stay clear:
   - `src/types/` = contract truth
   - `docs/pertti/` = architecture + workflow docs
   - `state/` = checkpoint history
   - `projects/` = current project snapshot

7. No silent architectural drift.
   - Review, checkpoint, then continue.

8. Recovery must be possible from GitHub alone.
   - If the project cannot be recovered without chat history, the workflow is incomplete.
