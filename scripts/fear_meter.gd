extends ProgressBar
func _ready() -> void:
	SignalBus.fear_changed.connect(fear_changed)

func fear_changed():
	self.value = Globals.fear
