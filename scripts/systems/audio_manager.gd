extends Node
## Autoload "Audio": convention-loaded music and SFX with graceful silence for
## anything missing (same philosophy as art — the game never blocks on
## assets). Paths: assets/audio/music/<key>.<ext>, assets/audio/sfx/<key>.<ext>
## with ext priority ogg > mp3 > wav (generated placeholders are .wav, so any
## imported real track automatically wins).
##
## Implements GDD §11's "percussion & voice only" mode: when enabled, music
## keys prefer the "<key>_percussion" variant if one exists.

const SETTINGS_PATH := "user://settings.json"
const EXTS := ["ogg", "mp3", "wav"]
const SFX_POOL_SIZE := 8

var music_volume := 0.8
var sfx_volume := 0.8
var percussion_only := false

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active: AudioStreamPlayer
var _current_key := ""
var _sfx_pool: Array = []
var _cache := {}


func _ready() -> void:
	_music_a = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	add_child(_music_a)
	add_child(_music_b)
	_active = _music_a
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_pool.append(p)
	_load_settings()


## Crossfades to the track for `key`; silence if no file exists. Passing the
## already-playing key is a no-op, so screens can call this unconditionally.
func play_music(key: String) -> void:
	if key == "" or key == _current_key:
		return
	_current_key = key
	var stream: AudioStream = null
	if percussion_only:
		stream = _find_stream("res://assets/audio/music/%s_percussion" % key)
	if stream == null:
		stream = _find_stream("res://assets/audio/music/%s" % key)
	_loopify(stream)
	var from := _active
	var to := _music_b if _active == _music_a else _music_a
	_active = to
	var tw := create_tween()
	if from.playing:
		tw.parallel().tween_property(from, "volume_db", -60.0, 0.8)
		tw.parallel().tween_callback(from.stop).set_delay(0.85)
	if stream != null:
		to.stream = stream
		to.volume_db = -60.0
		to.play()
		tw.parallel().tween_property(to, "volume_db", linear_to_db(maxf(music_volume, 0.001)), 0.8)


func play_sfx(key: String) -> void:
	if sfx_volume <= 0.0:
		return
	var stream := _find_stream("res://assets/audio/sfx/%s" % key)
	if stream == null:
		return
	for p: AudioStreamPlayer in _sfx_pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = linear_to_db(maxf(sfx_volume, 0.001))
			p.play()
			return
	# pool exhausted — steal the first player
	_sfx_pool[0].stream = stream
	_sfx_pool[0].play()


func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_active.volume_db = linear_to_db(maxf(music_volume, 0.001)) if music_volume > 0.0 else -80.0
	_save_settings()


func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	_save_settings()


func set_percussion_only(on: bool) -> void:
	percussion_only = on
	_save_settings()
	# Restart the current key so the variant swap is audible immediately.
	var key := _current_key
	_current_key = ""
	play_music(key)


func _find_stream(base_path: String) -> AudioStream:
	if _cache.has(base_path):
		return _cache[base_path]
	var stream: AudioStream = null
	for ext in EXTS:
		var path := "%s.%s" % [base_path, ext]
		if ResourceLoader.exists(path):
			stream = load(path)
			break
	_cache[base_path] = stream  # cache nulls too — misses are the common case
	return stream


## Imported WAV placeholders lose loop metadata; force looping at runtime.
func _loopify(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.data.size() / 2  # 16-bit mono frames
	elif stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var blob = JSON.parse_string(FileAccess.open(SETTINGS_PATH, FileAccess.READ).get_as_text())
	if blob is Dictionary:
		music_volume = clampf(float(blob.get("music_volume", 0.8)), 0.0, 1.0)
		sfx_volume = clampf(float(blob.get("sfx_volume", 0.8)), 0.0, 1.0)
		percussion_only = bool(blob.get("percussion_only", false))


func _save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"music_volume": music_volume,
			"sfx_volume": sfx_volume,
			"percussion_only": percussion_only,
		}))
