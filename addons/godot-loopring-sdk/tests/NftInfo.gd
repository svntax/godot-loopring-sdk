extends PanelContainer

# Simple display for Loopring L2 NFTs

onready var nft_name = get_node("%Name")
onready var nft_description = get_node("%Description")
onready var nft_image = get_node("%NftImage")
onready var attributes_list = get_node("%AttributesList")
onready var attributes_label = get_node("%AttributesLabel")

func add_attribute(value: String) -> void:
	var attribute_entry = Label.new()
	attribute_entry.text = value
	attribute_entry.autowrap = true
	attributes_list.add_child(attribute_entry)
