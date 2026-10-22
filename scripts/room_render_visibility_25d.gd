extends RefCounted
## Render policy only. Discovery is input, never a side effect of occlusion.
## Shared boundaries render if at least one owning room has been discovered.
static func can_render(owners: Array, discovered: Dictionary) -> bool:
    for owner in owners:
        if discovered.has(owner):
            return true
    return false
