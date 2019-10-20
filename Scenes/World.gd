extends Node

const Player = preload("res://Scenes/Player.tscn")
const PlayerPacket = preload("res://PlayerPacket.gd")

# Map[playerId, Player] - playerId is the same as NetworkId
var players: Dictionary = {}
# Map[teamId, List[PlayerId]]
var teams: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	var networkId = get_tree().get_network_unique_id()
	
	for playerId in players:
		if playerId == networkId:
			players[playerId].set_network_master(playerId)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func add_player(newPlayerId, teamId):
	var player = Player.instance()
	player.set_name("player-" + str(newPlayerId))
	players[newPlayerId] = player
	player.set_network_master(newPlayerId)
	
	player.id = newPlayerId
	player.teamId = teamId
	add_team_member(player, teamId)
	
	var ship = get_node("Ship")
	player.position = ship.get_node("SpawnLocation").position
	ship.add_child(player)
	return player

func add_team_member(player, teamId):
	if teams.has(teamId):
		teams[teamId].append(player.id)
	else:
		teams[teamId] = [ player.id ]

func server_update_all_players():
	server_update_players(self.players.keys())

func server_update_players_on_team(teamId):
	print("update team")
	server_update_players(self.teams[teamId])
	
func server_update_other_players_on_team(teamId, playerId):
	print("update team")
	var players = teams[teamId]
	players.remove(playerId)
	server_update_players(players)

# Server needs sync clients with its state.
func server_update_players(playerIds: Array):
	print("update_players")
	var playersData = []
	for playerId in playerIds:
		var player = players[playerId]
		var playerData = {
			id = playerId,
			position = player.position,
			velocity = player.velocity,
			#movement = player.movement
		}
		playersData.append(playerData)
	rpc("update_players", Network.time(), playersData)



remote func update_players(timeSent, playersData):
	if get_tree().get_rpc_sender_id() == 1:
		for playerData in playersData:
			var player = players[playerData.id]
			#player.updateData(timeSent, playerData)
			
remote func update_players_on_team(timeSent, playersData):
	if get_tree().get_rpc_sender_id() == 1:
		for playerData in playersData:
			var player = players[playerData.id]
			#player.updateData(timeSent, playerData)
