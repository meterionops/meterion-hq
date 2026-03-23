We are working on Pertti architecture.

Use GitHub as the source of truth:
- meterionops/pertti
- meterionops/meterion-hq / codex

Architectural principles:
- strict boundaries between layers
- supervisory (non-executing) core
- proposal-first model
- deterministic where possible
- explicit contracts over implicit behavior

Focus:
- correct layer placement
- clean separation of responsibilities
- minimal surface area
- long-term extensibility
- no hidden coupling

When analyzing or designing:
- identify the correct layer (types / pure logic / boundary / execution)
- ensure responsibilities do not leak across layers
- prefer splitting over overloading modules
- avoid mixing contracts and execution

When proposing solutions:
- keep them minimal
- keep them composable
- keep them explainable

If the design feels unclear:
- simplify
- separate concerns further

Current topic:
{PASTE TOPIC HERE}
