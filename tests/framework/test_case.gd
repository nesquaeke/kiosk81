class_name TestCase
extends RefCounted
## Base class for unit tests. Every method whose name starts with
## "test_" is run by TestRunner. Failures are collected, not thrown.

var failures: PackedStringArray = []
var current_test: String = ""


## Called before every test method. Override to build fresh fixtures.
func before_each() -> void:
	pass


func assert_true(value: bool, message: String = "") -> void:
	if not value:
		_fail("expected true. " + message)


func assert_false(value: bool, message: String = "") -> void:
	if value:
		_fail("expected false. " + message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		_fail("expected %s, got %s. %s" % [var_to_str(expected), var_to_str(actual), message])


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	if typeof(actual) == typeof(unexpected) and actual == unexpected:
		_fail("did not expect %s. %s" % [var_to_str(unexpected), message])


func fail(message: String) -> void:
	_fail(message)


func _fail(message: String) -> void:
	failures.append("%s: %s" % [current_test, message])
