extends Control

const BG := Color("#071018")
const PANEL := Color("#101d29")
const GREEN := Color("#39f5a3")
const BLUE := Color("#28baff")
const GOLD := Color("#e7bd63")

var world: Node3D
var camera: Camera3D
var object_root: Node3D
var status_label: Label
var file_dialog: FileDialog
var export_dialog: FileDialog
var project_path := ""
var orbit_angle := 0.7
var camera_distance := 6.0
var selected_object: Node3D
var viewport_3d: SubViewport
var sculpt_enabled := false
var sculpt_brush := "Clay"
var sculpt_radius := 0.42
var sculpt_strength := 0.12

func _ready() -> void:
	_build_world()
	_build_ui()
	_add_primitive("Box")
	_set_status("Ready • Import GLB / GLTF / OBJ or add a primitive")

func _build_world() -> void:
	world = Node3D.new()
	world.name = "World"
	add_child(world)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = BG
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#7894a8")
	environment.ambient_light_energy = 0.7
	env.environment = environment
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -35, 0)
	light.light_energy = 1.4
	world.add_child(light)
	object_root = Node3D.new()
	object_root.name = "Assets"
	world.add_child(object_root)
	camera = Camera3D.new()
	camera.position = Vector3(0, 2.5, camera_distance)
	camera.look_at(Vector3.ZERO)
	world.add_child(camera)
	camera.current = true

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)
	var brand := Label.new()
	brand.text = "G.I  /  3D ANIMATION STUDIO"
	brand.add_theme_color_override("font_color", GREEN)
	brand.add_theme_font_size_override("font_size", 22)
	header.add_child(brand)
	var powered := Label.new()
	powered.text = "POWERED BY အိုင်ကိုကို"
	powered.add_theme_color_override("font_color", GOLD)
	powered.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	powered.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(powered)
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 6)
	root.add_child(toolbar)
	_add_button(toolbar, "＋ Box", func(): _add_primitive("Box"))
	_add_button(toolbar, "＋ Sphere", func(): _add_primitive("Sphere"))
	_add_button(toolbar, "＋ Capsule", func(): _add_primitive("Capsule"))
	_add_button(toolbar, "Sculpt Sphere", _add_sculpt_sphere)
	_add_button(toolbar, "Import 3D", _open_import)
	_add_button(toolbar, "Export GLB", _open_export)
	_add_button(toolbar, "Save Project", _save_project)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var viewport_panel := PanelContainer.new()
	viewport_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(viewport_panel)
	var view := SubViewportContainer.new()
	view.gui_input.connect(_on_viewport_input)
	view.stretch = true
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport_panel.add_child(view)
	var sub := SubViewport.new()
	viewport_3d = sub
	sub.size = Vector2i(800, 600)
	sub.own_world_3d = true
	view.add_child(sub)
	# Move the already-created 3D world into the viewport's world.
	world.get_parent().remove_child(world)
	sub.add_child(world)
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 205
	body.add_child(side)
	var tools_title := Label.new()
	tools_title.text = "ASSET TOOLS"
	tools_title.add_theme_color_override("font_color", BLUE)
	side.add_child(tools_title)
	_add_button(side, "Focus Selected", _focus_selected)
	_add_button(side, "Rotate +15°", func(): _rotate_selected(15.0))
	_add_button(side, "Rotate -15°", func(): _rotate_selected(-15.0))
	_add_button(side, "Scale +", func(): _scale_selected(1.1))
	_add_button(side, "Scale -", func(): _scale_selected(0.9))
	_add_button(side, "Free Image → 3D", _open_ai_help)
	var sculpt_title := Label.new()
	sculpt_title.text = "SCULPT BRUSH"
	sculpt_title.add_theme_color_override("font_color", GREEN)
	side.add_child(sculpt_title)
	var brush_picker := OptionButton.new()
	for brush in ["Standard", "Clay", "Smooth", "Inflate", "Move", "Flatten", "Crease", "Mask"]:
		brush_picker.add_item(brush)
	brush_picker.select(1)
	brush_picker.item_selected.connect(func(index: int):
		sculpt_brush = brush_picker.get_item_text(index)
		_set_status("Sculpt brush: " + sculpt_brush)
	)
	side.add_child(brush_picker)
	var size_label := Label.new()
	size_label.text = "Brush Size"
	side.add_child(size_label)
	var size_slider := HSlider.new()
	size_slider.min_value = 0.12
	size_slider.max_value = 0.9
	size_slider.step = 0.02
	size_slider.value = sculpt_radius
	size_slider.value_changed.connect(func(value: float): sculpt_radius = value)
	side.add_child(size_slider)
	var strength_label := Label.new()
	strength_label.text = "Brush Strength"
	side.add_child(strength_label)
	var strength_slider := HSlider.new()
	strength_slider.min_value = 0.01
	strength_slider.max_value = 0.35
	strength_slider.step = 0.01
	strength_slider.value = sculpt_strength
	strength_slider.value_changed.connect(func(value: float): sculpt_strength = value)
	side.add_child(strength_slider)
	_add_button(side, "Enable Sculpt Touch", func():
		sculpt_enabled = not sculpt_enabled
		_set_status("Sculpt touch " + ("enabled" if sculpt_enabled else "disabled"))
	)
	var note := Label.new()
	note.text = "AI generation runs on a hosted GPU service. Import the resulting GLB/OBJ here."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", Color("#a9bac8"))
	side.add_child(note)
	status_label = Label.new()
	status_label.text = "Starting…"
	status_label.add_theme_color_override("font_color", GREEN)
	root.add_child(status_label)
	file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.add_filter("*.glb, *.gltf, *.obj", "3D Models")
	file_dialog.file_selected.connect(_import_model)
	add_child(file_dialog)
	export_dialog = FileDialog.new()
	export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	export_dialog.add_filter("*.glb", "GLB Model")
	export_dialog.file_selected.connect(_export_model)
	add_child(export_dialog)
	_apply_theme(self)

func _apply_theme(node: Control) -> void:
	node.add_theme_color_override("font_color", Color("#e5f2f8"))
	node.add_theme_font_size_override("font_size", 14)
	if node is PanelContainer:
		var style := StyleBoxFlat.new()
		style.bg_color = PANEL
		style.border_color = Color("#1d4250")
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		node.add_theme_stylebox_override("panel", style)
	for child in node.get_children():
		if child is Control:
			_apply_theme(child)

func _add_button(parent: Node, label: String, action: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size.y = 38
	button.pressed.connect(action)
	parent.add_child(button)

func _add_primitive(kind: String) -> void:
	var mesh_instance := MeshInstance3D.new()
	match kind:
		"Sphere":
			mesh_instance.mesh = SphereMesh.new()
		"Capsule":
			mesh_instance.mesh = CapsuleMesh.new()
		_:
			mesh_instance.mesh = BoxMesh.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#38dca0")
	material.metallic = 0.25
	material.roughness = 0.35
	mesh_instance.material_override = material
	var holder := Node3D.new()
	holder.name = "%s_%02d" % [kind, object_root.get_child_count() + 1]
	holder.add_child(mesh_instance)
	object_root.add_child(holder)
	selected_object = holder
	_set_status("Added " + kind)

func _open_import() -> void:
	file_dialog.popup_centered_ratio(0.85)

func _import_model(path: String) -> void:
	var extension := path.get_extension().to_lower()
	if extension == "obj":
		_set_status("OBJ import is not enabled in this first build. Convert to GLB/GLTF, then import.")
		return
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error: Error = document.append_from_file(path, state)
	if error != OK:
		_set_status("Import failed: " + error_string(error))
		return
	var imported := document.generate_scene(state)
	if imported == null:
		_set_status("Could not create a scene from this model.")
		return
	imported.name = path.get_file().get_basename()
	object_root.add_child(imported)
	selected_object = imported
	_set_status("Imported " + path.get_file())

func _open_export() -> void:
	export_dialog.current_file = "GI_KOKO_Asset.glb"
	export_dialog.popup_centered_ratio(0.8)

func _export_model(path: String) -> void:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error: Error = document.append_from_node(object_root, state)
	if error != OK:
		_set_status("Export preparation failed: " + error_string(error))
		return
	error = document.write_to_filesystem(state, path)
	_set_status("Exported GLB" if error == OK else "Export failed: " + error_string(error))

func _save_project() -> void:
	var data := {"version": 1, "objects": []}
	for child in object_root.get_children():
		data.objects.append({"name": child.name, "position": var_to_str(child.position), "rotation": var_to_str(child.rotation), "scale": var_to_str(child.scale)})
	var path := "user://gi_koko_project.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_set_status("Project save failed.")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	_set_status("Project saved on this device")

func _focus_selected() -> void:
	if selected_object:
		camera.look_at(selected_object.global_position)
		_set_status("Focused selected object")

func _rotate_selected(degrees: float) -> void:
	if selected_object:
		selected_object.rotate_y(deg_to_rad(degrees))
		_set_status("Object rotated")

func _scale_selected(factor: float) -> void:
	if selected_object:
		selected_object.scale *= factor
		_set_status("Object scaled")

func _open_ai_help() -> void:
	_set_status("Open the free TripoSR demo in your browser, generate a model, then import its GLB.")
	OS.shell_open("https://huggingface.co/spaces/stabilityai/TripoSR")

func _set_status(message: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = message


func _add_sculpt_sphere() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 32
	sphere.rings = 20
	var surface := SurfaceTool.new()
	surface.create_from(sphere, 0)
	var editable_mesh: ArrayMesh = surface.commit()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = editable_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#39dca4")
	material.metallic = 0.12
	material.roughness = 0.55
	mesh_instance.material_override = material
	var holder := Node3D.new()
	holder.name = "SculptSphere_%02d" % (object_root.get_child_count() + 1)
	holder.add_child(mesh_instance)
	var body := StaticBody3D.new()
	body.name = "SculptCollider"
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.0
	collision.shape = shape
	body.add_child(collision)
	holder.add_child(body)
	object_root.add_child(holder)
	selected_object = holder
	sculpt_enabled = true
	_set_status("Sculpt sphere ready • drag on the model to apply " + sculpt_brush)

func _on_viewport_input(event: InputEvent) -> void:
	if not sculpt_enabled or selected_object == null or viewport_3d == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var origin := camera.project_ray_origin(event.position)
		var direction := camera.project_ray_normal(event.position)
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 100.0)
		var hit := viewport_3d.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var collider := hit.collider as StaticBody3D
			if collider != null and collider.get_parent() == selected_object:
				_apply_sculpt_brush(hit.position)
				_set_status(sculpt_brush + " brush applied")

func _apply_sculpt_brush(world_hit: Vector3) -> void:
	var mesh_instance := selected_object.get_child(0) as MeshInstance3D
	if mesh_instance == null or not (mesh_instance.mesh is ArrayMesh):
		return
	var mesh := mesh_instance.mesh as ArrayMesh
	if mesh.get_surface_count() == 0:
		return
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var local_hit := mesh_instance.to_local(world_hit)
	for i in range(vertices.size()):
		var point: Vector3 = vertices[i]
		var distance := point.distance_to(local_hit)
		if distance > sculpt_radius:
			continue
		var falloff := 1.0 - (distance / sculpt_radius)
		falloff = falloff * falloff
		var radial := point.normalized()
		var amount := sculpt_strength * falloff
		match sculpt_brush:
			"Standard", "Clay", "Inflate":
				vertices[i] = point + radial * amount
			"Crease":
				vertices[i] = point - radial * amount * 0.8
			"Flatten":
				vertices[i] = point.lerp(radial * local_hit.length(), amount)
			"Move":
				vertices[i] = point + local_hit.normalized() * amount
			"Smooth":
				vertices[i] = point.lerp(radial, amount * 0.35)
			"Mask":
				pass
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	for i in range(vertices.size()):
		normals[i] = vertices[i].normalized()
	arrays[Mesh.ARRAY_NORMAL] = normals
	var rebuilt := ArrayMesh.new()
	rebuilt.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#39dca4")
	material.roughness = 0.55
	mesh_instance.mesh = rebuilt
	mesh_instance.material_override = material
