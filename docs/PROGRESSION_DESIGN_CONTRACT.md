# Next RPG Design Iteration — Progression, Powers and Feats

Status: **design-only contract; not authorisation to implement gameplay**.
Recorded: 2026-10-23. Iteration number intentionally unassigned: existing numbered gameplay iterations retain their scope.

## Authority and sources

Read alongside:
- [AGENTS.md](../AGENTS.md): current implementation authority and bounded iteration discipline.
- [DESIGN.md](../DESIGN.md): true 2D, gamepad-first action, compact statistics and physical contact before RPG resolution.
- [ITERATION_01.md](ITERATION_01.md): authoritative combat-room contract for that milestone.
- [RPG_SYSTEMS.md](RPG_SYSTEMS.md): wider RPG design reference on this design branch.

Source snapshot: main at c8dda02c353fc37dd5ca53dc72dc330e80f3e2e6; RPG reference at design/rpg-systems commit 67308a6f236d7cc8f3036ba8013eacece019e46f.

This contract bounds the next **design pass** to character progression, power acquisition, feat choices and active-slot eligibility. It does not supersede any gameplay implementation contract. Nothing here changes current combat tuning, controls, ammunition, equipment or restart behaviour.

## Design question and deliverable

Can a character become stronger and gain meaningful build choices gradually while retaining a small, readable set of gamepad actions?

Deliver a coherent written model, slot rules, worked examples and an explicit decision backlog. Do not create code, scenes, Resources, UI, migrations, assets or progression infrastructure in this pass. Existing gameplay branches and main remain untouched.

## Decision status

**Recorded direction** means supported by the user request or RPG reference. **Proposed contract rule** means a bounded clarification for review, not a claim of an earlier user decision. **Open** means no implementation default may be silently inferred.

## Progression model

### Recorded direction

Character progression has three distinct rewards:
1. **Numerical growth:** bonus statistics improve a character's capabilities.
2. **Power development:** powers become available gradually; learning and upgrading powers are separate from equipping them.
3. **Feat choices:** the player selects build specialisations, including changes to slot eligibility.

Character progression and equipment progression are separate, interacting tracks. This pass defines the character track only. Equipment acquisition, inventory and affix systems remain outside its scope.

The reference identifies STR, DEX, CON, WIS and INT, but their combat formulas and advancement rules remain open. Preserve compact early numbers and the threat posed by ordinary enemies. Bonus stats must not replace position, range, collision, attack timing or ammunition management.

For discussion, distinguish baseline statistics, earned character bonuses and eventual equipment modifiers. This is a conceptual separation, not a requirement for a runtime stat framework.

### Proposed contract rules

Describe advancement using **milestones** until the levelling schedule is agreed. A milestone can award a stat bonus, power-learning opportunity, power upgrade or feat choice; it need not award all four.

A future advancement record should state:
- eligibility or milestone;
- reward type and permitted choices;
- prerequisites;
- whether the result grants knowledge, changes an existing power, or changes loadout eligibility.

Do not assume that every level grants a feat, that every bonus is player-allocated, or that a power unlock automatically equips it.

### Open

XP versus other advancement triggers; level cap; milestone levels; stat bonus sizes and allocation; HP growth; caps and stacking; retroactive effects. Level 1–20 is an existing proposal, not an agreed schedule.

## Power unlock and upgrade structure

### Recorded direction

Keep these states distinct:

| Concept | Meaning |
| --- | --- |
| Eligible | Character meets the stated requirements to acquire the power. |
| Known | Character has learned the power into their available library. |
| Equipped | A known power occupies a compatible active slot. |
| Usable now | Equipped power also satisfies mode, prerequisites, resources and recovery conditions. |

Eligibility alone does not grant ownership. Knowing a power does not grant another active slot. Equipping a power does not bypass cooldowns or prerequisites.

Powers unlock gradually. Learning a new power expands choice; upgrading a known power changes or specialises that power. Branching upgrades may offer alternatives rather than simple numerical improvements.

Each future power definition must identify its category, acquisition requirements, effect and relevant activation restrictions. Costs, charges, cooldowns and upgrades belong to the power, not to the slot.

A power temporarily unusable because of weapon mode or prerequisites remains selected. Availability and cooldown are separate states.

### Open

Guaranteed unlocks versus player-selected learning; shared versus separate learning/upgrade opportunities; the proposed hybrid schedule; prerequisite trees; upgrade exclusivity and replacement; power catalogue; cooldowns, charges, costs and interruption rules.

## Slot categories and action boundaries

### Recorded direction

Four baseline configurable class-power slots:

| Slot category | Role | Illustrative reference example |
| --- | --- | --- |
| Offensive / Attack | A specialised attack or offensive effect | Power Strike |
| Defensive | Protection, mitigation or defensive response | Brace / Shield Block |
| Utility | Support or another non-primary-attack capability | Second Wind |
| Movement | Repositioning or mobility | Dodge Roll |

“Attack slot” in the conversion rule means the **Offensive class-power slot category**. It does not mean the basic weapon Attack action.

Basic Attack, weapon-mode switching, Item/quick item and Interact remain distinct from these four class-power slots. Power slots are not equipment slots. A shield equipment slot is not the Defensive power slot.

Preserve a viable at-will basic attack in the eventual design; this does not override an enemy's resistance or immunity. The current sword and bow remain governed by their existing contract.

The reference controller mapping is provisional. This document assigns no new buttons and remaps no current controls.

### Proposed contract rule

Each active slot holds at most one power. An empty compatible slot is allowed; category flexibility does not permit multiple powers in one slot.

### Open

Starting powers, timing of slot access, duplicate copies of the same power across slots, multi-category power classification and final control mapping.

## Feat choices and slot conversion

### Recorded direction

Feats consume normal feat choices and customise builds. They may modify powers, improve synergies or broaden slot eligibility. They are not automatically granted alongside every power unlock.

The requested defensive-to-attack/utility conversion follows the reference's preferred **optional eligibility expansion**:
- A qualifying feat permits an existing Defensive slot to accept an Offensive power or a Utility power, as specified by the feat.
- The slot retains permission to hold a Defensive power.
- The player chooses the equipped power during build configuration.
- No extra active slot or controller input is created.
- The feat does not itself teach a power.
- Prerequisites, mode restrictions, costs, charges and cooldowns still apply.
- No build reconfiguration during combat.
- Movement and Item actions remain stable; this contract introduces no conversion for them.

The practical trade-off is loadout capacity: filling the Defensive slot with an attack or utility power leaves that slot without an equipped defensive power. The feat does not delete defence statistics, shield equipment or other independent defensive effects.

### Proposed contract rules

Use these illustrative feat variants to make the rule reviewable:

| Illustrative feat | Defensive slot accepts | Consequence when filled with the new category |
| --- | --- | --- |
| Offensive Flexibility | Defensive or Offensive | One additional equipped offensive power |
| Utility Flexibility | Defensive or Utility | One additional equipped utility power |

These are working labels, not approved feat names or a final catalogue. Whether one feat offers a choice of category or separate feats provide each option remains open.

A conversion requires an existing eligible slot. It cannot create a slot from nothing. An incompatible or unknown power cannot be assigned.

An eventual implementation specification must define what happens to an equipped power if the enabling feat is removed. An invalid assignment must never silently remain usable.

### Open

Feat unlock cadence; number of choices; prerequisites; whether both flexibility options can coexist; repeatability and stacking; respec availability/cost; category choice permanence; cooldown handling when reconfiguring; safe timing and definition of “in combat”.

Do not infer that flexibility permits cooldown resets, combat swapping or automatic activation of two powers.

## Worked design checks

These are paper examples, not current game behaviour. Power names and reward timing are illustrative.

1. **Gradual unlock:** a Fighter becomes eligible for Power Strike. Until learned, it cannot be equipped. Once learned, it may fill an Offensive slot; its unlock does not add another slot.
2. **Offensive conversion:** a Fighter knows two distinct Offensive powers and has Offensive Flexibility. One fills the normal Offensive slot; the other fills the broadened Defensive slot. There are still four class-power slots, and that Defensive slot provides no equipped defensive power.
3. **Utility conversion:** Utility Flexibility lets a known Utility power occupy the Defensive slot while a different Utility power occupies the normal Utility slot. This adds an equipped option, not a free cast or cooldown bypass.
4. **Return to defence:** during permitted build configuration, the broadened slot can hold a Defensive power again. Whether changing the feat itself is allowed is a separate open respec decision.
5. **Temporary restriction:** a shield-dependent power remains equipped when ranged mode makes it unavailable. Slot flexibility does not make shield blocking available in ranged mode.
6. **Combat boundary:** an attempted mid-combat reassignment is disallowed under the intended design. This document does not add that system to the present combat slice.
7. **Stat growth:** a future earned bonus affects only the statistics specified by its eventual rule. It cannot turn a physically invalid sword swing into contact.

## Explicit non-goals

No implementation of levelling, XP, character creation, inventory, equipment, loot, save/load, town, Guild, Codex, recruitment, multiclassing or additional classes. Fighter is the reference class only. No full power catalogue, balanced feat tree or numerical progression table.

Do not replace the current five-arrow combat-room default with the RPG reference's future ten-arrow starting loadout. Do not add shields, mode switching, healing or new powers to the current game through this document.

## Design acceptance criteria

This design pass is complete when:
1. Stat growth, power learning/upgrading, equipping and feat selection are distinguished.
2. All four slot categories and their separation from basic Attack, Item and equipment are explicit.
3. Defensive-to-Offensive and Defensive-to-Utility builds are described without increasing active-slot count or removing defensive eligibility.
4. Conversion preserves acquisition requirements, restrictions and no combat reconfiguration.
5. Worked cases cover learning, both conversions, defence restoration and invalid/temporary availability states.
6. Unsettled progression, balance, feat and reconfiguration decisions are clearly labelled.
7. Only documentation is changed; current implementation contracts and gameplay are preserved.

## Implementation handoff gate

A later, explicitly authorised implementation pass must select a bounded subset, resolve its necessary open decisions, and create a numbered iteration specification with concrete behaviour and testable acceptance criteria. Update AGENTS.md / DESIGN.md milestone references deliberately at that time.

Do not treat completion of this document as permission to begin that pass.

## Validation for this delivery

Review against the four source documents and the requested progression decisions. Verify the commit contains documentation only. Godot validation is not required for a documentation-only change; no runtime test result is claimed.
