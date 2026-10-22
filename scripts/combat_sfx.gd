extends RefCounted
## Tiny synthesized prototype sounds. No external assets required.
const SAMPLE_RATE := 22050
static var cache: Dictionary = {}

static func play(parent: Node, kind: String) -> void:
    if not cache.has(kind):
        cache[kind] = _make_sound(kind)
    var voice := AudioStreamPlayer.new()
    voice.stream = cache[kind]
    voice.volume_db = -10.0
    parent.add_child(voice)
    voice.finished.connect(voice.queue_free)
    voice.play()

static func _make_sound(kind: String) -> AudioStreamWAV:
    var duration := 0.13
    var pitch := 330.0
    if kind == "bow":
        duration = 0.16
        pitch = 520.0
    elif kind == "swing":
        duration = 0.22
        pitch = 160.0
    elif kind == "hit":
        duration = 0.12
        pitch = 110.0
    elif kind == "wall":
        duration = 0.09
        pitch = 700.0
    elif kind == "hurt":
        duration = 0.20
        pitch = 180.0
    elif kind == "switch":
        duration = 0.09
        pitch = 440.0
    var count := int(SAMPLE_RATE * duration)
    var bytes := PackedByteArray()
    bytes.resize(count * 2)
    var phase := 0.0
    for i in range(count):
        var progress := float(i) / float(count)
        var envelope := pow(1.0 - progress, 2.0)
        var frequency := pitch * (1.0 - 0.45 * progress)
        phase += TAU * frequency / SAMPLE_RATE
        var noise := randf_range(-1.0, 1.0)
        var signal := sin(phase) * 0.55 + noise * (0.65 if kind in ["swing", "hit", "wall"] else 0.15)
        var sample := clampi(roundi(signal * envelope * 11000.0), -32768, 32767)
        bytes.encode_s16(i * 2, sample)
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = SAMPLE_RATE
    wav.stereo = false
    wav.data = bytes
    return wav
