extends VehicleBody

# Member variables

export var steering_max_angle = 0.75
export var steering_speed = 4.0
export var steering_percent_drop = 0.75
export var steering_from_speed = 18
export var steering_to_speed = 70
var steering_speed_range = 0
var steering_target = 0
var steering_angle = 0

var throttle = 0;
var brakes = false

#Alternative A
export var torque_curve_rpms = [500, 5000, 5500, 6500, 7500, 9000]
export var torque_curve_torques = [400, 1100, 1300, 1800, 1600, 0]

#Alternative B
export var torque_curve = [Vector2(500,400), Vector2(5000, 1100), Vector2(5500, 1300), 
                           Vector2(6500, 1800), Vector2(7500, 1600), Vector2(9000, 0)]


export var gear_ratios = [-4.25, 3.2, 2.24, 1.57, 1.23, 1.065]
export var differential_ratio = 2.1
export var transmission_efficiency = 0.75
export var drag_coefficient = 0.8
export var brake_strength = 50
export var has_handbrake = true

var current_gear
	
var spin_out = 4

func _ready():
	steering_speed_range = steering_to_speed - steering_from_speed
	current_gear = 1

func _physics_process(delta):

	if Input.is_action_just_pressed("reset"):
		#get_tree().reload_current_scene()
		apply_impulse(Vector3(1, 0, 0), Vector3(0, mass * 2, 0))
	
	if (Input.is_action_pressed("cam_1")):
		get_node("Camera1").make_current()
	elif (Input.is_action_pressed("cam_2")):
		get_node("Camera2").make_current()
	elif (Input.is_action_pressed("cam_3")):
		get_node("Camera3").make_current()
			
	if (Input.is_action_pressed("ui_left")):
		steering_target = 1
	elif (Input.is_action_pressed("ui_right")):
		steering_target = -1
	else:
		steering_target = 0
	
	if (Input.is_action_pressed("ui_up")):
		throttle = 1
	else:
		throttle = 0
	
	if (Input.is_action_pressed("ui_down")):
		brake = brake_strength
	elif has_handbrake:
		if Input.is_action_pressed("handbrake"):
			brake = brake_strength / 4
			
			if (spin_out > 3):
				spin_out -= 10 * delta
			
			get_node("VehicleWheel").wheel_friction_slip = spin_out
			get_node("VehicleWheel2").wheel_friction_slip = spin_out
		else:
			brake = 0
			if (spin_out < 4):
				spin_out += 1 * delta
			if spin_out > 4:
				spin_out = 4
			get_node("VehicleWheel").wheel_friction_slip = spin_out
			get_node("VehicleWheel2").wheel_friction_slip = spin_out
		
	var wheel_radius = get_node("VehicleWheel").wheel_radius
	var local_velocity = get_transform().basis.z.dot(linear_velocity)
	
	var kph = local_velocity * 3.6	
	var omega = local_velocity / wheel_radius * 6.28;
	var rpm = abs(omega) * abs(gear_ratios[current_gear]) * differential_ratio * (60.0 / 6.28)

	if rpm < torque_curve_rpms[0]:
		rpm = torque_curve_rpms[0]
	if rpm > torque_curve_rpms[5]:
		rpm = torque_curve_rpms[5]
		
	if (current_gear == 1 and omega <= 1.0 and omega >= 0 and brake > 0):
		current_gear = 0;
		
	if current_gear == 0:
		if throttle != 0:
			current_gear = 1
		elif brake > 0:
			throttle = 1
			brake = 0
		
	if (current_gear > 1):
		if rpm < torque_curve_rpms[1] * 0.5:
			current_gear -= 1
	else:
		pass
		#if rpm < 2000:
		#	rpm = 2000
			
	if current_gear > 0 and rpm > torque_curve_rpms[4] and current_gear < 5:
		current_gear += 1
	
	var high = 0
	while (rpm >= torque_curve_rpms[high]):
		high += 1
		if high >= 6:
			high = 5
			break
	var low = high - 1
	if (high == 0):
		low = 0
		high = 1
	
	var interp = (rpm - torque_curve_rpms[low]) / (torque_curve_rpms[high] - torque_curve_rpms[low])
	var engine_torque = torque_curve_torques[low] + ((torque_curve_torques[high] - torque_curve_torques[low]) * interp)
	var wheel_torque = throttle * engine_torque * gear_ratios[current_gear] * differential_ratio * transmission_efficiency
	
	engine_force = wheel_torque * wheel_radius * 2
	
	print("Gear: %d  RPM: %d  KPH: %d  Force: %d" % [current_gear, rpm, kph, engine_force])
		
	#calculate steering angle
	steering_angle += steering_speed * steering_target * delta
	
	#re-center if not steering
	if not steering_target:
		if steering_angle > 0:
			steering_angle -= steering_speed * delta
			if steering_angle < 0:
				steering_angle = 0
		else:
			steering_angle += steering_speed * delta
			if steering_angle > 0:
				steering_angle = 0
	
	#calculate the new max steering angle based on velocity data
	var max_steer = steering_max_angle
	
	if kph < steering_from_speed:
		#going slower than the minimum speed, so no change.
		pass 
	elif kph > steering_to_speed:
		#going faster than highest speed, so remove completely!
		max_steer -= max_steer * steering_percent_drop
	else:
		#inside the range [steering_from_speed, steering_to_speed]
		var steer_delta = (kph - steering_from_speed) / steering_speed_range
		max_steer -= max_steer * steering_percent_drop * steer_delta
		
	if steering_angle > max_steer:
		steering_angle = max_steer
	elif steering_angle < -max_steer:
		steering_angle = -max_steer
	
	steering = steering_angle
	
