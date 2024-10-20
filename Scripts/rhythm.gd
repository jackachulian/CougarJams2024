class_name Rhythm
extends Control

@export var note_scene: PackedScene
@export var max_note_distance: float = 50
@export var miss_popup: PackedScene
@export var bad_popup: PackedScene
@export var okay_popup: PackedScene
@export var good_popup: PackedScene
@export var great_popup: PackedScene
@export var cauldron_splash_effect: PackedScene

@onready var note_spawn_point: Marker2D = $ColorRect/NoteSpawnPoint
@onready var target_center: Control = $ColorRect/ColorRect3/TargetCenter
@onready var popup_center: Marker2D = $ColorRect/ColorRect3/PopupCenter
@onready var notes_parent: Node = $Notes
@onready var cleared_notes_parent: Node = $ClearedNotes
@onready var game_screen: RhythmGameScreen = $".."
@onready var dialogue: Dialogue = $"../Dialogue"
@onready var dynamic_music_player: DynamicMusicPlayer = $"../DynamicMusic"
@onready var cauldron: Sprite2D = $CauldronFront

@onready var space_input_hint: Sprite2D = $ColorRect/ColorRect3/TargetCenter/SpaceInputHint


var current_note_speed: float = 0 # should be 0 during cutscenes to activate intro/outro track
var notes_left: int
var time_until_next_note: float
var in_rhythm_mode = false # true while in rhythm mode

var min_speed: float = 200
var max_speed: float = 600

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	min_speed = game_screen.level.min_speed
	max_speed = game_screen.level.max_speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not in_rhythm_mode:
		return
	
	if Input.is_action_just_pressed("rhythm_press"):
		rhythm_press()
	
	for note: Node2D in notes_parent.get_children():
		#note.position.x = 0
		note.position.y += current_note_speed * delta
		if note.global_position.y > target_center.global_position.y + max_note_distance:
			game_screen.lose_health(6)
			hit_popup(miss_popup)
			note.queue_free()
		
	if notes_left > 0:
		time_until_next_note -= delta
		if time_until_next_note < 0:
			spawn_note()
			time_until_next_note = randf_range(0.25, 1.0)
			var next_note_time = Time.get_unix_time_from_system() + time_until_next_note
			
			# LEAVING QUANTIZING ATTEMPT FOR LATER too much math...
			#var next_note_song_time_elapsed = next_note_time - dynamic_music.start_time
			#var beat_length = 60 / (dynamic_music.current_bpm * 4)
			#var next_beat = ceil(next_note_song_time_elapsed / beat_length) * beat_length
			#time_until_next_note = next_beat
			
			notes_left -= 1
			
	if notes_left <= 0 and notes_parent.get_child_count() == 0:
		in_rhythm_mode = false
		space_input_hint.visible = false
		dialogue.start_dialogue_mode()
		return
		
func start_rhythm_mode():
	if not in_rhythm_mode:
		visible = true
		space_input_hint.visible = true
		in_rhythm_mode = true
		notes_left = 5

func rhythm_press():
	var hit_type
	for note: Node2D in notes_parent.get_children():
		var distance_from_target = abs(note.global_position.y - target_center.global_position.y)
			
		if distance_from_target < max_note_distance*0.175:
			hit_type = "great"
			game_screen.gain_health(3)
			hit_popup(great_popup)
		elif distance_from_target < max_note_distance*0.4:
			hit_type = "good"
			game_screen.gain_health(2)
			hit_popup(good_popup)
		elif distance_from_target < max_note_distance*0.65:
			hit_type = "okay"
			game_screen.gain_health(1)
			hit_popup(okay_popup)
		elif distance_from_target < max_note_distance:
			hit_type = "bad"
			hit_popup(bad_popup)
		elif distance_from_target < max_note_distance*2:
			hit_type = "miss"
			game_screen.lose_health(6)
			hit_popup(miss_popup)
		
		if hit_type:
			if hit_type == "miss":
				note.queue_free()
			else:
				clear_anim(note)
			return
		
func adjust_speed(speed: float):
	current_note_speed += speed
	if current_note_speed < min_speed:
		current_note_speed = min_speed
	elif current_note_speed > max_speed:
		current_note_speed = max_speed
	print("speed: ", current_note_speed)

func hit_popup(scene: PackedScene):
	var popup: Control = scene.instantiate()
	popup.global_position = popup_center.global_position
	add_child(popup)
	
	get_tree().create_tween().tween_property(popup, "modulate", Color(1,1,1,0), 1.0)
	await get_tree().create_tween().tween_property(popup, "position", popup.position + Vector2.UP*50, 1.0).finished
	
	if is_instance_valid(popup):
		popup.queue_free()

func splash_animation():
	var splash: CPUParticles2D = cauldron_splash_effect.instantiate()
	splash.global_position = cauldron.global_position
	splash.emitting = true
	add_child(splash)
	
	await get_tree().create_timer(2.0).timeout
	splash.queue_free()

func spawn_note():
	var note: Sprite2D = note_scene.instantiate()
	note.global_position = note_spawn_point.global_position
	var note_textures = game_screen.level.note_textures
	if note_textures and len(note_textures) > 0:
		note.texture = note_textures[randi_range(0, len(note_textures)-1)]
	notes_parent.add_child(note)
	#print("spawned note at ", note.global_position)

func clear_anim(note: Sprite2D):
	note_hit_anim(note)
	
	note.reparent(cleared_notes_parent)
	
	get_tree().create_tween().tween_property(note, "global_position", cauldron.global_position, 0.3)
	get_tree().create_tween().tween_property(note, "rotation", note.rotation + deg_to_rad(randf_range(-30, 30)), 0.3).finished
	
	await get_tree().create_timer(0.15).timeout
	
	splash_animation()
	
	await get_tree().create_timer(0.15).timeout
	
	note.queue_free()
	
func note_hit_anim(note: Sprite2D):
	var note_hit = note.duplicate()
	cleared_notes_parent.add_child(note_hit)
	
	if Level.current_level.note_hit_textures:
		note_hit.texture = Level.current_level.note_hit_textures[0]
	
	get_tree().create_tween().tween_property(note_hit, "modulate", Color(1,1,1,0), 0.3)
	await get_tree().create_tween().tween_property(note_hit, "scale", note_hit.scale*1.75, 0.3).finished
	
	note_hit.queue_free()
