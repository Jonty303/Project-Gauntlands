# Iteration 01 artwork

`room.png`, `adventurer.png` and `goblin.png` are original pixel art created for
Project Gauntlands in this implementation. No external artwork, commercial
game sprites, source packs or third-party textures were used. These assets may
be redistributed and modified with this project; no third-party attribution
or licence dependency applies.

The room is a hand-authored 640×384 composition using a 32px stone grid, opaque
weathered masonry, chipped floor slabs, cracks, dirt and restrained damp/moss.
The playable area is x=48…592, y=80…352. Foreground wall caps lie outside the
playable feet area.

Each actor sheet contains 48×48 transparent frames, 12 columns and four facing
rows (south, north, east, west). Columns are idle, four walk poses, sword windup,
sword active, sword recovery, bow draw, bow release/recovery, hurt, and dead.
All animation is selected from explicit simulation state and timing; the art
does not drive damage timing. Nearest filtering and integer viewport scaling
preserve the pixel grid. Shared goblin art intentionally identifies one enemy
type, with role/health/state identified by the HUD.

## Iteration 02 additions

The second room and corridor reuse the original room texture and its floor /
wall regions without altering the source image. Door timber, iron straps,
masonry jambs, the brass wall switch, coins and arrow bundles are original
pixel-aligned artwork drawn by `interactable.gd` and `pickup.gd` in the existing
palette. No external assets or licence dependencies were introduced.
