extends RefCounted

# Internal assembly root that owns the zone runtime state and service graph.

const ZoneRuntimePortScript = preload("res://addons/nascentsoul/runtime/zone_runtime_port.gd")
const ZoneRuntimeHooksScript = preload("res://addons/nascentsoul/runtime/zone_runtime_hooks.gd")

var store: ZoneStore = null
var context: ZoneContext = null
var runtime_port = null
var runtime_hooks = null
var input_service: ZoneInputService = null
var render_service: ZoneRenderService = null
var transfer_service: ZoneTransferService = null
var targeting_service: ZoneTargetingService = null

func ensure(zone, config: ZoneConfig) -> void:
	if store == null:
		store = ZoneStore.new()
	if context == null:
		context = ZoneContext.new(zone, store, config)
	else:
		context.attach(zone, store, config)
	if runtime_port == null:
		runtime_port = ZoneRuntimePortScript.new(zone, self)
	else:
		runtime_port.attach(zone, self)
	if input_service == null:
		input_service = ZoneInputService.new(context, runtime_port)
	if render_service == null:
		render_service = ZoneRenderService.new(context, runtime_port)
	if transfer_service == null:
		transfer_service = ZoneTransferService.new(context, runtime_port)
	if targeting_service == null:
		targeting_service = ZoneTargetingService.new(context, runtime_port)
	if runtime_hooks == null:
		runtime_hooks = ZoneRuntimeHooksScript.new(zone, self, runtime_port)
	else:
		runtime_hooks.attach(zone, self, runtime_port)
	input_service.bind_runtime_services(transfer_service, targeting_service)
	transfer_service.bind_services(input_service, render_service)

func cleanup() -> void:
	if runtime_hooks != null:
		runtime_hooks.cleanup()
	if input_service != null:
		input_service.cleanup()
	if targeting_service != null:
		targeting_service.cleanup()
	if transfer_service != null:
		transfer_service.cleanup()
	if render_service != null:
		render_service.cleanup()
	if context != null:
		context.cleanup()
	if store != null:
		store.cleanup()
	if runtime_port != null:
		runtime_port.cleanup()
	input_service = null
	targeting_service = null
	transfer_service = null
	render_service = null
	runtime_hooks = null
	runtime_port = null
	context = null
	store = null
