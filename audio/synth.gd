class_name Synth
## Procedural lo-fi audio: every sound in the game is generated here, so there are no audio assets.

const RATE := 16000


static func _wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
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
	}
