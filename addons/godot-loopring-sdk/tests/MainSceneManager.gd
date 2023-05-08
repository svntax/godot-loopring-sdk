extends Node2D

var poseidon_helper_script = load("res://addons/godot-loopring-sdk/utils/PoseidonHelper.cs")

const NftInfoCard = preload("res://addons/godot-loopring-sdk/tests/NftInfo.tscn")

onready var wallet_connector = $WalletConnector

onready var wallet_label = $UI/WalletLabel
onready var api_key_label = $UI/ApiKeyLabel
onready var unlock_button = $UI/UnlockButton
onready var unlock_label = $UI/UnlockLabel
onready var check_user_nfts_button = $UI/CheckUserNFTsButton
onready var nft_list_container = $UI/NftList/HBoxContainer
onready var token_address_input = $UI/TokenAddress

# Note: these should NOT be saved. They should be deleted after you're done
# using them. You can always query the API key or account object again if needed
# in the future.
var api_key : String = ""
var account_object : Dictionary = {}

func _ready():
	unlock_button.show()
	check_user_nfts_button.hide()
	
	wallet_connector.connect("failed_to_sign", self, "_on_web3_sign_fail")
	
	# Get and display the wallet address
	wallet_label.text = "Wallet: " + LoopringGlobals.wallet
	get_ens()

func get_ens() -> void:
	var json = Loopring.resolve_ens(LoopringGlobals.wallet)
	if json is GDScriptFunctionState:
		json = yield(json, "completed")
	if json.error == OK:
		if json.result.has("data") and json.result.get("data", "") != "":
			wallet_label.text = json.result.data

func get_account() -> void:
	var json = Loopring.get_account_object(LoopringGlobals.wallet)
	if json is GDScriptFunctionState:
		json = yield(json, "completed")
	account_object = json.result

func get_api_key(_xapisig: String):
	# Queries user's API Key
	var json = Loopring.get_api_key(str(account_object.get("accountId")), _xapisig)
	if json is GDScriptFunctionState:
		json = yield(json, "completed")
	
	if json.error != OK:
		printerr("Failed to parse API key from response.")
		unlock_button.disabled = false
		unlock_button.text = "Unlock"
		return
	
	api_key = json.result.get("apiKey")
	if api_key == "":
		api_key_label.text = "Failed to get API key. Check response."
		unlock_button.disabled = false
		unlock_button.text = "Unlock"
	else:
		api_key_label.text = "API Key (first 5 chars):   " + api_key.substr(0, 5) + "******************"
		# Finished retrieving API key
		unlock_button.hide()
		check_user_nfts_button.show()
		unlock_label.text = "You can now check your NFTs"

func get_tokens() -> void:
	# Queries user NFT data
	# NOTE: 0x1D006a27BD82E10F9194D30158d91201E9930420
	# is the address for the original MetaBoy collection smart contract
	var token_address = token_address_input.text
	var json = Loopring.get_token_balance(str(account_object.get("accountId")), api_key, token_address, true)
	
	if json is GDScriptFunctionState:
		json = yield(json, "completed")
	
	var response_object = json.result
	if response_object.has("data"):
		# Note: In this example scene, we allow the user to query for different
		# smart contracts, but in a game or app that deals with specific collections
		# only, caching the NFT data here is better.
		
		# First clear the list of label nodes
		for child in nft_list_container.get_children():
			child.queue_free()
		
		var tokens : Array = response_object.get("data")
		for token in tokens:
			var nft_card = NftInfoCard.instance()
			nft_list_container.add_child(nft_card)
			
			# Read the NFT metadata
			var metadata = token.get("metadata")
			
			var nft_name = metadata.get("base").get("name")
			var nft_description = metadata.get("base").get("description")
			var nft_attributes_json = JSON.parse(metadata.get("extra").get("attributes"))
			if nft_attributes_json.error == OK:
				var nft_attributes = nft_attributes_json.result
				if nft_attributes and !nft_attributes.empty():
					for attribute in nft_attributes:
						nft_card.add_attribute(attribute.get("trait_type") + ": " + attribute.get("value"))
				else:
					nft_card.attributes_label.text = "Attributes: No attributes."
			else:
				printerr("Failed to parse token attributes.")
			
			nft_card.nft_name.text = nft_name
			var description = nft_description
			if description == null or description == "":
				description = "No description."
			nft_card.nft_description.text = description
				
			# Attempt to get NFT image
			# TODO: Godot does not support displaying gifs
#			var image_link = metadata.get("base").get("image")
#			var image_hash = image_link.substr(image_link.find_last("/") + 1)
#			var nft_image_texture = load_texture_from_web(LoopringGlobals.IPFSNODE + image_hash)
#			if nft_image_texture is GDScriptFunctionState:
#				nft_image_texture = yield(nft_image_texture, "completed")
#			nft_card.nft_image.texture = nft_image_texture

# Download an image from a url and create a Texture from it.
func load_texture_from_web(url: String) -> Texture:
	var texture = ImageTexture.new()
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request(url)
	
	# [result, status code, response headers, body]
	var response = yield(http, "request_completed")
	if response[0] != OK:
		var message = "An error occurred in the HTTP request."
		push_error(message)
		return
	
	var body = response[3]
	var image = Image.new()
	var image_error = image.load_png_from_buffer(body)
	if image_error != OK:
		printerr("An error occurred while trying to display the image.")
	
	texture.create_from_image(image)
	
	http.queue_free()
	
	return texture

func sign_message_function() -> void:
	# Keyseed is manually set as a string as sometimes
	# the object account's keySeed is null. Not sure why, may be an await/async issue.
	var keyseed_msg : String = "Sign this message to access Loopring Exchange: 0x0BABA1Ad5bE3a5C0a66E7ac838a129Bf948f1eA4 with key nonce: 0"
	var response = ""
	
	# *Sometimes* it fails to fetch the account keyseed, but also the keyNonce can be different,
	# if the account information is not empty or null, we replace the keyNonce at the end.
	if !account_object.has("keySeed"):
		printerr("Failed to fetch account info.")
		keyseed_msg += "0"
	elif account_object.get("keySeed") != "" or account_object.get("keySeed") != null:
		keyseed_msg = keyseed_msg.substr(0, keyseed_msg.length() - 1) + str(int(account_object.get("keyNonce")) - 1)
	else:
		printerr("Failed to fetch account info.")
		keyseed_msg += "0"
	
	# Checks which wallet the user has, as WalletConnect has a different signing
	# method, and then signs the keySeed message.
	if LoopringGlobals.current_wallet_type == LoopringGlobals.WalletType.METAMASK:
		response = wallet_connector.sign_web3_message("m", LoopringGlobals.wallet, keyseed_msg)
	elif LoopringGlobals.current_wallet_type == LoopringGlobals.WalletType.WALLETCONNECT:
		pass
		#response = personal_sign_walletconnect() # TODO see comment for this function
	elif LoopringGlobals.current_wallet_type == LoopringGlobals.WalletType.GME:
		response = wallet_connector.sign_web3_message("gme", LoopringGlobals.wallet, keyseed_msg)
	
	if response is GDScriptFunctionState:
		response = yield(response, "completed")
	
	if !response:
		# This can happen if users disconnect their wallet from the app and try
		# to sign a transaction anyway.
		printerr("Logging out the user...")
		Loopring.logout()
		get_tree().change_scene("res://addons/godot-loopring-sdk/tests/TestLogin.tscn")
		return
	
	var poseidon_helper = poseidon_helper_script.new()
	var x_api_sig = poseidon_helper.GetApiKeyEDDSASig(response, str(account_object.get("accountId")), LoopringGlobals.wallet)
	get_api_key(x_api_sig)

# Sign a message with WalletConnect
# TODO: This originally uses WalletConnectUnity's "WalletConnect.cs" script component.
# Currently not implemented
#func personal_sign_walletconnect(message: String, address_index: int = 0) -> String:
#	var address = WalletConnect.ActiveSession.Accounts[addressIndex]
#	var results = await WalletConnect.ActiveSession.EthPersonalSign(address, message)
#
#	return results

func _on_UnlockButton_pressed():
	unlock_button.disabled = true
	unlock_button.text = "Waiting for response..."
	yield(get_account(), "completed")
	sign_message_function()

func _on_CheckUserNFTsButton_pressed():
	check_user_nfts_button.disabled = true
	check_user_nfts_button.text = "Fetching user's NFTs..."
	yield(get_tokens(), "completed")
	check_user_nfts_button.disabled = false
	check_user_nfts_button.text = "Check user's NFTs"

func _on_LogoutButton_pressed():
	Loopring.logout()
	get_tree().change_scene("res://addons/godot-loopring-sdk/tests/TestLogin.tscn")

func _on_web3_sign_fail():
	print("Logging out user...")
	Loopring.logout()
	get_tree().change_scene("res://addons/godot-loopring-sdk/tests/TestLogin.tscn")
