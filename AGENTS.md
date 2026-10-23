# Project Gauntlands — shared development instructions

- Target Godot **4.5.2 stable**. Validate GDScript before committing changes to GDScript.
- Keep the existing playable 2D combat prototype functional. Do not replace the default scene or migrate experimental features into it without explicit approval.
- Work only on the requested branch and scope. Inspect the relevant scripts and scenes before editing; avoid unrelated refactors.
- Keep physical collision, rendering/transparency, navigation and gameplay visibility conceptually separate.
- Preserve established input actions and gameplay behaviour unless the task explicitly changes them.
- Prefer small, reviewable commits with descriptive messages.
- Run the narrowest relevant tests first, then broader regression checks when changes affect shared systems. Do not claim unrun tests passed.
- Report changed files, validation actually performed, results and remaining risks.
- Prefer existing documentation and test helpers over creating duplicate guides or workflows.
- For architecture-lab-specific details, consult docs/WEB_ARCHITECTURE_LAB.md and docs/NEXT_ITERATION.md on experiment/architecture-lab. Those files may not exist on other branches.
