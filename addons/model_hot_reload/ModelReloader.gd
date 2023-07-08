extends Node
class_name ModelReloader3D

## Watches over a couple of nodes to update their models whenever it changes on disk.
##
## Assign a node (if left unassigned, it will self-assign its parent) and a property
## to take care of, as well as a resource path to look for.[br]
## Whenever the resource changes on disk, it will promptly reload it, allowing faster
## iteration cycles.

@export_category('Hot Reload')

## Whether this ModelReloader3D will reload by itself.
@export var auto_reload : bool = true
## The target nodes to watch out for!
@export var target_nodes : Array[Node3D]
## The target property to swap.
@export var target_property : StringName = &"mesh"

signal resource_changed_on_disk
signal resource_reloaded

func _ready() -> void:
	if !target_nodes or target_nodes.size() < 1:
		target_nodes = [get_parent()]
	
	_test()

func _test():
	reload()

## Reloads the relevant data to update the target resource.
func reload() -> void:
	if !target_nodes:
		push_error('No target nodes assigned for this hot reloader: {name}.'.format({
			"name": name
		}))
		return

	for node in target_nodes:
		print('Reloading: ' + node.name)
		var current_resource = node.get(target_property)

		if !current_resource:
			push_error('{name}.{target_property} is null or does not exist'.format({
				"name": name,
				"prop_name": target_property
			}))
			return
		print(current_resource)
		if !current_resource is Resource:
			push_error('The current value of {prop_name} is not of type Resource.'.format({
				"name": name,
				"prop_name": target_property
			}))
			return
		
		_replace_with_new_resource(node, target_property, current_resource)
		
				
## Completely reloads a resource and swaps it on the target node only.
## It does not update the resource's data, so if another node uses this resource,
## it will not update there...[br][br]
## New `load` calls will reload the resource properly.
func _replace_with_new_resource(node : Node3D, property : StringName, old_resource : Resource) -> void:
	var path = old_resource.resource_path
	# TODO: Remove this test.
	path = 'res://my_box2.tres'
	var new_resource = _load(path)
	new_resource.take_over_path(old_resource.resource_path)
	node.set(property, new_resource)

## Loads a resource from disk, with specific requirements.
func _load(path : String) -> Resource:
	return load(path)
