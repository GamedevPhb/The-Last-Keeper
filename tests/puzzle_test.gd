extends SceneTree
## Headless logic test for the puzzles: lamp order, generator valves, breakers, cellar lock.
## Run: godot-4 --headless --path . --script res://tests/puzzle_test.gd

var _failures := 0


func _initialize() -> void:
	root.add_child(load("res://main.tscn").instantiate())


## Runs on the first frame, once every _ready has built its interactables.
func _process(_delta: float) -> bool:
	var state := root.get_node("GameState")
	var main := root.get_node("Main")
	var beacon: Node = main.get_node("Island/Lighthouse/Beacon")
	var stations := main.get_node("Island/Details/Stations")
	var generator := stations.get_node("Station_Generator")

	# Lamp: wrong order jams the mechanism and resets the sequence.
	state.oil_cans = 2
	beacon.get_node("Crank").interact(null)
	beacon._on_interacted(null)
	_check(not beacon.lit, "lamp must not light after a jammed sequence")
	for step in ["OilTank", "Crank", "Lens"]:
		beacon.get_node(step).interact(null)
	beacon._on_interacted(null)
	_check(beacon.lit, "lamp lights after oil, crank, lens")
	_check(state.oil_cans == 1, "lighting consumes one oil can")

	# Generator: wrong order resets, right order with fuel starts it.
	var wrong: int = (generator.order[0] + 1) % 4
	generator.get_node("Valve%s" % generator.LABELS[wrong]).interact(null)
	for index in generator.order:
		generator.get_node("Valve%s" % generator.LABELS[index]).interact(null)
	_check(not generator.running, "generator needs fuel even with the right order")
	state.fuel_cans = 1
	generator.get_node("FuelIn").interact(null)
	for index in generator.order:
		generator.get_node("Valve%s" % generator.LABELS[index]).interact(null)
	_check(generator.running and state.generator_on, "generator starts with fuel and the right order")

	# Breakers: capacity is two circuits.
	state.toggle_breaker("radio")
	state.toggle_breaker("house")
	state.toggle_breaker("motor")
	_check(state.powered("radio") and state.powered("house") and not state.powered("motor"), "third breaker overloads")

	# Cellar: dials spell 8-3-5.
	var lock := stations.get_node("Station_Cellar")
	var cans_before: int = state.oil_cans
	for i in 3:
		for _n in lock.CODE[i]:
			lock.get_node("Dial%d" % i).interact(null)
	_check(state.oil_cans == cans_before + 2, "cellar opens with the code")

	print("PUZZLE TEST FAILED (%d)" % _failures if _failures else "PUZZLE TEST PASSED")
	quit(1 if _failures else 0)
	return true


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL: " + message)
