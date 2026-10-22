# Project Gauntlands development instructions

- Use Godot 4.5.2 and validate GDScript before committing changes to GDScript.
- Reproduce bugs and test fixes in Godot whenever possible.
- Keep experimental architecture and visibility scenes separate from the original playable combat prototype.
- Preserve existing gameplay unless explicitly asked to change it.
- Use one consistent coordinate system for floors, walls, doors, and character movement.
- Treat physical collision and visual transparency as separate systems.
- Test camera rotation, doorway geometry, floor collision, room discovery, and transparency changes for regressions when changing these systems.
- Make small, understandable commits with descriptive messages.
- Report what was tested, what passed, and what remains unverified. For documentation-only changes, verify the documentation and commit scope; explicitly state that Godot runtime behavior was not tested.
