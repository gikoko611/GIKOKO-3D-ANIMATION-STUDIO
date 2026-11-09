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
var animation_player: AnimationPlayer
var timeline_slider: HSlider
var timeline_time := 0.0
var camera_markers: Array[Dictionary] = []
var subtitle_cues: Array[Dictionary] = []
var subtitle_dialog: AcceptDialog
var subtitle_input: LineEdit
var srt_dialog: FileDialog
var audio_dialog: FileDialog
var audio_player: AudioStreamPlayer
var subtitle_preview: Label
var film_playing := false
var film_clock := 0.0
var audio_file_path := ""
var sculpt_enabled := false
var sculpt_brush := "Clay"
var sculpt_radius := 0.42
var sculpt_strength := 0.12
var sculpt_undo_stack: Array[ArrayMesh] = []
var sculpt_redo_stack: Array[ArrayMesh] = []
var rig_root: Node3D
var rig_joints: Dictionary = {}
var rig_sliders: Dictionary = {}
var side_rig_container: VBoxContainer
const SCULPT_HISTORY_LIMIT := 20

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
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "FilmAudioPlayer"
	world.add_child(audio_player)
	animation_player = AnimationPlayer.new()
	animation_player.name = "StudioAnimationPlayer"
	animation_player.root_node = NodePath("..")
	world.add_child(animation_player)
	var animation_library := AnimationLibrary.new()
	animation_library.add_animation("Take 001", Animation.new())
	animation_player.add_animation_library("", animation_library)

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
	var toolbar_scroll := ScrollContainer.new()
	toolbar_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	toolbar_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	toolbar_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar_scroll.custom_minimum_size.y = 48
	root.add_child(toolbar_scroll)
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 6)
	toolbar_scroll.add_child(toolbar)
	_add_button(toolbar, "＋ Box", func(): _add_primitive("Box"))
	_add_button(toolbar, "＋ Sphere", func(): _add_primitive("Sphere"))
	_add_button(toolbar, "＋ Capsule", func(): _add_primitive("Capsule"))
	_add_button(toolbar, "Sculpt Sphere", _add_sculpt_sphere)
	_add_button(toolbar, "Import 3D", _open_import)
	_add_button(toolbar, "Export GLB", _open_export)
	_add_button(toolbar, "Save Project", _save_project)
	_add_button(toolbar, "Load Project", _load_project)
	var is_mobile := get_viewport_rect().size.x < 700.0
	var body: BoxContainer = VBoxContainer.new() if is_mobile else HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var viewport_panel := PanelContainer.new()
	viewport_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if is_mobile:
		viewport_panel.custom_minimum_size.y = 280
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
	var side_scroll := ScrollContainer.new()
	side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	side_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if is_mobile:
		side_scroll.custom_minimum_size.y = 300
	else:
		side_scroll.custom_minimum_size.x = 205
	body.add_child(side_scroll)
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 5)
	side_scroll.add_child(side)
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
	_add_button(side, "Undo Sculpt", _undo_sculpt)
	_add_button(side, "Redo Sculpt", _redo_sculpt)
	var animation_title := Label.new()
	animation_title.text = "ANIMATION TIMELINE"
	animation_title.add_theme_color_override("font_color", BLUE)
	side.add_child(animation_title)
	var time_label := Label.new()
	time_label.text = "Time: 0.00s"
	side.add_child(time_label)
	timeline_slider = HSlider.new()
	timeline_slider.min_value = 0.0
	timeline_slider.max_value = 5.0
	timeline_slider.step = 0.1
	timeline_slider.value = 0.0
	timeline_slider.value_changed.connect(func(value: float):
		timeline_time = value
		time_label.text = "Time: %.2fs" % value
		if animation_player != null and animation_player.is_playing():
			animation_player.pause()
			animation_player.seek(value, true)
	)
	side.add_child(timeline_slider)
	_add_button(side, "＋ Set Transform Key", _add_transform_key)
	_add_button(side, "＋ Set Rig Pose Key", _add_rig_pose_key)
	_add_button(side, "◀ Previous Rig Key", _previous_rig_key)
	_add_button(side, "Next Rig Key ▶", _next_rig_key)
	_add_button(side, "Delete Rig Key At Time", _delete_rig_key_at_time)
	_add_button(side, "▶ Play Animation", _play_animation)
	_add_button(side, "■ Stop Animation", _stop_animation)
	var rig_title := Label.new()
	rig_title.text = "QUICK CHARACTER RIG"
	rig_title.add_theme_color_override("font_color", GREEN)
	side.add_child(rig_title)
	_add_button(side, "＋ Create Rig Mannequin", _create_rig_mannequin)
	_add_button(side, "Reset Rig Pose", _reset_rig_pose)
	_add_button(side, "Pose: Walk", _pose_walk)
	_add_button(side, "Pose: Arms Up", _pose_arms_up)
	var rig_hint := Label.new()
	rig_hint.text = "Select a joint slider to pose the mannequin. Use Set Transform Key on the rig root for basic motion."
	rig_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rig_hint.add_theme_color_override("font_color", Color("#a9bac8"))
	side.add_child(rig_hint)
	side_rig_container = VBoxContainer.new()
	side_rig_container.add_theme_constant_override("separation", 2)
	side.add_child(side_rig_container)
	var film_title := Label.new()
	film_title.text = "FILM MAKER"
	film_title.add_theme_color_override("font_color", GOLD)
	side.add_child(film_title)
	_add_button(side, "＋ Camera Marker", _add_camera_marker)
	_add_button(side, "▶ Play Film Preview", _play_film_preview)
	_add_button(side, "■ Stop Film Preview", _stop_film_preview)
	_add_button(side, "＋ Import Audio", _open_audio_import)
	_add_button(side, "▶ Play Audio", _play_audio)
	_add_button(side, "■ Stop Audio", _stop_audio)
	_add_button(side, "＋ Subtitle Cue", _open_subtitle_dialog)
	_add_button(side, "Export Subtitles (SRT)", _open_srt_export)
	subtitle_preview = Label.new()
	subtitle_preview.text = "Subtitle preview"
	subtitle_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_preview.add_theme_color_override("font_color", GOLD)
	side.add_child(subtitle_preview)
	_add_button(side, "Duplicate Object", _duplicate_selected)
	_add_button(side, "Delete Object", _delete_selected)
	_add_button(side, "Reset Transform", _reset_selected)
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
	subtitle_dialog = AcceptDialog.new()
	subtitle_dialog.title = "Add Subtitle Cue"
	subtitle_dialog.dialog_text = "Subtitle text (time uses the current timeline position):"
	subtitle_input = LineEdit.new()
	subtitle_input.placeholder_text = "Enter dialogue / subtitle..."
	subtitle_input.custom_minimum_size.x = 320
	subtitle_dialog.add_child(subtitle_input)
	subtitle_dialog.confirmed.connect(_add_subtitle_cue)
	add_child(subtitle_dialog)
	srt_dialog = FileDialog.new()
	srt_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	srt_dialog.access = FileDialog.ACCESS_FILESYSTEM
	srt_dialog.add_filter("*.srt", "SubRip subtitles")
	srt_dialog.current_file = "GI_KO_KO_Subtitles.srt"
	srt_dialog.file_selected.connect(_export_srt)
	add_child(srt_dialog)
	audio_dialog = FileDialog.new()
	audio_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	audio_dialog.access = FileDialog.ACCESS_FILESYSTEM
	audio_dialog.add_filter("*.wav, *.mp3", "WAV / MP3 audio files")
	audio_dialog.file_selected.connect(_import_audio)
	add_child(audio_dialog)
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
	var data := {"version": 3, "objects": [], "camera_markers": camera_markers, "subtitles": subtitle_cues}
	for child in object_root.get_children():
		var mesh_kind := "Imported"
		var saved_rig_pose := {}
		if is_instance_valid(rig_root) and child == rig_root:
			mesh_kind = "QuickRig"
			for joint_name in rig_joints.keys():
				var joint := rig_joints[joint_name] as Node3D
				saved_rig_pose[joint_name] = [joint.rotation_degrees.x, joint.rotation_degrees.y, joint.rotation_degrees.z]
		elif child.name.begins_with("SculptSphere"):
			mesh_kind = "SculptSphere"
		elif child.get_child_count() > 0 and child.get_child(0) is MeshInstance3D:
			var mesh := (child.get_child(0) as MeshInstance3D).mesh
			if mesh is BoxMesh:
				mesh_kind = "Box"
			elif mesh is SphereMesh:
				mesh_kind = "Sphere"
			elif mesh is CapsuleMesh:
				mesh_kind = "Capsule"
		data.objects.append({
			"name": child.name,
			"type": mesh_kind,
			"position": [child.position.x, child.position.y, child.position.z],
			"rotation": [child.rotation.x, child.rotation.y, child.rotation.z],
			"scale": [child.scale.x, child.scale.y, child.scale.z],
			"rig_pose": saved_rig_pose
		})
	var path := "user://gi_koko_project.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_set_status("Project save failed: " + error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	_set_status("Project saved on this device • " + str(data.objects.size()) + " objects")

func _load_project() -> void:
	var path := "user://gi_koko_project.json"
	if not FileAccess.file_exists(path):
		_set_status("No saved project found on this device.")
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_set_status("Project load failed: " + error_string(FileAccess.get_open_error()))
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("objects") or typeof(parsed.objects) != TYPE_ARRAY:
		_set_status("Saved project file is invalid.")
		return
	for child in object_root.get_children():
		object_root.remove_child(child)
		child.free()
	selected_object = null
	camera_markers.clear()
	subtitle_cues.clear()
	for marker in parsed.get("camera_markers", []):
		if typeof(marker) == TYPE_DICTIONARY:
			camera_markers.append(marker)
	for cue in parsed.get("subtitles", []):
		if typeof(cue) == TYPE_DICTIONARY:
			subtitle_cues.append(cue)
	sculpt_undo_stack.clear()
	sculpt_redo_stack.clear()
	for item in parsed.objects:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var kind := str(item.get("type", "Box"))
		if kind == "Imported":
			continue
		if kind == "QuickRig":
			_create_rig_mannequin()
		elif kind == "SculptSphere":
			_add_sculpt_sphere()
		else:
			_add_primitive(kind)
		var node := object_root.get_child(object_root.get_child_count() - 1) as Node3D
		node.name = str(item.get("name", kind))
		var p: Array = item.get("position", [0.0, 0.0, 0.0])
		var r: Array = item.get("rotation", [0.0, 0.0, 0.0])
		var s: Array = item.get("scale", [1.0, 1.0, 1.0])
		if p.size() == 3:
			node.position = Vector3(float(p[0]), float(p[1]), float(p[2]))
		if r.size() == 3:
			node.rotation = Vector3(float(r[0]), float(r[1]), float(r[2]))
		if s.size() == 3:
			node.scale = Vector3(float(s[0]), float(s[1]), float(s[2]))
		if kind == "QuickRig":
			var saved_pose: Variant = item.get("rig_pose", {})
			if typeof(saved_pose) == TYPE_DICTIONARY:
				for joint_name in saved_pose.keys():
					var angles: Variant = saved_pose[joint_name]
					if typeof(angles) == TYPE_ARRAY and angles.size() == 3 and rig_joints.has(str(joint_name)):
						var joint := rig_joints[str(joint_name)] as Node3D
						joint.rotation_degrees = Vector3(float(angles[0]), float(angles[1]), float(angles[2]))
						if rig_sliders.has(str(joint_name)):
							var row := rig_sliders[str(joint_name)] as VBoxContainer
							(row.get_child(1) as HSlider).set_value_no_signal(float(angles[2]))
		selected_object = node
	_set_status("Project loaded • " + str(object_root.get_child_count()) + " objects")

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

func _add_transform_key() -> void:
	if selected_object == null or animation_player == null:
		_set_status("Select an object before setting a keyframe.")
		return
	var library := animation_player.get_animation_library("")
	if library == null:
		return
	var animation := library.get_animation("Take 001")
	if animation == null:
		return
	var target_path := NodePath("Assets/" + str(selected_object.name))
	var properties := ["position", "rotation", "scale"]
	for property in properties:
		var track_path := NodePath(str(target_path) + ":" + property)
		var track_index := -1
		for index in range(animation.get_track_count()):
			if animation.track_get_path(index) == track_path:
				track_index = index
				break
		if track_index == -1:
			track_index = animation.add_track(Animation.TYPE_VALUE)
			animation.track_set_path(track_index, track_path)
			animation.value_track_set_update_mode(track_index, Animation.UPDATE_CONTINUOUS)
		var value: Variant = selected_object.get(property)
		var key_index := animation.track_find_key(track_index, timeline_time, true)
		if key_index >= 0:
			animation.track_remove_key(track_index, key_index)
		animation.track_insert_key(track_index, timeline_time, value)
	animation.length = maxf(animation.length, timeline_time + 0.1)
	_set_status("Transform keyframe set at %.2fs" % timeline_time)

func _create_rig_mannequin() -> void:
	if is_instance_valid(rig_root):
		object_root.remove_child(rig_root)
		rig_root.queue_free()
	rig_joints.clear()
	rig_sliders.clear()
	rig_root = Node3D.new()
	rig_root.name = "GI_KOKO_QuickRig"
	object_root.add_child(rig_root)
	var hips := _rig_joint("Hips", rig_root, Vector3(0, 0.95, 0))
	var torso := _rig_joint("Spine", hips, Vector3(0, 0.28, 0))
	_rig_capsule(torso, "TorsoMesh", 0.32, 0.68, Vector3(0, 0.08, 0))
	var chest := _rig_joint("Chest", torso, Vector3(0, 0.35, 0))
	_rig_capsule(chest, "ChestMesh", 0.29, 0.42, Vector3(0, 0.0, 0))
	var neck := _rig_joint("Neck", chest, Vector3(0, 0.28, 0))
	_rig_capsule(neck, "NeckMesh", 0.10, 0.18, Vector3(0, 0.06, 0))
	var head := _rig_joint("Head", neck, Vector3(0, 0.18, 0))
	var head_mesh := MeshInstance3D.new()
	var head_sphere := SphereMesh.new()
	head_sphere.radius = 0.19
	head_sphere.height = 0.38
	head_mesh.mesh = head_sphere
	head_mesh.position.y = 0.12
	head_mesh.material_override = _rig_material(Color("#e7bd63"))
	head.add_child(head_mesh)
	for side in [-1, 1]:
		var suffix := "L" if side < 0 else "R"
		var shoulder := _rig_joint("Shoulder_" + suffix, chest, Vector3(0.34 * side, 0.15, 0))
		_rig_capsule(shoulder, "UpperArm_" + suffix, 0.105, 0.48, Vector3(0, -0.22, 0))
		var elbow := _rig_joint("Elbow_" + suffix, shoulder, Vector3(0, -0.44, 0))
		_rig_capsule(elbow, "Forearm_" + suffix, 0.085, 0.40, Vector3(0, -0.19, 0))
		var hand := _rig_joint("Hand_" + suffix, elbow, Vector3(0, -0.38, 0))
		_rig_capsule(hand, "HandMesh_" + suffix, 0.07, 0.16, Vector3(0, -0.06, 0))
		var hip := _rig_joint("Hip_" + suffix, hips, Vector3(0.14 * side, -0.02, 0))
		_rig_capsule(hip, "Thigh_" + suffix, 0.13, 0.52, Vector3(0, -0.25, 0))
		var knee := _rig_joint("Knee_" + suffix, hip, Vector3(0, -0.49, 0))
		_rig_capsule(knee, "Shin_" + suffix, 0.095, 0.48, Vector3(0, -0.23, 0))
		var foot := _rig_joint("Foot_" + suffix, knee, Vector3(0, -0.44, 0.06))
		_rig_capsule(foot, "FootMesh_" + suffix, 0.08, 0.22, Vector3(0, -0.02, 0.10))
	selected_object = rig_root
	_build_rig_controls()
	_set_status("Quick Rig created • 15 articulated joints • select a slider to pose")
	_focus_selected()

func _rig_joint(joint_name: String, parent: Node3D, offset: Vector3) -> Node3D:
	var joint := Node3D.new()
	joint.name = joint_name
	joint.position = offset
	parent.add_child(joint)
	rig_joints[joint_name] = joint
	return joint

func _rig_capsule(parent: Node3D, mesh_name: String, radius: float, height: float, offset: Vector3) -> void:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = height
	capsule.radial_segments = 8
	capsule.rings = 4
	instance.mesh = capsule
	instance.position = offset
	instance.material_override = _rig_material(Color("#28baff") if mesh_name.contains("Arm") or mesh_name.contains("Forearm") else Color("#39dca3"))
	parent.add_child(instance)

func _rig_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.12
	material.roughness = 0.48
	return material

func _build_rig_controls() -> void:
	for child in rig_sliders.values():
		if is_instance_valid(child):
			child.queue_free()
	rig_sliders.clear()
	for joint_name in ["Spine", "Chest", "Head", "Shoulder_L", "Elbow_L", "Shoulder_R", "Elbow_R", "Hip_L", "Knee_L", "Hip_R", "Knee_R"]:
		if not rig_joints.has(joint_name):
			continue
		var row := VBoxContainer.new()
		var label := Label.new()
		label.text = joint_name.replace("_", " ")
		row.add_child(label)
		var slider := HSlider.new()
		slider.min_value = -180.0
		slider.max_value = 180.0
		slider.step = 1.0
		slider.custom_minimum_size.x = 170
		slider.value_changed.connect(_on_rig_joint_slider.bind(joint_name))
		row.add_child(slider)
		side_rig_container.add_child(row)
		rig_sliders[joint_name] = row

func _on_rig_joint_slider(value: float, joint_name: String) -> void:
	if rig_joints.has(joint_name):
		(rig_joints[joint_name] as Node3D).rotation_degrees.z = value

func _set_rig_joint_rotation(joint_name: String, degrees: float) -> void:
	if not rig_joints.has(joint_name):
		return
	(rig_joints[joint_name] as Node3D).rotation_degrees.z = degrees
	if rig_sliders.has(joint_name):
		var row := rig_sliders[joint_name] as VBoxContainer
		var slider := row.get_child(1) as HSlider
		slider.set_value_no_signal(degrees)

func _reset_rig_pose() -> void:
	if not is_instance_valid(rig_root):
		_set_status("Create the Quick Rig first.")
		return
	for joint in rig_joints.values():
		(joint as Node3D).rotation = Vector3.ZERO
	for row in rig_sliders.values():
		var slider := row.get_child(1) as HSlider
		slider.set_value_no_signal(0.0)
	_set_status("Rig pose reset")

func _pose_walk() -> void:
	if not is_instance_valid(rig_root):
		_set_status("Create the Quick Rig first.")
		return
	_reset_rig_pose()
	_set_rig_joint_rotation("Hip_L", -28.0)
	_set_rig_joint_rotation("Knee_L", 32.0)
	_set_rig_joint_rotation("Hip_R", 28.0)
	_set_rig_joint_rotation("Shoulder_L", 22.0)
	_set_rig_joint_rotation("Shoulder_R", -22.0)
	_set_status("Walk pose applied")

func _pose_arms_up() -> void:
	if not is_instance_valid(rig_root):
		_set_status("Create the Quick Rig first.")
		return
	_reset_rig_pose()
	_set_rig_joint_rotation("Shoulder_L", 150.0)
	_set_rig_joint_rotation("Shoulder_R", -150.0)
	_set_status("Arms-up pose applied")

func _add_rig_pose_key() -> void:
	if not is_instance_valid(rig_root) or rig_joints.is_empty():
		_set_status("Create a Quick Rig and pose its joints first.")
		return
	var library := animation_player.get_animation_library("")
	if library == null:
		_set_status("Animation library is unavailable.")
		return
	var animation := library.get_animation("Take 001")
	if animation == null:
		_set_status("Take 001 animation is unavailable.")
		return
	var keyed_count := 0
	for joint_name in rig_joints.keys():
		var joint := rig_joints[joint_name] as Node3D
		var track_path := NodePath("Assets/" + str(rig_root.name) + "/" + str(joint_name) + ":rotation")
		var track_index := -1
		for index in range(animation.get_track_count()):
			if animation.track_get_path(index) == track_path:
				track_index = index
				break
		if track_index == -1:
			track_index = animation.add_track(Animation.TYPE_VALUE)
			animation.track_set_path(track_index, track_path)
			animation.value_track_set_update_mode(track_index, Animation.UPDATE_CONTINUOUS)
		var key_index := animation.track_find_key(track_index, timeline_time, true)
		if key_index >= 0:
			animation.track_remove_key(track_index, key_index)
		animation.track_insert_key(track_index, timeline_time, joint.rotation)
		keyed_count += 1
	animation.length = maxf(animation.length, timeline_time + 0.1)
	if timeline_slider != null:
		timeline_slider.max_value = maxf(5.0, animation.length)
	_set_status("Rig pose key saved • %d joints at %.2fs" % [keyed_count, timeline_time])

func _get_rig_key_times() -> Array[float]:
	var times: Array[float] = []
	if animation_player == null:
		return times
	var library := animation_player.get_animation_library("")
	if library == null:
		return times
	var animation := library.get_animation("Take 001")
	if animation == null or not is_instance_valid(rig_root):
		return times
	var prefix := NodePath("Assets/" + str(rig_root.name) + "/")
	for track_index in range(animation.get_track_count()):
		var path := animation.track_get_path(track_index)
		if not str(path).begins_with(str(prefix)):
			continue
		for key_index in range(animation.track_get_key_count(track_index)):
			var key_time := animation.track_get_key_time(track_index, key_index)
			var exists := false
			for saved_time in times:
				if absf(saved_time - key_time) < 0.001:
					exists = true
					break
			if not exists:
				times.append(key_time)
	times.sort()
	return times

func _set_timeline_position(value: float) -> void:
	timeline_time = maxf(0.0, value)
	if timeline_slider != null:
		timeline_slider.set_value_no_signal(timeline_time)
	if animation_player != null:
		animation_player.pause()
		animation_player.seek(timeline_time, true)

func _previous_rig_key() -> void:
	var times := _get_rig_key_times()
	for index in range(times.size() - 1, -1, -1):
		if times[index] < timeline_time - 0.001:
			_set_timeline_position(times[index])
			_set_status("Moved to previous rig key • %.2fs" % timeline_time)
			return
	if not times.is_empty():
		_set_timeline_position(times[0])
		_set_status("Moved to first rig key • %.2fs" % timeline_time)
	else:
		_set_status("No rig pose keys yet.")

func _next_rig_key() -> void:
	for key_time in _get_rig_key_times():
		if key_time > timeline_time + 0.001:
			_set_timeline_position(key_time)
			_set_status("Moved to next rig key • %.2fs" % timeline_time)
			return
	_set_status("No later rig pose key found.")

func _delete_rig_key_at_time() -> void:
	if animation_player == null or not is_instance_valid(rig_root):
		_set_status("Create a Quick Rig first.")
		return
	var library := animation_player.get_animation_library("")
	if library == null:
		return
	var animation := library.get_animation("Take 001")
	if animation == null:
		return
	var prefix := "Assets/" + str(rig_root.name) + "/"
	var removed := 0
	for track_index in range(animation.get_track_count()):
		if not str(animation.track_get_path(track_index)).begins_with(prefix):
			continue
		for key_index in range(animation.track_get_key_count(track_index) - 1, -1, -1):
			if absf(animation.track_get_key_time(track_index, key_index) - timeline_time) <= 0.06:
				animation.track_remove_key(track_index, key_index)
				removed += 1
	_set_status("Deleted %d rig joint keys near %.2fs" % [removed, timeline_time])

func _play_animation() -> void:
	if animation_player == null:
		return
	animation_player.stop()
	animation_player.play("Take 001")
	_set_status("Playing Take 001")

func _stop_animation() -> void:
	if animation_player == null:
		return
	animation_player.stop()
	_set_status("Animation stopped")



func _process(delta: float) -> void:
	if not film_playing:
		return
	film_clock += delta
	timeline_time = film_clock
	if timeline_slider != null:
		timeline_slider.set_value_no_signal(timeline_time)
	_update_film_camera()
	_update_subtitle_preview()
	var duration := _film_duration()
	if duration > 0.0 and film_clock >= duration:
		_stop_film_preview()

func _film_duration() -> float:
	var duration := 0.0
	for marker in camera_markers:
		duration = maxf(duration, float(marker.get("time", 0.0)))
	for cue in subtitle_cues:
		duration = maxf(duration, float(cue.get("time", 0.0)) + float(cue.get("duration", 3.0)))
	if animation_player != null:
		var library := animation_player.get_animation_library("")
		if library != null:
			var anim := library.get_animation("Take 001")
			if anim != null:
				duration = maxf(duration, anim.length)
	if duration > 0.0:
		duration = maxf(duration, 1.0)
	return duration

func _play_film_preview() -> void:
	var has_animation := false
	if animation_player != null:
		var library := animation_player.get_animation_library("")
		if library != null:
			var take := library.get_animation("Take 001")
			has_animation = take != null and take.get_track_count() > 0
	if camera_markers.is_empty() and subtitle_cues.is_empty() and not has_animation:
		_set_status("Add camera markers, subtitle cues or transform keys first.")
		return
	film_clock = 0.0
	film_playing = true
	if has_animation:
		animation_player.play("Take 001")
	_set_status("Film preview playing")

func _stop_film_preview() -> void:
	film_playing = false
	if animation_player != null:
		animation_player.stop()
	if audio_player != null and audio_player.playing:
		audio_player.stop()
	_set_status("Film preview stopped")

func _update_film_camera() -> void:
	if camera_markers.is_empty():
		return
	var markers := camera_markers.duplicate(true)
	markers.sort_custom(func(a: Dictionary, b: Dictionary): return float(a.get("time", 0.0)) < float(b.get("time", 0.0)))
	var before: Dictionary = markers[0]
	var after: Dictionary = markers[markers.size() - 1]
	for marker in markers:
		if float(marker.get("time", 0.0)) <= film_clock:
			before = marker
		if float(marker.get("time", 0.0)) >= film_clock:
			after = marker
			break
	var start_time := float(before.get("time", 0.0))
	var end_time := float(after.get("time", start_time))
	var weight := 0.0
	if end_time > start_time:
		weight = clampf((film_clock - start_time) / (end_time - start_time), 0.0, 1.0)
	var p1: Array = before.get("position", [0.0, 2.5, camera_distance])
	var p2: Array = after.get("position", p1)
	var r1: Array = before.get("rotation", [0.0, 0.0, 0.0])
	var r2: Array = after.get("rotation", r1)
	camera.position = Vector3(float(p1[0]), float(p1[1]), float(p1[2])).lerp(Vector3(float(p2[0]), float(p2[1]), float(p2[2])), weight)
	camera.rotation = Vector3(float(r1[0]), float(r1[1]), float(r1[2])).lerp(Vector3(float(r2[0]), float(r2[1]), float(r2[2])), weight)

func _update_subtitle_preview() -> void:
	if subtitle_preview == null:
		return
	var active_text := ""
	for cue in subtitle_cues:
		var start := float(cue.get("time", 0.0))
		var finish := start + float(cue.get("duration", 3.0))
		if film_clock >= start and film_clock <= finish:
			active_text = str(cue.get("text", ""))
			break
	subtitle_preview.text = active_text

func _open_audio_import() -> void:
	audio_dialog.popup_centered_ratio(0.8)

func _import_audio(path: String) -> void:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		_set_status("Audio file is empty or could not be read.")
		return
	var extension := path.get_extension().to_lower()
	var stream: AudioStream
	match extension:
		"wav":
			var wav := AudioStreamWAV.new()
			wav.data = bytes
			stream = wav
		"mp3":
			var mp3 := AudioStreamMP3.new()
			mp3.data = bytes
			stream = mp3
		_:
			_set_status("Unsupported audio format.")
			return
	audio_player.stream = stream
	audio_file_path = path
	_set_status("Audio loaded: " + path.get_file())

func _play_audio() -> void:
	if audio_player == null or audio_player.stream == null:
		_set_status("Import a WAV or MP3 audio file first.")
		return
	audio_player.play()
	_set_status("Audio playback started")

func _stop_audio() -> void:
	if audio_player != null:
		audio_player.stop()
		_set_status("Audio playback stopped")


func _duplicate_selected() -> void:
	if selected_object == null:
		_set_status("Select or create an object first.")
		return
	var copy := selected_object.duplicate() as Node3D
	if copy == null:
		return
	copy.name = selected_object.name + "_Copy"
	copy.position += Vector3(0.35, 0.0, 0.35)
	object_root.add_child(copy)
	selected_object = copy
	_set_status("Object duplicated")

func _delete_selected() -> void:
	if selected_object == null:
		_set_status("No selected object to delete.")
		return
	var doomed := selected_object
	selected_object = null
	object_root.remove_child(doomed)
	doomed.queue_free()
	_set_status("Object deleted")

func _reset_selected() -> void:
	if selected_object == null:
		_set_status("No selected object.")
		return
	selected_object.position = Vector3.ZERO
	selected_object.rotation = Vector3.ZERO
	selected_object.scale = Vector3.ONE
	_set_status("Transform reset")

func _add_camera_marker() -> void:
	camera_markers.append({
		"time": timeline_time,
		"position": [camera.position.x, camera.position.y, camera.position.z],
		"rotation": [camera.rotation.x, camera.rotation.y, camera.rotation.z]
	})
	_set_status("Camera marker saved at %.2fs • %d markers" % [timeline_time, camera_markers.size()])

func _open_subtitle_dialog() -> void:
	subtitle_input.text = ""
	subtitle_dialog.popup_centered()

func _add_subtitle_cue() -> void:
	var line := subtitle_input.text.strip_edges()
	if line.is_empty():
		_set_status("Subtitle text is empty.")
		return
	subtitle_cues.append({"time": timeline_time, "duration": 3.0, "text": line})
	_set_status("Subtitle cue added at %.2fs • %d cues" % [timeline_time, subtitle_cues.size()])

func _open_srt_export() -> void:
	srt_dialog.popup_centered_ratio(0.8)

func _export_srt(path: String) -> void:
	var cues := subtitle_cues.duplicate(true)
	cues.sort_custom(func(a: Dictionary, b: Dictionary): return float(a.get("time", 0.0)) < float(b.get("time", 0.0)))
	var output := ""
	for i in range(cues.size()):
		var start := float(cues[i].get("time", 0.0))
		var finish := start + maxf(0.5, float(cues[i].get("duration", 3.0)))
		output += str(i + 1) + "\n"
		output += _format_srt_time(start) + " --> " + _format_srt_time(finish) + "\n"
		output += str(cues[i].get("text", "")) + "\n\n"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_set_status("SRT export failed: " + error_string(FileAccess.get_open_error()))
		return
	file.store_string(output)
	file.close()
	_set_status("SRT exported • %d subtitle cues" % cues.size())

func _format_srt_time(seconds: float) -> String:
	var total_ms := int(maxf(0.0, seconds) * 1000.0)
	var hours := int(total_ms / 3600000)
	var minutes := int((total_ms % 3600000) / 60000)
	var secs := int((total_ms % 60000) / 1000)
	var millis := total_ms % 1000
	return "%02d:%02d:%02d,%03d" % [hours, minutes, secs, millis]


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
	var snapshot := mesh.duplicate(true) as ArrayMesh
	if snapshot != null:
		sculpt_undo_stack.append(snapshot)
		if sculpt_undo_stack.size() > SCULPT_HISTORY_LIMIT:
			sculpt_undo_stack.pop_front()
		sculpt_redo_stack.clear()
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

func _undo_sculpt() -> void:
	var mesh_instance := selected_object.get_child(0) as MeshInstance3D if selected_object != null else null
	if mesh_instance == null or not (mesh_instance.mesh is ArrayMesh) or sculpt_undo_stack.is_empty():
		_set_status("No sculpt action to undo")
		return
	sculpt_redo_stack.append((mesh_instance.mesh as ArrayMesh).duplicate(true) as ArrayMesh)
	mesh_instance.mesh = sculpt_undo_stack.pop_back()
	_set_status("Sculpt action undone")

func _redo_sculpt() -> void:
	var mesh_instance := selected_object.get_child(0) as MeshInstance3D if selected_object != null else null
	if mesh_instance == null or not (mesh_instance.mesh is ArrayMesh) or sculpt_redo_stack.is_empty():
		_set_status("No sculpt action to redo")
		return
	sculpt_undo_stack.append((mesh_instance.mesh as ArrayMesh).duplicate(true) as ArrayMesh)
	mesh_instance.mesh = sculpt_redo_stack.pop_back()
	_set_status("Sculpt action redone")
