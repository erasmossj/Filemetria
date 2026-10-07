extends Node3D

## Raio do ponto (point.tscn). O colisor da reta para na superfície da esfera.
const POINT_RADIUS := 0.05

@onready var mesh_instance: MeshInstance3D = $Area3D/LineMesh
@onready var collision: CollisionShape3D = $Area3D/LineCollision

func _ready() -> void:
	## Cada reta ganha a própria cópia da malha e do shape,
	## senão mudar a altura de uma mudaria todas.
	mesh_instance.mesh = mesh_instance.mesh.duplicate()
	collision.shape = collision.shape.duplicate()

func set_length(length: float) -> void:
	## A malha vai de centro a centro dos pontos.
	mesh_instance.mesh.height = length
	## O colisor desconta um raio de ponto em cada ponta, para não cobrir os pontos.
	collision.shape.height = max(length - 2.0 * POINT_RADIUS, 0.01)
