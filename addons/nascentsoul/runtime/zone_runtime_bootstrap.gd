extends RefCounted

# Internal runtime bootstrap that owns the zone store, shared context, and the
# core services wired into a Zone instance.

var store: ZoneStore = null
var context: ZoneContext = null
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
		context.store = store
		context.zone = zone
		context.update_config(config)
	if input_service == null:
		input_service = ZoneInputService.new(context)
	if render_service == null:
		render_service = ZoneRenderService.new(context)
	if transfer_service == null:
		transfer_service = ZoneTransferService.new(context)
	if targeting_service == null:
		targeting_service = ZoneTargetingService.new(context)
	context.bind_services(input_service, render_service, transfer_service, targeting_service)
	transfer_service.bind_services(input_service, render_service)

func cleanup() -> void:
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
	input_service = null
	targeting_service = null
	transfer_service = null
	render_service = null
	context = null
	store = null
