class_name AudioSynth
extends RefCounted
## Procedural sound effects: all SFX are synthesized at runtime into
## AudioStreamWAV buffers. No external audio assets needed.
## Usage: AudioSynth.play(parent_node, "pistol")

const MIX_RATE := 22050

static var _cache: Dictionary = {}

static func get_sfx(sfx_name: String) -> AudioStreamWAV:
	if _cache.has(sfx_name):
		return _cache[sfx_name]
	var s: AudioStreamWAV = null
	match sfx_name:
		"pistol":
			s = _tone(900.0, 180.0, 0.09, "square", 0.45)
		"fireball":
			s = _tone(320.0, 90.0, 0.30, "saw", 0.40)
		"bolt":
			s = _tone(1400.0, 2400.0, 0.25, "saw", 0.35)
		"punch":
			s = _noise_burst(0.12, 0.55)
		"slam":
			s = _tone(90.0, 35.0, 0.35, "sine", 0.7)
		"explosion":
			s = _noise_burst(0.45, 0.6)
		"hit":
			s = _tone(1200.0, 1200.0, 0.05, "square", 0.3)
		"hurt":
			s = _tone(220.0, 110.0, 0.20, "saw", 0.4)
		"alarm":
			s = _sequence([660.0, 880.0, 660.0, 880.0], 0.12, "square", 0.3)
		"win":
			s = _sequence([523.0, 659.0, 784.0, 1046.0], 0.13, "sine", 0.4)
		"lose":
			s = _sequence([330.0, 262.0, 196.0], 0.22, "saw", 0.35)
		"click":
			s = _tone(800.0, 800.0, 0.04, "square", 0.25)
		# --- traversal and interaction ---
		"dash":
			s = _tone(500.0, 1500.0, 0.18, "sine", 0.32)
		"cast":
			s = _tone(200.0, 700.0, 0.35, "sine", 0.35)
		"mantle":
			s = _noise_burst(0.16, 0.30)
		"pick":
			s = _tone(2200.0, 1900.0, 0.03, "square", 0.22)
		"unlock":
			s = _sequence([700.0, 1050.0], 0.07, "square", 0.30)
		"arcane":
			s = _tone(300.0, 1800.0, 0.40, "sine", 0.38)
		"smash":
			s = _noise_burst(0.38, 0.65)
		# --- guard fire: the wind-up beep is the audible half of the dodge cue ---
		"aim":
			s = _tone(620.0, 1250.0, 0.13, "sine", 0.22)
		"guard_shot":
			s = _tone(760.0, 130.0, 0.13, "saw", 0.42)
	if s != null:
		_cache[sfx_name] = s
	return s

## Play a named SFX as a one-shot 2D sound under `parent`.
static func play(parent: Node, sfx_name: String, vol_db: float = 0.0) -> void:
	var stream := get_sfx(sfx_name)
	if stream == null or parent == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = vol_db
	parent.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

static func _wave_fn(wave: String, phase: float) -> float:
	match wave:
		"square":
			return 1.0 if sin(phase) >= 0.0 else -1.0
		"saw":
			var t := phase / TAU
			return 2.0 * (t - floor(t)) - 1.0
		_:
			return sin(phase)

static func _tone_samples(f0: float, f1: float, dur: float, wave: String, vol: float) -> PackedFloat32Array:
	var n := int(MIX_RATE * dur)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		var freq := lerpf(f0, f1, t)
		phase += TAU * freq / MIX_RATE
		# slight decay envelope + click-free edges
		var env := (1.0 - t * 0.7)
		var edge := minf(1.0, minf(float(i), float(n - i)) / (MIX_RATE * 0.005))
		samples[i] = _wave_fn(wave, phase) * vol * env * edge
	return samples

static func _tone(f0: float, f1: float, dur: float, wave: String, vol: float) -> AudioStreamWAV:
	return _pack(_tone_samples(f0, f1, dur, wave, vol))

static func _noise_burst(dur: float, vol: float) -> AudioStreamWAV:
	var n := int(MIX_RATE * dur)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var smooth := 0.0
	for i in n:
		var t := float(i) / float(n)
		# lowpassed-ish noise: blend with previous sample
		smooth = smooth * 0.7 + randf_range(-1.0, 1.0) * 0.3
		samples[i] = smooth * vol * (1.0 - t)
	return _pack(samples)

static func _sequence(freqs: Array, note_dur: float, wave: String, vol: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var gap_n := int(MIX_RATE * 0.02)
	for f in freqs:
		samples.append_array(_tone_samples(float(f), float(f), note_dur, wave, vol))
		var old_size := samples.size()
		samples.resize(old_size + gap_n)  # silence gap (zeros)
	return _pack(samples)

static func _pack(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var v := int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = MIX_RATE
	w.stereo = false
	w.data = data
	return w
