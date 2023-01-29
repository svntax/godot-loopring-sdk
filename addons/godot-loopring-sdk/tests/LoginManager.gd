extends Node

export (NodePath) var button_metamask_path = NodePath()
var button_metamask

export (NodePath) var button_walletconnect_path = NodePath()
var button_walletconnect

export (NodePath) var button_gamestop_path = NodePath()
var button_gamestop

export (NodePath) var wallet_connector_path = NodePath()
var wallet_connector

onready var loading_rect = $LoadingRect
onready var loading_label = $LoadingLabel
onready var loading_cancel_button = $LoadingCancelButton

func _ready():
	hide_loading_ui()
	
	var user_config = ConfigFile.new()
	var err = user_config.load(LoopringGlobals.USER_DATA_SAVE_PATH)
	if err == ERR_FILE_NOT_FOUND:
		print("No user data found.")
	elif err != OK:
		print("Error when attempting to load user data.")
	else:
		var account = user_config.get_value(LoopringGlobals.DATA_SECTION, "Account", "")
		var wallet_type = user_config.get_value(LoopringGlobals.DATA_SECTION, "WalletType", -1)
		if account != null and account != "" and wallet_type != null and LoopringGlobals.is_valid_wallet_type(wallet_type):
			# Wallet account detected, skip the login screen
			LoopringGlobals.wallet = account
			LoopringGlobals.set_wallet_type(wallet_type)
			get_tree().change_scene("res://addons/godot-loopring-sdk/tests/TestMainScene.tscn")
	
	# Connect the buttons to their respective callbacks
	button_metamask = get_node(button_metamask_path)
	button_metamask.connect("pressed", self, "Button_Metamask")

	button_walletconnect = get_node(button_walletconnect_path)
	button_walletconnect.connect("pressed", self, "Button_Metamask")

	button_gamestop = get_node(button_gamestop_path)
	button_gamestop.connect("pressed", self, "Button_GME")
	
	# Connect the WalletConnector signal to handle wallet sign in
	wallet_connector = get_node(wallet_connector_path)
	wallet_connector.connect("wallet_connected", self, "_on_wallet_connected")

func Button_GME():
	show_loading_ui()
	wallet_connector.connect_to_web3_wallet("gme")
	LoopringGlobals.set_wallet_type(LoopringGlobals.WalletType.GME)

func Button_Metamask():
	show_loading_ui()
	wallet_connector.connect_to_web3_wallet("m")
	LoopringGlobals.set_wallet_type(LoopringGlobals.WalletType.METAMASK)

func Button_WalletConnect():
	# TODO Apparently this needs a separate process/UX flow? QR code login should
	# be possible.
	show_loading_ui()
	LoopringGlobals.set_wallet_type(LoopringGlobals.WalletType.WALLETCONNECT)

func _on_wallet_connected(wallet: String):
	if wallet == null or wallet.empty():
		print("Failed to connect wallet.")
		LoopringGlobals.clear_wallet()
		hide_loading_ui()
		return
	
	# At this point, LoopringGlobals.wallet should be set.
	print("Connected with wallet: " + wallet)
	save_user_login()
	get_tree().change_scene("res://addons/godot-loopring-sdk/tests/TestMainScene.tscn")

func save_user_login() -> void:
	var user_config = ConfigFile.new()
	var err = user_config.load(LoopringGlobals.USER_DATA_SAVE_PATH)
	if err != OK:
		user_config = ConfigFile.new()
	user_config.set_value(LoopringGlobals.DATA_SECTION, "Account", LoopringGlobals.wallet)
	user_config.set_value(LoopringGlobals.DATA_SECTION, "WalletType", LoopringGlobals.current_wallet_type)
	user_config.save(LoopringGlobals.USER_DATA_SAVE_PATH)

func show_loading_ui() -> void:
	loading_rect.show()
	loading_label.show()
	loading_cancel_button.show()

func hide_loading_ui() -> void:
	loading_rect.hide()
	loading_label.hide()
	loading_cancel_button.hide()

func _on_LoadingCancelButton_pressed():
	hide_loading_ui()
