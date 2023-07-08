extends Node

## Watches over a couple of nodes to update their models whenever it changes on disk.
##
## Assign a node (if left unassigned, it will self-assign its parent) and a property
## to take care of, as well as a resource path to look for.[br]
## Whenever the resource changes on disk, it will promptly reload it, allowing faster
## iteration cycles.

## Disable if you'd like to gain performance
const PERFORM_SAFETY_CHECKS = true

signal resource_changed_on_disk
signal resource_reloaded

@export_category('Hot Reload')

## Whether this ModelReloader3D will reload by itself.
@export var auto_reload : bool = true
## The resource to watch for!
@export var resource : Resource:
	set(v):
		resource = v
		if !v:
			return
		_reload_path = resource.resource_path
## The target nodes to replace the resource in!
@export var target_nodes : Array[Node3D]
## The target property in the nodes that the Resource is stored in!
@export var target_property : StringName = &"mesh"

@export_group('Overrides')
@export_file() var reload_path_override = ""
var _reload_path:
	set(v):
		_reload_path = ProjectSettings.globalize_path(v)

var _cooling_down : bool = false
var _waiting_to_reload : bool = false

var dir_watcher

func _ready() -> void:
	# Disable hot reload functionality on Release to free memory.
	if (ProjectSettings.get_setting(&'editor_tools/hot_reload/enabled') or false) == false:
		queue_free()
		return

	if !target_nodes or target_nodes.size() < 1:
		target_nodes = [get_parent()]
	
	start_watching(
		_get_watched_path()
	)

func _test():
	reload()

func _get_watched_path():
	if reload_path_override:
		return reload_path_override
	return _reload_path

func start_watching(file : String):
	print('Watching ', file, ' for hot reload.')

	## Start watching for file updating!
	if dir_watcher:
		dir_watcher.queue_free()
	dir_watcher = DirectoryWatcher.new()
	dir_watcher.add_scan_directory(file.get_base_dir())

	add_child(dir_watcher)
	dir_watcher.files_modified.connect(_dir_watcher_any_file_modified)
	dir_watcher.files_created.connect(_dir_watcher_any_file_modified)
	dir_watcher.files_deleted.connect(_dir_watcher_any_file_modified)

func _dir_watcher_any_file_modified(files : Array):
	var watched_path = _get_watched_path()

	if !watched_path:
		push_warning('Resource can\'t be hot reloaded as its not saved on disk.')

	for file in files:
		if file == watched_path:
			print('Resource modified: ', file, '. Reloading!')
			reload()

func _dir_watcher_any_file_created(files : Array):
	var watched_path = _get_watched_path()
	for file in files:
		reload()

func _dir_watcher_any_file_deleted(files : Array):
	var watched_path = _get_watched_path()
	for file in files:
		push_error('File deleted on disk.')

## Reloads the relevant data to update the target resource.
func reload() -> void:
	## If cooling down, ask to reload when the cooldown finishes.
	if _cooling_down:
		_waiting_to_reload = true
		return

	if !target_nodes:
		push_error('No target nodes assigned for this hot reloader: {name}.'.format({
			"name": name
		}))
		return

	# Some resource types may require custom loading.
	var new_resource = _reload_and_replace(resource)

	for node in target_nodes:
		print('Reloading ' + node.to_string() + '\'s ' + target_property + '!')
		
		if PERFORM_SAFETY_CHECKS:
			var current_resource = node.get(target_property)

			if !current_resource:
				push_error('{name}.{target_property} is null or does not exist'.format({
					"name": name,
					"prop_name": target_property
				}))
				return
			
			if !current_resource is Resource:
				push_error('The current value of {prop_name} is not of type Resource.'.format({
					"name": name,
					"prop_name": target_property
				}))
				return
		
		node[target_property] = new_resource
	
	## Cool down to avoid reloading a resource too much.
	#cool_down(ProjectSettings.get_setting(&'editor_tools/hot_reload/rate_limiter_cooldown') or 1.0)
	
	resource = new_resource
	resource_reloaded.emit()
		
				
## Completely reloads a resource and swaps it on the target node only.
## It does not update the resource's data, so if another node uses this resource,
## it will not update there...[br][br]
## New `load` calls will reload the resource properly.
func _reload_and_replace(old_resource : Resource) -> Resource:
	var path = old_resource.resource_path
	if reload_path_override:
		path = reload_path_override
	var new_resource = _load(path)
	new_resource.take_over_path(old_resource.resource_path)
	_reload_path = new_resource.resource_path
	print('new path:', _reload_path)
	return new_resource

## Loads a resource from disk, with specific requirements.
func _load(path : String) -> Resource:
	return ResourceLoader.load(path, "", 0)

## Avoid reloading resources for an amount of time.
func cool_down(amount : float):
	_cooling_down = true
	print('Cooling down.')
	await get_tree().create_timer(amount).timeout
	_cooling_down = false
	print('Cool down finished.')

	## If reload was called at any point while cooling down,
	## reload.
	if _waiting_to_reload:
		_waiting_to_reload = false
		reload()
