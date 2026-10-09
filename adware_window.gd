extends Window

func _ready():
	# Obtener tamaño de la pantalla y de la ventana
	var screen_size = DisplayServer.screen_get_size()
	var window_size = self.size
	
	# Posición aleatoria dentro de los límites del monitor
	var random_x = randi_range(0, screen_size.x - window_size.x)
	var random_y = randi_range(0, screen_size.y - window_size.y)
	
	self.position = Vector2i(random_x, random_y)
	
	# Conectar el botón "X" nativo de la ventana del sistema operativo
	self.close_requested.connect(_on_close_requested)

func _on_close_requested():
	queue_free() # Destruye la ventana al cerrarla
