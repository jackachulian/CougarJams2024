class_name Dialogue
extends Control

@export var dialogue_option_scene: PackedScene
@export var good_rating_texture: Texture2D
@export var neutral_rating_texture: Texture2D
@export var bad_rating_texture: Texture2D

@onready var respond_time_left_bar: TextureProgressBar = $OpponentDialoguePanel/RespondTimeLeftBar
@onready var random_popup_container: Control = $RandomPopupContainer
@onready var rhythm: Rhythm = $"../Rhythm"
@onready var rating_anim_rect: TextureRect = $"../PortraitContainer/OpponentPortrait/RatingAnimRect"

var dialogue_options = []
var dialogue_ratings = []
var dialogue_options_queued = []
var time_until_next_option: float
var in_dialogue_mode = false # true while in rhythm mode

var respond_time_remaining: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not in_dialogue_mode:
		return
		
	time_until_next_option -= delta
	if time_until_next_option <= 0:
		if len(dialogue_options_queued) > 0:
			spawn_random_option()
			time_until_next_option = randf_range(0.25, 1.0)
		
	respond_time_remaining -= delta
	if respond_time_remaining <= 0:
		submit_dialogue(-1)
		respond_time_remaining = 100.0
	else:
		respond_time_left_bar.value = respond_time_remaining

func start_dialogue_mode():
	if in_dialogue_mode:
		return
		
	visible = true
	in_dialogue_mode = true
	dialogue_options = ["good option 1", "good option 2", "neutral option 3", "bad option 4", "bad option 5"]
	dialogue_ratings = ["good", "good", "neutral", "bad", "bad"]
	dialogue_options_queued = dialogue_options
	respond_time_remaining = 10.0
	
	respond_time_left_bar.max_value = respond_time_remaining

func spawn_random_option():
	var i = randi_range(0, len(dialogue_options_queued)-1)
	var text: String = dialogue_options_queued.pop_at(i)
	var option_index = dialogue_options.find(text)
	var option: Button = dialogue_option_scene.instantiate()
	option.text = text
	option.pressed.connect(func(): submit_dialogue(option_index))
	
	var random_x: int = 0
	var random_y: int = 0
	
	option.position = Vector2(random_x, random_y)
	
	var iteration_max: int = 50
	
	var intersects: bool = true
	while intersects:
		random_x = randi_range(0, random_popup_container.size.x - option.size.x)
		random_y = randi_range(0, random_popup_container.size.y - option.size.y)
		
		var popup_rect = Rect2(Vector2(random_x, random_y), option.size)
		
		intersects = false
		for child: Control in random_popup_container.get_children():
			if child.get_rect().intersects(popup_rect):
				#print(popup_rect, " intersects with ", child.get_rect())
				intersects = true
				break
		
		iteration_max -= 1
		if iteration_max <= 0:
			print("MAX ITERATIONS REACHED")
			break
	
	print("placed at ", random_x, ", ", random_y)
	random_popup_container.add_child(option)
	option.position = Vector2(random_x, random_y)
	option.modulate = Color(1,1,1,0)
	var fade_in_tween = get_tree().create_tween().tween_property(option, "modulate", Color.WHITE, 0.5)
	await fade_in_tween.finished
		
	await get_tree().create_timer(randf_range(2.0, 6.0)).timeout
	
	if not is_instance_valid(option):
		return
	
	var fade_out_tween = get_tree().create_tween().tween_property(option, "modulate", Color(1,1,1,0), 0.5)
	if not fade_out_tween:
		return
	
	await fade_out_tween.finished
	
	if is_instance_valid(option):
		option.queue_free()
		dialogue_options_queued.push_back(text)

# empty for no dialogue option selected
func submit_dialogue(option_index: int):
	if option_index == -1:
		bad_rating()
	else:
		var rating = dialogue_ratings[option_index]
		if rating == "good":
			good_rating()
		elif rating == "bad":
			bad_rating()
		else:
			neutral_rating()
		
	for child in random_popup_container.get_children():
		child.queue_free()
		
	visible = false
	in_dialogue_mode = false
	rhythm.start_rhythm_mode()

func good_rating():
	rating_anim_rect.texture = good_rating_texture
	rating_anim(Vector2.UP)
	
func neutral_rating():
	rating_anim_rect.texture = neutral_rating_texture
	rating_anim(Vector2.ZERO)
	
func bad_rating():
	rating_anim_rect.texture = bad_rating_texture
	rating_anim(Vector2.DOWN)
	
func rating_anim(dir: Vector2):
	var base_position = rating_anim_rect.position
	rating_anim_rect.modulate = Color.WHITE
	
	#get_tree().create_tween().tween_property(rating_anim_rect, "modulate", Color(1,1,1,0), 1.0)
	#await get_tree().create_tween().tween_property(rating_anim_rect, "position", base_position + dir*50, 1.0).finished
	
	if is_instance_valid(rating_anim_rect):
		rating_anim_rect.modulate = Color(1,1,1,0)
		rating_anim_rect.position = base_position
	