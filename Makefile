# Purrfect Recall — native app development
#
# Quick start (macOS):
#   make build        # API deps + PurrfectRecallMac debug build
#   make start        # API in background + launch Mac app
#   make rebuild      # full reinstall, rebuild, restart
#
# iOS:
#   make build-ios    # API deps + simulator build
#   make start-ios    # API + install/launch on booted simulator

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
MACOS_APP := $(DERIVED_DATA)/Build/Products/Debug/$(MACOS_SCHEME).app
IOS_APP := $(DERIVED_DATA)/Build/Products/Debug-iphonesimulator/$(IOS_SCHEME).app

MIGRATION_SCRIPTS := \
	add_review_table \
	add_flashcard_columns \
	add_flashcard_media_columns \
	add_fsrs_memory_columns

.PHONY: help \
	deps sync migrate verify-api build-api \
	build rebuild clean clean-py clean-native \
	start start-macos start-ios stop restart logs status \
	dev-api dev-web \
	xcodegen \
	build-macos build-ios run-macos run-ios-sim \
	release-macos release-ios \
	archive-macos archive-ios

.DEFAULT_GOAL := help

help: ## Show available targets
	@echo "Purrfect Recall — Makefile targets"
	@echo ""
	@grep -E '^[a-zA-Z0-9_.-]+:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  %-18s %s\n", $$1, $$2}' | sort
	@echo ""
	@echo "Variables: HOST=$(HOST) API_PORT=$(API_PORT) IOS_SIM=$(IOS_SIM)"

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

build-api: deps migrate verify-api ## Sync deps, migrate DB, verify API

build: build-api build-macos ## Build API + PurrfectRecallMac (debug)
	@echo "Build complete → $(MACOS_APP)"

rebuild: stop clean-py build start ## Reinstall deps, rebuild Mac app, restart API + app
	@echo "Rebuild complete."

clean-py: ## Reinstall Python virtualenv packages
	cd "$(ROOT)" && uv sync --reinstall

clean-native: ## Remove Xcode DerivedData
	rm -rf "$(DERIVED_DATA)"

clean: clean-native ## Remove native build artifacts and dist output
	rm -rf "$(DIST_DIR)"

# --- Run (native) ---

start-api: ## Start API in background
	@chmod +x "$(ROOT)/scripts/start-api.sh"
	@"$(ROOT)/scripts/start-api.sh"

start: start-api run-macos ## Start API + launch PurrfectRecallMac

start-macos: start ## Alias for start

start-ios: start-api run-ios-sim ## Start API + build/install/launch iOS simulator app

stop: ## Stop background API
	@chmod +x "$(ROOT)/scripts/stop-api.sh"
	@"$(ROOT)/scripts/stop-api.sh"

restart: stop start ## Restart API and launch Mac app

restart-ios: stop start-ios ## Restart API and launch iOS simulator app

dev-api: ## Run API in foreground with --reload
	cd "$(ROOT)" && uv run uvicorn app.main:app --reload --host "$(HOST)" --port "$(API_PORT)"

dev-web: ## Legacy: API + web frontend in foreground (./scripts/dev.sh)
	"$(ROOT)/scripts/dev.sh"

logs: ## Tail API log
	@tail -f "$(DEV_DIR)/backend.log"

status: ## Show API and native app status
	@port_pid() { lsof -ti ":$$1" 2>/dev/null | head -1; }; \
	api_pid="$$(port_pid $(API_PORT))"; \
	if [ -n "$$api_pid" ]; then \
		echo "api:    running on :$(API_PORT) (pid $$api_pid)"; \
	else \
		echo "api:    stopped"; \
	fi; \
	if [ -d "$(MACOS_APP)" ]; then \
		echo "macos:  built → $(MACOS_APP)"; \
	else \
		echo "macos:  not built (run make build-macos)"; \
	fi; \
	if pgrep -xq "$(MACOS_SCHEME)" 2>/dev/null; then \
		echo "macos:  running"; \
	else \
		echo "macos:  not running"; \
	fi

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

build-ios: build-api ## Debug build — PurrfectRecallIOS (simulator)
	cd "$(APPS_DIR)" && $(XCODEBUILD) \
		-scheme "$(IOS_SCHEME)" \
		-configuration Debug \
		-destination 'platform=iOS Simulator,name=$(IOS_SIM)' \
		-derivedDataPath "$(DERIVED_DATA)" \
		build

run-macos: ## Launch PurrfectRecallMac (.app must exist)
	@test -d "$(MACOS_APP)" || { echo "Missing $(MACOS_APP) — run make build-macos"; exit 1; }
	@open -n "$(MACOS_APP)"
	@echo "Launched $(MACOS_SCHEME)"

run-ios-sim: build-ios ## Install + launch PurrfectRecallIOS on booted simulator
	@test -d "$(IOS_APP)" || { echo "Missing $(IOS_APP)"; exit 1; }
	@xcrun simctl install booted "$(IOS_APP)"
	@xcrun simctl launch booted com.purrfectrecall.ios
	@echo "Launched $(IOS_SCHEME) on simulator"

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
