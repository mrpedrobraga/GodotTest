@tool
extends EditorPlugin

const new_project_settings = {
	&'editor_tools/hot_reload/enabled': true,
	&'editor_tools/hot_reload/rate_limiter_cooldown': 1.0
}

func _enter_tree():
	add_custom_type(
		'ResourceReloader',
		'Node',
		preload("res://addons/resource_hot_reload/ResourceReloader.gd"),
		get_editor_interface().get_base_control().get_theme_icon('Reload', 'EditorIcons')
	)
	
	# Set default value for project settings.
	var any_changed = false
	for key in new_project_settings.keys():
		if !ProjectSettings.has_setting(key):
			any_changed = true
			ProjectSettings.set_setting(key, new_project_settings[key])
			print('Creating setting: ', key)
	if any_changed:
		ProjectSettings.save()

func _exit_tree():
	remove_custom_type('ResourceReloader')
