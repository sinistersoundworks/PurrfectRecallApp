# Purrfect Recall — development and release targets
#
# Quick start:
#   make dev       # foreground API + frontend (Ctrl+C stops both)
#   make rebuild   # clean deps, migrate, restart background servers
#   make help      # list all targets

ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
APPS_DIR := $(ROOT)/apps
DEV_DIR := $(ROOT)/.dev
DIST_DIR := $(ROOT)/dist

HOST ?= 127.0.0.1
API_PORT ?= 8000
FRONTEND_PORT ?= 5500

DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer
export DEVELOPER_DIR

XCODEBUILD := xcodebuild
DERIVED_DATA := $(APPS_DIR)/build/DerivedData

MACOS_SCHEME := PurrfectRecallMac
IOS_SCHEME := PurrfectRecallIOS
IOS_SIM ?= iPhone 17

MIGRATION_SCRIPTS := \
	add_review_table \
	add_flashcard_columns \
	add_flashcard_media_columns \
	add_fsrs_memory_columns

.PHONY: help \
	deps sync migrate verify-api \
	build rebuild clean clean-py clean-native \
	dev start stop restart logs status \
	xcodegen \
	build-macos build-ios run-ios-sim \
	release-macos release-ios \
	archive-macos archive-ios

.DEFAULT_GOAL := help

help: ## Show available targets
	@echo "Purrfect Recall — Makefile targets"
	@echo ""
	@grep -E '^[a-zA-Z0-9_.-]+:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  %-18s %s\n", $$1, $$2}' | sort
	@echo ""
	@echo "Variables: HOST=$(HOST) API_PORT=$(API_PORT) FRONTEND_PORT=$(FRONTEND_PORT) IOS_SIM=$(IOS_SIM)"

# --- Python / API ---

deps sync: ## Install Python dependencies (uv sync)
	@command -v uv >/dev/null 2>&1 || { echo "uv required: https://docs.astral.sh/uv/"; exit 1; }
	cd "$(ROOT)" && uv sync

migrate: ## Run SQLite migration scripts (skipped if study.db missing)
	@if [ ! -f "$(ROOT)/study.db" ]; then \
		echo "No study.db — migrations skipped (DB created on first API start)."; \
	else \
		for script in $(MIGRATION_SCRIPTS); do \
			echo "→ scripts/$${script}.py"; \
			cd "$(ROOT)" && uv run python "scripts/$${script}.py"; \
		done; \
	fi

verify-api: ## Verify FastAPI app imports
	cd "$(ROOT)" && uv run python -c "from app.main import app; print('API OK')"

build: deps migrate verify-api ## Sync deps, migrate DB, verify API
	@echo "Build complete."

rebuild: stop clean-py build start ## Full rebuild: reinstall deps, migrate, restart servers
	@echo "Rebuild complete — servers running in background."

clean-py: ## Reinstall Python virtualenv packages
	cd "$(ROOT)" && uv sync --reinstall

clean-native: ## Remove Xcode DerivedData
	rm -rf "$(DERIVED_DATA)"

clean: clean-native ## Remove native build artifacts and dist output
	rm -rf "$(DIST_DIR)"

# --- Dev servers ---

dev: ## Run API + frontend in foreground (like ./scripts/dev.sh)
	"$(ROOT)/scripts/dev.sh"

start: build ## Start API + frontend in background
	@chmod +x "$(ROOT)/scripts/start-dev-background.sh"
	"$(ROOT)/scripts/start-dev-background.sh"

stop: ## Stop background API + frontend
	@chmod +x "$(ROOT)/scripts/stop-dev.sh"
	@"$(ROOT)/scripts/stop-dev.sh"

restart: stop start ## Restart background servers

logs: ## Tail background server logs
	@tail -f "$(DEV_DIR)/backend.log" "$(DEV_DIR)/frontend.log"

status: ## Show whether dev servers are running
	@port_pid() { lsof -ti ":$$1" 2>/dev/null | head -1; }; \
	for svc in backend:$(API_PORT) frontend:$(FRONTEND_PORT); do \
		name="$${svc%%:*}"; port="$${svc##*:}"; \
		pid="$$(port_pid $$port)"; \
		if [ -n "$$pid" ]; then \
			echo "$$name: running on :$$port (pid $$pid)"; \
		else \
			echo "$$name: stopped"; \
		fi; \
	done

# --- Xcode ---

xcodegen: ## Regenerate PurrfectRecall.xcodeproj from project.yml
	@command -v xcodegen >/dev/null 2>&1 || { echo "xcodegen required: brew install xcodegen"; exit 1; }
	cd "$(APPS_DIR)" && xcodegen generate

build-macos: ## Debug build — PurrfectRecallMac
	cd "$(APPS_DIR)" && $(XCODEBUILD) \
		-scheme "$(MACOS_SCHEME)" \
		-configuration Debug \
		-destination 'platform=macOS' \
		-derivedDataPath "$(DERIVED_DATA)" \
		build

build-ios: ## Debug build — PurrfectRecallIOS (simulator)
	cd "$(APPS_DIR)" && $(XCODEBUILD) \
		-scheme "$(IOS_SCHEME)" \
		-configuration Debug \
		-destination 'platform=iOS Simulator,name=$(IOS_SIM)' \
		-derivedDataPath "$(DERIVED_DATA)" \
		build

run-ios-sim: build-ios ## Build iOS app and launch on booted simulator
	@xcrun simctl install booted "$(DERIVED_DATA)/Build/Products/Debug-iphonesimulator/$(IOS_SCHEME).app"
	@xcrun simctl launch booted com.purrfectrecall.ios

release-macos: xcodegen ## Release build — PurrfectRecallMac (.app in dist/)
	@mkdir -p "$(DIST_DIR)"
	cd "$(APPS_DIR)" && $(XCODEBUILD) \
		-scheme "$(MACOS_SCHEME)" \
		-configuration Release \
		-destination 'platform=macOS' \
		-derivedDataPath "$(DERIVED_DATA)" \
		build
	cp -R "$(DERIVED_DATA)/Build/Products/Release/$(MACOS_SCHEME).app" "$(DIST_DIR)/"
	@echo "→ $(DIST_DIR)/$(MACOS_SCHEME).app"

release-ios: xcodegen ## Release build — PurrfectRecallIOS (.app in dist/)
	@mkdir -p "$(DIST_DIR)"
	cd "$(APPS_DIR)" && $(XCODEBUILD) \
		-scheme "$(IOS_SCHEME)" \
		-configuration Release \
		-destination 'generic/platform=iOS' \
		-derivedDataPath "$(DERIVED_DATA)" \
		build
	cp -R "$(DERIVED_DATA)/Build/Products/Release-iphoneos/$(IOS_SCHEME).app" "$(DIST_DIR)/"
	@echo "→ $(DIST_DIR)/$(IOS_SCHEME).app"

archive-macos: xcodegen ## Xcode archive for macOS (App Store / notarization)
	@mkdir -p "$(DIST_DIR)"
	cd "$(APPS_DIR)" && $(XCODEBUILD) \
		-scheme "$(MACOS_SCHEME)" \
		-configuration Release \
		-destination 'generic/platform=macOS' \
		-derivedDataPath "$(DERIVED_DATA)" \
		-archivePath "$(DIST_DIR)/$(MACOS_SCHEME).xcarchive" \
		archive
	@echo "→ $(DIST_DIR)/$(MACOS_SCHEME).xcarchive"

archive-ios: xcodegen ## Xcode archive for iOS (App Store)
	@mkdir -p "$(DIST_DIR)"
	cd "$(APPS_DIR)" && $(XCODEBUILD) \
		-scheme "$(IOS_SCHEME)" \
		-configuration Release \
		-destination 'generic/platform=iOS' \
		-derivedDataPath "$(DERIVED_DATA)" \
		-archivePath "$(DIST_DIR)/$(IOS_SCHEME).xcarchive" \
		archive
	@echo "→ $(DIST_DIR)/$(IOS_SCHEME).xcarchive"
