class_name SeasonCalendar
## Tabular lunar (Hijri civil) calendar — GDD §9.3.1. Deterministic and
## identical worldwide: arithmetic 30-year cycle (leap years 2,5,7,10,13,
## 16,18,21,24,26,29; leap adds a day to month 12). Backend later ships an
## authored Umm-al-Qura schedule via config; this arithmetic version is the
## prototype stand-in and offline fallback.

const EPOCH_OFFSET_DAYS := 492148  # unix epoch JD 2440587.5 - islamic civil epoch JD 1948439.5
const CYCLE_DAYS := 10631          # 30 lunar years
const LEAP_YEARS_IN_CYCLE := [2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29]

## Season names per GDD §9.3.1 — grounded in the research source's teaching
## for each month (its entry-way number and associated reality); the game
## never names the real months; each season's Codex entry (moon_01..12)
## links to the source teachings instead.
const SEASON_NAMES := {
	1: "The Door", 2: "The Cave", 3: "The Kingdom",
	4: "The Straight Path", 5: "The Kneeling", 6: "The Moon",
	7: "The Ascent", 8: "The Salvation", 9: "The Light",
	10: "The City", 11: "The Patience", 12: "The Fountain",
}


static func _is_leap(year_in_cycle: int) -> bool:
	return year_in_cycle in LEAP_YEARS_IN_CYCLE


## unix seconds -> {"year": int, "month": 1..12, "day": 1..30}
static func from_unix(unix: int) -> Dictionary:
	var days := int(floor(unix / 86400.0)) + EPOCH_OFFSET_DAYS
	var cycles := days / CYCLE_DAYS
	var rem := days % CYCLE_DAYS
	var year_in_cycle := 1
	for y in range(1, 31):
		var year_len := 355 if _is_leap(y) else 354
		if rem < year_len:
			year_in_cycle = y
			break
		rem -= year_len
	var month := 1
	for m in range(1, 13):
		var mlen := 30 if m % 2 == 1 else 29
		if m == 12 and _is_leap(year_in_cycle):
			mlen += 1
		if rem < mlen:
			month = m
			break
		rem -= mlen
	return { "year": cycles * 30 + year_in_cycle, "month": month, "day": rem + 1 }


static func season_id(unix: int) -> String:
	var h := from_unix(unix)
	return "%d-%02d" % [h["year"], h["month"]]


static func season_name(unix: int) -> String:
	return SEASON_NAMES[from_unix(unix)["month"]]


static func season_codex_id(unix: int) -> String:
	return "moon_%02d" % from_unix(unix)["month"]


static func season_day(unix: int) -> int:
	return from_unix(unix)["day"]
