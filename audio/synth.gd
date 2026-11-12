class_name Synth
## Procedural lo-fi audio: every sound in the game is generated here, so there are no audio assets.

const RATE := 16000


# --- PS1 SPU texture ----------------------------------------------------------
# Every sample passes through _spu() inside _wav(), so the score and every effect
# (including ones added later in build_effects) sound sampled rather than synthesized:
# a sample-and-hold at a lower rate (dull top, a little alias), PS-ADPCM style 4-bit
# block coding (granular noise that rides the signal) and a final bit-depth crush.
# Tweak by ear; set SPU_ALIAS / SPU_ADPCM to 0.0 to bypass a stage.

## Rate of the sample-and-hold pass, in Hz (PS1 instruments sat around 11-22 kHz).
const SPU_RATE := 11025.0
## How much of the held, aliased signal replaces the clean one (0..1).
const SPU_ALIAS := 0.4
## How much of the ADPCM coding error is kept (0 = clean, 1 = full 4-bit PS-ADPCM).
const SPU_ADPCM := 0.6
## Final bit depth of the stored sample (10-12 keeps it lo-fi without going 8-bit).
const SPU_BITS := 11
const _ADPCM_BLOCK := 28
# First three PS-ADPCM predictor filters (none, 60/64, 115/64 & -52/64).
const _ADPCM_K0 := [0.0, 0.9375, 1.796875]
const _ADPCM_K1 := [0.0, 0.0, -0.8125]


static func _spu(src: PackedFloat32Array) -> PackedFloat32Array:
	var n := src.size()
	var out := src.duplicate()
	if SPU_ALIAS > 0.0 and SPU_RATE < RATE:
		var step := SPU_RATE / RATE
		var acc := 1.0
		var held := 0.0
		for i in n:
			acc += step
			if acc >= 1.0:
				acc -= 1.0
				held = src[i]
			out[i] = src[i] + (held - src[i]) * SPU_ALIAS
	if SPU_ADPCM <= 0.0:
		return out
	var s1 := 0.0
	var s2 := 0.0
	var start := 0
	while start < n:
		var end := mini(start + _ADPCM_BLOCK, n)
		# Pick the predictor with the smallest residual peak, like the real encoder.
		var best := 0
		var best_peak := INF
		for f in 3:
			var k0: float = _ADPCM_K0[f]
			var k1: float = _ADPCM_K1[f]
			var p1 := s1
			var p2 := s2
			var peak := 0.0
			for j in range(start, end):
				var x := out[j]
				var r := absf(x - k0 * p1 - k1 * p2)
				if r > peak:
					peak = r
				p2 = p1
				p1 = x
			if peak < best_peak:
				best_peak = peak
				best = f
		# Power-of-two step so the residual fits a signed nibble (the SPU "shift").
		var q_step := pow(2.0, ceilf(log(maxf(best_peak / 7.0, 1.0 / 32768.0)) / log(2.0)))
		var c0: float = _ADPCM_K0[best]
		var c1: float = _ADPCM_K1[best]
		for j in range(start, end):
			var x := out[j]
			var pred := c0 * s1 + c1 * s2
			var q := clampf(roundf((x - pred) / q_step), -8.0, 7.0)
			var y := clampf(pred + q * q_step, -1.0, 1.0)
			s2 = s1
			s1 = y
			out[j] = x + (y - x) * SPU_ADPCM
		start = end
	return out


static func _wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	samples = _spu(samples)
	var levels := float(1 << (SPU_BITS - 1))
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(roundf(samples[i] * levels) / levels, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav


static func _count(seconds: float) -> int:
	return int(seconds * RATE)


## Low-passed noise burst with an exponential decay.
static func noise(seconds: float, smooth: float, decay: float, gain := 1.0) -> AudioStreamWAV:
	var n := _count(seconds)
	var out := PackedFloat32Array()
	out.resize(n)
	var last := 0.0
	for i in n:
		last = lerpf(last, randf_range(-1.0, 1.0), smooth)
		out[i] = last * exp(-decay * float(i) / RATE) * gain
	return _wav(out)


## Decaying tone with optional harmonics (ratio, level pairs).
static func tone(freq: float, seconds: float, decay: float, gain := 0.6, harmonics := [] as Array) -> AudioStreamWAV:
	var n := _count(seconds)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var v := sin(TAU * freq * t)
		for h: Array in harmonics:
			v += sin(TAU * freq * h[0] * t) * h[1]
		out[i] = v * exp(-decay * t) * gain
	return _wav(out)


## Frequency sweep, for whooshes, creaks and rumbles.
static func sweep(from_hz: float, to_hz: float, seconds: float, gain := 0.5, saw := false) -> AudioStreamWAV:
	var n := _count(seconds)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var k := float(i) / n
		phase += TAU * lerpf(from_hz, to_hz, k) / RATE
		var v := (fposmod(phase, TAU) / PI - 1.0) if saw else sin(phase)
		out[i] = v * gain * sin(PI * k)
	return _wav(out)


## Looping low-passed noise with slow swells, for wind and surf. Wrap-around is cross-faded.
static func ambience(seconds: float, smooth: float, swell_hz: float, depth: float, gain: float) -> AudioStreamWAV:
	var n := _count(seconds)
	var fade := _count(0.4)
	var raw := PackedFloat32Array()
	raw.resize(n + fade)
	var last := 0.0
	for i in n + fade:
		last = lerpf(last, randf_range(-1.0, 1.0), smooth)
		raw[i] = last
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var v := raw[i]
		if i < fade:
			var k := float(i) / fade
			v = raw[i] * k + raw[n + i] * (1.0 - k)
		out[i] = v * gain * (1.0 - depth + depth * (0.5 + 0.5 * sin(TAU * swell_hz * float(i) / n * seconds)))
	return _wav(out, true)


## Sum of sines. `seconds * freq` should be whole numbers so the loop is seamless.
static func drone(seconds: float, freqs: Array, tremolo_hz: float, tremolo_depth: float, gain: float) -> AudioStreamWAV:
	var n := _count(seconds)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for f: float in freqs:
			v += sin(TAU * f * t)
		var trem := 1.0 - tremolo_depth + tremolo_depth * (0.5 + 0.5 * sin(TAU * tremolo_hz * t))
		out[i] = v / freqs.size() * trem * gain
	return _wav(out, true)


## One lub-dub heartbeat per loop (1 second).
static func heartbeat(gain: float) -> AudioStreamWAV:
	var n := _count(1.0)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for beat: Array in [[0.0, 1.0], [0.28, 0.7]]:
			var local: float = t - beat[0]
			if local >= 0.0:
				v += sin(TAU * (70.0 - 35.0 * minf(local, 0.2) * 5.0) * local) * exp(-18.0 * local) * beat[1]
		out[i] = v * gain
	return _wav(out, true)


## Mains hum with a little buzz, 2 seconds loop.
static func hum(gain: float) -> AudioStreamWAV:
	var n := _count(2.0)
	var out := PackedFloat32Array()
	out.resize(n)
	var last := 0.0
	for i in n:
		var t := float(i) / RATE
		last = lerpf(last, randf_range(-1.0, 1.0), 0.2)
		out[i] = (sin(TAU * 50.0 * t) + 0.5 * sin(TAU * 100.0 * t) + 0.3 * sin(TAU * 150.0 * t) + last * 0.25) * gain * 0.5
	return _wav(out, true)


## Two clicks per second, for the lamp's clockwork.
static func ticking(gain: float) -> AudioStreamWAV:
	var n := _count(1.0)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for at: float in [0.0, 0.5]:
			var local := t - at
			if local >= 0.0:
				v += sin(TAU * 1800.0 * local) * exp(-90.0 * local)
		out[i] = v * gain
	return _wav(out, true)


## Crackling radio static with random gating.
static func radio_static(seconds: float) -> AudioStreamWAV:
	var n := _count(seconds)
	var out := PackedFloat32Array()
	out.resize(n)
	var gate := 1.0
	for i in n:
		if i % 400 == 0:
			gate = 1.0 if randf() > 0.35 else 0.15
		out[i] = randf_range(-1.0, 1.0) * 0.35 * gate * sin(PI * float(i) / n)
	return _wav(out)


# --- Adaptive score -----------------------------------------------------------
# D minor (D pedal, Phrygian colour from Eb) at 96 BPM in 4/4. Every music loop is
# exactly one bar (2.5 s = 40000 samples), so all layers start together, stay locked
# and wrap without a click: sustained voices snap to whole cycles per bar and struck
# notes wrap their tails back to the start of the buffer.

const BPM := 96.0
const BEATS := 4
const BEAT := 60.0 / BPM
const BAR := BEAT * BEATS
## Pitch of the bell sample (D5); other notes are played with pitch_scale.
const BELL_NOTE := 74


static func midi_hz(note: float) -> float:
	return 440.0 * pow(2.0, (note - 69.0) / 12.0)


static func _bar_buffer() -> PackedFloat32Array:
	return _buffer(BAR)


static func _buffer(seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(_count(seconds))
	out.fill(0.0)
	return out


## Adds steady sines ([midi, level] pairs). Each pitch snaps to a whole number of cycles
## per buffer, so the loop is seamless. `chorus` adds a twin one cycle higher (slow beating).
static func _sustain(out: PackedFloat32Array, voices: Array, gain: float, chorus := false) -> void:
	var n := out.size()
	var seconds := float(n) / RATE
	var steps := PackedFloat64Array()
	var levels := PackedFloat32Array()
	for voice: Array in voices:
		var cycles := maxf(round(midi_hz(voice[0]) * seconds), 1.0)
		steps.append(TAU * cycles / n)
		levels.append(voice[1])
		if chorus:
			steps.append(TAU * (cycles + 1.0) / n)
			levels.append(float(voice[1]) * 0.6)
	for i in n:
		var v := 0.0
		for k in steps.size():
			v += sin(steps[k] * i) * levels[k]
		out[i] += v * gain


## Amplitude swell with a whole number of cycles per buffer, peaking at sample 0.
static func _swell(out: PackedFloat32Array, cycles: int, depth: float) -> void:
	var n := out.size()
	for i in n:
		out[i] *= 1.0 - depth + depth * (0.5 + 0.5 * cos(TAU * float(cycles) * float(i) / n))


## Struck/plucked voice with partials ([ratio, level]); `glide` starts the pitch higher
## and drops it fast (drum bodies). The tail wraps around the buffer end.
static func _strike(out: PackedFloat32Array, at: float, freq: float, length: float, attack: float, decay: float, gain: float, partials := [] as Array, glide := 0.0) -> void:
	var n := out.size()
	var start := int(at * RATE)
	var phase := 0.0
	for i in mini(_count(length), n):
		var t := float(i) / RATE
		phase += TAU * freq * (1.0 + glide * exp(-30.0 * t)) / RATE
		var v := sin(phase)
		for p: Array in partials:
			v += sin(phase * float(p[0])) * float(p[1])
		out[(start + i) % n] += v * minf(t / attack, 1.0) * exp(-decay * t) * gain


## Low-passed noise hit (felt, rim, tick). The tail wraps around the buffer end.
static func _hit(out: PackedFloat32Array, rng: RandomNumberGenerator, at: float, length: float, smooth: float, decay: float, gain: float) -> void:
	var n := out.size()
	var start := int(at * RATE)
	var last := 0.0
	for i in mini(_count(length), n):
		last = lerpf(last, rng.randf_range(-1.0, 1.0), smooth)
		out[(start + i) % n] += last * exp(-decay * float(i) / RATE) * gain


## Calm: low open pad (D2, A2, D3, F3, A3, D4) with a slow breath once per bar.
static func _music_pad() -> PackedFloat32Array:
	var out := _bar_buffer()
	_sustain(out, [[38, 0.45], [45, 0.2], [50, 0.35], [53, 0.22], [57, 0.25], [62, 0.1]], 0.32, true)
	_swell(out, 1, 0.2)
	return out


## Uneasy: soft low thump on beats 1 and 3 and a minor-third / minor-sixth chord
## (D4 F4 Bb4) that swells with the half-note pulse.
static func _music_pulse() -> PackedFloat32Array:
	var out := _bar_buffer()
	for beat: int in [0, 2]:
		_strike(out, beat * BEAT, midi_hz(38), 1.4, 0.008, 4.0, 0.45, [[2.0, 0.35], [3.0, 0.12]], 0.12)
	var chord := _bar_buffer()
	_sustain(chord, [[62, 0.4], [65, 0.35], [70, 0.3]], 0.22)
	_swell(chord, 2, 0.6)
	for i in out.size():
		out[i] += chord[i]
	return out


## Tense: low eighth-note ostinato on D with Eb and F neighbours.
static func _music_ostinato() -> PackedFloat32Array:
	var out := _bar_buffer()
	var line: Array[int] = [38, 38, 50, 38, 39, 38, 50, 41]
	for i in line.size():
		var accent := 1.0 if i % 4 == 0 else 0.7
		_strike(out, i * BEAT * 0.5, midi_hz(line[i]), 0.6, 0.004, 6.0, 0.3 * accent, [[2.0, 0.5], [3.0, 0.3], [4.0, 0.18], [5.0, 0.1]])
	return out


## Tense: muffled drum (pitched body + felt noise) and a muted rim on 2 and 4.
static func _music_perc(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out := _bar_buffer()
	for beat: float in [0.0, 0.75, 2.0, 2.5]:
		_strike(out, beat * BEAT, 58.0, 0.45, 0.002, 12.0, 0.5, [[2.0, 0.15]], 0.9)
		_hit(out, rng, beat * BEAT, 0.25, 0.06, 22.0, 2.0)
	for beat: float in [1.0, 3.0]:
		_hit(out, rng, beat * BEAT, 0.12, 0.35, 45.0, 0.45)
	return out


## Tense: Eb3 + Ab3 (flat second and tritone over D) and A4 rubbing Bb4, beating
## slowly and swelling three times per bar against the 4/4.
static func _music_dissonance() -> PackedFloat32Array:
	var out := _bar_buffer()
	_sustain(out, [[51, 0.4], [56, 0.35], [69, 0.15], [70, 0.15]], 0.28, true)
	_swell(out, 3, 0.35)
	return out


## Danger: heartbeat on every beat (96 bpm).
static func _music_heart(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out := _bar_buffer()
	for beat: int in BEATS:
		var at := beat * BEAT
		_strike(out, at, 46.0, 0.3, 0.004, 16.0, 0.8, [[2.0, 0.3], [3.0, 0.1]], 0.7)
		_strike(out, at + 0.2, 42.0, 0.3, 0.004, 18.0, 0.55, [[2.0, 0.3], [3.0, 0.1]], 0.7)
		_hit(out, rng, at, 0.08, 0.04, 40.0, 1.2)
	return out


## Danger: high cluster (A5 under D6 Eb6 E6) with a 6.4 Hz flutter.
static func _music_cluster() -> PackedFloat32Array:
	var out := _bar_buffer()
	_sustain(out, [[81, 0.25], [86, 0.3], [87, 0.3], [88, 0.2]], 0.12, true)
	_swell(out, 16, 0.5)
	return out


## Danger: muted sixteenth-note ticks on D3/Eb3, the tightest rhythm.
static func _music_tight(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out := _bar_buffer()
	var line: Array[int] = [50, 50, 51, 50, 50, 50, 51, 50, 50, 50, 53, 50, 51, 50, 51, 50]
	for i in line.size():
		var at := i * BEAT * 0.25
		_strike(out, at, midi_hz(line[i]), 0.2, 0.002, 22.0, 0.2 if i % 4 == 0 else 0.13, [[2.0, 0.4], [3.0, 0.2]])
		_hit(out, rng, at, 0.05, 0.5, 80.0, 0.22 if i % 2 == 0 else 0.13)
	return out


## Every music stream, keyed by name. Pure and thread-safe (own RNG), so it can be
## built on a worker thread. Loops: pad, pulse, ostinato, perc, dissonance, heart,
## cluster, tight. One-shots: bell, stinger, rise.
static func build_music() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	return {
		"pad": _wav(_music_pad(), true),
		"pulse": _wav(_music_pulse(), true),
		"ostinato": _wav(_music_ostinato(), true),
		"perc": _wav(_music_perc(rng), true),
		"dissonance": _wav(_music_dissonance(), true),
		"heart": _wav(_music_heart(rng), true),
		"cluster": _wav(_music_cluster(), true),
		"tight": _wav(_music_tight(rng), true),
		"bell": _music_bell(),
		"stinger": _music_stinger(),
		"rise": _music_rise(rng),
	}


## Celesta-like bell at D5, long soft tail.
static func _music_bell() -> AudioStreamWAV:
	var out := _buffer(2.8)
	_strike(out, 0.0, midi_hz(BELL_NOTE), 2.8, 0.003, 1.7, 0.3, [[2.0, 0.15], [2.76, 0.1], [4.07, 0.2], [5.4, 0.05]])
	return _wav(out)


## Ship lost: a low gong that swells in (no hard attack) under a D-Eb-Ab cluster.
static func _music_stinger() -> AudioStreamWAV:
	var out := _buffer(3.5)
	_strike(out, 0.0, midi_hz(26), 3.5, 0.15, 1.1, 0.45, [[2.0, 0.6], [2.76, 0.35], [4.2, 0.15]])
	for note: int in [62, 63, 68]:
		_strike(out, 0.0, midi_hz(note), 3.5, 0.9, 1.3, 0.18, [[2.0, 0.2]])
	return _wav(out)


## Lamp out: a 4 s crescendo of three voices gliding up a fourth plus brightening
## noise, which peaks around 2.6 s and recedes instead of cutting off.
static func _music_rise(rng: RandomNumberGenerator) -> AudioStreamWAV:
	var out := _buffer(4.0)
	var n := out.size()
	var from_notes := [50.0, 51.0, 56.0]
	var phases := PackedFloat64Array([0.0, 0.0, 0.0])
	var last := 0.0
	for i in n:
		var k := float(i) / n
		var env := pow(sin(PI * pow(k, 1.6)), 2.0) if k > 0.0 else 0.0
		var v := 0.0
		for j in 3:
			phases[j] += TAU * midi_hz(from_notes[j] + 5.0 * k * k) / RATE
			v += sin(phases[j]) + 0.3 * sin(phases[j] * 2.0)
		last = lerpf(last, rng.randf_range(-1.0, 1.0), 0.05 + 0.25 * k)
		out[i] = (v * 0.12 + last * 0.6) * env
	return _wav(out)


# --- Lamp console (GDD 4.1.1) -------------------------------------------------

## Glub-glub of oil running through a metal funnel: rising bubbles over a faint ring.
static func glug(seconds: float, bubbles: int, gain: float) -> AudioStreamWAV:
	var n := _count(seconds)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var starts: Array[float] = []
	for b in bubbles:
		starts.append(seconds * float(b) / bubbles + rng.randf_range(0.0, 0.05))
	for i in n:
		var t := float(i) / RATE
		var v := sin(TAU * 1250.0 * t) * 0.05 * exp(-2.0 * t)
		for at in starts:
			var local := t - at
			if local >= 0.0 and local < 0.09:
				v += sin(TAU * (260.0 + 5200.0 * local) * local) * exp(-30.0 * local)
		out[i] = v * gain * sin(PI * float(i) / n)
	return _wav(out)


## Spirit blowtorch: a hiss that brightens (rises) as it goes, over a soft roar.
static func torch(seconds: float, gain: float) -> AudioStreamWAV:
	var n := _count(seconds)
	var out := PackedFloat32Array()
	out.resize(n)
	var low := 0.0
	var high := 0.0
	for i in n:
		var k := float(i) / n
		var r := randf_range(-1.0, 1.0)
		low = lerpf(low, r, 0.04)
		high = lerpf(high, r, lerpf(0.25, 0.75, k))
		out[i] = (low * 1.4 + (r - high) * lerpf(0.2, 0.55, k)) * gain * minf(k * 8.0, 1.0) * minf((1.0 - k) * 6.0, 1.0)
	return _wav(out)


## Hand pump stroke: air "tchuf" plus a short leather creak.
static func pump_stroke(gain: float) -> AudioStreamWAV:
	var n := _count(0.32)
	var out := PackedFloat32Array()
	out.resize(n)
	var last := 0.0
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		last = lerpf(last, randf_range(-1.0, 1.0), 0.35)
		var air := last * exp(-14.0 * t) * minf(t * 300.0, 1.0)
		phase += TAU * (95.0 + 40.0 * t) / RATE
		var creak := (fposmod(phase, TAU) / PI - 1.0) * 0.25 * exp(-8.0 * maxf(t - 0.08, 0.0)) * (1.0 if t > 0.08 else 0.0)
		out[i] = (air + creak) * gain
	return _wav(out)


## Valve: three thread clicks, then the low "fuump" of the vapour catching.
static func valve_ignite(gain: float) -> AudioStreamWAV:
	var n := _count(0.9)
	var out := PackedFloat32Array()
	out.resize(n)
	var last := 0.0
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for at: float in [0.0, 0.07, 0.14]:
			var local := t - at
			if local >= 0.0:
				v += sin(TAU * 2100.0 * local) * exp(-110.0 * local) * 0.5
		var whoomp := t - 0.25
		if whoomp >= 0.0:
			last = lerpf(last, randf_range(-1.0, 1.0), 0.06)
			var env := minf(whoomp * 20.0, 1.0) * exp(-4.5 * whoomp)
			v += (last * 1.6 + sin(TAU * (55.0 + 70.0 * whoomp) * whoomp) * 0.6) * env
		out[i] = v * gain
	return _wav(out)


## One dry ratchet click.
static func ratchet(gain: float) -> AudioStreamWAV:
	var n := _count(0.07)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		out[i] = (sin(TAU * 2600.0 * t) * 0.6 + sin(TAU * 900.0 * t) * 0.4 + randf_range(-0.4, 0.4)) * exp(-95.0 * t) * gain
	return _wav(out)


## Damp cloth on glass: back-and-forth friction with a thin squeak.
static func wipe(seconds: float, gain: float) -> AudioStreamWAV:
	var n := _count(seconds)
	var out := PackedFloat32Array()
	out.resize(n)
	var last := 0.0
	for i in n:
		var t := float(i) / RATE
		last = lerpf(last, randf_range(-1.0, 1.0), 0.45)
		var stroke := absf(sin(TAU * 3.2 * t))
		var squeak := sin(TAU * (1900.0 + 250.0 * sin(TAU * 7.0 * t)) * t) * 0.18 * maxf(stroke - 0.7, 0.0) * 3.0
		out[i] = (last * 0.6 * stroke + squeak) * gain * sin(PI * float(i) / n)
	return _wav(out)


## Drowned burner: a choked thud and a few oily sputters.
static func drown(gain: float) -> AudioStreamWAV:
	var n := _count(1.0)
	var out := PackedFloat32Array()
	out.resize(n)
	var last := 0.0
	var gate := 0.0
	for i in n:
		var t := float(i) / RATE
		if i % 900 == 0:
			gate = 1.0 if randf() > 0.55 else 0.0
		last = lerpf(last, randf_range(-1.0, 1.0), 0.12)
		var thud := sin(TAU * (75.0 - 30.0 * t) * t) * exp(-7.0 * t)
		var sputter := last * gate * exp(-2.5 * t) * 0.8
		out[i] = (thud + sputter) * gain
	return _wav(out)


# --- Breaker panel ---------------------------------------------------------------

## Knife-switch lever: a short metal scrape and a heavy clack at the end of its throw.
static func lever(gain: float) -> AudioStreamWAV:
	var n := _count(0.3)
	var out := PackedFloat32Array()
	out.resize(n)
	var last := 0.0
	for i in n:
		var t := float(i) / RATE
		last = lerpf(last, randf_range(-1.0, 1.0), 0.5)
		var scrape := last * 0.35 * (1.0 if t < 0.12 else 0.0) * sin(PI * minf(t / 0.12, 1.0))
		var hit := t - 0.12
		var clack := 0.0
		if hit >= 0.0:
			clack = (sin(TAU * 160.0 * hit) + 0.5 * sin(TAU * 410.0 * hit) + randf_range(-0.3, 0.3)) * exp(-35.0 * hit)
		out[i] = (scrape + clack) * gain
	return _wav(out)


## Overload: a sharp electrical crack with a sizzling tail.
static func snap(gain: float) -> AudioStreamWAV:
	var n := _count(0.45)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var crack := randf_range(-1.0, 1.0) * exp(-60.0 * t)
		var sizzle := randf_range(-1.0, 1.0) * 0.25 * exp(-6.0 * t) * (1.0 if randf() > 0.7 else 0.2)
		out[i] = (crack + sizzle + sin(TAU * 1200.0 * t) * 0.3 * exp(-40.0 * t)) * gain
	return _wav(out)


## Mains buzz swelling in as a circuit takes the load.
static func buzz(gain: float) -> AudioStreamWAV:
	var n := _count(0.7)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var k := float(i) / n
		var v := sin(TAU * 100.0 * t) + 0.6 * signf(sin(TAU * 200.0 * t)) * 0.4 + 0.3 * sin(TAU * 300.0 * t)
		out[i] = v * gain * minf(k * 5.0, 1.0) * (1.0 - k)
	return _wav(out)


# --- Inventory, status and portable radio --------------------------------------

## A looping stream played once, for one-shot effects built from loops.
static func _once(wav: AudioStreamWAV) -> AudioStreamWAV:
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return wav


## Gulps: a few low, wet bubbles.
static func gulps(count: int, gain: float) -> AudioStreamWAV:
	var seconds := 0.3 * count
	var n := _count(seconds)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var local := fmod(t, 0.3)
		out[i] = sin(TAU * (140.0 + 380.0 * local) * local) * exp(-14.0 * local) * gain
	return _wav(out)


## Chewing: soft gated crunches.
static func chew(gain: float) -> AudioStreamWAV:
	var n := _count(0.9)
	var out := PackedFloat32Array()
	out.resize(n)
	var last := 0.0
	for i in n:
		var t := float(i) / RATE
		last = lerpf(last, randf_range(-1.0, 1.0), 0.3)
		var local := fmod(t, 0.22)
		out[i] = last * exp(-18.0 * local) * gain
	return _wav(out)


## Hollow stomach growl: a wobbling low saw.
static func growl(gain: float) -> AudioStreamWAV:
	var n := _count(0.9)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := float(i) / n
		phase += TAU * (70.0 + 25.0 * sin(TAU * 5.0 * t)) / RATE
		out[i] = (fposmod(phase, TAU) / PI - 1.0) * gain * sin(PI * k) * (0.6 + 0.4 * sin(TAU * 9.0 * t))
	return _wav(out)


## Dull blow, then the noise falling away: the keeper's last sound.
static func mix_death_blow() -> AudioStreamWAV:
	var n := _count(3.2)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := float(i) / n
		phase += TAU * (46.0 - 10.0 * minf(t, 1.0)) / RATE
		var blow := sin(phase) * exp(-t * 6.0) * 1.0 + randf_range(-1.0, 1.0) * exp(-t * 40.0) * 0.6
		var hiss := randf_range(-1.0, 1.0) * 0.3 * minf(maxf(t - 0.3, 0.0) * 6.0, 1.0) * (1.0 - k)
		out[i] = clampf(blow + hiss, -1.0, 1.0)
	return _wav(out)


## White noise falling away, for the fade to death.
static func fade_noise(seconds: float, gain: float) -> AudioStreamWAV:
	var n := _count(seconds)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var k := float(i) / n
		out[i] = randf_range(-1.0, 1.0) * gain * minf(k * 10.0, 1.0) * (1.0 - k)
	return _wav(out)


# --- Opening cutscene ------------------------------------------------------------

## One-cylinder boat motor: low, slightly irregular thumps over `seconds`.
static func motor(seconds: float, rate: float, gain: float) -> AudioStreamWAV:
	var n := _count(seconds)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var beats: Array[float] = []
	var at := 0.0
	while at < seconds:
		beats.append(at)
		at += 1.0 / rate * rng.randf_range(0.85, 1.15)
	var last := 0.0
	for i in n:
		var t := float(i) / RATE
		last = lerpf(last, randf_range(-1.0, 1.0), 0.05)
		var v := last * 0.3
		for b in beats:
			var local := t - b
			if local >= 0.0 and local < 0.15:
				v += sin(TAU * 48.0 * local) * exp(-25.0 * local)
		out[i] = v * gain * minf(minf(t * 20.0, (seconds - t) * 20.0), 1.0)
	return _wav(out)


## A wet voice through radio static: formant-ish buzz chopped by noise.
static func radio_voice(seconds: float, gain: float) -> AudioStreamWAV:
	var n := _count(seconds)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := float(i) / n
		phase += TAU * (110.0 + 18.0 * sin(TAU * 3.0 * t)) / RATE
		var voice := (fposmod(phase, TAU) / PI - 1.0) * (0.5 + 0.5 * sin(TAU * 4.5 * t)) * 0.5
		var hiss := randf_range(-1.0, 1.0) * 0.45
		out[i] = (voice * sin(TAU * 700.0 * t) * 0.8 + hiss) * gain * sin(PI * k)
	return _wav(out)


## Wood under load: a slow, bending creak.
static func wood_creak(seconds: float, gain: float) -> AudioStreamWAV:
	var n := _count(seconds)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var k := float(i) / n
		phase += TAU * lerpf(180.0, 120.0, k) * (1.0 + 0.3 * sin(TAU * 22.0 * k)) / RATE
		out[i] = (fposmod(phase, TAU) / PI - 1.0) * gain * sin(PI * k) * (0.5 + 0.5 * signf(sin(phase * 0.05)))
	return _wav(out)


## Old two-tone telephone bell: two bursts of a 25 Hz warble (440/480 Hz, hard-clipped for
## a tinny SPU bite) then a pause. Loops every 2.4 s.
static func phone_ring(gain := 0.55) -> AudioStreamWAV:
	var n := _count(2.4)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var in_burst := (t < 0.5) or (t >= 0.7 and t < 1.2)
		if not in_burst:
			out[i] = 0.0
			continue
		var local := t if t < 0.5 else t - 0.7
		var env := minf(local * 80.0, 1.0) * minf((0.5 - local) * 80.0, 1.0)
		var warble := 0.5 + 0.5 * signf(sin(TAU * 25.0 * t))
		var v := sin(TAU * 440.0 * t) + sin(TAU * 480.0 * t) + 0.3 * sin(TAU * 1320.0 * t)
		out[i] = clampf(v * 0.8, -1.0, 1.0) * warble * env * gain
	return _wav(out, true)


static func build_effects() -> Dictionary:
	return {
		"step": noise(0.16, 0.12, 22.0, 0.9),
		"land": noise(0.22, 0.08, 14.0, 1.0),
		"jump": sweep(180.0, 320.0, 0.14, 0.3),
		"click": noise(0.05, 0.6, 60.0, 0.8),
		"clunk": tone(90.0, 0.25, 14.0, 0.8, [[2.1, 0.3]]),
		"jam": sweep(220.0, 90.0, 0.5, 0.5, true),
		"switch": tone(140.0, 0.12, 30.0, 0.8, [[3.0, 0.4]]),
		"paper": noise(0.25, 0.5, 12.0, 0.5),
		"creak": sweep(120.0, 260.0, 0.7, 0.35, true),
		"ring": tone(880.0, 0.5, 5.0, 0.5, [[1.5, 0.5]]),
		"static": radio_static(0.7),
		"bell": tone(392.0, 1.6, 2.2, 0.6, [[2.76, 0.5], [5.4, 0.25]]),
		"horn": tone(110.0, 1.8, 1.2, 0.7, [[1.01, 0.8], [2.0, 0.3]]),
		"ignite": sweep(80.0, 600.0, 0.6, 0.4),
		"gen_start": sweep(40.0, 70.0, 1.2, 0.6, true),
		"lamp_fill": glug(0.8, 5, 0.55),
		"lamp_heat": torch(0.8, 0.45),
		"lamp_pump": pump_stroke(0.7),
		"lamp_valve": valve_ignite(0.6),
		"lamp_ratchet": ratchet(0.7),
		"lamp_wipe": wipe(0.65, 0.5),
		"lamp_fail": drown(0.8),
		"lamp_pfft": noise(0.2, 0.3, 16.0, 0.6),
		"lamp_hiss": noise(0.9, 0.85, 3.5, 0.35),
		"lamp_beat": tone(1500.0, 0.05, 120.0, 0.2),
		"gust": sweep(260.0, 420.0, 1.6, 0.18),
		"lever": lever(0.7),
		"breaker_snap": snap(0.6),
		"breaker_buzz": buzz(0.35),
		"pickup": sweep(300.0, 520.0, 0.12, 0.35),
		"drop": tone(110.0, 0.18, 22.0, 0.6, [[2.4, 0.3]]),
		"inv_click": tone(900.0, 0.04, 90.0, 0.3, [[1.5, 0.4]]),
		"drink": gulps(3, 0.6),
		"eat": chew(0.5),
		"bandage": noise(0.6, 0.6, 5.0, 0.35),
		"radio_beep": tone(1760.0, 0.14, 12.0, 0.35),
		"dry_throat": noise(0.35, 0.2, 9.0, 0.5),
		"stomach": growl(0.4),
		"heart": _once(heartbeat(0.7)),
		"death": fade_noise(3.0, 0.5),
		"death_blow": mix_death_blow(),
		"hurt": tone(85.0, 0.3, 10.0, 0.9, [[1.6, 0.4]]),
		"boat_motor": motor(1.0, 6.0, 0.6),
		"boat_idle": motor(1.4, 3.0, 0.45),
		"splash": noise(0.5, 0.25, 7.0, 0.55),
		"metal_creak": sweep(140.0, 95.0, 1.2, 0.25, true),
		"hull_knock": tone(70.0, 0.45, 9.0, 0.8, [[2.3, 0.4], [3.7, 0.2]]),
		"radio_voice": radio_voice(1.4, 0.5),
		"knob_click": tone(2400.0, 0.03, 160.0, 0.4),
		"pier_creak": wood_creak(0.9, 0.35),
		"rope_slap": noise(0.12, 0.7, 40.0, 0.7),
		"boat_bell": tone(523.0, 1.8, 2.0, 0.55, [[2.4, 0.4], [5.1, 0.2]]),
	}
