extends Node3D

## Cenas instanciadas pelo sistema.
const POINT_SCENE: PackedScene = preload("res://src/entities/statics/Point/point.tscn")
const LINE_SCENE: PackedScene = preload("res://src/entities/statics/Line/line.tscn")

## Distância mínima entre A e B para existir reta.
const MIN_LINE_LENGTH := 0.001

@onready var sp = $"../../../../SpawnManager"

## Reta em andamento: ponto A esperando o segundo clique.
var has_a_point := false
var point_a: Node3D = null
var point_a_position: Vector3

## Retas fechadas, em ordem de criação.
## Cada item: {"line": Node3D, "a": Node3D, "b": Node3D, "length": float}
var lines: Array[Dictionary] = []


## Clique esquerdo: ancora o ponto A ou fecha a reta no ponto B.
func add_point(point_position: Vector3) -> void:
	if not has_a_point:
		point_a = sp.spawn_entity(POINT_SCENE, point_position)
		point_a_position = point_position
		has_a_point = true
		return

	## Comprimento em metros (1 unidade = 1 metro).
	var length := point_a_position.distance_to(point_position)

	## B em cima de A: ignora o clique e A continua esperando.
	if length <= MIN_LINE_LENGTH:
		return

	var point_b: Node3D = sp.spawn_entity(POINT_SCENE, point_position)
	
	var label_point_b = point_b.get_node("HUD/LabelGroup/PointLabel")
	label_point_b.text = "%.2f" % length + "m"
	
	var midpoint := point_a_position.lerp(point_position, 0.5)
	var line: Node3D = sp.spawn_entity(LINE_SCENE, midpoint, length, point_position)

	lines.append({"line": line, "a": point_a, "b": point_b, "length": length})

	has_a_point = false
	point_a = null


## Q: cancela a reta em andamento, apagando o ponto A.
func cancel_line() -> void:
	if not has_a_point:
		return

	sp.remove_entity(point_a)
	point_a = null
	has_a_point = false


## E: desfaz a última reta fechada (reta + seus dois pontos).
func undo_last_line() -> void:
	if lines.is_empty():
		return

	_erase_line(lines.size() - 1)


## Ctrl+E: apaga todas as retas e também a reta em andamento.
func clear_lines() -> void:
	cancel_line()

	for record in lines:
		_free_line(record)
	lines.clear()


## Botão direito: apaga o ponto mirado e a reta a que ele pertence.
func remove_point(point: Node3D) -> void:
	if point == point_a:
		cancel_line()
		return

	for i in lines.size():
		if lines[i]["a"] == point or lines[i]["b"] == point:
			_erase_line(i)
			return


## Comprimento da última reta fechada, em metros (0 se não houver).
func get_last_line_length() -> float:
	return 0.0 if lines.is_empty() else lines[-1]["length"]


func _erase_line(index: int) -> void:
	_free_line(lines[index])
	lines.remove_at(index)


func _free_line(record: Dictionary) -> void:
	sp.remove_entity(record["line"])
	sp.remove_entity(record["a"])
	sp.remove_entity(record["b"])
