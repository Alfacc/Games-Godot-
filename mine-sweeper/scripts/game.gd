extends Node2D


const TILE_SCENE = preload("res://scenes/tile.tscn")
const MINE_SCENE = preload("res://scenes/mine.tscn")
const CLEAR_SCENE = preload("res://scenes/clear.tscn")

const X_SPRITE = preload("res://assets/sprites/red_x (32 x 32).png")

var started = false
var finished = false
var victory = false

#var FirstTilePosition : Vector2
var Tiles : Array
var tileSize = 128
var verticalTiles = 16
var horizontalTiles = 32
var sweepedTiles = 0

var SafeArea : Array # area do primeiro clique
var Mines : Array
var initialMines = 105
var bombCount = 0

var timer = 0.0
var flagsUsed = 0

var alreadyShowed = false

func _ready() -> void:
	spawn_tiles()
	
	$flagsRemaining.label_settings.font_color = "#ffffff"
	$flagsRemaining.label_settings.outline_color = "#ffffff"
	
	$flagsRemaining.text = str(initialMines)

func _process(delta: float) -> void:
	if started and not finished:
		timer += delta
		$timer.text = String.num(timer, 1)
	
		$flagsRemaining.text = str(initialMines - flagsUsed)
		if $flagsRemaining.text == "0":
			$flagsRemaining.label_settings.font_color = "#ca3020"
			$flagsRemaining.label_settings.outline_color = "#ca3020"
		else:
			$flagsRemaining.label_settings.font_color = "#ffffff"
			$flagsRemaining.label_settings.outline_color = "#ffffff"
		
		if sweepedTiles == horizontalTiles * verticalTiles - initialMines:
			victory = true
			finished = true
	
	if finished and not alreadyShowed: # fim de jogo
		alreadyShowed = true
		$endSceneDelay.start()
		await $endSceneDelay.timeout
		end_scene()
		
		if victory: # venceu
			pass
		else:
			pass

func _on_focus_lost():
	pass

func _on_button_pressed() -> void:
	get_tree().reload_current_scene()


func spawn_tiles():
	for y in range(1, verticalTiles + 1):
		for x in range(1, horizontalTiles + 1):
			var tileInstance = TILE_SCENE.instantiate()
			add_child(tileInstance)
			Tiles.append(tileInstance)
			tileInstance.position = Vector2i(x * tileSize - tileSize / 2, y * tileSize + tileSize * 1.5)

func spawn_mines(minesNumber):
	for m in range(0, minesNumber):
		var mineInstance = MINE_SCENE.instantiate()
		add_child(mineInstance)
		mineInstance.position = Vector2i(randi_range(1, horizontalTiles) * tileSize - tileSize / 2, randi_range(1, verticalTiles) * tileSize + tileSize * 1.5)
		
		while not check_position(mineInstance.position):
			mineInstance.position = Vector2i(randi_range(1, horizontalTiles) * tileSize - tileSize / 2, randi_range(1, verticalTiles) * tileSize + tileSize * 1.5)
		Mines.append(mineInstance.position)

func check_position(Position):
	for i in range(0, Mines.size()):
		if Vector2i(Position) == Vector2i(Mines[i]): # or Position == FirstTilePosition:
			return false # existe mina na posicao
	return true # a posicao esta vazia

func end_scene():
	for t in range(0, Tiles.size()):
		Tiles[t].load_tile()
		
		if victory: # venceu
			if Tiles[t].MineOnTile.size() > 0:
				Tiles[t].get_node("flag").visible = true
				await get_tree().process_frame
			flagsUsed = initialMines
		
		else: # perdeu
			if Tiles[t].MineOnTile.size() != 0 and not Tiles[t].get_node("flag").visible: # tem bomba mas nao tem bandeira no tile
				Tiles[t].get_node("explosion").visible = true
				bombCount += 1
				if bombCount == 1 or bombCount % 10 == 0:
					$bombSound2.play()
				await get_tree().process_frame
			elif Tiles[t].MineOnTile.size() == 0 and Tiles[t].get_node("flag").visible: # tile com bandeira marcada errada pelo jogador
				Tiles[t].get_node("explosion").set_texture(X_SPRITE)
				Tiles[t].get_node("explosion").visible = true
