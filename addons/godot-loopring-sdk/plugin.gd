tool
extends EditorPlugin

const AUTOLOAD_LOOPRING = "Loopring"
const AUTOLOAD_LOOPRING_GLOBALS = "LoopringGlobals"

func _enter_tree():
	add_autoload_singleton(AUTOLOAD_LOOPRING, "res://addons/godot-loopring-sdk/Loopring.gd")
	add_autoload_singleton(AUTOLOAD_LOOPRING_GLOBALS, "res://addons/godot-loopring-sdk/LoopringGlobals.gd")

func _exit_tree():
	remove_autoload_singleton(AUTOLOAD_LOOPRING)
	remove_autoload_singleton(AUTOLOAD_LOOPRING_GLOBALS)
