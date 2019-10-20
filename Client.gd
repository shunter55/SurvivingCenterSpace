extends Node

const DEFAULT_PORT = 8055
const DEFAULT_IP = "127.0.0.1"
const MAX_PLAYERS = 3

var players = {}
var self_data

# Called when the node enters the scene tree for the first time.
func _ready():
	connect_to_server()

func create_server():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)
	
func connect_to_server():
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(DEFAULT_IP, DEFAULT_PORT)
	get_tree().set_network_peer(peer)

func _connected_to_server():
	pass
