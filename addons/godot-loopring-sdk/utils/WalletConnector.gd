extends Node

signal wallet_connected(wallet)
signal failed_to_sign()

# JavaScript methods for web API

var connect_to_wallet_callback = JavaScript.create_callback(self, "_on_wallet_connected")
func connect_to_wallet(wallet_name: String) -> void:
	var window = JavaScript.get_interface("window")
	var Wallet = null
	var wallet = wallet_name.to_lower()
	
	match wallet:
		"gme":
			Wallet = window.gamestop
		"m":
			Wallet = window.ethereum
		_:
			window.alert("Wallet not set!")
	
	if !Wallet: return
	
	# See https://godotengine.org/qa/120130/javascript-interface-help-to-call-a-method-solved
	var query = JavaScript.create_object("Object")
	query["method"] = "eth_requestAccounts"
	Wallet.request(query).then(connect_to_wallet_callback)

func _on_wallet_connected(res):
	# Response is a string[] - An array of a single, hexadecimal Ethereum address string
	var arr = res[0]
	var wallet = arr[0]
	LoopringGlobals.wallet = wallet
	emit_signal("wallet_connected", wallet)

var our_sign_message_callback = JavaScript.create_callback(self, "_on_message_signed")
var our_sign_message_error_callback = JavaScript.create_callback(self, "_on_message_signed_error")
func our_sign_message(wallet: String, account: String, msg: String) -> void:
	var window = JavaScript.get_interface("window") 
	var Wallet = null
	wallet = wallet.to_lower()
	
	match wallet:
		"gme":
			Wallet = window.gamestop
		"m":
			Wallet = window.ethereum
		_:
			window.alert("Wallet not set!")
	
	if !Wallet: return

	var query = JavaScript.create_object("Object")
	query["method"] = "personal_sign"
	var params = JavaScript.create_object("Array")
	params[0] = msg
	params[1] = account
	query["params"] = params
	Wallet.request(query).then(our_sign_message_callback).catch(our_sign_message_error_callback)

func _on_message_signed(res):
	var window = JavaScript.get_interface("window")
	# Response is an array with a single string element
	window.WCsignature = res[0]

func _on_message_signed_error(res):
	printerr("Failed to sign request.")
	emit_signal("failed_to_sign")

func get_signature() -> String:
	var window = JavaScript.get_interface("window")
	if !window.WCsignature:
		return ""
	
	var returnStr = window.WCsignature
	return returnStr

# Functions from the original WalletConnector.cs file

func connect_to_web3_wallet(wallet_name: String) -> void:
	connect_to_wallet(wallet_name)

func sign_web3_message(wallet_name: String, acc: String, message: String) -> String:
	our_sign_message(wallet_name, acc, message)
	var sig = ""
	
	var timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	
	while sig == "":
		timer.start(1)
		yield(timer, "timeout")
		print("Waiting for signature")
		sig = get_signature()
	
	timer.queue_free()
	
	return sig
