.PHONY: setup test deploy open clean help

help:
	@echo "SoleCount — Quick commands"
	@echo ""
	@echo "  make setup    One-time Mac setup (Homebrew, XcodeGen, fastlane, keys, generate project)"
	@echo "  make open     Generate project and open in Xcode"
	@echo "  make test     Run all tests"
	@echo "  make deploy   Full deployment (tests → TestFlight → App Review)"
	@echo "  make clean    Remove build artifacts and generated project"
	@echo ""
	@echo "For first-time setup, run: make setup"

setup:
	@bash scripts/setup_mac.sh

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
