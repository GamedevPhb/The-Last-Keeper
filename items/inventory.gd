class_name Inventory
extends RefCounted
## 32 slots of {id, count} (empty slot = {}), plus the stack held by the cursor.
## Minecraft-style operations: `left()` picks up / places / merges / swaps, `right()` takes
## half or places one. Owned by `GameState.inventory`; the UI only calls these.

signal changed

const SIZE := 32
const COLUMNS := 8
## The first row is the hotbar: `selected` is the slot in hand (keys 1-8, wheel, d-pad left/right).
const HOTBAR := COLUMNS

## name, stack size, description, how it is used and, for consumables, seconds and effects.
const ITEMS := {
	"flashlight": {"name": "Lanterna", "stack": 1, "use": "flashlight",
		"desc": "Lanterna de mão. Na mão (barra de atalhos), F / R1 liga e desliga; F a traz para a mão."},
	"battery": {"name": "Pilha", "stack": 4, "use": "battery",
		"desc": "Pilha grande. Usar recarrega a lanterna em +50%. Ela gasta enquanto acesa."},
	"lens_cleaner": {"name": "Limpador de lente", "stack": 2, "use": "lens",
		"desc": "Pano e álcool. Usar limpa a lente: luz 1,5x mais forte e mais longa por cerca de 90 s, ou até a pilha acabar."},
	"radio": {"name": "Rádio portátil", "stack": 1, "use": "radio",
		"desc": "Retransmite o rádio da casa. Usar abre a tela (R / direcional para cima). Recarrega na base, junto do rádio."},
	"oil": {"name": "Lata de óleo", "stack": 4, "use": "console",
		"desc": "Óleo de lamparina. Gasta no console da lâmpada (ABASTECER).", "console": "Use no console da lâmpada, no topo do farol."},
	"fuel": {"name": "Lata de combustível", "stack": 2, "use": "console",
		"desc": "Diesel para o gerador do galpão.", "console": "Use no tanque do gerador, no galpão."},
	"water": {"name": "Garrafa d'água", "stack": 3, "use": "consume", "time": 2.0, "effects": {"thirst": 35.0},
		"desc": "Água da cisterna. Sede +35."},
	"can": {"name": "Lata de conserva", "stack": 3, "use": "consume", "time": 2.0, "effects": {"hunger": 40.0, "thirst": -5.0},
		"desc": "Sardinha em conserva, salgada. Fome +40, sede −5."},
	"biscuit": {"name": "Bolacha", "stack": 5, "use": "consume", "time": 2.0, "effects": {"hunger": 15.0},
		"desc": "Bolacha de água e sal, meio mole. Fome +15."},
	"bandage": {"name": "Curativo", "stack": 2, "use": "consume", "time": 4.0, "effects": {"health": 40.0},
		"desc": "Gaze e iodo. Vida +40, leva 4 s para aplicar."},
	"axe": {"name": "Machado", "stack": 1, "use": "equip",
		"desc": "Machado de lenha. Corpo a corpo e quase silencioso: 25 de dano. Na barra de atalhos, selecionar (1-8 / roda do mouse / direcional ← →) equipa."},
	"pistol": {"name": "Pistola P38", "stack": 1, "use": "equip",
		"desc": "Pistola velha do vigia anterior. Pente de 6, 35 de dano, estampido alto. Selecionar na barra equipa. Recarrega com T / L2."},
	"shotgun": {"name": "Espingarda", "stack": 1, "use": "equip",
		"desc": "Cano duplo, 2 tiros. De perto derruba qualquer um (80 de dano), de longe quase nada. O barulho vai longe. Selecionar na barra equipa."},
	"portinho": {"name": "Portinho", "stack": 1, "use": "portinho",
		"desc": "Bonequinho de lata: um farol com chapéu azul, polegar para cima. Usar pede uma dica sobre o que está perto."},
	"wood": {"name": "Lenha", "stack": 8,
		"desc": "Toras secas. Entram nas fábricas de óleo e de combustível."},
	"algae": {"name": "Algas", "stack": 8,
		"desc": "Algas oleosas da costa norte. Entram na fábrica de óleo."},
	"fat": {"name": "Gordura", "stack": 8,
		"desc": "Gordura animal rançosa. Entra na fábrica de óleo."},
	"coal": {"name": "Carvão", "stack": 8,
		"desc": "Pedras de carvão da gruta. Entram na fábrica de combustível."},
	"scrap": {"name": "Restos", "stack": 8,
		"desc": "Sucata de naufrágio. Entra na fábrica de combustível."},
	"fish": {"name": "Peixe", "stack": 3, "use": "consume", "time": 3.0, "effects": {"hunger": 30.0, "thirst": 5.0},
		"desc": "Peixe pescado, assado no fogão. Fome +30, sede +5."},
	"ammo_pistol": {"name": "Munição 9 mm", "stack": 12,
		"desc": "Cartuchos soltos para a pistola. Escassos: conte cada um."},
	"shells": {"name": "Cartucho calibre 12", "stack": 6,
		"desc": "Cartuchos de espingarda. Só os do porão."},
}

var slots: Array[Dictionary] = []
var cursor: Dictionary = {}
var selected := 0


func _init() -> void:
	clear()


func clear() -> void:
	slots.clear()
	for i in SIZE:
		slots.append({})
	cursor = {}
	changed.emit()


static func stack_of(id: String) -> int:
	return ITEMS[id].stack if ITEMS.has(id) else 1


static func item_name(id: String) -> String:
	return ITEMS[id].name if ITEMS.has(id) else id


func count(id: String) -> int:
	var total := 0
	for slot in slots:
		if slot.get("id", "") == id:
			total += slot.count
	if cursor.get("id", "") == id:
		total += cursor.count
	return total


## Adds up to `amount`, topping up existing stacks first. Returns what did not fit.
func add(id: String, amount: int) -> int:
	var remaining := amount
	var limit := stack_of(id)
	for slot in slots:
		if remaining <= 0:
			break
		if slot.get("id", "") == id and slot.count < limit:
			var moved := mini(limit - slot.count, remaining)
			slot.count += moved
			remaining -= moved
	for i in SIZE:
		if remaining <= 0:
			break
		if slots[i].is_empty():
			var moved := mini(limit, remaining)
			slots[i] = {"id": id, "count": moved}
			remaining -= moved
	if remaining != amount:
		changed.emit()
	return remaining


## Removes `amount` (from the cursor first, then the last slots). False if there is not enough.
func remove(id: String, amount: int) -> bool:
	if count(id) < amount:
		return false
	var remaining := amount
	if cursor.get("id", "") == id:
		var taken := mini(cursor.count, remaining)
		cursor.count -= taken
		remaining -= taken
		if cursor.count <= 0:
			cursor = {}
	for i in range(SIZE - 1, -1, -1):
		if remaining <= 0:
			break
		if slots[i].get("id", "") == id:
			var taken := mini(slots[i].count, remaining)
			slots[i].count -= taken
			remaining -= taken
			if slots[i].count <= 0:
				slots[i] = {}
	changed.emit()
	return true


## Takes `amount` out of slot `index` and returns it as a stack ({} if empty).
func take_at(index: int, amount: int) -> Dictionary:
	var slot := slots[index]
	if slot.is_empty():
		return {}
	var taken := mini(amount, slot.count)
	slot.count -= taken
	if slot.count <= 0:
		slots[index] = {}
	changed.emit()
	return {"id": slot.id, "count": taken}


## Left click: pick the whole stack up, or put the held stack down (merge, or swap).
func left(index: int) -> void:
	var slot := slots[index]
	if cursor.is_empty():
		if slot.is_empty():
			return
		cursor = slot
		slots[index] = {}
	elif slot.is_empty():
		slots[index] = cursor
		cursor = {}
	elif slot.id == cursor.id:
		var moved := mini(stack_of(slot.id) - slot.count, cursor.count)
		slot.count += moved
		cursor.count -= moved
		if cursor.count <= 0:
			cursor = {}
	else:
		slots[index] = cursor
		cursor = slot
	changed.emit()


## Right click: take half the stack (rounded up), or drop one of the held stack here.
func right(index: int) -> void:
	var slot := slots[index]
	if cursor.is_empty():
		if slot.is_empty():
			return
		var half := ceili(slot.count / 2.0)
		cursor = take_at(index, half)
	elif slot.is_empty() or (slot.id == cursor.id and slot.count < stack_of(slot.id)):
		if slot.is_empty():
			slots[index] = {"id": cursor.id, "count": 1}
		else:
			slot.count += 1
		cursor.count -= 1
		if cursor.count <= 0:
			cursor = {}
	changed.emit()


## Puts the held stack back into the slots. Returns what did not fit (left in the cursor).
func stow_cursor() -> Dictionary:
	if cursor.is_empty():
		return {}
	var held := cursor
	cursor = {}
	var rest := add(held.id, held.count)
	if rest > 0:
		cursor = {"id": held.id, "count": rest}
	changed.emit()
	return cursor


## Restores slots from save data (JSON turns counts into floats).
func load_slots(saved: Array, held: Dictionary) -> void:
	clear()
	for i in mini(saved.size(), SIZE):
		var slot: Dictionary = saved[i]
		if not slot.is_empty():
			slots[i] = {"id": str(slot.id), "count": int(slot.count)}
	if not held.is_empty():
		cursor = {"id": str(held.id), "count": int(held.count)}
	changed.emit()


## Id in the selected hotbar slot ("" if empty).
func selected_id() -> String:
	return slots[selected].get("id", "")


## Hotbar slot holding `id` (the selected one first), or -1.
func hotbar_index(id: String) -> int:
	if slots[selected].get("id", "") == id:
		return selected
	for i in HOTBAR:
		if slots[i].get("id", "") == id:
			return i
	return -1


## Makes sure `id` sits in the hotbar: a stack from the backpack rows moves to the first free
## hotbar slot, or swaps with the selected one. Returns its hotbar slot, -1 if not in any slot.
func bring_to_hotbar(id: String) -> int:
	var at := hotbar_index(id)
	if at >= 0:
		return at
	var from := -1
	for i in range(HOTBAR, SIZE):
		if slots[i].get("id", "") == id:
			from = i
			break
	if from < 0:
		return -1
	var to := selected
	for i in HOTBAR:
		if slots[i].is_empty():
			to = i
			break
	var moved := slots[to]
	slots[to] = slots[from]
	slots[from] = moved
	changed.emit()
	return to


func take_cursor() -> Dictionary:
	var held := cursor
	cursor = {}
	changed.emit()
	return held
