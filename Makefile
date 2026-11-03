.PHONY: setup appstore-setup test deploy open clean help

help:
	@echo "SoleCount — Quick commands"
	@echo ""
	@echo "  make setup           One-time Mac setup (Homebrew, XcodeGen, fastlane, keys, generate project)"
	@echo "  make appstore-setup  Create app in App Store Connect (bundle ID, pricing, IAP)"
	@echo "  make test            Run all tests"
	@echo "  make deploy          Full deployment (tests → TestFlight → App Review)"
	@echo "  make open            Generate project and open in Xcode"
	@echo "  make clean           Remove build artifacts and generated project"
	@echo ""
	@echo "First-time setup: make setup, then make appstore-setup"

setup:
	@bash scripts/setup_mac.sh

appstore-setup:
	@fastlane setup

open:
	@xcodegen generate
	@open SoleCount.xcodeproj

test:
	@fastlane ios test

deploy:
	@bash scripts/deploy.sh

clean:
	@rm -rf build DerivedData fastlane/test_output fastlane/screenshots
	@rm -rf SoleCount.xcodeproj SoleCount.xcworkspace
	@echo "Cleaned build artifacts and generated project"
