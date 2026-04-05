APP    = WindowManager
XCPROJ = $(APP).xcodeproj
BUILD  = build

.PHONY: generate build run clean setup icons

# ── Primary build (swift build, works without full Xcode) ──────────────────
build:
	swift build -c release

app: build
	mkdir -p $(BUILD)/$(APP).app/Contents/MacOS
	mkdir -p $(BUILD)/$(APP).app/Contents/Resources
	cp .build/release/$(APP)   $(BUILD)/$(APP).app/Contents/MacOS/$(APP)
	cp Resources/Info.plist    $(BUILD)/$(APP).app/Contents/Info.plist
	cp -r Sources/$(APP)/Assets.xcassets \
	      $(BUILD)/$(APP).app/Contents/Resources/
	# Compile asset catalog (actool ships with Command Line Tools)
	xcrun actool Sources/$(APP)/Assets.xcassets \
	  --compile $(BUILD)/$(APP).app/Contents/Resources \
	  --platform macosx --minimum-deployment-target 14.0 \
	  --app-icon AppIcon --output-partial-info-plist /dev/null 2>/dev/null || true
	codesign --force --deep --sign - $(BUILD)/$(APP).app
	@echo "✓ Built $(BUILD)/$(APP).app"

run: app
	open $(BUILD)/$(APP).app

# ── Xcode project (open in Xcode once installed, used for signing) ──────────
generate:
	xcodegen generate

$(XCPROJ):
	xcodegen generate

# ── One-time setup ──────────────────────────────────────────────────────────
icons:
	swift scripts/generate_icon.swift

setup: icons generate

# ── When Xcode IS installed ─────────────────────────────────────────────────
xcode-build: $(XCPROJ)
	xcodebuild \
	  -project $(XCPROJ) -scheme $(APP) \
	  -configuration Release \
	  CONFIGURATION_BUILD_DIR=$(PWD)/$(BUILD) \
	  CODE_SIGNING_ALLOWED=NO build

clean:
	rm -rf $(BUILD)
	swift package clean
