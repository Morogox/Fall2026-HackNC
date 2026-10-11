class_name ShuffleBag
extends RefCounted

var _items: Array = []
var _bag: Array = []
var _last = null


func _init(items: Array) -> void:
	_items = items.filter(func(x): return x != null)


func draw(reject: Callable = Callable()):
	if _items.is_empty():
		return null

	if _bag.is_empty():
		_refill()


	var pick_index := _bag.size() - 1
	if reject.is_valid():
		for i in range(_bag.size() - 1, -1, -1):
			if not reject.call(_bag[i]):
				pick_index = i
				break

	_last = _bag[pick_index]
	_bag.remove_at(pick_index)
	return _last


func _refill() -> void:
	_bag = _items.duplicate()
	_bag.shuffle()
	if _bag.size() > 1 and _bag.back() == _last:
		var tmp = _bag[0]
		_bag[0] = _bag.back()
		_bag[_bag.size() - 1] = tmp
