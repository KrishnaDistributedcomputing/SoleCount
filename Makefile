.PHONY: setup setup-local appstore-setup test deploy release submit open clean help doctor status check

help:
	@echo "SoleCount — Quick commands"
	@echo ""
	@echo "  make setup-local     Setup with no Apple membership (tools, project, simulator, Xcode)"
	@echo "  make setup           Same setup. If Apple details are missing, it does setup-local."
	@echo "  make doctor          Green/red checklist, with the fix for each red item"
	@echo "  make check           Fast identity and secret checks (no Xcode)"
	@echo "  make test            Run all tests in the iPhone Simulator (no Team ID needed)"
	@echo "  make open            Generate project and open in Xcode"
	@echo "  make release         Records, tests, TestFlight, and the store listing. Does not submit."
	@echo "  make submit          Send the latest TestFlight build to App Review"
	@echo "  make deploy          Same as make release"
	@echo "  make status          TestFlight build and App Store review state"
	@echo "  make appstore-setup  Only the App Store records (bundle ID and the free app)"
	@echo "  make clean           Remove build artifacts and generated project"
	@echo ""
	@echo "Waiting on Apple? Run: make setup-local"
	@echo "After Apple's email:  make doctor, then make release. After TestFlight: make submit"

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

check:
	@bash scripts/check_repo.sh
	@bash scripts/check_repo.sh --self-test

test:
	@echo "Running tests in the iPhone Simulator. No Apple Team ID is needed."
	@fastlane ios test

release:
	@bash scripts/release.sh

submit:
	@bash scripts/submit.sh

deploy:
	@bash scripts/release.sh

clean:
	@rm -rf build DerivedData fastlane/test_output fastlane/screenshots
	@rm -rf SoleCount.xcodeproj SoleCount.xcworkspace
	@echo "Cleaned build artifacts and generated project"
