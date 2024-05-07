# Lint all Swift code
# Requires swift-format: brew install swift-format
lint:
	swift-format lint --parallel --recursive .

# Format all Swift code
# Requires swift-format: brew install swift-format
format:
	swift-format format --in-place --recursive --parallel .

# Test all Swift code
test:
	swift test
