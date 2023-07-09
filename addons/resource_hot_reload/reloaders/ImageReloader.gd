extends ResourceReloader
class_name ImageReloader

func _reload_and_replace(old_resource: Resource):
	var img_texture : ImageTexture = old_resource as ImageTexture
	var new_image = Image.load_from_file(reload_path_override)
	img_texture.resource_path = reload_path_override
	img_texture.set_image(new_image)
	return img_texture
