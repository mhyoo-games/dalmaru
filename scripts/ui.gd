class_name UI
extends RefCounted
## 화면 글자 꾸미기 도우미.

const INK := Color("2b1e2f")
const PAPER := Color("f8edd5")
const GOLD := Color("f6cf57")

static func label(text: String, size := 12, col := Color.WHITE, outline := true, small := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", Game.font_small if small else Game.font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if outline:
		l.add_theme_color_override("font_outline_color", INK)
		l.add_theme_constant_override("outline_size", 4)
	return l

static func heart_tex(i: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = Fx.tex("hearts")
	at.region = Rect2(i * 9, 0, 9, 8)
	return at

static func box() -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = Fx.tex("ui_box")
	n.patch_margin_left = 8
	n.patch_margin_right = 8
	n.patch_margin_top = 8
	n.patch_margin_bottom = 8
	return n
