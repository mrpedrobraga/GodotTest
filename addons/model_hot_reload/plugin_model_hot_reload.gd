@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type(
		'ResourceReloader',
		'Node',
		preload("res://addons/model_hot_reload/ModelReloader.gd"),
		get_editor_interface().get_base_control().get_theme_icon('Reload', 'EditorIcons')
	)

func _exit_tree():
	remove_custom_type('ResourceReloader')
