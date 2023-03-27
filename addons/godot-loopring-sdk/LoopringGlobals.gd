extends Node

enum WalletType { NONE, METAMASK, WALLETCONNECT, GME }
var current_wallet_type = WalletType.NONE

var wallet : String = ""
var ENS : String = ""

const USER_DATA_SAVE_PATH = "user://user_data.cfg"
const DATA_SECTION = "LoopringData" # Name of the section in the user data file that contains the user's info.

# Required for API calls for NFT data
const IPFSNODE : String = "https://ipfs.io/ipfs/" # Set to public gateway, set to private for better perfomance

func set_wallet_type(wallet_type: int) -> void:
	current_wallet_type = wallet_type

func get_wallet_type_as_string() -> String:
	if current_wallet_type == WalletType.NONE:
		return ""
	elif current_wallet_type == WalletType.GME:
		return "gme"
	else:
		return "m"

func clear_wallet() -> void:
	wallet = ""
	ENS = ""
	current_wallet_type = WalletType.NONE

func is_valid_wallet_type(wallet_type: int) -> bool:
	return wallet_type in [WalletType.METAMASK, WalletType.WALLETCONNECT, WalletType.GME]
