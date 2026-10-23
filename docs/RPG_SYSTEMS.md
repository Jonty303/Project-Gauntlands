# Gauntlands — RPG Systems Design

Status: **design reference, not an implementation contract**. Recorded 2026-10-23.
This document collects decisions from the RPG design discussion. Numerical examples are illustrative unless explicitly designated as rules. Do not implement these systems until a dedicated iteration specification authorises them. Existing iteration contracts take precedence for their own scope.

## Vision and progression
- Real-time, gamepad-first dungeon action with tabletop-inspired RPG resolution and meaningful character builds.
- Two interlocking progression tracks: **character** (attributes, skills, feats, selectable powers and upgrades) and **equipment** (items, statistics, affixes, synergies). Either track may trade off against the other rather than always stacking.
- Begin with **Fighter** only. Possible future classes, in intended order: Magic-User, Thief/Rogue, Cleric/Priest. No commitment to implement them yet.
- Preserve the possibility of multiclass feats, cross-class powers, rare items granting powers, and unconventional builds (e.g. plate Fighter with Blink), without implementing them now.

## Attributes and initial Fighter generation
Five attributes: Strength (STR), Dexterity (DEX), Constitution (CON), Wisdom (WIS), Intelligence (INT). No Charisma; occasional social/roleplay checks should use relevant existing attributes and skills.
- STR: physical strength and melee; DEX: precision, ranged and evasion; CON: HP, poison resistance and endurance; WIS: perception, intuition and possibly divine magic; INT: arcane knowledge and magic. Exact formulas remain undecided.
- Proposed familiar D&D modifier: floor((score - 10) / 2), subject to balancing.
- Starting character: roll **4d6 drop lowest** five times; sort descending.
- Randomly assign highest and second-highest to STR/DEX with equal probability of which receives the highest; assign middle score to CON; randomly assign fourth and fifth to WIS/INT with equal probability of which receives fourth.
- No player allocation or reroll in initial character creation. An optional randomisation button is a future idea, not a current requirement.
- Attribute growth and full levelling rules are not decided.

## Combat modes and active actions
There are seven player-facing actions: Attack (uses current weapon mode), Switch melee/ranged, Offensive power, Defensive power, Utility power, Movement power, Item/quick item, plus a separate Interact/Use action.
- **Melee mode:** melee weapon and compatible shield/offhand are active. Shield may restrict future melee combos and enables shield-dependent blocking powers.
- **Ranged mode:** only ranged weapon is active; no shield block. A shield remains equipped but inactive.
- Equipping a shield does **not** replace the ranged equipment slot. Shield has a separate equipment slot.
- Two-handed melee interactions, passive bonuses from equipped-but-inactive items, and switching timing/interrupts remain undecided.
- Power remains selected when temporarily unusable due to mode or prerequisites; availability and cooldown are distinct states.
- Each character should retain a viable at-will attack; resistances/immunities can still make a given attack ineffective against a particular enemy.

### Controller concept (provisional mapping)
Xbox-style example: left stick move; right stick directional target selection/cycling; R3 lock/unlock. Face buttons: A Attack, B Movement, X Interact/Use, Y Item. LB Defensive, RB Offensive, LT Utility, RT Switch mode. Keyboard mirrors controller for development. This is a proposal to playtest, not a final remap of existing controls. Attack and Switch placements may be reconsidered. Directional movement powers should use movement direction; target-lock behaviour should remain consistent with DESIGN.md.

## Power model
- Four configurable class-power slots: **Offensive, Defensive, Utility, Movement**.
- Weapon/attack sources occupy the melee or ranged weapon slot and may be physical items, conjured weapons, or intrinsic attacks. At-will magical attacks such as Magic Missile and conjured blades can replace physical weapons and remain spammable/balanced against other basic attacks.
- Conjured attacks occupying weapon slots do **not** automatically receive physical weapon item statistics. This is a meaningful trade-off; flexibility, effects, scaling or upgrades may compensate. Other powers may explicitly require and modify a physical weapon.
- Powers may have individual cooldowns, charges, charge-recovery rules, duration, damage types, tags, prerequisites and branching upgrades. Cooldown is not determined by slot.
- Illustrative cadence: at-will attack cadence; tactical ~5–30s; encounter-scale ~60s; expedition-scale ~5–10 minutes. These are not fixed cooldown rules, and elapsed-time cooldowns are not necessarily per-encounter/per-dungeon use limits.
- Power upgrades could trade duration against cooldown, add charges, change behaviour, or specialise into mutually exclusive variants. Acquisition/progression not yet decided.
- Suggested tags/hooks for future data-driven design: damage type, attack category, weapon type; activation, travel, arrival, block/hit and completion events. Avoid building an elaborate framework prematurely.
- Example powers: Fighter Power Strike (offensive), Brace/Shield Block (defensive), Second Wind (utility), Dodge Roll (movement). Other future examples: Sprint, Charge, Blink, Fireball. Names and tuning provisional.

## Armour and mobility
- Physical Dodge/Roll and similar movement powers are affected by armour: shorter distance, fewer maximum charges and/or recovery constraints. Do not necessarily stack every penalty.
- Sprint and Charge may have different armour interactions; magical Blink/teleportation generally ignores physical armour-mobility penalties unless a specific rule says otherwise.
- Armour categories and exact multipliers are unbalanced examples, not final rules.
- Chest armour determines primary base Armour Class and armour category. Other slots may provide separate affixes/stats without necessarily adding base AC.

## Fighter starting loadout (agreed direction)
Every initial Fighter starts with the **same basic gear** irrespective of rolled attributes:
- Melee: basic sword.
- Ranged: basic bow.
- Shield: basic shield **carried in inventory initially**, available to equip in its separate shield slot.
- Chest: leather chest armour, determines base AC.
- Head: basic helmet; legs: leather breeches; feet: leather boots; hands: leather gloves.
- Starting gear is intentionally trash-tier: no bonus statistics on these items except chest armour's AC contribution.
- Ammunition slot initially holds **10 arrows**; capacity may be upgraded later.
- Additional arrows may be stored in inventory, but **cannot be transferred to the loaded ammo slot during combat**. Ammo replenishment outside combat is allowed; exact engagement boundary TBD.
- No gear swapping or build reconfiguration during combat.
- Later recruits from the tavern may have varied equipment; fixed loadout applies to the initial character.

## Equipment, prerequisites and item bonuses
- Equipment slots and active action/power slots are distinct.
- Classes may differ in permitted/effective equipment slots: Fighter has physical weapon and shield versatility; future Magic-User may trade equipment stat slots for intrinsic/conjured powers. Exact restrictions not settled.
- Individual item properties are **independently evaluated**: an item remains usable, and its unconditional bonuses continue working, even if one conditional bonus's prerequisite is unmet. Show inactive property and its requirement in tooltips.
- Prerequisites may reference a specific equipped power, feat, upgrade, weapon type, armour category, active mode or event. Distinguish 'power equipped' from 'power used/triggers'.
- Example: Stormbrand has normal damage and lightning-on-hit regardless of build, but its Charge-specific stun triggers only when Charge is equipped and used successfully.
- Item effects may alter a specific power slot or event: flame along a physical roll/charge path, fire at Blink endpoints (teleportation does not traverse intervening floor), lightning weapon attacks, shield reflect, chaining projectiles, etc. Item modifiers can be stat modifiers, behavioural modifiers or power grants.
- Modifiers should respect physical mechanics and damage types; do not accidentally trigger floor traps along a Blink's nonexistent traversed path.
- Future feats may bridge classes/powers; conditional effects and stacking limits need explicit rules before implementation.

## Skills and feats
- Skills should matter in dungeon exploration, not just dialogue: examples Perception, Athletics, Thievery, Arcana, Dungeoneering, Insight.
- Skill investment could change the quality of hints and detection, not merely binary success/failure.
- Feats customise builds, including weapon synergies, physical mobility, power modifications and possibly future multiclass access.
- Specific skill lists, feat trees and progression remain open.

## Recovery and quick items
- No assumed passive full HP regeneration. Recovery can come from powers (e.g. Fighter's Second Wind) and items (healing potions), plus eventual safe-town recovery.
- Second Wind is a possible Utility power with cooldown/charges; exact amount, cooldown and out-of-combat restrictions undecided. Avoid making it mandatory or allowing unrestricted waiting to trivialise attrition without deliberate design.
- **Dedicated Item action/quick slot** separate from four class powers. It references an accessible inventory stack or reusable item; activation can consume one item, spend charges or trigger an item cooldown.
- Reassigning quick item and replenishing ammo during combat are disallowed in the intended design. Exact potion behaviour and replenishment mechanics remain open.

## Hardcore, tavern and Guild (future)
- Hardcore death loses the individual character; secured Guild/Codex progress persists. Cemetery/statues for notable dead adventurers remain possible.
- Proposed tavern recruitment after death: present **four randomly generated candidates**, showing stats, with no free rerolls. The player chooses one.
- Guild/Codex unlocks may later improve recruitment choice, candidate quality or allow rerolls. These are proposals, not settled entitlements.
- Crucial progression idea: midgame Guild achievements could allow recruitment of higher-level adventurers (e.g. level 8 instead of level 1), reducing replay frustration. Higher-level recruits must have appropriate powers/feats/skills, not just increased HP. Their gear may vary.
- Do not implement tavern/recruitment/Guild progression in the first Fighter RPG prototype.

## Deferred design decisions
Combat maths and scaling; hit/crit/miss and armour formula; exact power cooldowns, charge recovery and upgrades; passive affixes of inactive weapons/shields; weapon switch timing; power interruptions; two-handed and dual-wield combos; consumable and health attrition balancing; levelling and attribute increases; item UI and controller testing; precise class equipment permissions; multiclassing; recruitment unlocks.

## Delivery discipline
Keep Iteration 03 focused on its dungeon/traps/enemies/escape contract. This document is design reference only. When RPG implementation is authorised, create a bounded docs/ITERATION_XX.md with explicit acceptance criteria and update AGENTS.md / DESIGN.md references deliberately rather than expanding current iterations.
