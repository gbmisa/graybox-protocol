class_name TripAudio
extends RefCounted
## The trip zones' sounds, synthesized (TripZone). Both play from where the
## face is, never from the player's head.
##
##   whisper()  a loop of breathy, syllable-shaped noise — someone close,
##              saying something you can't make out
##   sting()    a short wrong chord with a scrape, for the face behind you

static var _whisper: AudioStreamWAV
static var _sting: AudioStreamWAV

static func whisper() -> AudioStreamWAV:
	if _whisper != null:
		return _whisper
	var rate := float(AudioSynth.MIX_RATE)
	var n := int(rate * 4.0)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	# Band-passed noise (two one-pole filters) under a syllable envelope: bursts
	# of 0.08-0.3s with gaps, a sibilant edge on some of them.
	var lp1 := 0.0
	var lp2 := 0.0
	var env := 0.0
	var target := 0.0
	var next_change := 0
	var hiss := 0.0
	for i in n:
		if i >= next_change:
			var on := rng.randf() < 0.62
			target = rng.randf_range(0.4, 1.0) if on else 0.0
			hiss = 1.0 if on and rng.randf() < 0.3 else 0.0
			next_change = i + int(rate * (rng.randf_range(0.08, 0.3) if on else rng.randf_range(0.05, 0.4)))
		env += (target - env) * 0.004
		var x := rng.randf_range(-1.0, 1.0)
		lp1 += (x - lp1) * 0.18
		lp2 += (lp1 - lp2) * 0.18
		var band := lp1 - lp2 * 0.9
		out[i] = (band * 1.6 + x * 0.25 * hiss) * env * 0.5
	# Fade the loop's ends into each other.
	var f := int(rate * 0.1)
	for i in f:
		var k := float(i) / f
		out[i] *= k
		out[n - 1 - i] *= k
	_whisper = AudioSynth._pack(out)
	_whisper.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_whisper.loop_begin = 0
	_whisper.loop_end = n
	return _whisper

static func sting() -> AudioStreamWAV:
	if _sting != null:
		return _sting
	var rate := float(AudioSynth.MIX_RATE)
	var n := int(rate * 1.4)
	var out := PackedFloat32Array()
	out.resize(n)
	var freqs := [196.0, 207.6, 293.7, 311.1, 466.2]   # a cluster, all of it wrong
	var lp := 0.0
	for i in n:
		var t := float(i) / rate
		var s := 0.0
		for fq in freqs:
			s += sin(TAU * fq * t * (1.0 + 0.004 * sin(t * 31.0))) / freqs.size()
		lp += (randf_range(-1.0, 1.0) - lp) * 0.06
		var scrape := lp * exp(-t * 3.0) * 1.5
		out[i] = (s * 0.8 + scrape) * exp(-t * 2.2) * minf(1.0, t * 80.0) * 0.6
	_sting = AudioSynth._pack(out)
	return _sting
