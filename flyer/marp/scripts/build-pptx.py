#!/usr/bin/env python3
"""Build a native, fully editable PowerPoint version of the A4 tri-fold flyer.

Run with: uv run --with python-pptx python scripts/build-pptx.py
Output: build/slides-native.pptx

It mirrors slides.md by hand (same geometry as the Marp CSS, in 96 dpi
pixels), so keep the two in sync when you change content.
"""
from pptx_lib import (
    ASSETS, CYAN, INK, MSO_SHAPE, NAVY, PANEL, PP_ALIGN, SOFT, WHITE, MONO, LIGHT, GREY, DIM, TEAL, SILVER, MSO_ANCHOR,
    blank_slide, fill_bg, line, new_presentation, picture, px, rect, text,
)
from pptx_lib import ROOT

OUT = ROOT / "build" / "slides-native.pptx"

W, H = 794, 1123
PANEL_H = (374, 375, 374)
PAD = 54
CONTENT_W = W - 2 * PAD


def pt(css_px):
    return css_px * 0.75


def box(slide, x, y, w, h, *a, **k):
    """text() in CSS pixels."""
    return text(slide, px(x), px(y), px(w), px(h), *a, **k)


def build_cover(s, top):
    rect(s, 0, px(top), px(W), px(PANEL_H[0]), NAVY, name="Cover panel")
    rect(s, 0, px(top + PANEL_H[0] - 6), px(W), px(6), CYAN, name="Cover rule")
    picture(s, ASSETS / "flatcar-logo.svg", px(PAD), px(74), px(170), px(104), align="left",
            name="Flatcar logo")
    box(s, 254, 78, 520, 50, "Flatcar Container Linux", pt(38), WHITE, bold=True, name="Title")
    box(s, 254, 130, 520, 32, "Minimal. Immutable. Secure by default.", pt(21), CYAN,
        bold=True, name="Tagline")
    box(s, PAD, 212, CONTENT_W, 100,
        [("A ", False), ("fully free and open-source, community-driven", True, CYAN),
         (" Linux distribution that is minimal, security-focused and ", False),
         ("optimized to run containers", True, CYAN),
         (".", False), ("\n", False), ("A ", False),
         ("CNCF project", True, CYAN),
         (" that is always up to date and gives you full control over your fleet.", False)],
        pt(21), WHITE, name="Intro")


def build_cards(s, top):
    box(s, PAD, top + 20, CONTENT_W, 36, "Why Flatcar", pt(24), INK, bold=True, align=PP_ALIGN.CENTER, name="Heading")
    cards = [
        ("Immutable, image-based",
         [("A minimal footprint with a read-only, verified ", False), ("/usr", False, None, MONO),
          (". No package manager on the node, so every machine is the same.", False)]),
        ("Self-updating, with rollback",
         [("A/B partitions apply updates in the background. You control when to reboot "
           "into the new image, and a bad update rolls back automatically.", False)]),
        ("Operating System as Code",
         [("Describe the machine in YAML and Ignition applies units, files, SSH keys, users "
           "and disks at first boot. No interactive setup.", False)]),
        ("Extensible with sysexts",
         [("Add Docker, Podman, Kubernetes or GPU drivers as systemd-sysext overlays, "
           "pinned to the version you want.", False)]),
    ]
    cw = (CONTENT_W - 14) / 2
    rows = [(top + 58, 128), (top + 200, 108)]
    for i, (title, body) in enumerate(cards):
        x = PAD + (i % 2) * (cw + 14)
        y, h = rows[i // 2]
        rect(s, px(x), px(y), px(cw), px(h), PANEL, name=f"Card {i + 1}")
        rect(s, px(x), px(y), px(5), px(h), CYAN, name=f"Card {i + 1} accent")
        box(s, x + 19, y + 10, cw - 33, 26, title, pt(19), INK, bold=True,
            name=f"Card {i + 1} title")
        box(s, x + 19, y + 40, cw - 33, h - 46, body, pt(15), SOFT, name=f"Card {i + 1} text")
    sy = top + 322
    rect(s, px(PAD), px(sy), px(CONTENT_W), px(38), NAVY, MSO_SHAPE.ROUNDED_RECTANGLE,
         radius=0.2, name="Platforms band")
    box(s, PAD, sy, CONTENT_W, 38,
        [("Supported wherever you run your containers:", True, CYAN),
         (" every major cloud, on-prem and bare metal", False)],
        pt(15), WHITE, align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE, name="Platforms")


def build_community(s, top):
    rect(s, 0, px(top), px(W), px(PANEL_H[2]), NAVY, name="Community panel")
    box(s, PAD, top + 36, CONTENT_W, 36, "Get started and join us", pt(24), WHITE, bold=True,
        align=PP_ALIGN.CENTER, name="Heading")
    qrs = [
        ("flatcar_org.png", "Website", "flatcar.org"),
        ("flatcar_gh.png", "GitHub", "flatcar/Flatcar"),
        ("flatcar_learning_series.png", "Learning series", "learn.flatcar.org"),
        ("flatcar_discord.png", "Discord", "chat.flatcar.org"),
    ]
    gap = 14
    cw = (CONTENT_W - 3 * gap) / 4
    y, ch = top + 81, 170
    for i, (img, label, sub) in enumerate(qrs):
        x = PAD + i * (cw + gap)
        rect(s, px(x), px(y), px(cw), px(ch), WHITE, MSO_SHAPE.ROUNDED_RECTANGLE,
             radius=0.06, name=f"QR card {label}")
        picture(s, ASSETS / "qr" / img, px(x + (cw - 118) / 2), px(y + 8), px(118), px(118),
                name=f"QR {label}")
        box(s, x, y + 130, cw, 20, label, pt(15), INK, bold=True, align=PP_ALIGN.CENTER,
            name=f"{label} label")
        box(s, x, y + 150, cw, 16, sub, pt(12.5), SOFT, align=PP_ALIGN.CENTER,
            name=f"{label} caption")
    box(s, PAD, top + 272, CONTENT_W, 22, "COME SAY HI", pt(15), CYAN, bold=True,
        name="Come say hi heading")
    box(s, PAD, top + 298, CONTENT_W, 56,
        [("Join our Discord server", True),
         (" to ask questions and chat with the maintainers: chat.flatcar.org", False),
         ("\nOffice hours and dev syncs: every 2nd and 4th Thursday, 2:30 pm UTC", False)],
        pt(16), WHITE, name="Come say hi")


def build_differs(s, top):
    rect(s, 0, px(top), px(W), px(PANEL_H[0]), NAVY, name="Differs panel")
    rect(s, 0, px(top + PANEL_H[0] - 6), px(W), px(6), CYAN, name="Differs rule")
    box(s, PAD, top + 48, CONTENT_W, 36, "How Flatcar differs", pt(24), WHITE, bold=True,
        align=PP_ALIGN.CENTER, name="Heading")
    rows = [
        ("Anyone can change software at any time",
         "Read-only system; extras run as containers or system extensions"),
        ("Patches packages one by one, in place", "Writes a whole new image to a second partition"),
        ("A failed update can leave a server broken", "A failed boot rolls back automatically"),
        ("Server configuration slowly drifts apart",
         "Every node stays identical, defined as code and set up at first boot"),
    ]
    lw = (CONTENT_W - 10) * 1 / 2.25
    rw = (CONTENT_W - 10) - lw
    rx = PAD + lw + 10
    box(s, PAD, top + 98, lw, 20, "TRADITIONAL SERVER OS", pt(13), GREY, bold=True,
        align=PP_ALIGN.CENTER, name="Left header")
    box(s, rx, top + 98, rw, 20, "FLATCAR", pt(13), CYAN, bold=True,
        align=PP_ALIGN.CENTER, name="Right header")
    y = top + 124
    heights = [48, 34, 34, 48]
    for i, ((a, b), h) in enumerate(zip(rows, heights)):
        rect(s, px(PAD), px(y), px(lw), px(h), DIM, MSO_SHAPE.ROUNDED_RECTANGLE, radius=0.1,
             name=f"Old {i + 1}")
        box(s, PAD + 12, y, lw - 24, h, a, pt(14.5), SILVER, anchor=MSO_ANCHOR.MIDDLE,
            name=f"Old {i + 1} text")
        rect(s, px(rx), px(y), px(rw), px(h), TEAL, MSO_SHAPE.ROUNDED_RECTANGLE, radius=0.1,
             name=f"New {i + 1}")
        rect(s, px(rx), px(y), px(4), px(h), CYAN, name=f"New {i + 1} accent")
        box(s, rx + 14, y, rw - 26, h, b, pt(14.5), WHITE, anchor=MSO_ANCHOR.MIDDLE,
            name=f"New {i + 1} text")
        y += h + 6


def build_trusted(s, top):
    box(s, PAD, top + 28, CONTENT_W, 36, "Trusted in production", pt(24), INK, bold=True,
        align=PP_ALIGN.CENTER, name="Heading")
    cards = [
        ("Run at scale", "Companies behind products you may already use rely on Flatcar across fleets of tens of thousands of nodes."),
        ("Adopters", "Adobe, STACKIT, DeepL, AT&T, 1&1 Mail & Media, Equinix Metal, Qualys, Wipro and many more."),
        ("GPU and AI ready", "The NVIDIA driver is its own system extension, so the OS and the driver update separately."),
        ("Vendor neutral", "A CNCF project guided by Steering and Technical committees, which keeps the project neutral and open."),
    ]
    cw = (CONTENT_W - 14) / 2
    rows = [(top + 76, 108), (top + 198, 108)]
    for i, (title, body) in enumerate(cards):
        x = PAD + (i % 2) * (cw + 14)
        y, h = rows[i // 2]
        rect(s, px(x), px(y), px(cw), px(h), PANEL, name=f"Card {i + 1}")
        rect(s, px(x), px(y), px(5), px(h), CYAN, name=f"Card {i + 1} accent")
        box(s, x + 19, y + 10, cw - 33, 26, title, pt(19), INK, bold=True,
            name=f"Card {i + 1} title")
        box(s, x + 19, y + 40, cw - 33, h - 46, body, pt(15), SOFT, name=f"Card {i + 1} text")


def build_faq(s, top):
    rect(s, 0, px(top), px(W), px(PANEL_H[2]), NAVY, name="FAQ panel")
    box(s, PAD, top + 26, CONTENT_W, 36, "Frequently Asked Questions", pt(24), WHITE, bold=True,
        align=PP_ALIGN.CENTER, name="Heading")
    items = [
        ("What does immutable mean?", "The core of the operating system is read-only, while your data and configuration stay writable. Updates replace the OS image, so all machines stay identical."),
        ("What does declarative mean?", "Think of it as Operating System as Code, like a Dockerfile for your OS. You describe the machine you want in a short YAML file, and it is applied automatically at first boot."),
        ("Can I install software on it?", "Yes, just not with a package manager on the host. Run your apps as containers, and add extra host tools as system extensions: only the runtime pieces you need."),
        ("What can I run on it?", "Any container workload, with Docker, containerd, Podman or whatever runtime you prefer. Kubernetes is popular but optional, and you can add your own tools as system extensions."),
        ("How often does it update?", "From every couple of weeks to every couple of years. Pick a channel (Alpha, Beta, Stable or LTS), then leave updates automatic or control them yourself."),
        ("How do I get started?", "Run it locally in QEMU with the Learning Series at learn.flatcar.org, no cloud account needed."),
    ]
    gap = 22
    cw = (CONTENT_W - gap) / 2
    for i, (q, a) in enumerate(items):
        x = PAD + (i % 2) * (cw + gap)
        y = top + 70 + (i // 2) * 98
        box(s, x, y, cw, 22, q, pt(15.5), CYAN, bold=True, name=f"Q{i + 1}")
        box(s, x, y + 22, cw, 70, a, pt(13.5), WHITE, name=f"A{i + 1}")


def add_fold_marks(s, tops):
    for y in tops[1:]:
        for x1, x2 in ((0, 14), (W - 14, W)):
            line(s, px(x1), px(y), px(x2), px(y), SOFT, 0.5, name="Fold mark")


def main():
    prs = new_presentation(px(W), px(H))
    tops = [0, PANEL_H[0], PANEL_H[0] + PANEL_H[1]]
    s = blank_slide(prs)
    fill_bg(s, WHITE)
    build_cover(s, tops[0])
    build_cards(s, tops[1])
    build_community(s, tops[2])
    add_fold_marks(s, tops)
    s = blank_slide(prs)
    fill_bg(s, WHITE)
    build_differs(s, tops[0])
    build_trusted(s, tops[1])
    build_faq(s, tops[2])
    add_fold_marks(s, tops)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    prs.save(OUT)
    print(f"✅ Built {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
