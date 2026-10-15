extends TestCase
## Physical provisions, including soap (not sold by the demo day's correct path).

var fixture: Node3D


func before_each() -> void:
	fixture = Node3D.new()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	# The synchronous runner is called from the test scene's _ready. Adding under
	# that scene enters the real tree and runs child _ready without a deferred wait.
	var test_scene: Node = tree.root.get_child(tree.root.get_child_count() - 1)
	test_scene.add_child(fixture)


func after_each() -> void:
	fixture.free()


func _parcel(item: String, quantity: int, source: String = "official") -> RationParcel3D:
	var result: RationParcel3D = RationParcel3D.new()
	result.configure(item, quantity, source)
	fixture.add_child(result)
	return result


func test_configuration_before_ready_controls_first_physical_product() -> void:
	var parcel: RationParcel3D = _parcel("sugar", 1000, "hidden")
	assert_true(parcel.is_node_ready())
	assert_eq(parcel.item_id, "sugar")
	assert_eq(parcel.amount, 1000)
	assert_eq(parcel.source, "hidden")
	assert_eq(parcel.action, "parcel")
	assert_eq(parcel.collision_layer, 2)
	assert_true(parcel.caption.text.contains("CUKIER"))
	assert_true(parcel.caption.text.contains("1000 g"))
	assert_true(parcel.bounds_size.y > parcel.bounds_size.x, "sugar is an upright bag")


func test_all_product_colliders_rest_on_origin_and_labels_move_with_packaging() -> void:
	var parcel: RationParcel3D = _parcel("meat", 750)
	var dimensions: Array[Vector3] = []
	for product: String in ["meat", "sugar", "soap"]:
		var quantity: int = 1 if product == "soap" else 500
		parcel.configure(product, quantity, "official")
		var collision: CollisionShape3D = parcel.get_node("OrderCollision") as CollisionShape3D
		assert_true(collision.shape is BoxShape3D)
		assert_eq((collision.shape as BoxShape3D).size, parcel.bounds_size)
		assert_true(is_zero_approx(collision.position.y - parcel.bounds_size.y / 2), "bottom rests on support")
		assert_true(parcel.bounds_size.x > 0 and parcel.bounds_size.y > 0 and parcel.bounds_size.z > 0)
		assert_eq(parcel.support_offset, 0.0)
		dimensions.append(parcel.bounds_size)
		assert_true(parcel.is_ancestor_of(parcel.caption), "ink belongs to the physical package")
		assert_eq(parcel.caption.billboard, BaseMaterial3D.BILLBOARD_DISABLED)
		var previous: Vector3 = parcel.caption.global_position
		var displacement: Vector3 = Vector3(0.3, 0.1, -0.2)
		parcel.position += displacement
		assert_true(parcel.caption.global_position.is_equal_approx(previous + displacement))
		assert_true(parcel.grip_position.is_finite())
		assert_true(parcel.carry_position().is_finite())
		assert_true(parcel.carry_rotation().is_finite())
		if product == "soap":
			assert_true(parcel.caption.text.contains("MYDŁO"))
			assert_true(parcel.caption.text.contains("1 szt."))
	assert_ne(dimensions[0], dimensions[1])
	assert_ne(dimensions[1], dimensions[2])
	assert_ne(dimensions[0], dimensions[2])


func test_reconfiguration_preserves_body_collider_world_pose_and_attached_hand() -> void:
	var parcel: RationParcel3D = _parcel("meat", 750)
	parcel.position = Vector3(0.4, 0.97, -2.0)
	parcel.rotation = Vector3(0, 0.2, 0)
	var pose: Transform3D = parcel.global_transform
	var body_id: int = parcel.get_instance_id()
	var collision_id: int = parcel.get_node("OrderCollision").get_instance_id()
	var hand: Node3D = Node3D.new()
	parcel.add_child(hand)
	for product: String in ["meat", "sugar", "soap", "meat"]:
		parcel.configure(product, 1 if product == "soap" else 500, "official")
		assert_eq(parcel.get_instance_id(), body_id)
		assert_eq(parcel.get_node("OrderCollision").get_instance_id(), collision_id)
		assert_eq(parcel.global_transform, pose)
		assert_true(is_instance_valid(hand) and hand.get_parent() == parcel)
		var shape: Shape3D = (parcel.get_node("OrderCollision") as CollisionShape3D).shape
		var label: Label3D = parcel.caption
		parcel.configure(product, 2 if product == "soap" else 250, "hidden")
		assert_eq((parcel.get_node("OrderCollision") as CollisionShape3D).shape, shape, "amount update reuses geometry")
		assert_eq(parcel.caption, label, "amount update reuses the attached printed label")
		assert_true(parcel.caption.text.contains("2 szt." if product == "soap" else "250 g"))
		assert_false(parcel.caption.text.to_lower().contains("hidden"), "stock choice is not a floating verdict label")


func test_every_product_has_loaded_pick_and_place_foley_without_invalid_events() -> void:
	var foley: RationFoley = RationFoley.new()
	fixture.add_child(foley)
	var expected: PackedStringArray = []
	for product: String in ["meat", "sugar", "soap"]:
		for contact: String in ["pick", "place"]:
			var event: String = "package_%s_%s" % [product, contact]
			assert_true(foley.streams.get(event) is AudioStream, "imported " + event)
			foley.play_package(contact, product)
			expected.append(event)
	assert_eq(foley.events, expected)
	foley.play_package("place", "unknown")
	foley.play_package("unknown", "soap")
	assert_eq(foley.events, expected, "unsupported contacts do not manufacture events")
