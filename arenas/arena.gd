extends Spatial

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var prop_loader := {}

# Called when the node enters the scene tree for the first time.
func _ready():
	preload_props()
	#load_arena_file("res://arenas/teest.arena")
	load_arena_file("res://arenas/equilibriste.arena")
	load_vehicle("res://vehicles/gt/gt.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func str_to_vector(var s: String) -> Vector3:
	var parts := s.split(" ")
	if parts.size() == 3:
		return Vector3(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())
	else:
		return Vector3()

func spawn_prop(var name : String, var position: Vector3, var rotation: Vector3):
	
	if prop_loader.has(name):
		var prop := prop_loader[name].instance() as Spatial
		add_child(prop)
		#var real_rotation = Vector3(deg2rad(rotation.x), deg2rad(rotation.y), deg2rad(rotation.z))
		#prop.global_transform = Transform(Basis(real_rotation), position)
		prop.rotate_z(deg2rad(rotation.z))
		prop.rotate_y(deg2rad(rotation.y))
		prop.rotate_x(deg2rad(rotation.x))
		prop.global_translate(position)
		
		
	#print("spawn_prop:", name, position, rotation)

func load_arena_file(var file : String):
	var arena_file := XMLParser.new()
	arena_file.open(file)
	while arena_file.read() == OK:
		if arena_file.get_node_name() == "Prop":
			var name := arena_file.get_named_attribute_value("name")
			var position := str_to_vector(arena_file.get_named_attribute_value("position"))
			var rotation := str_to_vector(arena_file.get_named_attribute_value("rotation"))
			spawn_prop(name, position, rotation)

func preload_props():
	prop_loader["2x4"] = preload("res://props/2x4/2x4.tscn")
	prop_loader["Barrel"] = preload("res://props/barrel/barrel.tscn")
	prop_loader["Big Box"] = preload("res://props/bigbox/bigbox.tscn")
	prop_loader["Concrete Bump"] = preload("res://props/concrete/concrete.tscn")
	prop_loader["Concrete Tube"] = preload("res://props/tunnel/tunnel.tscn")
	prop_loader["Cone"] = preload("res://props/cone/cone.tscn")
	prop_loader["Crate"] = preload("res://props/crate/crate.tscn")
	prop_loader["Dumpster"] = preload("res://props/dumpster/dumpster.tscn")
	prop_loader["Garage Stand"] = preload("res://props/garage_stand/garage_stand.tscn")
	prop_loader["Indicator"] = preload("res://props/indicator/indicator.tscn")
	prop_loader["Junk Car"] = preload("res://props/simple_car/simple_car.tscn")
	prop_loader["Kicker 1"] = preload("res://props/kicker1/kicker1.tscn")
	prop_loader["Loop"] = preload("res://props/loop/loop.tscn")
	prop_loader["Plywood"] = preload("res://props/plywood/plywood.tscn")
	prop_loader["Quarter Pipe"] = preload("res://props/quarterpipe/quarterpipe.tscn")
	prop_loader["Ring"] = preload("res://props/ring/ring.tscn")
	prop_loader["Simple Jump 1"] = preload("res://props/simple_jump1/simple_jump1.tscn")
	prop_loader["Small Jump 1"] = preload("res://props/small_jump1/small_jump1.tscn")
	prop_loader["Stop Sign"] = preload("res://props/stop_sign/stop_sign.tscn")
	prop_loader["Super Jump 1"] = preload("res://props/super_jump1/super_jump1.tscn")
	prop_loader["Tunnel Jump"] = preload("res://props/tunnel_jump/tunnel_jump.tscn")
	
func load_vehicle(name):
	var vehicle = load(name).instance()
	add_child(vehicle)
	vehicle.global_transform = $VehicleSpawnPoint.global_transform