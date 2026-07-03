extends SceneTree
## Generates procedural placeholder audio (synthesized PCM) so the game is
## audible before any real tracks exist: 12 SFX + 6 seamless ambient/percussion
## loops. Real audio imported via tools/import_art.sh (as .ogg/.mp3) wins over
## these .wav files automatically (AudioManager extension priority).
## Loop seamlessness: every component frequency completes whole cycles within
## the loop length, so loops click-free.
## Run:  godot --headless --path . -s res://tools/gen_placeholder_audio.gd

const RATE := 44100
const LOOP_SECONDS := 16.0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/audio/sfx")
	DirAccess.make_dir_recursive_absolute("res://assets/audio/music")

	# --- SFX ---
	_save_sfx("ui_tap", _sfx_tap())
	_save_sfx("hit", _sfx_hit(false))
	_save_sfx("hit_crit", _sfx_hit(true))
	_save_sfx("heal", _sfx_sweep(420.0, 840.0, 0.35, 0.25))
	_save_sfx("evade", _sfx_evade())
	_save_sfx("trance", _sfx_trance())
	_save_sfx("fall", _sfx_sweep(300.0, 70.0, 0.5, 0.3))
	_save_sfx("reveal_novice", _sfx_chord([392.0], 0.5))
	_save_sfx("reveal_wayfarer", _sfx_chord([392.0, 523.25], 0.7))
	_save_sfx("reveal_luminary", _sfx_chord([392.0, 493.88, 587.33, 783.99], 1.3))
	_save_sfx("victory", _sfx_chord([523.25, 659.25, 783.99, 1046.5], 1.5))
	_save_sfx("defeat", _sfx_chord([440.0, 392.0, 311.13], 1.3))

	# --- music loops ---
	_save_music("title", _music_drone([110.0, 165.0, 220.0], [0.12, 0.07, 0.04], 0.25))
	_save_music("title_percussion", _music_pulse(0.5, 0.10, []))
	_save_music("valley_1", _music_drone([74.0, 111.0, 148.0], [0.12, 0.08, 0.04], 0.125))
	_save_music("battle", _music_pulse(1.875, 0.22, [98.0, 147.0]))
	_save_music("battle_percussion", _music_pulse(1.875, 0.26, []))
	_save_music("boss", _music_boss())
	print("DONE — run: godot --headless --path . --import")
	quit(0)


# --- write helpers -------------------------------------------------------------

func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	return wav


func _save_sfx(key: String, samples: PackedFloat32Array) -> void:
	_to_wav(samples).save_to_wav("res://assets/audio/sfx/%s.wav" % key)
	print("sfx: ", key)


func _save_music(key: String, samples: PackedFloat32Array) -> void:
	_to_wav(samples).save_to_wav("res://assets/audio/music/%s.wav" % key)
	print("music: ", key)


# --- synth building blocks -------------------------------------------------------

func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


func _add_tone(buf: PackedFloat32Array, start: float, dur: float, freq: float,
		amp: float, attack: float = 0.01, decay: float = 4.0) -> void:
	var s0 := int(start * RATE)
	var n := mini(int(dur * RATE), buf.size() - s0)
	for i in n:
		var t := float(i) / RATE
		var env := minf(t / maxf(attack, 0.001), 1.0) * exp(-decay * t)
		buf[s0 + i] += sin(TAU * freq * t) * amp * env


func _add_noise(buf: PackedFloat32Array, start: float, dur: float,
		amp: float, decay: float = 20.0) -> void:
	var s0 := int(start * RATE)
	var n := mini(int(dur * RATE), buf.size() - s0)
	var prev := 0.0
	for i in n:
		var t := float(i) / RATE
		# one-pole lowpass tames the hiss into a thump-ish texture
		prev = prev * 0.7 + (randf() * 2.0 - 1.0) * 0.3
		buf[s0 + i] += prev * amp * exp(-decay * t)


func _add_sweep(buf: PackedFloat32Array, start: float, dur: float,
		f0: float, f1: float, amp: float) -> void:
	var s0 := int(start * RATE)
	var n := mini(int(dur * RATE), buf.size() - s0)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := lerpf(f0, f1, t / dur)
		phase += TAU * f / RATE
		var env := minf(t / 0.01, 1.0) * (1.0 - t / dur)
		buf[s0 + i] += sin(phase) * amp * env


# --- SFX recipes ---------------------------------------------------------------

func _sfx_tap() -> PackedFloat32Array:
	var b := _buf(0.08)
	_add_tone(b, 0.0, 0.08, 900.0, 0.35, 0.002, 40.0)
	return b


func _sfx_hit(crit: bool) -> PackedFloat32Array:
	var b := _buf(0.25 if crit else 0.18)
	_add_noise(b, 0.0, 0.15, 0.5 if crit else 0.35, 25.0)
	_add_tone(b, 0.0, 0.15, 120.0 if crit else 150.0, 0.5, 0.002, 18.0)
	if crit:
		_add_tone(b, 0.02, 0.2, 240.0, 0.3, 0.002, 12.0)
	return b


func _sfx_sweep(f0: float, f1: float, dur: float, amp: float) -> PackedFloat32Array:
	var b := _buf(dur + 0.05)
	_add_sweep(b, 0.0, dur, f0, f1, amp)
	return b


func _sfx_evade() -> PackedFloat32Array:
	var b := _buf(0.15)
	_add_tone(b, 0.0, 0.05, 1300.0, 0.25, 0.002, 30.0)
	_add_tone(b, 0.06, 0.06, 1600.0, 0.22, 0.002, 30.0)
	return b


func _sfx_trance() -> PackedFloat32Array:
	var b := _buf(1.0)
	_add_tone(b, 0.0, 1.0, 220.0, 0.28, 0.35, 1.8)
	_add_tone(b, 0.0, 1.0, 330.0, 0.2, 0.45, 1.8)
	_add_sweep(b, 0.1, 0.8, 200.0, 440.0, 0.12)
	return b


func _sfx_chord(freqs: Array, total: float) -> PackedFloat32Array:
	var b := _buf(total)
	var step := 0.14
	for i in freqs.size():
		var last := i == freqs.size() - 1
		_add_tone(b, i * step, total - i * step, freqs[i],
			0.3, 0.01, 1.5 if last else 5.0)
	return b


# --- music recipes (seamless loops: freq * LOOP_SECONDS is whole) ---------------

func _music_drone(freqs: Array, amps: Array, tremolo_hz: float) -> PackedFloat32Array:
	var b := _buf(LOOP_SECONDS)
	for i in b.size():
		var t := float(i) / RATE
		var v := 0.0
		for j in freqs.size():
			v += sin(TAU * freqs[j] * t) * amps[j]
		b[i] = v * (1.0 + 0.18 * sin(TAU * tremolo_hz * t))
	return b


## Frame-drum-ish pulse at `beats_per_second` (chosen so beats fit the loop
## exactly), optionally over a drone.
func _music_pulse(beats_per_second: float, thump_amp: float, drone_freqs: Array) -> PackedFloat32Array:
	var b := _buf(LOOP_SECONDS)
	for j in drone_freqs.size():
		var f: float = drone_freqs[j]
		var a := 0.09 / (j + 1)
		for i in b.size():
			b[i] += sin(TAU * f * float(i) / RATE) * a
	var beat_count := int(LOOP_SECONDS * beats_per_second)
	for k in beat_count:
		var start := float(k) / beats_per_second
		var strong := k % 4 == 0
		_add_noise(b, start, 0.09, thump_amp * (1.0 if strong else 0.55), 45.0)
		_add_tone(b, start, 0.12, 82.0 if strong else 110.0, thump_amp * 0.9, 0.002, 25.0)
	return b


func _music_boss() -> PackedFloat32Array:
	var b := _buf(LOOP_SECONDS)
	# beating minor-second drone = dread
	for i in b.size():
		var t := float(i) / RATE
		b[i] = sin(TAU * 55.0 * t) * 0.14 + sin(TAU * 58.25 * t) * 0.12
	for k in 8:
		var start := k * 2.0
		_add_noise(b, start, 0.12, 0.2, 30.0)
		_add_tone(b, start, 0.2, 65.0, 0.22, 0.002, 15.0)
	return b
