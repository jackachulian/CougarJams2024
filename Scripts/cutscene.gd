class_name Cutscene
extends Control

@export var message_linger_time: float = 2.0

@onready var npc_dialogue_box: DialogueBox = $NpcDialogueBox
@onready var player_dialogue_box: DialogueBox = $PlayerDialogueBox

@onready var rhythm: Rhythm = $"../Rhythm"
@onready var dialogue: Dialogue = $"../Dialogue"

var current_cutscene_lines: Array
var cutscene_index: int
var linger_time_remaining: float

# true for in intro cutscene, false for in outro cutscene
var in_intro_cutscene: bool

var in_level_transition: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	play_intro_cutscene()
	
func play_intro_cutscene():
	current_cutscene_lines = dialogue.dialogue["intro_dialogue"]
	cutscene_index = -1
	in_intro_cutscene = true
	visible = true
	display_next_line()
	
func play_outro_cutscene():
	in_intro_cutscene = false
	current_cutscene_lines = dialogue.dialogue["outro_dialogue"]
	cutscene_index = -1
	visible = true
	display_next_line()
	
func _process(delta: float) -> void:
	if not visible:
		return
	
	if Input.is_action_just_pressed("rhythm_press"):
		if npc_dialogue_box.typing:
			npc_dialogue_box.show_full_line()
		elif player_dialogue_box.typing:
			player_dialogue_box.show_full_line()
		else:
			display_next_line()
	
	if not npc_dialogue_box.typing and not player_dialogue_box.typing:
		linger_time_remaining -= delta
		if linger_time_remaining <= 0:
			display_next_line()
	
func display_next_line():
	cutscene_index += 1
	linger_time_remaining = message_linger_time
	if cutscene_index >= len(current_cutscene_lines):
		if in_intro_cutscene:
			visible = false
			rhythm.current_note_speed = rhythm.game_screen.level.starting_speed
			rhythm.start_rhythm_mode()
		elif not in_level_transition:
			var next_level = rhythm.game_screen.level.next_level
			if next_level:
				transition_to_level(next_level)
			else:
				dialogue.npc_dialogue_box.show_message("(There are no levels after this yet, thanks for playing!)")
			pass
	else:
		var dialogue_line = current_cutscene_lines[cutscene_index]
		var speaker: String = dialogue_line[0]
		var message: String = dialogue_line[1]
		# if "npc" show on npc box, if "player" show on player box. not implemented yet
		if speaker == "player":
			npc_dialogue_box.visible = false
			player_dialogue_box.show_message(message)
		else:
			player_dialogue_box.visible = false
			npc_dialogue_box.show_message(message)
		
func transition_to_level(next_level: Level):
	in_level_transition = true
	var base_pos = rhythm.game_screen.opponent_portrait.position
	get_tree().create_tween().tween_property(rhythm.game_screen.opponent_portrait, "position", base_pos + Vector2.LEFT * 450, 1.25)
	await get_tree().create_tween().tween_property(rhythm.game_screen.dynamic_music_player, "volume_db", -30, 1.5).finished
	
	rhythm.game_screen.level = next_level
	Level.current_level = next_level
	rhythm.game_screen.dynamic_music_player.dynamic_music = next_level.dynamic_music
	rhythm.game_screen.dynamic_music_player.current_track_index = -1
	rhythm.game_screen.dynamic_music_player.current_division = 0
	rhythm.game_screen.dynamic_music_player. in_transition_track = false
	rhythm.game_screen.dynamic_music_player.play_next_track()
	dialogue.load_dialog_from_file()
	dialogue.current_question_index = -1
	play_intro_cutscene()
	
	
	get_tree().create_tween().tween_property(rhythm.game_screen.opponent_portrait, "position", base_pos, 1.25)
	await get_tree().create_tween().tween_property(rhythm.game_screen.dynamic_music_player, "volume_db", -30, 1.5).finished
	in_level_transition = false
	
func on_line_finished():
	pass
