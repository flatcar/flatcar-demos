# KubeCon NA 2026 Flatcar Flyer

A one-page A4 tri-fold flyer for the Flatcar booth, written in Marp. It is a
rebuild of the Word flyer in the parent folder (`flatcar-flyer.docx`), with the
Flatcar theme and Overpass font, four feature cards, a QR code row and the
community details.

Each side is a tri-fold: three equal panels that line up with the two fold
lines, so each reads on its own when folded. Page 1 is the outside (cover, why
Flatcar, community); page 2 is the inside (how Flatcar differs, trusted in
production, quick answers).

All content lives in [`slides.md`](slides.md) (one slide per side). The A4 page
size comes from the `flatcar-a4` theme in
[`themes/flatcar-a4.css`](themes/flatcar-a4.css). Edit the text and links
there, and the QR codes in `assets/qr/`, then build the PDF.

## Build

The recommended path is Podman + `make`. Everything runs inside a small
container image so the host only needs `podman` and `make`.

```sh
make setup        # first-time: build the slides-builder container image
make build        # -> build/slides.pdf
make clean        # remove build artifacts
```

Native (no container), requires Node.js on the host:

```sh
npm ci            # or npm install
make native-build # -> build/slides.pdf
make watch        # rebuilds on save
```

See `make help` for the full target list.

## Duplex printing

Every build also writes `build/slides-page2-flipped.pdf`, the same flyer with page 2 rotated 180 degrees. Use it if your printer flips the back side of a duplex sheet the wrong way. Needs `pypdf` or [uv](https://docs.astral.sh/uv/).

## PowerPoint

`make pptx` builds a native, fully editable PowerPoint at
`build/slides-native.pptx` (needs [uv](https://docs.astral.sh/uv/) and
`rsvg-convert`). It is a hand-built mirror of `slides.md`, not a converter:
`scripts/build-pptx.py` rebuilds the flyer from the helpers in
`scripts/pptx_lib.py`, so keep it in sync with `slides.md`. The file refers to the Overpass font by name, so
install Overpass to see it as designed.

---

Generated from [cookiecutter-marp-flatcar](https://github.com/flatcar/cookiecutter-marp-flatcar) by **Jan Bronicki**.
