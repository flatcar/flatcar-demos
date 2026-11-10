"""Helpers for building native, editable PowerPoint decks with python-pptx.

Shared by `scripts/build-pptx.py`. Everything is placed in inches (or in CSS
pixels with `px()`, so Marp CSS values can be reused 1:1 at 96 dpi). Text,
cards and bands are real PowerPoint shapes. Logos and QR codes are pictures
(SVGs are rasterised first, because python-pptx has no SVG support).

Needs: python-pptx, Pillow and `rsvg-convert` (librsvg) for SVG assets.
"""
import subprocess
from pathlib import Path

from PIL import Image
from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import MSO_ANCHOR, PP_ALIGN
from pptx.util import Emu, Inches, Pt

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"
TMP = ROOT / "build" / "pptx-assets"

NAVY = RGBColor(0x12, 0x17, 0x2B)
CYAN = RGBColor(0x09, 0xBA, 0xC8)
INK = RGBColor(0x12, 0x17, 0x2B)
SOFT = RGBColor(0x3A, 0x44, 0x60)
PANEL = RGBColor(0xF1, 0xF4, 0xF9)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
LIGHT = RGBColor(0xD5, 0xDB, 0xE8)
GREY = RGBColor(0x9A, 0xA3, 0xB8)
SILVER = RGBColor(0xC3, 0xCA, 0xD9)
DIM = RGBColor(0x25, 0x2A, 0x3E)
TEAL = RGBColor(0x10, 0x3A, 0x4C)
FONT = "Overpass"
MONO = "Consolas"

__all__ = [
    "ASSETS", "NAVY", "CYAN", "INK", "SOFT", "PANEL", "WHITE", "FONT", "MSO_ANCHOR",
    "MSO_SHAPE", "PP_ALIGN", "px", "new_presentation", "blank_slide", "raster",
    "fill_bg", "rect", "text", "picture", "line",
]


def px(value: float) -> float:
    """CSS pixels (96 dpi) to inches."""
    return value / 96


def new_presentation(width_in: float, height_in: float) -> Presentation:
    prs = Presentation()
    prs.slide_width = Emu(int(Inches(width_in)))
    prs.slide_height = Emu(int(Inches(height_in)))
    return prs


def blank_slide(prs):
    return prs.slides.add_slide(prs.slide_layouts[6])


def raster(path: Path, height_px: int = 600) -> Path:
    """Return a PNG for any asset (rasterises SVGs once)."""
    if path.suffix.lower() != ".svg":
        return path
    TMP.mkdir(parents=True, exist_ok=True)
    out = TMP / (path.stem + ".png")
    subprocess.run(["rsvg-convert", "-h", str(height_px), str(path), "-o", str(out)], check=True)
    return out


def fill_bg(slide, color):
    bg = slide.background.fill
    bg.solid()
    bg.fore_color.rgb = color


def rect(slide, x, y, w, h, color, shape=MSO_SHAPE.RECTANGLE, radius=None, name=None):
    """Flat filled shape without outline or shadow. `radius` is 0..0.5 for rounded rects."""
    s = slide.shapes.add_shape(shape, Inches(x), Inches(y), Inches(w), Inches(h))
    s.fill.solid()
    s.fill.fore_color.rgb = color
    s.line.fill.background()
    s.shadow.inherit = False
    style = s._element.find("{http://schemas.openxmlformats.org/presentationml/2006/main}style")
    if style is not None:  # the theme style carries the drop shadow LibreOffice renders
        s._element.remove(style)
    if radius is not None:
        s.adjustments[0] = radius
    if name:
        s.name = name
    return s


def text(slide, x, y, w, h, runs, size, color=WHITE, bold=False, align=PP_ALIGN.LEFT,
         anchor=MSO_ANCHOR.TOP, line_spacing=None, name=None):
    """Add a text box. `runs` is a str or a list of (text, bold[, color[, font]]) tuples.
    `size` is in points; "\\n" inside a run starts a new line."""
    tb = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    if name:
        tb.name = name
    tf = tb.text_frame
    tf.word_wrap = True
    tf.margin_left = tf.margin_right = tf.margin_top = tf.margin_bottom = 0
    tf.vertical_anchor = anchor
    p = tf.paragraphs[0]
    p.alignment = align
    if line_spacing:
        p.line_spacing = line_spacing
    if isinstance(runs, str):
        runs = [(runs, bold)]
    for item in runs:
        t, b, *rest = item
        for n, part in enumerate(t.split("\n")):
            if n:
                p.add_line_break()
            if not part:
                continue
            r = p.add_run()
            r.text = part
            r.font.name = rest[1] if len(rest) > 1 and rest[1] else FONT
            r.font.size = Pt(size)
            r.font.bold = b
            r.font.color.rgb = rest[0] if rest and rest[0] is not None else color
    return tb


def picture(slide, path, x, y, w, h, align="center", name=None):
    """Place a picture inside the (x, y, w, h) box, preserving the aspect ratio."""
    path = raster(Path(path))
    iw, ih = Image.open(path).size
    scale = min(w / iw, h / ih)
    pw, ph = iw * scale, ih * scale
    px_ = x + (w - pw) / 2 if align == "center" else (x + w - pw if align == "right" else x)
    py = y + (h - ph) / 2
    pic = slide.shapes.add_picture(str(path), Inches(px_), Inches(py), Inches(pw), Inches(ph))
    if name:
        pic.name = name
    return pic


def line(slide, x1, y1, x2, y2, color, width_pt=0.75, name=None):
    c = slide.shapes.add_connector(1, Inches(x1), Inches(y1), Inches(x2), Inches(y2))
    c.line.color.rgb = color
    c.line.width = Pt(width_pt)
    if name:
        c.name = name
    return c
