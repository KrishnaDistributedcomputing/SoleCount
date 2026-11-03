.PHONY: setup setup-local appstore-setup test deploy open clean help

help:
	@echo "SoleCount — Quick commands"
	@echo ""
	@echo "  make setup-local     Setup with no Apple membership (tools, project, simulator, Xcode)"
	@echo "  make setup           Same setup, and it asks for your Apple Team ID and API key"
	@echo "  make test            Run all tests in the iPhone Simulator (no Team ID needed)"
	@echo "  make open            Generate project and open in Xcode"
	@echo "  make appstore-setup  Create the app in App Store Connect (after Apple emails you)"
	@echo "  make deploy          Tests, TestFlight, and App Review (after Apple emails you)"
	@echo "  make clean           Remove build artifacts and generated project"
	@echo ""
	@echo "Waiting on Apple? Run: make setup-local"
	@echo "After Apple's email:  make setup, then make appstore-setup"

setup:
	@bash scripts/setup_mac.sh

setup-local:
	@bash scripts/setup_mac.sh --no-apple

appstore-setup:
	@bash scripts/require_apple.sh
	@fastlane setup

open:
	@xcodegen generate
	@open SoleCount.xcodeproj

test:
	@echo "Running tests in the iPhone Simulator. No Apple Team ID is needed."
	@fastlane ios test

deploy:
	@bash scripts/deploy.sh

clean:
	@rm -rf build DerivedData fastlane/test_output fastlane/screenshots
	@rm -rf SoleCount.xcodeproj SoleCount.xcworkspace
	@echo "Cleaned build artifacts and generated project"
