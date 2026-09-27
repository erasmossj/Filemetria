extends Node3D

@onready var mesh_instance: MeshInstance3D = $Area3D/LineMesh
@onready var collision: CollisionShape3D = $Area3D/LineCollision

func _ready() -> void:
	## Cada reta ganha a própria cópia da malha e do shape,
	## senão mudar a altura de uma mudaria todas.
	mesh_instance.mesh = mesh_instance.mesh.duplicate()
	collision.shape = collision.shape.duplicate()

func set_length(length: float) -> void:
	mesh_instance.mesh.height = length
	collision.shape.height = length
