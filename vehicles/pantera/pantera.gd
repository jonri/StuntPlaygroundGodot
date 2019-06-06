extends VehicleBody

# Member variables

export var steering_max_angle = 0.74
export var steering_speed = 2.0
export var steering_percent_drop = 0.85
export var steering_from_speed = 20
export var steering_to_speed = 90
var steering_speed_range = 0
var steering_target = 0
var steering_angle = 0

var throttle = 0;
var brakes = false

var torque_curve_rpms = [100, 3500, 5500, 6500, 7500, 9000]
var torque_curve_torques = [300, 520, 760, 900, 8500, 0]
var gear_ratios = [-5.0, 2.4, 1.75, 1.15, 0.92, 0.8]
var differential_ratio = 2.1
var transmission_efficiency = 0.75
var drag_coefficient = 0.8
var brake_strength = 50

var current_gear
	
var spin_out = 4

func _ready():
	steering_speed_range = steering_to_speed - steering_from_speed
	current_gear = 1

func _physics_process(delta):

	if Input.is_action_just_pressed("reset"):
		apply_impulse(Vector3(1, 0, 0), Vector3(0, 2000, 0))
	
	if (Input.is_action_pressed("cam_1")):
		get_node("Camera1").make_current()
	elif (Input.is_action_pressed("cam_2")):
		get_node("Camera2").make_current()
			
	if (Input.is_action_pressed("ui_left")):
		steering_target = 1
	elif (Input.is_action_pressed("ui_right")):
		steering_target = -1
	else:
		steering_target = 0
	
	if (Input.is_action_pressed("ui_up")):
		throttle = 1
		#engine_force = 2000
	else:
		throttle = 0
		#engine_force = 0
	
	if (Input.is_action_pressed("ui_down")):
		brake = brake_strength
	elif Input.is_action_pressed("handbrake"):
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

		
	if Input.is_action_just_pressed("shift_down"):
		if current_gear > 1:
			current_gear -= 1
	if Input.is_action_just_pressed("shift_up"):
		if current_gear < 5:
			current_gear += 1
		
	var kph = linear_velocity.length() * 3.6	
	var omega = linear_velocity.length() / 0.35 * 6.28;
	var rpm = omega * gear_ratios[current_gear] * differential_ratio * (60.0 / 6.28)
	
	if rpm < torque_curve_rpms[0]:
		rpm = torque_curve_rpms[0]
	if rpm > torque_curve_rpms[5]:
		rpm = torque_curve_rpms[5]
	
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
	
	engine_force = wheel_torque * 0.35 * 2
	
	#print("Gear: %d  RPM: %d  KPH: %d  Force: %d" % [current_gear, rpm, kph, engine_force])
	
	
	if (current_gear > 1):
		if rpm < torque_curve_rpms[1] * 0.5:
			current_gear -= 1
	else:
		if rpm < 2000:
			rpm = 2000
			
	if rpm > torque_curve_rpms[4] and current_gear < 5:
		current_gear += 1
		
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
	
