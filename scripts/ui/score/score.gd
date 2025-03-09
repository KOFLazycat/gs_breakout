class_name Score
extends Control

@onready var score: Label = $Score


func set_score(new_score: int) -> void:
	var tween: Tween = create_tween()
	tween.tween_method(update_label, score .text.to_int(), new_score, 0.2).set_trans(Tween.TRANS_LINEAR)
	# 放大到 1.5 倍，快速完成（0.2秒）
	tween.parallel().tween_property(score, "scale", Vector2(1.5, 1.5), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 缩放到原始尺寸，带有弹性效果（0.5秒）
	tween.tween_property(score, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func update_label(v: int) -> void:
	score.text = str(v)
