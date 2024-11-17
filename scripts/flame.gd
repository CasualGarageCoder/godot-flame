extends Node

enum Tools {
	TOOL_ERASER,
	TOOL_PENCIL
}

@export_range(1., 16., 1.) var brush_size : float = 8.

@export_range(1., 16., 1.) var eraser_size : float = 16.

@onready var tools_to_button : Dictionary[Tools, Button] = {
	Tools.TOOL_ERASER : $%EraserButton,
	Tools.TOOL_PENCIL : $%PenButton
}

@onready var selected_color : ColorPickerButton = $%SelectedColor

@onready var current_color : Color = $%SelectedColor.color

@onready var selected_tool : Tools = Tools.TOOL_PENCIL

@onready var tool_drag : bool = false

@onready var last_drag_pos : Vector2

@onready var next_drag_pos : Vector2

@onready var flame_image : Image

@onready var flame_texture : ImageTexture

@onready var drawer : Control = $%Drawer

@onready var drawing_viewport : SubViewport = $%DrawingViewport

func _texture_event(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		var me : InputEventMouseButton = event as InputEventMouseButton
		if me.button_index == MOUSE_BUTTON_LEFT:
			if me.pressed and not tool_drag:
				last_drag_pos = me.position
			tool_drag = me.pressed

	if event is InputEventMouseMotion and tool_drag:
		var me : InputEventMouseMotion = event as InputEventMouseMotion
		next_drag_pos = me.position
		drawer.queue_redraw()

func _flame_draw() -> void:
	# FIXME The Eraser doesn't work :( (Which is normal because of the additive method ...)
	drawer.draw_line(last_drag_pos, next_drag_pos, current_color if selected_tool == Tools.TOOL_PENCIL else Color.TRANSPARENT, brush_size if selected_tool == Tools.TOOL_PENCIL else eraser_size)
	last_drag_pos = next_drag_pos
	
func _ready() -> void:
	_select_tool(Tools.TOOL_PENCIL)
	selected_color.color = Color.DARK_RED
	current_color = selected_color.color
	selected_color.color_changed.connect(_select_color)
	$%PenButton.pressed.connect(_select_tool.bind(Tools.TOOL_PENCIL))
	$%EraserButton.pressed.connect(_select_tool.bind(Tools.TOOL_ERASER))
	$%FlameTexture.gui_input.connect(_texture_event)
	flame_image = Image.create_empty(256, 512, true,Image.FORMAT_RGBA8)
	drawer.draw.connect(_flame_draw)

func _process(_delta):
	var prev : Image = drawing_viewport.get_texture().get_image()
	var text : ImageTexture = ImageTexture.create_from_image(prev)
	($%Flame.material_override as ShaderMaterial).set_shader_parameter("decal", text)

func _select_color(color : Color) -> void:
	current_color = color

func _select_tool(tool : Tools) -> void:
	selected_tool = tool
	for t in tools_to_button:
		var button : Button = tools_to_button[t]
		button.modulate = Color.WHITE if t == selected_tool else Color.WEB_GRAY
