extends SceneTree
## Generates only the dedicated product assets, never the existing world scenes.
## godot --headless --path . --script res://tools/build_kiosk_products.gd


func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/models/kiosk_products")
	for spec: Dictionary in KioskCatalog.PRODUCTS:
		var root: Node3D = KioskProductModels.create(spec["id"])
		_own(root, root)
		var scene: PackedScene = PackedScene.new()
		var err: Error = scene.pack(root)
		if err == OK:
			err = ResourceSaver.save(scene, "res://assets/models/kiosk_products/%s.tscn" % spec["id"])
		root.free()
		if err != OK:
			push_error("Product build failed: %s" % error_string(err))
			quit(1)
			return
	print("[products] built %d reusable models" % KioskCatalog.PRODUCTS.size())
	quit(0)


func _own(node: Node, root: Node) -> void:
	for child: Node in node.get_children():
		child.owner = root
		_own(child, root)
