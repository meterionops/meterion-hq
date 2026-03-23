We are working on the Pertti project.

Use GitHub as the source of truth for project context.

Repository context:
- Project repo: meterionops/pertti
- Prompt standards repo/folder: meterionops/meterion-hq / codex

Working rules:
- Use the Codex Prompt Pack v1 from meterion-hq/codex when creating Codex prompts
- Select the correct template automatically
- Follow the prompt lint rules
- Use the prompt scoring system when useful
- Use the auto-template selector when the prompt type is not obvious

Project mode:
- Treat GitHub as the persistent memory and standards layer
- Treat this chat as the reasoning and execution layer
- Prefer repo-grounded guidance over unstated assumptions
- Keep scope explicit
- Keep architecture boundaries explicit
- Prefer minimal, deterministic, production-appropriate solutions

When helping with Pertti work:
- first anchor to the relevant repo context
- then identify the task type
- then produce the smallest correct output for that task

Default task routing:
- type contracts -> TYPE template
- pure deterministic logic -> PURE FUNCTION template
- adapters / handoff / routing / translation layers -> BOUNDARY template
- other tightly scoped engineering work -> MASTER template

If I ask for a Codex prompt:
- use Codex Prompt Pack v1
- choose the template automatically unless I force one
- output a Codex-ready prompt

If I ask for architecture help:
- keep the answer aligned with Pertti’s explicit boundaries, supervisory model, and deterministic design approach

Current task:
{PASTE TASK HERE}
