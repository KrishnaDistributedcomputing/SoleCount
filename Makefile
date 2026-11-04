.PHONY: setup setup-local appstore-setup test deploy release open clean help doctor status

help:
	@echo "SoleCount — Quick commands"
	@echo ""
	@echo "  make setup-local     Setup with no Apple membership (tools, project, simulator, Xcode)"
	@echo "  make setup           Same setup. If Apple details are missing, it does setup-local."
	@echo "  make doctor          Green/red checklist, with the fix for each red item"
	@echo "  make test            Run all tests in the iPhone Simulator (no Team ID needed)"
	@echo "  make open            Generate project and open in Xcode"
	@echo "  make release         Full path: records, tests, TestFlight, metadata, review"
	@echo "  make deploy          Same as make release"
	@echo "  make status          TestFlight build and App Store review state"
	@echo "  make appstore-setup  Only the App Store records (bundle ID and the free app)"
	@echo "  make clean           Remove build artifacts and generated project"
	@echo ""
	@echo "Waiting on Apple? Run: make setup-local"
	@echo "After Apple's email:  make doctor, then make release"

setup:
	@bash scripts/setup_mac.sh

setup-local:
	@bash scripts/setup_mac.sh --no-apple

doctor:
	@bash scripts/doctor.sh

status:
	@bash scripts/status.sh

appstore-setup:
	@bash scripts/prepare_apple.sh
	@bash scripts/require_apple.sh
	@fastlane setup

open:
	@xcodegen generate
	@open SoleCount.xcodeproj

test:
	@echo "Running tests in the iPhone Simulator. No Apple Team ID is needed."
	@fastlane ios test

release:
	@bash scripts/release.sh

deploy:
	@bash scripts/release.sh

clean:
	@rm -rf build DerivedData fastlane/test_output fastlane/screenshots
	@rm -rf SoleCount.xcodeproj SoleCount.xcworkspace
	@echo "Cleaned build artifacts and generated project"
