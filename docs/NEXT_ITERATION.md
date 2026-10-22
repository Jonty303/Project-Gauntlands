# Architecture lab: next iteration

Continue this work on `experiment/architecture-lab`. Keep the architecture and visibility experiments isolated from the original playable combat prototype.

## Starting point

The branch tip inspected on 22 October 2026 was `c3bba4022e17f30d941775ab94d9e497939d9217` (`Fix GridMap floor collision shape registration`). This commit corrects MeshLibrary collision registration to use alternating Shape3D and Transform3D entries and adds `tests/grid_floor_collision_test.gd`.

Recent preceding commits:

- `a5f5971`: Decouple floor discovery visuals from persistent GridMap collision.
- `41b379c`: Ground hero on collidable GridMap tiles and build complete doorway partition returns.
- `0108851`: Add persistent room discovery and one-hop discovered-adjacent visibility fading.

The earlier `experiment/2point5d` branch ends at `b4588af` (`Remove faulty room-aware wall cutaway while retaining all gameplay and chest improvements`). The architecture lab is the branch for the remaining work below.

## Remaining work and acceptance checks

All items remain to be verified in Godot 4.5.2; this document does not certify runtime behavior.

1. Confirm the floor collision fix remains reliable during movement. Run the existing floor collision test and move the hero across floor tile boundaries and door thresholds, including while room visibility changes. Confirm the hero remains supported without falling through floors.
2. Verify walls and doorway returns align correctly. Inspect boundaries, corners, door openings, and return geometry using the same coordinate system as floors and character movement. Check for gaps, overlaps, and unintended obstruction.
3. Keep undiscovered rooms hidden. Confirm their visuals remain hidden until discovery, and that discovered rooms retain their discovery state after leaving and returning.
4. Make foreground walls approximately 4% opaque in the current room and discovered adjacent rooms. Verify the behavior across camera orientations and ensure it does not reveal undiscovered rooms.
5. Make closed foreground doors approximately 28% opaque. Verify the foreground classification and opacity as the camera rotates and the hero changes rooms.
6. Preserve wall and door collision regardless of visual transparency. Confirm faded walls and closed doors still block movement; opening a door should retain its intended gameplay behavior.
7. Test transitions between rooms and camera rotations. Repeat movement, discovery, wall fading, door fading, and collision checks before, during, and after transitions and rotations. Record what passed and what remains unverified.
8. Do not migrate the architecture into the playable combat scene until the lab is stable. Establish stability by completing the checks above and preserving existing gameplay.
