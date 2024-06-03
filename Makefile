.PHONY: all
all: build package

.PHONY: build
# Build RSSBar
build:
	swift build --configuration release

.PHONY: run
# Run the program
run:
	swift run RSSBar

.PHONY: lint
# Lint all Swift code
# Requires swift-format: brew install swift-format
lint:
	swift-format lint --parallel --recursive .

.PHONY: format
# Format all Swift code
# Requires swift-format: brew install swift-format
format:
	swift-format format --in-place --recursive --parallel .

.PHONY: test
# Test all Swift code
test:
	swift test

.build/AppIcon.icns: SupportingFiles/RSSBar/icon.png
	rm -r .build/AppIcon.iconset .build/AppIcon.icns &>/dev/null || true
	mkdir -p .build/AppIcon.iconset
# Create icons for different sizes
	sips -z 16 16 $< --out ".build/AppIcon.iconset/icon_16x16.png"
	sips -z 32 32 $< --out ".build/AppIcon.iconset/icon_16x16@2x.png"
	sips -z 32 32 $< --out ".build/AppIcon.iconset/icon_32x32.png"
	sips -z 64 64 $< --out ".build/AppIcon.iconset/icon_32x32@2x.png"
	sips -z 128 128 $< --out ".build/AppIcon.iconset/icon_128x128.png"
	sips -z 256 256 $< --out ".build/AppIcon.iconset/icon_128x128@2x.png"
	sips -z 256 256 $< --out ".build/AppIcon.iconset/icon_256x256.png"
	sips -z 512 512 $< --out ".build/AppIcon.iconset/icon_256x256@2x.png"
	sips -z 512 512 $< --out ".build/AppIcon.iconset/icon_512x512.png"
# Compile icons
	iconutil --convert icns --output .build/AppIcon.icns .build/AppIcon.iconset

.PHONY: package
package: .build/AppIcon.icns
	mkdir -p .build/RSSBar.app/Contents/MacOS
	cp .build/release/RSSBar .build/RSSBar.app/Contents/MacOS
	mkdir -p .build/RSSBar.app/Contents/Resources
	cp .build/AppIcon.icns .build/RSSBar.app/Contents/Resources/AppIcon.icns
