class_name CodexEntry
extends Resource
## One page of "The Traveler's Notebook" — the dawah layer (GDD §1.1).
## Body follows the language policy; links point at the recorded lore source
## pages (decided 2026-07: Codex entries hyperlink out to sources).

@export var id: StringName
@export var title: String = ""
@export var order_index: int = 0
@export_multiline var body: String = ""
## Each entry: "Label | https://url" — rendered as tappable Learn-more links.
@export var links: Array = []
