extends Area2D


@onready var game = get_node("/root/game")

const CLEAR_SCENE = preload("res://scenes/clear.tscn")
var revealed = false
var cleared = false

const TILE_SPRITE = preload("res://assets/sprites/campo.png")
const EMPTY_TILE_SPRITE = preload("res://assets/sprites/campo_vazio.png")
const X_SPRITE = preload("res://assets/sprites/red_x (32 x 32).png")

var MineOnTile : Array
var MinesNearbyList : Array


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and not $explosion.visible and game.started and not game.finished: #and game.started == true: # marcar
		mark()
	
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not game.finished: # cavar
		if game.sweepedTiles < 1: # primeiro clique
			var FirstTilePosition = Vector2i(position)
			
			game.SafeArea.append(FirstTilePosition)
			game.SafeArea.append(Vector2i(FirstTilePosition.x, FirstTilePosition.y - game.tileSize))
			game.SafeArea.append(Vector2i(FirstTilePosition.x, FirstTilePosition.y + game.tileSize))
			game.SafeArea.append(Vector2i(FirstTilePosition.x - game.tileSize, FirstTilePosition.y))
			game.SafeArea.append(Vector2i(FirstTilePosition.x + game.tileSize, FirstTilePosition.y))
			game.SafeArea.append(Vector2i(FirstTilePosition.x - game.tileSize, FirstTilePosition.y - game.tileSize))
			game.SafeArea.append(Vector2i(FirstTilePosition.x + game.tileSize, FirstTilePosition.y - game.tileSize))
			game.SafeArea.append(Vector2i(FirstTilePosition.x - game.tileSize, FirstTilePosition.y + game.tileSize))
			game.SafeArea.append(Vector2i(FirstTilePosition.x + game.tileSize, FirstTilePosition.y + game.tileSize))
			
			for p in range(0, game.SafeArea.size()):
				game.Mines.append(game.SafeArea[p])
			game.spawn_mines(game.initialMines)
			
			await get_tree().physics_frame
			
			game.started = true
		
		if not $flag.visible and $tileSprite.texture == TILE_SPRITE and not $explosion.visible: # clicou no campo pela primeira vez
			sweep()
		elif not $flag.visible and $tileSprite.texture == EMPTY_TILE_SPRITE and not $explosion.visible and not cleared: # clicou em um campo já clicado
			call_deferred("clear")

func _on_tile_mid_area_entered(area: Area2D) -> void:
	if area.is_in_group("clears"):
		if not $flag.visible: # para evitar que uma bomba em uma casa com bandeira exploda caso o jogador clique numa casa ja revelada
			sweep()

func mark():
	if $flag.visible: # tirou a bandeira
		$flag.visible = false
		game.flagsUsed -= 1
	elif not $flag.visible and $tileSprite.texture == TILE_SPRITE and game.flagsUsed < game.initialMines: # colocou a bandeira
		$flag.visible = true
		game.flagsUsed += 1

func sweep():
	load_tile()
	
	if not MineOnTile.size() == 0: # explodiu
		game.finished = true
		$explosion.visible = true
		get_parent().get_node("bombSound1").play()
	else: # espaco vazio
		if not revealed:
			game.sweepedTiles += 1
		revealed = true
		
		$tileSprite.set_texture(EMPTY_TILE_SPRITE)
		$number.visible = true
		get_parent().get_node("clickSound").play()
		if MinesNearbyList.size() == 0 and not cleared: # revelar os campos ao redor
			cleared = true
			call_deferred("clear")

func clear():
	var clearInstance = CLEAR_SCENE.instantiate()
	get_parent().add_child(clearInstance)
	clearInstance.position = position
	await get_tree().physics_frame
	clearInstance.queue_free()

func load_tile():
	MineOnTile = $tileCenter.get_overlapping_areas()
	MinesNearbyList = get_overlapping_areas()
	
	if MineOnTile.size() < 1 and MinesNearbyList.size() > 0:
		$number.text = str(MinesNearbyList.size())
	
	load_number()

func load_number():
	var newColorSettings = $number.label_settings.duplicate()
	match $number.text: # OS NUMEROS DEVEM SER EM STRING
		"1":
			newColorSettings.font_color = "#0000ff"
			newColorSettings.outline_color = "#0000ff"
		"2":
			newColorSettings.font_color = "#009426"
			newColorSettings.outline_color = "#009426"
		"3":
			newColorSettings.font_color = "#ea0012"
			newColorSettings.outline_color = "#ea0012"
		"4":
			newColorSettings.font_color = "#250081"
			newColorSettings.outline_color = "#250081"
		"5":
			newColorSettings.font_color = "#59000d"
			newColorSettings.outline_color = "#59000d"
		"6":
			newColorSettings.font_color = "#007583"
			newColorSettings.outline_color = "#007583"
		"7":
			newColorSettings.font_color = "#770082"
			newColorSettings.outline_color = "#770082"
		"8":
			newColorSettings.font_color = "#5e5e5e"
			newColorSettings.outline_color = "#5e5e5e"
	
	$number.label_settings = newColorSettings
