extends Node3D

## Variáveis globais
@onready var POINT_SCENE = preload("res://src/entities/statics/Point/point.tscn")
@onready var LINE_SCENE = preload("res://src/entities/statics/Line/line.tscn")
@onready var sp = $"../../../../SpawnManager"
var has_a_point = false
var last_point_position : Vector3

func call_system(position : Vector3):
	_create_point(position)

func _create_point(position : Vector3):
	sp.spawn_entity(POINT_SCENE, position, null, null)
	
	if has_a_point:
		var line_length = last_point_position.distance_to(position)
		if line_length > 0.001:
			var line_position = last_point_position.lerp(position, 0.5)
			sp.spawn_entity(LINE_SCENE, line_position, line_length, position)
	
	has_a_point = !has_a_point
	last_point_position = position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
