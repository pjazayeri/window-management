APP      = WindowManager
BUNDLE   = $(APP).app
BINARY   = .build/release/$(APP)
PLIST    = Resources/Info.plist

.PHONY: build app run clean

build:
	swift build -c release

app: build
	mkdir -p $(BUNDLE)/Contents/MacOS
	mkdir -p $(BUNDLE)/Contents/Resources
	cp $(BINARY) $(BUNDLE)/Contents/MacOS/$(APP)
	cp $(PLIST)  $(BUNDLE)/Contents/Info.plist
	# Ad-hoc code sign so macOS will run the bundle
	codesign --force --deep --sign - $(BUNDLE)
	@echo "✓ Built $(BUNDLE)"

run: app
	open $(BUNDLE)

clean:
	rm -rf $(BUNDLE)
	swift package clean
