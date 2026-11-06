---
marp: true
theme: flatcar-a4
paginate: false
title: "Flatcar Container Linux: Flyer"
author: Flatcar Maintainers
---

<style>
/* A4 portrait tri-fold flyer (96 dpi: 794 x 1123 px). The page is split into
 * three equal panels at the fold lines (1123 / 3 = 374 px), and each panel
 * reads on its own when folded. */
section.flyer {
  padding: 0;
  font-size: 18px;
  line-height: 1.4;
  display: grid;
  grid-template-rows: 374px 375px 374px;
  background: #fff;
  color: #12172B;
}
section.flyer h1, section.flyer h2, section.flyer h3 { position: static; background: none; padding: 0; margin: 0; }
section.flyer .panel { position: relative; box-sizing: border-box; overflow: hidden; padding: 0 54px; display: flex; flex-direction: column; justify-content: center; }
section.flyer .panel.navy { background-color: #12172B; color: #fff; }

/* Fold marks at the page edges */
section.flyer .fold { position: absolute; left: 0; right: 0; height: 0; z-index: 5; }
section.flyer .fold::before, section.flyer .fold::after { content: ""; position: absolute; top: 0; width: 14px; border-top: 1px solid #8A93A8; }
section.flyer .fold::before { left: 0; }
section.flyer .fold::after { right: 0; }
section.flyer .fold.f1 { top: 374px; }
section.flyer .fold.f2 { top: 749px; }

/* Panel 1: cover */
section.flyer .p1 { border-bottom: 6px solid #09BAC8; }
section.flyer .p1 .brand { display: flex; align-items: center; gap: 30px; }
section.flyer .p1 img.logo { height: 104px; width: auto; flex: none; }
section.flyer .p1 h1 { color: #fff; font-size: 38px; line-height: 1.05; font-weight: 700; white-space: nowrap; }
section.flyer .p1 .tag { margin: 8px 0 0 0; color: #09BAC8; font-size: 21px; font-weight: 700; }
section.flyer .p1 .lead { margin: 28px 0 0 0; font-size: 21px; line-height: 1.4; color: #fff; }
section.flyer .p1 .lead strong { color: #09BAC8; }

/* Panel 2: what makes Flatcar different */
section.flyer .p2 h2 { font-size: 24px; font-weight: 700; color: #12172B; margin-bottom: 14px; }
section.flyer .cards { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
section.flyer .card { border-left: 5px solid #09BAC8; background: #F1F4F9; border-radius: 0 8px 8px 0; padding: 10px 14px 12px; }
section.flyer .card h3 { font-size: 19px; line-height: 1.15; font-weight: 700; color: #12172B; }
section.flyer .card p { margin: 4px 0 0 0; font-size: 15px; line-height: 1.33; color: #3A4460; }
section.flyer .card code { font-size: 13px; background: #E2E8F2; padding: 0 4px; border-radius: 3px; }
section.flyer .runs { margin-top: 14px; padding: 9px 14px; border-radius: 8px; background: #12172B; color: #fff; font-size: 15px; text-align: center; }
section.flyer .runs strong { color: #09BAC8; }

/* Panel 3: community and booth */
section.flyer .p3 h2 { font-size: 24px; font-weight: 700; color: #fff; margin-bottom: 12px; }
section.flyer .qrs { display: grid; grid-template-columns: repeat(4, 1fr); gap: 14px; }
section.flyer .qr { background: #fff; border-radius: 10px; padding: 8px 8px 9px; text-align: center; }
section.flyer .qr img { display: block; width: 118px; height: auto; margin: 0 auto; }
section.flyer .qr p { margin: 3px 0 0 0; font-size: 15px; font-weight: 700; line-height: 1.15; color: #12172B; }
section.flyer .qr p span { display: block; font-weight: 400; font-size: 12.5px; color: #3A4460; margin-top: 1px; }
section.flyer .info { display: grid; margin-top: 16px; }
section.flyer .info h3 { color: #09BAC8; font-size: 15px; letter-spacing: 0.1em; text-transform: uppercase; font-weight: 700; margin-bottom: 3px; }
section.flyer .info p { margin: 0; font-size: 16px; line-height: 1.4; color: #fff; }
section.flyer .info p strong { color: #fff; }

/* Page 2 (inside spread): how it differs, who uses it, quick answers */
section.flyer .p4 { border-bottom: 6px solid #09BAC8; }
section.flyer .p4 h2, section.flyer .p6 h2 { font-size: 24px; font-weight: 700; color: #fff; margin-bottom: 4px; }
section.flyer .p2 h2, section.flyer .p3 h2, section.flyer .p5 h2, section.flyer .p6 h2 { text-align: center; }
section.flyer .p4 h2 { text-align: center; margin-bottom: 14px; }
section.flyer .p5 h2 { font-size: 24px; font-weight: 700; color: #12172B; margin-bottom: 14px; }
section.flyer .sub { margin: 0 0 12px 0; font-size: 16px; color: #D5DBE8; }
section.flyer .cmp { display: grid; grid-template-columns: 1fr 1.25fr; gap: 6px 10px; }
section.flyer .cmp div { font-size: 14.5px; line-height: 1.3; padding: 7px 12px; border-radius: 6px; display: flex; align-items: center; }
section.flyer .cmp .h { font-size: 13px; font-weight: 700; letter-spacing: 0.1em; text-transform: uppercase; padding: 0 12px 2px; justify-content: center; }
section.flyer .cmp .h.a { color: #9AA3B8; background: none; }
section.flyer .cmp .h.b { color: #09BAC8; background: none; border-left: 0; }
section.flyer .cmp .a { background: rgba(255,255,255,0.07); color: #C3CAD9; }
section.flyer .cmp .b { background: rgba(9,186,200,0.16); color: #fff; border-left: 4px solid #09BAC8; }
section.flyer .faq { display: grid; grid-template-columns: 1fr 1fr; gap: 10px 22px; margin-top: 6px; }
section.flyer .faq h3 { color: #09BAC8; font-size: 15.5px; font-weight: 700; line-height: 1.2; }
section.flyer .faq p { margin: 2px 0 0 0; font-size: 13.5px; line-height: 1.3; color: #fff; }
</style>

<!-- _class: flyer -->
<!-- _paginate: false -->

<div class="fold f1"></div>
<div class="fold f2"></div>

<div class="panel navy p1">
  <div class="brand">
    <img class="logo" src="assets/flatcar-logo.svg" alt="Flatcar">
    <div>

# Flatcar Container Linux

<p class="tag">Minimal. Immutable. Secure by default.</p>
    </div>
  </div>
  <p class="lead">A <strong>fully free and open-source, community-driven</strong> Linux distribution that is minimal, security-focused and <strong>optimized to run containers</strong>.<br>A <strong>CNCF project</strong> that is always up to date and gives you full control over your fleet.</p>
</div>

<div class="panel p2">

## Why Flatcar

<div class="cards">
  <div class="card"><h3>Immutable, image-based</h3><p>A minimal footprint with a read-only, verified <code>/usr</code>. No package manager on the node, so every machine is the same.</p></div>
  <div class="card"><h3>Self-updating, with rollback</h3><p>A/B partitions apply updates in the background. You control when to reboot into the new image, and a bad update rolls back automatically.</p></div>
  <div class="card"><h3>Operating System as Code</h3><p>Describe the machine in YAML and Ignition applies units, files, SSH keys, users and disks at first boot. No interactive setup.</p></div>
  <div class="card"><h3>Extensible with sysexts</h3><p>Add Docker, Podman, Kubernetes or GPU drivers as systemd-sysext overlays, pinned to the version you want.</p></div>
</div>

<div class="runs"><strong>Supported wherever you run your containers:</strong> every major cloud, on-prem and bare metal</div>
</div>

<div class="panel navy p3">

## Get started and join us

<div class="qrs">
  <div class="qr"><img src="assets/qr/flatcar_org.png" alt="flatcar.org"><p>Website<span>flatcar.org</span></p></div>
  <div class="qr"><img src="assets/qr/flatcar_gh.png" alt="GitHub"><p>GitHub<span>flatcar/Flatcar</span></p></div>
  <div class="qr"><img src="assets/qr/flatcar_learning_series.png" alt="Learning series"><p>Learning series<span>learn.flatcar.org</span></p></div>
  <div class="qr"><img src="assets/qr/flatcar_discord.png" alt="Discord"><p>Discord<span>chat.flatcar.org</span></p></div>
</div>

<div class="info">
  <div>

### Come say hi

<p><strong>Join our Discord server</strong> to ask questions and chat with the maintainers: chat.flatcar.org<br>Office hours and dev syncs: every 2nd and 4th Thursday, 2:30 pm UTC</p>
  </div>
</div>
</div>
</div>

---

<!-- _class: flyer -->
<!-- _paginate: false -->

<div class="fold f1"></div>
<div class="fold f2"></div>

<div class="panel navy p4">

## How Flatcar differs

<div class="cmp">
  <div class="h a">Traditional server OS</div><div class="h b">Flatcar</div>
  <div class="a">Anyone can change software at any time</div><div class="b">Read-only system; extras run as containers or system extensions</div>
  <div class="a">Patches packages one by one, in place</div><div class="b">Writes a whole new image to a second partition</div>
  <div class="a">A failed update can leave a server broken</div><div class="b">A failed boot rolls back automatically</div>
  <div class="a">Server configuration slowly drifts apart</div><div class="b">Every node stays identical, defined as code and set up at first boot</div>
</div>
</div>

<div class="panel p5">

## Trusted in production

<div class="cards">
  <div class="card"><h3>Run at scale</h3><p>Companies behind products you may already use rely on Flatcar across fleets of tens of thousands of nodes.</p></div>
  <div class="card"><h3>Adopters</h3><p>Adobe, STACKIT, DeepL, AT&amp;T, 1&amp;1 Mail &amp; Media, Equinix Metal, Qualys, Wipro and many more.</p></div>
  <div class="card"><h3>GPU and AI ready</h3><p>The NVIDIA driver is its own system extension, so the OS and the driver update separately.</p></div>
  <div class="card"><h3>Vendor neutral</h3><p>A CNCF project guided by Steering and Technical committees, which keeps the project neutral and open.</p></div>
</div>
</div>

<div class="panel navy p6">

## Frequently Asked Questions

<div class="faq">
  <div><h3>What does immutable mean?</h3><p>The core of the operating system is read-only, while your data and configuration stay writable. Updates replace the OS image, so all machines stay identical.</p></div>
  <div><h3>What does declarative mean?</h3><p>Think of it as Operating System as Code, like a Dockerfile for your OS. You describe the machine you want in a short YAML file, and it is applied automatically at first boot.</p></div>
  <div><h3>Can I install software on it?</h3><p>Yes, just not with a package manager on the host. Run your apps as containers, and add extra host tools as system extensions: only the runtime pieces you need.</p></div>
  <div><h3>What can I run on it?</h3><p>Any container workload, with Docker, containerd, Podman or whatever runtime you prefer. Kubernetes is popular but optional, and you can add your own tools as system extensions.</p></div>
  <div><h3>How often does it update?</h3><p>From every couple of weeks to every couple of years. Pick a channel (Alpha, Beta, Stable or LTS), then leave updates automatic or control them yourself.</p></div>
  <div><h3>How do I get started?</h3><p>Run it locally in QEMU with the Learning Series at learn.flatcar.org, no cloud account needed.</p></div>
</div>
</div>
</div>
</div>
</div>
