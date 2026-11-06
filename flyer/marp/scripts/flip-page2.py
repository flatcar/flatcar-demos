"""Write a copy of the PDF with page 2 rotated 180 degrees.

For printers that flip the back side of a duplex sheet the wrong way.
Usage: flip-page2.py [input.pdf] [output.pdf]
"""
import sys

from pypdf import PdfReader, PdfWriter

src = sys.argv[1] if len(sys.argv) > 1 else "build/slides.pdf"
dst = sys.argv[2] if len(sys.argv) > 2 else "build/slides-page2-flipped.pdf"

writer = PdfWriter()
for i, page in enumerate(PdfReader(src).pages):
    if i == 1:
        page.rotate(180)
    writer.add_page(page)
with open(dst, "wb") as f:
    writer.write(f)
print(f"Wrote {dst}")
