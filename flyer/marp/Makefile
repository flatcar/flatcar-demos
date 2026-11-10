# Makefile for Marp Slides, works with Podman (preferred) or Docker.

.PHONY: all build clean artifacts help test ci-build ci-artifacts setup \
        native-build pptx native-clean native-artifacts watch preview shell \
        image image-rebuild nuke

# Configuration
SCRIPTS_DIR = scripts
# Container engine auto-detect: podman first, then docker. Override with:
#   make build ENGINE=docker
ENGINE     ?= $(shell command -v podman > /dev/null 2>&1 && echo podman || (command -v docker > /dev/null 2>&1 && echo docker))
# Compose follows the engine. Both `podman compose` and `docker compose` invoke
# a v2 compose plugin (podman delegates to whichever external provider is
# installed; docker uses its bundled cli-plugin). Override if needed with:
#   make build COMPOSE="podman-compose"   or   COMPOSE="docker-compose"
COMPOSE    ?= $(ENGINE) compose

# Detect whether we're already inside the build container (skip wrapping).
CONTAINER_ENV := $(shell [ -f /run/.containerenv ] && echo true || echo false)

# Function: run a command inside the slides-builder container (or natively if
# we're already inside it). Bails out with install instructions if no container
# engine is available.
# Usage: $(call run-in-container,command,description)
define run-in-container
	@if [ "$(CONTAINER_ENV)" = "true" ]; then \
		echo "$(2) (inside container)..."; \
		$(1); \
	elif [ -z "$(ENGINE)" ]; then \
		echo "❌ Error: no container engine found (looked for podman, docker)."; \
		echo ""; \
		echo "On Fedora:  sudo dnf install -y podman podman-compose"; \
		echo "On Ubuntu:  sudo apt install -y podman podman-compose"; \
		echo "            (or: sudo apt install -y docker.io docker-compose-plugin)"; \
		echo "On macOS:   brew install podman  (or install Docker Desktop)"; \
		echo "Then:       make setup && make build"; \
		echo ""; \
		echo "Or to build without a container (requires Node.js):"; \
		echo "  make native-build"; \
		exit 1; \
	else \
		echo "📦 $(2) (using $(COMPOSE))..."; \
		$(COMPOSE) run --rm slides-builder bash -c "$(1)"; \
	fi
endef

# Default target
all: build

# First-time setup: verify the engine is usable and build the image.
setup:
	@echo "📦 Setting up container build environment..."
	@if [ -z "$(ENGINE)" ]; then \
		echo "❌ Error: no container engine found (looked for podman, docker)."; \
		echo "On Fedora: sudo dnf install -y podman podman-compose"; \
		echo "On Ubuntu: sudo apt install -y podman podman-compose"; \
		echo "           (or: sudo apt install -y docker.io docker-compose-plugin)"; \
		exit 1; \
	fi
	@if ! $(ENGINE) info > /dev/null 2>&1; then \
		echo "❌ Error: $(ENGINE) is installed but not usable."; \
		echo "Try running '$(ENGINE) info' once interactively, then re-run 'make setup'."; \
		exit 1; \
	fi
	@echo "Engine : $(ENGINE)"
	@echo "Compose: $(COMPOSE)"
	@echo "Building slides-builder image (Marp CLI + Chromium pre-installed)..."
	@echo "(One-time build; subsequent builds reuse the cached layers.)"
	@$(COMPOSE) build
	@echo "✅ Container environment ready. Try 'make build'."

# Build the slides PDF (containerised by default).
build:
	$(call run-in-container,$(SCRIPTS_DIR)/build.sh,Building Marp slides)

# Clean build outputs.
clean:
	$(call run-in-container,$(SCRIPTS_DIR)/clean.sh,Cleaning all build files)

# Gather artifacts for distribution.
artifacts: build
	$(call run-in-container,$(SCRIPTS_DIR)/gather-artifacts.sh,Gathering artifacts)

# Build + verify the PDF was produced.
test: build
	@echo "✅ Testing build..."
	@test -f build/slides.pdf && echo "✅ PDF generated successfully" || (echo "❌ PDF generation failed" && exit 1)

# CI pipelines.
ci-build: clean build test
	@echo "🚀 CI build completed successfully"

ci-artifacts: ci-build artifacts
	@echo "📦 CI artifacts prepared"

# Open an interactive shell in the build container.
shell:
	@$(COMPOSE) run --rm slides-builder bash

# Container lifecycle ---------------------------------------------------------

# Build (or rebuild incrementally) the slides-builder image.
image:
	@echo "📦 Building slides-builder image ($(COMPOSE))..."
	@$(COMPOSE) build

# Full rebuild: ignore cache, re-pull the base image, then prune dangling layers.
image-rebuild:
	@echo "♻️  Forcing full rebuild of slides-builder image ($(COMPOSE))..."
	@$(COMPOSE) build --no-cache --pull
	@-$(ENGINE) image prune -f > /dev/null 2>&1 || true
	@echo "✅ Image rebuilt."

# Wipe the container + image so the next 'make setup' starts clean.
nuke:
	@echo "💣 Removing slides-builder container, image, and volumes..."
	@-$(COMPOSE) down --rmi all -v 2> /dev/null || true
	@-$(ENGINE) rmi -f slides-builder:local localhost/slides-builder:local 2> /dev/null || true
	@echo "✅ Container environment removed. Run 'make setup' to recreate."

# Native (non-container) builds, require Node.js + npm on the host.
native-build:
	@echo "📑 Building Marp slides (native)..."
	@$(SCRIPTS_DIR)/build.sh

native-clean:
	@echo "🧹 Cleaning all build files (native)..."
	@$(SCRIPTS_DIR)/clean.sh

# Native, fully editable PowerPoint (needs uv and rsvg-convert).
# scripts/build-pptx.py mirrors slides.md by hand, keep the two in sync.
pptx:
	@uv run --with python-pptx --with pillow python $(SCRIPTS_DIR)/build-pptx.py

native-artifacts: native-build
	@echo "📦 Gathering artifacts (native)..."
	@$(SCRIPTS_DIR)/gather-artifacts.sh

# Authoring helpers, always native (need interactive Node + browser).
watch:
	@npm run watch

preview:
	@npm run preview

help:
	@echo "Marp Slides Build System (Podman or Docker)"
	@echo "==========================================="
	@echo ""
	@echo "Engine : $(ENGINE)"
	@echo "Compose: $(COMPOSE)"
	@echo ""
	@echo "🚀 Quick Start:"
	@echo "  make setup    - First-time setup (build the container image)"
	@echo "  make build    - Build slides.pdf (inside container)"
	@echo "  make clean    - Clean build artifacts (inside container)"
	@echo ""
	@echo "📋 Main Targets (containerised, auto-detects podman/docker):"
	@echo "  build         - Build slides.pdf"
	@echo "  clean         - Clean all build files and directories"
	@echo "  artifacts     - Gather build artifacts for distribution"
	@echo "  test          - Build and verify the slides"
	@echo "  ci-build      - Full CI build pipeline"
	@echo "  ci-artifacts  - Full CI pipeline with artifacts"
	@echo "  shell         - Open an interactive shell in the build container"
	@echo ""
	@echo "🐳 Container lifecycle:"
	@echo "  image         - (Re)build slides-builder image (uses cache)"
	@echo "  image-rebuild - Full rebuild (--no-cache --pull + prune)"
	@echo "  nuke          - Remove the container + image"
	@echo ""
	@echo "🔧 Native (no container, requires Node.js):"
	@echo "  native-build      - Build without a container"
	@echo "  native-clean      - Clean without a container"
	@echo "  native-artifacts  - Gather artifacts without a container"
	@echo "  pptx              - Native editable PowerPoint (build/slides-native.pptx, needs uv + rsvg-convert)"
	@echo ""
	@echo "👀 Authoring (native only):"
	@echo "  watch     - Rebuild on save (npm run watch)"
	@echo "  preview   - Live preview in browser (npm run preview)"
	@echo ""
	@echo "💡 Override the engine or compose runtime if needed:"
	@echo "      make build ENGINE=docker"
	@echo "      make build COMPOSE=\"podman-compose\""
