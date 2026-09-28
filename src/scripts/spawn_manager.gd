extends Node3D

func spawn_entity(entity : PackedScene, spawn_position : Vector3, entity_length = null, destiny = null) -> Node3D:
	var new_entity = entity.instantiate()
	get_tree().current_scene.add_child(new_entity)
	
	new_entity.global_position = spawn_position
	
	if entity_length != null and destiny != null:
		## Retas verticais: o "para cima" padrão não serve, troca por outro eixo.
		var direction: Vector3 = (destiny - spawn_position).normalized()
		var up := Vector3.UP
		if abs(direction.dot(up)) > 0.99:
			up = Vector3.RIGHT

		## −Z do nó passa a apontar para o destino.
		new_entity.look_at(destiny, up)

		## A própria reta ajusta o comprimento da malha e do colisor.
		new_entity.set_length(entity_length)
		
		## Adiciona o tamanho da reta na Label
		new_entity.set_label("%.2f" % entity_length)

	return new_entity

func remove_entity(entity : Node3D):
	if is_instance_valid(entity):
		entity.queue_free()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
