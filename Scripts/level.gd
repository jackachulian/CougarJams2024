class_name Level
extends Resource

static var current_level: Level

@export var name: String
@export var starting_speed: float = 300
@export var min_speed: float = 200
@export var min_speed_gain: float = 25 # amount min_speed increases by at the end of each round
@export var max_speed: float = 600
@export var max_speed_gain: float = 0 # amount max_speed increases by at the end of each round

@export var neutral_sprite: Texture
@export var happy_sprite: Texture
@export var very_happy_sprite: Texture
@export var	angry_sprite: Texture
@export var	very_angry_sprite: Texture

@export var rank_thresholds: Array[int] = [7500, 5500, 4000, 3000, 2000]

# level that comes after this level, if any.
@export var next_level: Level

@export var dialogue_name: String

@export var dynamic_music: DynamicMusic

@export var background_texture: Texture2D

@export var note_textures: Array[Texture2D]

@export var note_hit_textures: Array[Texture2D]

@export var note_target_texture: Texture2D
