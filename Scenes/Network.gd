extends Node

const PlayerPacket = preload("res://PlayerPacket.gd")

const DEFAULT_PORT = 8055
const DEFAULT_IP = "127.0.0.1"
const MAX_PLAYERS = 3

var world

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func _process(delta):
	pass

func create_server():
	var peer = NetworkedMultiplayerENet.new()
	var err = peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	if err != OK:
		#is another server running?
		print("Can't host, address in use.")
		return
		
	get_tree().set_network_peer(peer)
	
	create_world()
	register_player(get_tree().get_network_unique_id())
	
	var updateTimer = Timer.new()
	updateTimer.set_wait_time(0.5)
	updateTimer.set_one_shot(false)
	updateTimer.connect("timeout", world, "server_update_all_players")
	add_child(updateTimer)
	#updateTimer.start()

func connect_to_server():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(DEFAULT_IP, DEFAULT_PORT)
	get_tree().set_network_peer(peer)
	
	create_world()
	register_player(get_tree().get_network_unique_id())
	
# Called on both clients and server when a peer connects.
func _player_connected(id):
	print("player connected: " + str(id))
	var player = register_player(id)
	
	if get_tree().is_network_server():
		world.server_update_players_on_team(player.teamId)

# Only called on Clients
func _connected_ok():
	print("connected ok")
	pass

func create_world():
	world = preload("res://Scenes/World.tscn").instance()
	get_parent().add_child(world)

func register_player(newPlayerId):
	print("register player: " + str(newPlayerId))
	# Get the id of the RPC sender.
	var networkId = get_tree().get_network_unique_id()
	# Store the info
	var newPlayer = world.add_player(newPlayerId, 1)
	return newPlayer

var currentTimeDiff = abs(OS.get_unix_time() - OS.get_system_time_secs()) * 1000
func time():
	return OS.get_system_time_msecs() - currentTimeDiff - 1569898364754
	











