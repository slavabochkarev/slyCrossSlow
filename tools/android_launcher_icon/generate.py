"""Build deterministic Android launcher resources from the approved master PNG."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[2]
MASTER = Path(__file__).with_name("master.png")
RES = ROOT / "android" / "app" / "src" / "main" / "res"
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def prepared_master() -> Image.Image:
    source = Image.open(MASTER).convert("RGB")
    if source.width != source.height:
        raise ValueError("Master icon must be square")

    # The supplied RGB image has white outside its rounded illustration.
    # Remove only that exterior, leaving the artwork and its proportions intact.
    pixels = source.load()
    alpha = Image.new("L", source.size, 0)
    alpha_pixels = alpha.load()
    for y in range(source.height):
        left = next(
            (x for x in range(source.width) if min(pixels[x, y]) < 235),
            None,
        )
        if left is None:
            continue
        right = next(
            x for x in range(source.width - 1, -1, -1)
            if min(pixels[x, y]) < 235
        )
        for x in range(left + 1, right):
            alpha_pixels[x, y] = min(255, (x - left) * 127, (right - x) * 127)

    prepared = source.convert("RGBA")
    prepared.putalpha(alpha)
    return prepared


def scene_background(master: Image.Image) -> Image.Image:
    size = master.width
    vertical = Image.linear_gradient("L").resize((size, size))
    blue_gradient = ImageOps.colorize(vertical, "#07164f", "#082f48").convert("RGBA")
    combined = Image.alpha_composite(blue_gradient, master)
    softened = combined.filter(ImageFilter.GaussianBlur(size * 0.15))
    return Image.blend(softened, blue_gradient, 0.48).convert("RGBA")


def foreground(master: Image.Image, scale: float) -> Image.Image:
    side = round(108 * scale)
    # 72 dp artwork centered in the 108 dp adaptive layer: 18 dp per side.
    # Do not add another inset in the adaptive-icon XML.
    art_side = round(72 * scale)
    result = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    art = master.resize((art_side, art_side), Image.Resampling.LANCZOS)
    result.alpha_composite(art, ((side - art_side) // 2, (side - art_side) // 2))
    return result


def round_icon(background: Image.Image, front: Image.Image, scale: float) -> Image.Image:
    layered = Image.alpha_composite(background, front)
    inset = round(18 * scale)
    visible = layered.crop((inset, inset, layered.width - inset, layered.height - inset))
    size = round(48 * scale)
    visible = visible.resize((size, size), Image.Resampling.LANCZOS)
    mask = Image.new("L", (size * 4, size * 4), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size * 4 - 1, size * 4 - 1), fill=255)
    visible.putalpha(mask.resize((size, size), Image.Resampling.LANCZOS))
    return visible


def main() -> None:
    master = prepared_master()
    background = scene_background(master)
    for density, scale in DENSITIES.items():
        folder = RES / f"mipmap-{density}"
        folder.mkdir(parents=True, exist_ok=True)
        legacy_side = round(48 * scale)
        legacy_background = background.resize((legacy_side, legacy_side), Image.Resampling.LANCZOS)
        legacy_art = master.resize((legacy_side, legacy_side), Image.Resampling.LANCZOS)
        Image.alpha_composite(legacy_background, legacy_art).convert("RGB").save(
            folder / "ic_launcher.png", optimize=True
        )

        layer_side = round(108 * scale)
        adaptive_background = background.resize((layer_side, layer_side), Image.Resampling.LANCZOS)
        adaptive_foreground = foreground(master, scale)
        adaptive_background.convert("RGB").save(
            folder / "ic_launcher_background.png", optimize=True
        )
        adaptive_foreground.save(folder / "ic_launcher_foreground.png", optimize=True)
        round_icon(adaptive_background, adaptive_foreground, scale).save(
            folder / "ic_launcher_round.png", optimize=True
        )

    # Previews show the actual legacy and adaptive compositions at a readable size.
    high_density = DENSITIES["xxxhdpi"]
    layer_side = round(108 * high_density)
    high_background = background.resize((layer_side, layer_side), Image.Resampling.LANCZOS)
    high_foreground = foreground(master, high_density)
    layered = Image.alpha_composite(high_background, high_foreground)
    inset = round(18 * high_density)
    visible = layered.crop((inset, inset, layer_side - inset, layer_side - inset))
    circle_mask = Image.new("L", visible.size, 0)
    ImageDraw.Draw(circle_mask).ellipse((0, 0, visible.width - 1, visible.height - 1), fill=255)
    circle = visible.copy()
    circle.putalpha(circle_mask)
    circle.save(Path(__file__).with_name("preview_adaptive_round.png"))
    visible.save(Path(__file__).with_name("preview_adaptive_square.png"))


if __name__ == "__main__":
    main()
