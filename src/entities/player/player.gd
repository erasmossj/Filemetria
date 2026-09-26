extends CharacterBody3D

## Constantes do Player
@export_category("Player Settings")
@export var SPEED = 5.0
@export var FLY_VELOCITY = 10.0

## Constantes do Mouse
@export_category("Mouse Settings")
@export var MOUSE_SENSITIVITY = 0.2
@export var LIMIT_UP = 80.0
@export var LIMIT_DOWN = -80.0

## Variáveis globais
var cam_ver = 0.0
var cam_is_mov_now = false
var mouse_mode_captured = false

func _ready() -> void:
	## Captura o mouse.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	## Seta variáveis importantes para o controle da captura do mouse
	mouse_mode_captured = true
	cam_is_mov_now = true

func _input(event: InputEvent) -> void:
	# Rotaciona o Player na direção do Mouse.
	if event is InputEventMouseMotion and cam_is_mov_now:
		rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENSITIVITY))
		cam_ver -= deg_to_rad(event.relative.y * MOUSE_SENSITIVITY)
		cam_ver = clamp(cam_ver, deg_to_rad(LIMIT_DOWN), deg_to_rad(LIMIT_UP))
		$Head/Vertical.rotation.x = cam_ver
	
	# Libera o mouse ao apertar ESC.
	if event.is_action_pressed("pause"):
		if mouse_mode_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			mouse_mode_captured = !mouse_mode_captured
			cam_is_mov_now = !cam_is_mov_now
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_mode_captured = !mouse_mode_captured
			cam_is_mov_now = !cam_is_mov_now			

func _physics_process(delta: float) -> void:
	## Provavelmente não existirá gravidade no projeto, mas deixarei comentado.
	#if not is_on_floor() and !fly_mode:
		#velocity += get_gravity() * delta
	
	## Ajuste na velocidade de y para impedir que o player voe pro infinito e além.
	velocity.y = 0
	
	## Input de direção.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	## Input de voo.
	if Input.is_action_pressed("fly_up"):
		velocity.y += FLY_VELOCITY
	elif Input.is_action_pressed("fly_down"):
		velocity.y -= FLY_VELOCITY

	move_and_slide()
