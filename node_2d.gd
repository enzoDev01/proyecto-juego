extends Node2D

var dragging = false
var drag_start_mouse_pos = Vector2()
var drag_start_window_pos = Vector2()

@onready var poligono = $CollisionPolygon2D
@onready var sprite = $AnimatedSprite2D
@onready var http_request = $HTTPRequest
@onready var particulas = $CPUParticles2D
@onready var bocadillo = $Bocadillo

enum State { IDLE, WALK, SLEEP, ANGRY, ADWARE }
var adware_scene = preload("res://AdwareWindow.tscn")
var current_state = State.IDLE
var direction = 1 

# Usaremos dos timers ahora
var action_timer = Timer.new()
var sleep_timer = Timer.new()

func _ready():
	bocadillo.text = ""
	
	get_viewport().transparent_bg = true
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	
	var poligono_real = poligono.global_transform * poligono.polygon
	DisplayServer.window_set_mouse_passthrough(poligono_real)
	
	# Timer para el comportamiento aleatorio (moverse o quedarse quieta)
	action_timer.wait_time = 4.0 
	action_timer.autostart = true
	action_timer.timeout.connect(_on_action_timer_timeout) 
	add_child(action_timer)
	
	# Timer para quedarse dormida por inactividad
	sleep_timer.wait_time = 15.0 # Tiempo en segundos antes de dormirse
	sleep_timer.one_shot = true
	sleep_timer.autostart = true
	sleep_timer.timeout.connect(_on_sleep_timer_timeout)
	add_child(sleep_timer)
	
	http_request.request_completed.connect(_on_request_completed)
	
	pedir_consejo()
	cambiar_estado(State.IDLE)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_start_mouse_pos = DisplayServer.mouse_get_position()
			drag_start_window_pos = get_window().position
			particulas.restart()
			
			# Reiniciamos el contador de inactividad porque interactuamos con ella
			sleep_timer.start()
			cambiar_estado(State.ANGRY)
		else:
			dragging = false
			# Al soltarla, vuelve a la normalidad
			cambiar_estado(State.IDLE)
			bocadillo.text = "" # Limpiamos el texto de enojo

func _process(delta):
	var screen_size = DisplayServer.screen_get_size()
	var window_size = get_window().size
	var target_pos = get_window().position

	if dragging:
		var current_mouse_pos = DisplayServer.mouse_get_position()
		var diff = current_mouse_pos - drag_start_mouse_pos
		target_pos = drag_start_window_pos + diff
	else:
		if current_state == State.WALK:
			target_pos.x += direction * 2

	# Restringir movimiento a los límites de la pantalla
	target_pos.x = clampi(target_pos.x, 0, screen_size.x - window_size.x)
	target_pos.y = clampi(target_pos.y, 0, screen_size.y - window_size.y)
	
	# Rebote contra los bordes
	if current_state == State.WALK:
		if target_pos.x <= 0 or target_pos.x >= screen_size.x - window_size.x:
			direction *= -1
			sprite.flip_h = (direction == -1)

	get_window().position = target_pos

func _on_action_timer_timeout():
	# Si está durmiendo o enojada, no cambia a caminar o idle
	if current_state == State.SLEEP or current_state == State.ANGRY:
		return
		
	var opciones = [State.IDLE, State.WALK, State.ADWARE]
		
	# Alternar aleatoriamente solo entre IDLE (0) y WALK (1)
	var nuevo_estado = opciones.pick_random()
	cambiar_estado(nuevo_estado)

func _on_sleep_timer_timeout():
	# Cuando se acaba el tiempo de inactividad, se duerme
	cambiar_estado(State.SLEEP)

# Función auxiliar para manejar los cambios de animación y texto de forma ordenada
func cambiar_estado(nuevo_estado):
	current_state = nuevo_estado
	
	if current_state == State.IDLE:
		sprite.play("idle") 
	elif current_state == State.WALK:
		sprite.play("walk") 
		var opciones = [1, -1]
		direction = opciones.pick_random()
		sprite.flip_h = (direction == -1)
	elif current_state == State.SLEEP:
		sprite.play("sleep")
		bocadillo.text = "Zzz..."
	elif current_state == State.ANGRY:
		sprite.play("angry")
		bocadillo.text = "-.-"
	elif current_state == State.ADWARE:
		sprite.play("idle") # animación de "risa malvada" ?
		bocadillo.text = "¡Ups! Se me escapó un virus..."
		lanzar_adware()
		

func pedir_consejo():
	var error = http_request.request("https://api.adviceslip.com/advice")
	if error != OK:
		print("Error al realizar la petición HTTP")

func _on_request_completed(result, response_code, headers, body):
	# Si la mascota no está durmiendo ni enojada, muestra el consejo
	if response_code == 200 and current_state != State.SLEEP and current_state != State.ANGRY:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("slip"):
			var consejo_texto = json["slip"]["advice"]
			bocadillo.text = consejo_texto
			await get_tree().create_timer(5.0).timeout
			# Solo borramos el texto si no ha cambiado de estado mientras esperaba
			if current_state != State.SLEEP and current_state != State.ANGRY:
				bocadillo.text = ""
				
func lanzar_adware():
	if adware_scene:
		var num_ventanas = randi_range(1,3)
		for i in range(num_ventanas):
			var ventana = adware_scene.instantiate()
			add_child(ventana)
			ventana.show() # Hace visible la ventana en el SO
			
