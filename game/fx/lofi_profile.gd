class_name LoFiProfile
extends RefCounted
## One retro-intensity preset for the lo-fi look (Gorsel Hedef, sections 5-7).
## Pure data: LoFiView applies it to the screen and the world shaders.
## Faces, hands and documents never use these values (exempt materials, 2D UI).

enum Level { OFF, LIGHT, MEDIUM, STRONG }

const DEFAULT_LEVEL: Level = Level.MEDIUM
const LEVEL_NAMES_TR: PackedStringArray = ["Kapalı", "Hafif", "Orta", "Güçlü"]

var level: Level = DEFAULT_LEVEL
## The 3D world is drawn at window size / shrink (2 -> 960x540 at 1080p).
var shrink: int = 2
## Colour steps per channel; 256 means no visible reduction.
var color_levels: int = 32
## 0 = plain rounding, 1 = full 4x4 Bayer ordered dither.
var dither: float = 1.0
## 0 = perspective-correct textures, 1 = full PS1-style affine mapping.
var affine: float = 0.4
## Vertex snap grid in pixels; Vector2i.ZERO turns vertex jitter off.
var jitter_grid: Vector2i = Vector2i(480, 270)
var barrel: float = 0.04
var vignette: float = 0.35
## Edge colour fringing in low-res pixels; the visual target caps it at 1.
var chroma_px: float = 1.0
var grain: float = 0.05


static func for_level(requested: int) -> LoFiProfile:
	var p: LoFiProfile = LoFiProfile.new()
	p.level = clampi(requested, Level.OFF, Level.STRONG) as Level
	match p.level:
		Level.OFF:
			p.shrink = 1
			p.color_levels = 256
			p.dither = 0.0
			p.affine = 0.0
			p.jitter_grid = Vector2i.ZERO
			p.barrel = 0.0
			p.vignette = 0.0
			p.chroma_px = 0.0
			p.grain = 0.0
		Level.LIGHT:
			p.shrink = 2
			p.color_levels = 64
			p.dither = 0.6
			p.affine = 0.2
			p.jitter_grid = Vector2i(960, 540)
			p.barrel = 0.02
			p.vignette = 0.25
			p.chroma_px = 0.5
			p.grain = 0.03
		Level.MEDIUM:
			pass  # field defaults above are the MEDIUM preset
		Level.STRONG:
			p.shrink = 3
			p.color_levels = 24
			p.dither = 1.0
			p.affine = 0.7
			p.jitter_grid = Vector2i(320, 180)
			p.barrel = 0.06
			p.vignette = 0.45
			p.chroma_px = 1.0
			p.grain = 0.08
	return p


func display_name() -> String:
	return LEVEL_NAMES_TR[level]


## Internal 3D resolution for a given window size.
func internal_size(window_size: Vector2i) -> Vector2i:
	return Vector2i(maxi(1, window_size.x / shrink), maxi(1, window_size.y / shrink))
