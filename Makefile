# This makefile is mainly intended for use on the CI server (Travis). It
# requires xcpretty to be installed.

# If you are trying to build a release locally consider using the build.rb
# script in the Tools directory instead.


BUILD_DIR = OBJROOT="$(CURDIR)/build" SYMROOT="$(CURDIR)/build"
SHELL = /bin/bash -e -o pipefail
IOS = -scheme OCMockLib -destination 'platform=iOS Simulator,OS=latest,name=iPhone 11' $(BUILD_DIR)
MACOS = -scheme OCMock -sdk macosx $(BUILD_DIR)
XCODEBUILD = xcodebuild -project "$(CURDIR)/Source/OCMock.xcodeproj"

ci: clean test

clean:
	$(XCODEBUILD) clean
	rm -rf "$(CURDIR)/build"

test: test-ios test-macosx

test-ios:
	@echo "Running iOS tests..."
	$(XCODEBUILD) $(IOS) test | xcpretty -c

test-macosx:
	@echo "Running macOS tests..."
	$(XCODEBUILD) $(MACOS) test | xcpretty -c
