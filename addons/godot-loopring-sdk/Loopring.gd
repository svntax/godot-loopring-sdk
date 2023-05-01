extends Node

var poseidon_helper_script = load("res://addons/godot-loopring-sdk/utils/PoseidonHelper.cs")

var m_ApiEndpoint = "https://api3.loopring.io/api/v3/"

func get_api_key(_id: String, _response: String) -> Dictionary:
	var url = m_ApiEndpoint + "apiKey?accountId=" + _id
	var headers = ["X-API-SIG: " + _response]
	var use_ssl = true
	
	var api_result = query_api(url, headers, use_ssl, HTTPClient.METHOD_GET)
	if api_result is GDScriptFunctionState:
		api_result = yield(api_result, "completed")
	
	# See https://docs.loopring.io/en/dex_apis/getApiKey.html
	# for the response data.
	return api_result

func get_account_object(_wallet: String):
	var url = m_ApiEndpoint + "account?owner=" + _wallet
	var headers = ["Content-Type: application/json"]
	var use_ssl = true
	
	var api_result = query_api(url, headers, use_ssl, HTTPClient.METHOD_GET)
	
	if api_result is GDScriptFunctionState:
		api_result = yield(api_result, "completed")
	
	# See https://docs.loopring.io/en/dex_apis/getAccount.html
	# for the response data.
	return api_result

func get_token_balance(_account_id: String, _api_key: String, _token_address: String, _get_metadata: bool, _limit: int = -1, _offset: int = -1):
	var url = m_ApiEndpoint + "user/nft/balances?accountId=" + _account_id + "&tokenAddrs=" + _token_address + "&metadata=" + str(_get_metadata).to_lower() # + "&nftDatas=" + _nftDatas
	if _limit >= 1:
		url += "&limit=" + str(_limit)
	if _offset >= 1:
		url += "&offset=" + str(_offset)
	var headers = ["Content-Type: application/json", "X-API-KEY: " + _api_key]
	var use_ssl = true
	
	var api_result = query_api(url, headers, use_ssl, HTTPClient.METHOD_GET)
	if api_result is GDScriptFunctionState:
		api_result = yield(api_result, "completed")
	
	# See https://docs.loopring.io/en/dex_apis/getUserNftBalances.html
	# for the response data.
	return api_result

# TODO: untested
func resolve_ens(_wallet_address: String):
	var url = "https://api3.loopring.io/api/wallet/v3/resolveName?owner=" + _wallet_address # + "&nftDatas=" + _nftDatas
	var headers = ["Content-Type: application/json"]
	var use_ssl = true
	
	var api_result = query_api(url, headers, use_ssl, HTTPClient.METHOD_GET)
	if api_result is GDScriptFunctionState:
		api_result = yield(api_result, "completed")
	
	return api_result

# Used to fetch the metadata of a Loopring L2 NFT through IPFS.
# An alternative to this method is using the "&metadata=true" parameter in get_token_balance()
func get_metadata(_metadata_ipfs: String):
	var url = LoopringGlobals.IPFSNODE + _metadata_ipfs
	var headers = []
	var use_ssl = true
	
	var api_result = query_api(url, headers, use_ssl, HTTPClient.METHOD_GET)
	
	if api_result is GDScriptFunctionState:
		api_result = yield(api_result, "completed")
	
	return api_result

# Converts an nftId into its corresponding IPFS hash.
# See https://docs.loopring.io/en/integrations/counter_factual_nft.html
func get_ipfs_hash_from_nft_id(nft_id: String) -> String:
	var ipfs_hash = ""
	
	# Remove 0x from head of 32 byte hex string
	var raw_nft_id = nft_id.substr(2, len(nft_id) - 2)
	
	# Add 1220 to the raw id
	raw_nft_id = "1220" + raw_nft_id
	
	# Convert to array of bytes
	var bytes: PoolByteArray = hex_to_byte_array(raw_nft_id)
	
	# Encode in base58
	var poseidon_helper = poseidon_helper_script.new()
	ipfs_hash = poseidon_helper.EncodeToBase58(bytes)
	
	return ipfs_hash

# https://stackoverflow.com/questions/73738478/how-do-a2b-hex-python-but-in-godot
func hex_to_byte_array(hex:String) -> PoolByteArray:
	var hex_length := hex.length()
	if hex_length % 2 == 1:
		push_error("Not even length hex input")
		return PoolByteArray()

	# warning-ignore:integer_division
	var byte_length := hex_length / 2
	var result := PoolByteArray()
	result.resize(byte_length)
	for byte_index in byte_length:
		var hex_index := int(byte_index) * 2
		var hex_couple := hex.substr(hex_index, 2)
		result[byte_index] = ("0x" + hex_couple).hex_to_int()
	
	return result

# Clears the user's wallet and related data from the saved config file.
func logout() -> void:
	LoopringGlobals.clear_wallet()
	var save_path = LoopringGlobals.USER_DATA_SAVE_PATH
	var data_section = LoopringGlobals.DATA_SECTION
	var user_config = ConfigFile.new()
	
	var err = user_config.load(save_path)
	if err == ERR_FILE_NOT_FOUND:
		print("No user data found.")
	elif err != OK:
		print("Error when attempting to load user data.")
	else:
		if user_config.has_section(data_section):
			user_config.erase_section(data_section)
			user_config.save(save_path)

func query_api(url: String, headers: Array, use_ssl: bool, method: int, query: String = "") -> Dictionary:
	var http = HTTPRequest.new()
	add_child(http)
	http.request(url, headers, use_ssl, method, query)
	
	# [result, status code, response headers, body]
	var response = yield(http, "request_completed")
	if response[0] != OK:
		var message = "An error occurred in the HTTP request."
		push_error(message)
		return create_error_response(message)
	
	var body = response[3]
	var json = JSON.parse(body.get_string_from_utf8())
	if json.error != OK:
		var message = "Error when parsing JSON response."
		push_error(message)
		return create_error_response(message)
	
	http.queue_free()
	
	return json

# Format for error messages
func create_error_response(message: String) -> Dictionary:
	return {
		"error": {
			"message": message
		}
	}
