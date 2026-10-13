extends Node

signal upnp_finished(success: bool)

const PORT := 9999
const LEASE_SECONDS := 3600

var upnp: UPNP
var thread: Thread
var valid_connection := false
var external_ip := ""

func setup_upnp() -> void:
	thread = Thread.new()
	thread.start(_upnp_setup)

func _upnp_setup() -> void:
	upnp = UPNP.new()
	var result := upnp.discover(2000, 2, "InternetGatewayDevice")
	if result != UPNP.UPNP_RESULT_SUCCESS:
		push_warning("UPNP discovery failed: %d" % result)
		call_deferred("_finish", false)
		return

	var gw := upnp.get_gateway()
	if gw == null or not gw.is_valid_gateway():
		push_warning("No valid UPNP gateway")
		call_deferred("_finish", false)
		return

	# ENet uses UDP; only add TCP if you actually use it
	var map_udp := upnp.add_port_mapping(PORT, PORT, "godot_udp", "UDP", LEASE_SECONDS)
	if map_udp != UPNP.UPNP_RESULT_SUCCESS:
		push_warning("UDP mapping failed: %d" % map_udp)
		call_deferred("_finish", false)
		return

	external_ip = upnp.query_external_address()
	call_deferred("_finish", true)

func _finish(success: bool) -> void:
	thread.wait_to_finish()
	valid_connection = success
	upnp_finished.emit(success)

func _exit_tree() -> void:
	if thread and thread.is_started():
		thread.wait_to_finish()
	if valid_connection and upnp:
		var r := upnp.delete_port_mapping(PORT, "UDP")
		if r != UPNP.UPNP_RESULT_SUCCESS:
			push_warning("Failed to remove UDP mapping: %d" % r)
	valid_connection = false
